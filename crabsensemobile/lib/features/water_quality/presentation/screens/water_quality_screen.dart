// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/app_back.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../bloc/water_quality_bloc.dart';
import '../bloc/water_quality_event.dart';
import '../bloc/water_quality_state.dart';
import '../models/farm_filter_model.dart';
import '../widgets/farm_pond_filter_widget.dart';
import '../../data/repositories/scoped_history_service.dart';
import '../widgets/scoped_history_chart.dart';
import '../widgets/live_water_metrics.dart';

class WaterQualityScreen extends StatelessWidget {
  const WaterQualityScreen({super.key, this.farmId, this.pondId});

  final String? farmId;
  final String? pondId;

  @override
  Widget build(BuildContext context) => BlocProvider<WaterQualityBloc>(
        create: (_) => sl<WaterQualityBloc>()
          ..add(
            WaterQualityLoadRequested(
              farmId: farmId ?? 'default',
              // A row/box route inherits the area RAS reference.
            ),
          ),
        child: const _WaterQualityView(),
      );
}

class _WaterQualityView extends StatefulWidget {
  const _WaterQualityView();

  @override
  State<_WaterQualityView> createState() => _WaterQualityViewState();
}

class _WaterQualityViewState extends State<_WaterQualityView>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  StreamSubscription<List<NetworkType>>? _connectivitySubscription;
  bool _historyOnline = false;
  bool _foreground = false;
  int _networkGeneration = 0;
  DateTime? _onlineSince;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _startAutoRefreshTimer();
    _listenToConnectivity();
    unawaited(_probeHistoryNetwork());
  }

  void _startAutoRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!mounted) return;
      await _probeHistoryNetwork();
      final isOnline = await sl<NetworkInfo>().isConnected;
      if (isOnline && mounted) {
        context.read<WaterQualityBloc>().add(const WaterQualityRefreshRequested());
      }
    });
  }

  void _setHistoryNetwork(bool available) {
    if (!mounted) return;
    final next = available && _foreground;
    if (next == _historyOnline) return;
    setState(() {
      _historyOnline = next;
      _onlineSince = next ? DateTime.now() : null;
    });
    if (!next) {
      // Revoke pending/displayed history before waiting for SQLite purge.
      unawaited(sl<ScopedHistoryService>().invalidate());
    } else {
      context.read<WaterQualityBloc>().add(const WaterQualityRefreshRequested());
    }
  }

  Future<void> _probeHistoryNetwork() async {
    final generation = ++_networkGeneration;
    final available = await historyNetworkAvailable(sl<NetworkInfo>());
    if (!mounted || generation != _networkGeneration) return;
    _setHistoryNetwork(available);
  }

  void _listenToConnectivity() {
    _connectivitySubscription =
        sl<NetworkInfo>().onNetworkTypesChanged.listen((types) {
      ++_networkGeneration;
      _setHistoryNetwork(historyTransportAvailable(types));
    }, onError: (Object _) {
      ++_networkGeneration;
      _setHistoryNetwork(false);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ++_networkGeneration;
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _setHistoryNetwork(false);
    } else {
      unawaited(_probeHistoryNetwork());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ++_networkGeneration;
    _refreshTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navPad = MediaQuery.paddingOf(context).bottom + 88;
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: kHomeBg,
        title: const Text('Giám sát môi trường'),
        actions: [TextButton.icon(
          key: const Key('open-water-bench'),
          onPressed: () => context.push(Uri(path: RoutePaths.waterBench,
            queryParameters: {if (context.read<WaterQualityBloc>().state is WaterQualityLoaded)
              'farmingAreaId': (context.read<WaterQualityBloc>().state as WaterQualityLoaded).farmId}).toString()),
          icon: const Icon(Icons.science_outlined), label: const Text('Phân tích nước'))],
      ),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<WaterQualityBloc, WaterQualityState>(
          builder: (context, state) {
            if (state is WaterQualityLoading || state is WaterQualityInitial) {
              return _SkeletonBody(bottom: navPad);
            }
            if (state is WaterQualityError) {
              return _ErrorBody(
                isOffline: state.isOffline,
                message: state.message,
                onRetry: () => context.read<WaterQualityBloc>().add(
                      const WaterQualityRefreshRequested(),
                    ),
              );
            }
            if (state is WaterQualityLoaded) {
              return RefreshIndicator(
                color: kHomePrimary,
                onRefresh: () async {
                  final bloc = context.read<WaterQualityBloc>();
                  // Subscribe before dispatch; bounded UI wait even on route disposal.
                  final finished = bloc.stream.firstWhere(
                    (s) => (s is WaterQualityLoaded && !s.isRefreshing) || s is WaterQualityError,
                  );
                  bloc.add(const WaterQualityRefreshRequested());
                  try {
                    await finished.timeout(const Duration(seconds: 60));
                  } on TimeoutException {
                    // The BLoC continues to own the in-flight request.
                  } on StateError {
                    // The BLoC was closed when the screen was disposed.
                  }
                },
                child: _WaterQualityContent(state: state, bottomPad: navPad,
                  historyOnline: _historyOnline && _onlineSince != null &&
                    state.lastRefreshedAt != null &&
                    !state.lastRefreshedAt!.isBefore(_onlineSince!)),
              );
            }
            return _SkeletonBody(bottom: navPad);
          },
        ),
      ),
    );
  }
}

