import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes.dart';
import '../../../../core/utils/app_back.dart';
import '../../../../app/theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/box_remote_data_source.dart';
import '../../data/models/crab_model.dart';
import '../widgets/box_history_sections.dart';
import '../widgets/crab_avatar.dart';
import '../widgets/daily_box_care_sheet.dart';
import 'crab_list_screen.dart';
import '../../../../shared/widgets/errors/error_state_widget.dart';
import '../../domain/entities/box.dart';
import '../../domain/entities/box_enums.dart';
import '../../domain/usecases/get_box_details_usecase.dart';
import '../bloc/box_bloc.dart';
import '../bloc/box_event.dart';
import '../bloc/box_state.dart';

/// Box Details Screen — Light theme rebuild.
class BoxDetailsScreen extends StatelessWidget {
  const BoxDetailsScreen({required this.boxId, super.key});

  final String boxId;

  @override
  Widget build(BuildContext context) => BlocProvider<BoxBloc>(
    create: (_) =>
        BoxBloc(getBoxDetails: sl<GetBoxDetailsUseCase>())
          ..add(BoxDetailsLoadRequested(boxId)),
    child: _BoxDetailsView(boxId: boxId),
  );
}

// ─── Internal view ────────────────────────────────────────────────────────────

class _BoxDetailsView extends StatelessWidget {
  const _BoxDetailsView({required this.boxId});

  final String boxId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Material(
          color: Colors.transparent,
          child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background_chao_user.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
            SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.black,
                  ),
                  onPressed: () =>
                      appBack(context, fallback: RoutePaths.boxes),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Chi tiết hộp nuôi',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Chi tiết & chăm sóc',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.black,
                  ),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => SafeArea(
                      child: ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: const Text('Nhật ký vận hành'),
                        onTap: () {
                          Navigator.pop(context);
                          context.push(RoutePaths.operationsForBox(boxId));
                        },
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.black,
                  ),
                  onPressed: () => context.read<BoxBloc>().add(
                    BoxDetailsRefreshRequested(boxId),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
        ),
      ),
      body: BlocBuilder<BoxBloc, BoxState>(
        builder: (context, state) {
          if (state is BoxLoading) return const _SkeletonDetails();
          if (state is BoxError) {
            return ErrorStateWidget(
              icon: state.isOffline ? Icons.wifi_off : Icons.error_outline,
              title: state.isOffline ? 'Không có kết nối' : 'Đã xảy ra lỗi',
              message: state.message,
              onRetry: () =>
                  context.read<BoxBloc>().add(BoxDetailsLoadRequested(boxId)),
            );
          }
          if (state is BoxLoaded) {
            return RefreshIndicator(
              color: kHomePrimary,
              onRefresh: () async {
                context.read<BoxBloc>().add(BoxDetailsRefreshRequested(boxId));
                await context.read<BoxBloc>().stream.firstWhere(
                  (s) => s is BoxLoaded && !s.isRefreshing || s is BoxError,
                );
              },
              child: _BoxContent(box: state.box),
            );
          }
          return const _SkeletonDetails();
        },
      ),
    );
  }
}

// ─── Content ──────────────────────────────────────────────────────────────────

class _BoxContent extends StatelessWidget {
  const _BoxContent({required this.box});

  final Box box;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Staleness banner
          if (box.isDataStale) ...[_StaleBanner(), const SizedBox(height: 12)],

          // Section 1: Box info
          _BoxInfoCard(box: box),
          const SizedBox(height: 12),

          _SummaryMetrics(box: box),
          const SizedBox(height: 12),
          _TabSection(box: box),
        ],
      ),
    );
  }
}

class _SummaryMetrics extends StatefulWidget {
  const _SummaryMetrics({required this.box});
  final Box box;

  @override
  State<_SummaryMetrics> createState() => _SummaryMetricsState();
}

