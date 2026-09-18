import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../data/datasources/box_remote_data_source.dart';
import '../../data/models/crab_model.dart';
import '../widgets/action_panel.dart';
import '../widgets/box_timeline_widget.dart';
import '../../../../shared/widgets/errors/error_state_widget.dart';
import '../../../../shared/widgets/loading/skeleton_loader.dart';
import '../../domain/entities/box.dart';
import '../../domain/entities/box_enums.dart';
import '../../domain/entities/crab.dart';
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
        create: (_) => BoxBloc(getBoxDetails: sl<GetBoxDetailsUseCase>())
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
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kHomePrimary, kHomePrimaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () {
                    if (context.canPop()) context.pop();
                  },
                ),
                Expanded(
                  child: Text(
                    'Hộp nuôi ${boxId.length > 8 ? boxId.substring(0, 8).toUpperCase() : boxId.toUpperCase()}',
                    style: const TextStyle(
                      color: kHomeTextMain,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: () =>
                      context.read<BoxBloc>().add(BoxDetailsRefreshRequested(boxId)),
                ),
              ],
            ),
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
      length: 2,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Staleness banner
          if (box.isDataStale) ...[
            _StaleBanner(),
            const SizedBox(height: 12),
          ],

          // Section 1: Box info
          _BoxInfoCard(box: box),
          const SizedBox(height: 12),

          // Section 2: Water quality
          _WaterQualityCard(box: box),
          const SizedBox(height: 12),

          // Section 3: 2 tabs
          _TabSection(box: box),
        ],
      ),
    );
  }
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
        return 'Đang nuôi';
      case BoxStatus.inactive:
        return 'Trống';
      case BoxStatus.maintenance:
        return 'Bảo trì';
      case BoxStatus.harvested:
        return 'Đã thu hoạch';
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
                child: const Icon(Icons.inventory_2_rounded,
                    color: kHomePrimary, size: 16),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          _DetailRow(label: 'Mã hộp', value: box.id),
          _DetailRow(
              label: 'Thể tích',
              value: '${box.capacity} hộp • ${box.currentCrabCount} cua'),
          _DetailRow(
              label: 'Khu vực',
              value: box.pondId != null
                  ? '${box.farmId} / Ao ${box.pondId}'
                  : box.farmId),
          if (box.location.label != null)
            _DetailRow(label: 'Vị trí', value: box.location.label!),
          _DetailRow(
              label: 'Khối lượng TB',
              value: '${box.averageWeight.toStringAsFixed(1)}g'),
          _DetailRow(
              label: 'Giống cua', value: box.species.displayName),
        ],
      ),
    );
  }
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
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13,
                  color: kHomeTextMain,
                  fontWeight: FontWeight.w600),
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
                child: const Icon(Icons.water_drop_rounded,
                    color: kHomeSecondary, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Chất lượng nước',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kHomeTextMain),
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
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    minimumSize: Size.zero,
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
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
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    minimumSize: Size.zero,
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
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
                  color: statusC),
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
                Tab(text: 'Chi tiết'),
                Tab(text: 'Thao tác'),
              ],
            ),
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              children: [
                // Chi tiết tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Danh sách cua & Timeline',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kHomeTextMain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _TimelineSection(boxId: box.id),
                      const SizedBox(height: 12),
                      // Crab list button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                            '${RoutePaths.boxCrabs(box.id)}?boxCode=${Uri.encodeQueryComponent(box.qrCode.isNotEmpty ? box.qrCode : box.id)}',
                          ),
                          icon: const Icon(Icons.list_alt_rounded),
                          label: const Text('Xem danh sách cua'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kHomePrimary,
                            side: const BorderSide(color: kHomePrimary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Thao tác tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.9,
                        children: [
                          _ActionButton(
                            icon: Icons.videocam_rounded,
                            label: 'Quay video AI',
                            color: kHomePrimary,
                            onTap: () =>
                                context.push(RoutePaths.boxVideo(box.id)),
                          ),
                          _ActionButton(
                            icon: Icons.search_rounded,
                            label: 'Kiểm tra thủ công',
                            color: kHomeSecondary,
                            onTap: () =>
                                context.push(RoutePaths.boxInspect(box.id)),
                          ),
                          _ActionButton(
                            icon: Icons.bar_chart_rounded,
                            label: 'Xem báo cáo',
                            color: kHomePurple,
                            onTap: () => context.push(RoutePaths.reports),
                          ),
                          _ActionButton(
                            icon: Icons.agriculture_rounded,
                            label: 'Thu hoạch',
                            color: kHomeOrange,
                            onTap: () => context.push(
                              RoutePaths.harvestForBox(box.id,
                                  farmId: box.farmId),
                            ),
                          ),
                          _ActionButton(
                            icon: Icons.edit_note_rounded,
                            label: 'Nhật ký VH',
                            color: kHomeCyan,
                            onTap: () =>
                                context.push(RoutePaths.operationsForBox(box.id)),
                          ),
                          _ActionButton(
                            icon: Icons.camera_alt_rounded,
                            label: 'Camera',
                            color: kHomeTextSub,
                            onTap: () =>
                                context.push(RoutePaths.boxCamera(box.id)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.boxId});

  final String boxId;

  @override
  Widget build(BuildContext context) {
    return BoxTimelineWidget(events: const [], totalCount: 0);
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