class _WaterQualityContent extends StatefulWidget {
  const _WaterQualityContent({required this.state, required this.bottomPad,
    required this.historyOnline});

  final WaterQualityLoaded state;
  final double bottomPad;
  final bool historyOnline;

  @override
  State<_WaterQualityContent> createState() => _WaterQualityContentState();
}

class _WaterQualityContentState extends State<_WaterQualityContent> {
  List<FarmOption> _farms = const [];
  bool _farmsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    try {
      final areasResult = await sl<ApiClient>()
          .safeGet<Map<String, dynamic>>(ApiConstants.farmingAreas);

      List<dynamic> extract(Map<String, dynamic>? body) {
        if (body == null) return const [];
        if (body['data'] is List) return body['data'] as List;
        if (body['items'] is List) return body['items'] as List;
        return const [];
      }

      final areas = extract(areasResult.data.data);
      final farms = <FarmOption>[];
      for (final raw in areas) {
        final map = Map<String, dynamic>.from(raw as Map);
        final id = (map['id'] ?? '').toString();
        if (id.isEmpty) continue;
        farms.add(FarmOption(
          id: id,
          name: (map['name'] ?? map['code'] ?? 'Khu').toString(),
        ));
      }

      if (!mounted) return;
      setState(() {
        _farms = farms.isEmpty
            ? [FarmOption(id: widget.state.farmId, name: 'Khu hiện tại', ponds: const [])]
            : farms;
        _farmsLoading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _farms = [FarmOption(id: widget.state.farmId, name: 'Khu hiện tại', ponds: const [])];
        _farmsLoading = false;
      });
    }
  }

  void _onFilterChanged(String farmId, String? _) {
    context.read<WaterQualityBloc>().add(
          WaterQualityFarmChanged(farmId: farmId),
        );
  }

  @override
  Widget build(BuildContext context) {
    final readings = widget.state.readings;
    final resolvedFarmId = widget.state.farmId;
    final online = widget.historyOnline && !widget.state.isOffline;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _HeroHeader(
            onBack: () => appBack(context),
            onRefresh: () => context
                .read<WaterQualityBloc>()
                .add(const WaterQualityRefreshRequested()),
            filter: _farmsLoading
                ? const LinearProgressIndicator(
                    minHeight: 2,
                    color: kHomePrimary,
                    backgroundColor: kHomePrimaryBg,
                  )
                : FarmPondFilterWidget(
                    farms: _farms,
                    selectedFarmId: resolvedFarmId,
                    areaOnly: true,
                    isLoading: widget.state.isRefreshing,
                    embedded: true,
                    onSelectionChanged: _onFilterChanged,
                  ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, widget.bottomPad),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (widget.state.isOffline) ...[
                const _Banner(
                  icon: Icons.wifi_off_rounded,
                  title: 'Mất kết nối mạng',
                  subtitle: 'Không hiển thị lịch sử khi chưa xác minh quyền.',
                  color: kHomeWarning,
                ),
                const SizedBox(height: 10),
              ],
              LiveWaterMetrics(
                areaId: resolvedFarmId,
                rowId: null,
                readings: readings,
                online: online && !widget.state.isRefreshing,
                now: DateTime.now(),
              ),
              const SizedBox(height: 16),
              ScopedHistoryChart(
                areaId: resolvedFarmId,
                rowId: null,
                readings: readings,
                online: widget.historyOnline && !widget.state.isOffline,
                fetch: sl<ScopedHistoryService>().fetchOnline,
                revision: () => sl<ScopedHistoryService>().revision,
                invalidations: sl<ScopedHistoryService>().invalidations,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.onBack,
    required this.onRefresh,
    required this.filter,
  });

  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final Widget filter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            SizedBox(
              height: 210,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/background_chao_user.png',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.35),
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFFBFE8D4),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.55, 1.0],
                        colors: [
                          Color(0x33FFFFFF),
                          Color(0x00FFFFFF),
                          Color(0xCCF7FCFA),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 10, 14, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: onBack,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: Color(0xFF1F6B4A),
                            ),
                          ),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4F5C4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.water_drop_rounded,
                              size: 20,
                              color: Color(0xFF2F8A4E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chất lượng nước',
                                  style: TextStyle(
                                    color: Color(0xFF163A2C),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                                ),
                                Text(
                                  'Nước tuần hoàn chung khu',
                                  style: TextStyle(
                                    color: Color(0xFF5A7A6C),
                                    fontSize: 12,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: onRefresh,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFD5E8DC),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  size: 20,
                                  color: Color(0xFF2F8A4E),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: filter,
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Text(subtitle,
                    style: const TextStyle(color: kHomeTextSub, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.isOffline,
    required this.message,
    required this.onRetry,
  });

  final bool isOffline;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final color = isOffline ? kHomeWarning : kHomeDanger;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Không thể tải dữ liệu cảm biến',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kHomeTextSub, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: kHomePrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody({required this.bottom});
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
      children: const [
        _Skel(height: 168),
        SizedBox(height: 12),
        _Skel(height: 88),
        SizedBox(height: 14),
        _Skel(height: 220),
        SizedBox(height: 14),
        _Skel(height: 240),
        SizedBox(height: 14),
        _Skel(height: 160),
      ],
    );
  }
}

class _Skel extends StatelessWidget {
  const _Skel({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: kHomeBorder.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}