class _SummaryMetricsState extends State<_SummaryMetrics> {
  int _molts = 0;
  int _moves = 0;
  double? _crabWeight;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  @override
  void didUpdateWidget(covariant _SummaryMetrics oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final api = sl<ApiClient>();
      final crabs = await sl<BoxRemoteDataSource>().getCrabsByBox(widget.box.id);
      final crabId = crabs.isEmpty ? null : crabs.first.id;
      var molts = 0;
      var moves = 0;
      double? crabWeight;
      if (crabs.isNotEmpty) {
        crabWeight = crabs.first.weight;
      }
      if (crabId != null && crabId.isNotEmpty) {
        try {
          final moltRes = await api.get<dynamic>(
            ApiConstants.crabMoltings(crabId),
          );
          molts = _count(moltRes.data);
        } catch (_) {}
        try {
          final moveRes = await api.get<dynamic>(
            ApiConstants.crabAllocations(crabId),
          );
          moves = _count(moveRes.data);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _molts = molts;
        _moves = moves;
        _crabWeight = crabWeight;
      });
    } catch (_) {}
  }

  static int _count(dynamic raw) {
    if (raw is List) return raw.length;
    if (raw is Map) {
      final data = raw['data'] ?? raw['items'] ?? raw['results'];
      if (data is List) return data.length;
      if (data is Map) {
        final items = data['items'] ?? data['results'] ?? data['data'];
        if (items is List) return items.length;
        final n = data['total'] ?? data['count'];
        if (n is num) return n.toInt();
      }
      final n = raw['total'] ?? raw['count'];
      if (n is num) return n.toInt();
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.box;
    final items = [
      ('Ngày nuôi', '${_daysRaised(box)} ngày', Icons.calendar_today_rounded),
      (
        'Khối lượng',
        _crabWeight != null && _crabWeight! > 0
            ? '${_crabWeight!.toStringAsFixed(1)} g'
            : (box.averageWeight > 0
                  ? '${box.averageWeight.toStringAsFixed(1)} g'
                  : '—'),
        Icons.monitor_weight_outlined,
      ),
      ('Số lần lột xác', '$_molts', Icons.autorenew_rounded),
      ('Số lần chuyển hộp', '$_moves', Icons.swap_horiz_rounded),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.85,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _MetricCard(
            label: items[i].$1,
            value: items[i].$2,
            icon: items[i].$3,
          ),
        ],
      ],
    );
  }

  int _daysRaised(Box box) =>
      DateTime.now().difference(box.createdAt.toLocal()).inDays.clamp(0, 99999);
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: homeCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kHomePrimary, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: kHomeTextMain,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: kHomeTextSub),
        ),
      ],
    ),
  );
}

// ─── Stale Banner ─────────────────────────────────────────────────────────────

class _StaleBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kHomeWarningBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kHomeWarning.withOpacity(0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: kHomeWarning, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dữ liệu có thể đã cũ',
              style: TextStyle(
                color: kHomeWarning,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Box Info Card ────────────────────────────────────────────────────────────

class _BoxInfoCard extends StatelessWidget {
  const _BoxInfoCard({required this.box});

  final Box box;

  /// Nhãn + màu trạng thái hộp — LẤY ĐÚNG bảng của app desktop
  /// (`box_detail_page.dart`): active → xanh, empty/inactive → xám,
  /// maintenance → vàng. Trước đây mobile gán `maintenance` thành "Sắp lột xác"
  /// và tô bằng bộ màu cũ (kHomeWarning/kHomeSecondary) nên lệch hẳn desktop.
  Color _statusColor() {
    switch (box.status) {
      case BoxStatus.active:
        return CrabSenseColors.statusNormal;
      case BoxStatus.inactive:
      case BoxStatus.harvested:
        return CrabSenseColors.statusIdle;
      case BoxStatus.maintenance:
        return CrabSenseColors.statusWatch;
    }
  }

  String _statusLabel() {
    switch (box.status) {
      case BoxStatus.active:
        return 'Bình thường';
      case BoxStatus.inactive:
      case BoxStatus.maintenance:
      case BoxStatus.harvested:
        return box.status == BoxStatus.maintenance
            ? 'Cần theo dõi'
            : 'Hộp trống';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusC = _statusColor();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: homeCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kHomePrimaryBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: kHomePrimary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Thông tin hộp',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kHomeTextMain,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusC.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusC.withOpacity(0.5)),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStyle(
                    color: statusC,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: kHomeBorder),
          const SizedBox(height: 14),
          _DetailRow(
            label: 'Mã hộp',
            value: box.qrCode.isNotEmpty ? box.qrCode : box.id,
          ),
          _DetailRow(
            label: 'Ngày thả',
            value: DateFormat('dd/MM/yyyy').format(box.createdAt.toLocal()),
          ),
          _DetailRow(
            label: 'Ngày nuôi',
            value:
                '${DateTime.now().difference(box.createdAt.toLocal()).inDays.clamp(0, 99999)} ngày',
          ),
          _DetailRow(
            label: 'Khu nuôi',
            value: (box.location.label == null ||
                    box.location.label!.trim().isEmpty)
                ? 'Chưa cập nhật'
                : box.location.label!,
          ),
          _LotRow(boxId: box.id),
        ],
      ),
    );
  }
}

class _LotRow extends StatefulWidget {
  const _LotRow({required this.boxId});
  final String boxId;

  @override
  State<_LotRow> createState() => _LotRowState();
}

class _LotRowState extends State<_LotRow> {
  String _lot = '—';
  String _species = '—';
  String _length = '—';
  String _width = '—';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _LotRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  Future<void> _load() async {
    try {
      final crabs = await sl<BoxRemoteDataSource>().getCrabsByBox(widget.boxId);
      if (!mounted || crabs.isEmpty) return;
      final crab = crabs.first;
      final code = crab.lotCode?.trim();
      var lot = crab.lotName?.trim();
      if (lot == null || lot.isEmpty || lot == code) {
        lot = await _lotNameForCode(code) ?? lot;
      }
      setState(() {
        _lot = (lot == null || lot.isEmpty) ? (code ?? '—') : lot;
        final type = crab.crabType?.trim();
        _species = (type == null || type.isEmpty) ? '' : type;
        _length = crab.carapaceLengthMm == null || crab.carapaceLengthMm! <= 0
            ? '—'
            : '${crab.carapaceLengthMm!.toStringAsFixed(1)} mm';
        _width = crab.carapaceWidthMm == null || crab.carapaceWidthMm! <= 0
            ? '—'
            : '${crab.carapaceWidthMm!.toStringAsFixed(1)} mm';
      });
    } catch (_) {}
  }

  Future<String?> _lotNameForCode(String? code) async {
    if (code == null || code.isEmpty) return null;
    final res = await sl<ApiClient>().get<dynamic>(ApiConstants.crabLots);
    final decoded = jsonDecode(jsonEncode(res.data));
    dynamic raw = decoded;
    if (decoded is Map) raw = decoded['data'] ?? decoded['Data'] ?? decoded;
    if (raw is! List) return null;
    for (final item in raw) {
      if (item is! Map) continue;
      final lotCode =
          (item['lotCode'] ?? item['LotCode'] ?? item['code'])?.toString();
      if (lotCode != code) continue;
      final name = (item['name'] ?? item['Name'])?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _DetailRow(label: 'Lô cua', value: _lot),
      if (_species.isNotEmpty) _DetailRow(label: 'Loại cua', value: _species),
      _DetailRow(label: 'Dài mai', value: _length),
      _DetailRow(label: 'Rộng mai', value: _width),
    ],
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: kHomeTextSub,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: kHomeTextMain,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Water Quality Card ───────────────────────────────────────────────────────

class _WaterQualityCard extends StatefulWidget {
  const _WaterQualityCard({required this.box});

  final Box box;

  @override
  State<_WaterQualityCard> createState() => _WaterQualityCardState();
}

class _WaterQualityCardState extends State<_WaterQualityCard> {
  final List<_WqMetric> _metrics = [
    _WqMetric('pH', '7.8', 'pH', Icons.science_rounded, true),
    _WqMetric('DO', '5.2', 'mg/L', Icons.air_rounded, true),
    _WqMetric('Nhiệt độ', '28.3', '°C', Icons.thermostat_rounded, true),
    _WqMetric('NH3', '0.02', 'mg/L', Icons.biotech_rounded, true),
  ];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: homeCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kHomeSecondaryBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: kHomeSecondary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Chất lượng nước',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kHomeTextMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const LinearProgressIndicator(
              minHeight: 3,
              color: kHomePrimary,
              backgroundColor: kHomePrimaryBg,
            )
          else
            Row(
              children: _metrics.map((m) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _WqMetricTile(metric: m),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 14),
          // Chart placeholder
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: kHomeBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kHomeBorder),
            ),
            child: const Center(
              child: Text(
                'Biểu đồ 24 giờ qua',
                style: TextStyle(color: kHomeTextHint, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go(
                    widget.box.farmId.isNotEmpty
                        ? RoutePaths.waterQualityForFarm(widget.box.farmId)
                        : RoutePaths.waterQuality,
                  ),
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('Lịch sử'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kHomePrimary,
                    side: const BorderSide(color: kHomePrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    minimumSize: Size.zero,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go(
                    widget.box.farmId.isNotEmpty
                        ? RoutePaths.waterQualityForFarm(widget.box.farmId)
                        : RoutePaths.waterQuality,
                  ),
                  icon: const Icon(Icons.bar_chart_rounded, size: 16),
                  label: const Text('Chi tiết'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kHomePrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    minimumSize: Size.zero,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WqMetric {
  const _WqMetric(this.label, this.value, this.unit, this.icon, this.isOk);

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final bool isOk;
}

class _WqMetricTile extends StatelessWidget {
  const _WqMetricTile({required this.metric});

  final _WqMetric metric;

  @override
  Widget build(BuildContext context) {
    final statusC = metric.isOk ? kHomePrimary : kHomeDanger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: kHomeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kHomeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(metric.icon, color: statusC, size: 16),
          const SizedBox(height: 4),
          Text(
            metric.value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: kHomeTextMain,
            ),
          ),
          Text(
            metric.unit,
            style: const TextStyle(fontSize: 10, color: kHomeTextHint),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusC.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              metric.isOk ? 'OK' : 'Nguy hiểm',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: statusC,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Section ──────────────────────────────────────────────────────────────

class _TabSection extends StatelessWidget {
  const _TabSection({required this.box});

  final Box box;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: homeCardDecoration(),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kHomeBorder)),
            ),
            child: const TabBar(
              labelColor: kHomePrimary,
              unselectedLabelColor: kHomeTextSub,
              indicatorColor: kHomePrimary,
              indicatorWeight: 2,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'Theo dõi'),
                Tab(text: 'Cho ăn'),
                Tab(text: 'Lịch sử'),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: DefaultTabController.of(context),
            builder: (context, _) {
              final index = DefaultTabController.of(context).index;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: switch (index) {
                  0 => _OverviewTab(box: box),
                  1 => _FeedingTab(box: box),
                  _ => BoxHistorySections(
                    key: ValueKey('${box.id}-${box.averageWeight}'),
                    boxId: box.id,
                  ),
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatefulWidget {
  const _OverviewTab({required this.box});

  final Box box;

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  CrabModel? _crab;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCrab();
  }

  Future<void> _loadCrab() async {
    try {
      final crabs = await sl<BoxRemoteDataSource>().getCrabsByBox(
        widget.box.id,
      );
      if (mounted) setState(() => _crab = crabs.isEmpty ? null : crabs.first);
    } catch (_) {
      // The box detail remains usable when the optional crab lookup fails.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Chăm sóc trực tiếp',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: kHomeTextMain,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Ghi nhanh lượng ăn và tình trạng của cua trong hộp.',
          style: TextStyle(color: kHomeTextSub, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const LinearProgressIndicator(
            minHeight: 3,
            color: kHomePrimary,
            backgroundColor: kHomePrimaryBg,
          )
        else if (_crab == null)
          const Text(
            'Hộp chưa có cua để ghi phiếu chăm sóc.',
            style: TextStyle(color: kHomeTextSub, fontSize: 13),
          )
        else
          DailyBoxCareSheet(
            key: ValueKey(_crab!.id),
            boxId: widget.box.id,
            boxCode: widget.box.qrCode.isNotEmpty
                ? widget.box.qrCode
                : widget.box.id,
            farmId: widget.box.farmId,
            crab: _crab!,
            embedded: true,
            mode: 'monitor',
            onResult: (_) {
              _loadCrab();
              context.read<BoxBloc>().add(
                BoxDetailsRefreshRequested(widget.box.id),
              );
            },
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            final crab = _crab;
            if (crab == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hộp chưa có cua để chuyển.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => MoveCrabSheet(
                crab: crab,
                currentBoxId: widget.box.id,
                onSuccess: (code) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã chuyển cua sang hộp $code'),
                      backgroundColor: kHomePrimary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _loadCrab();
                  context.read<BoxBloc>().add(
                    BoxDetailsRefreshRequested(widget.box.id),
                  );
                },
              ),
            );
          },
          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
          label: const Text('Chuyển cua'),
          style: OutlinedButton.styleFrom(
            foregroundColor: kHomePrimaryDark,
            side: const BorderSide(color: kHomePrimary),
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedingTab extends StatefulWidget {
  const _FeedingTab({required this.box});
  final Box box;

  @override
  State<_FeedingTab> createState() => _FeedingTabState();
}

class _FeedingTabState extends State<_FeedingTab> {
  CrabModel? _crab;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCrab();
  }

  Future<void> _loadCrab() async {
    try {
      final crabs = await sl<BoxRemoteDataSource>().getCrabsByBox(
        widget.box.id,
      );
      if (mounted) setState(() => _crab = crabs.isEmpty ? null : crabs.first);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LinearProgressIndicator(
        minHeight: 3,
        color: kHomePrimary,
        backgroundColor: kHomePrimaryBg,
      );
    }
    if (_crab == null) {
      return const Text(
        'Hộp chưa có cua để ghi cho ăn.',
        style: TextStyle(color: kHomeTextSub, fontSize: 13),
      );
    }
    return DailyBoxCareSheet(
      key: ValueKey('feed-${_crab!.id}'),
      boxId: widget.box.id,
      boxCode: widget.box.qrCode.isNotEmpty
          ? widget.box.qrCode
          : widget.box.id,
      farmId: widget.box.farmId,
      crab: _crab!,
      embedded: true,
      mode: 'feed',
      onResult: (_) {
        _loadCrab();
        context.read<BoxBloc>().add(
          BoxDetailsRefreshRequested(widget.box.id),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: kHomeTextMain,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _SkeletonDetails extends StatelessWidget {
  const _SkeletonDetails();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Skel(height: 180),
        const SizedBox(height: 12),
        _Skel(height: 200),
        const SizedBox(height: 12),
        _Skel(height: 420),
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
        color: kHomeBorder.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
