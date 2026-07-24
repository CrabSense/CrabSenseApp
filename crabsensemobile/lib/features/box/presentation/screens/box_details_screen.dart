import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
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

/// Screen that displays the full details of a single crab farming box.
///
/// Takes [boxId] as a constructor parameter, creates a [BoxBloc] via DI,
/// and fires [BoxDetailsLoadRequested] on construction.
///
/// Sections displayed when loaded:
/// 1. Staleness / offline warning banner (if applicable)
/// 2. Box info (ID, status, farm, pond, location)
/// 3. Crab inventory statistics
/// 4. Water quality placeholder (links to module task 13)
/// 5. AI health status placeholder (links to module task 10)
/// 6. Active alerts placeholder (links to module task 14)
/// 7. Quick actions row (video, inspect)
///
/// Requirements: 4.1-4.10
class BoxDetailsScreen extends StatelessWidget {
  const BoxDetailsScreen({required this.boxId, super.key});

  /// The unique identifier of the box to display.
  final String boxId;

  @override
  Widget build(BuildContext context) => BlocProvider<BoxBloc>(
    create: (_) =>
        BoxBloc(getBoxDetails: sl<GetBoxDetailsUseCase>())..add(BoxDetailsLoadRequested(boxId)),
    child: _BoxDetailsView(boxId: boxId),
  );
}

// ── Internal view ─────────────────────────────────────────────────────────────

class _BoxDetailsView extends StatelessWidget {
  const _BoxDetailsView({required this.boxId});

  final String boxId;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CrabSenseColors.background,
    appBar: AppBar(
      title: Text('Box ${boxId.length > 12 ? '${boxId.substring(0, 12)}…' : boxId}'),
      backgroundColor: CrabSenseColors.surface,
      foregroundColor: CrabSenseColors.textPrimary,
    ),
    body: BlocBuilder<BoxBloc, BoxState>(
      builder: (context, state) {
        if (state is BoxLoading) {
          return const _SkeletonDetails();
        }

        if (state is BoxError) {
          return ErrorStateWidget(
            icon: state.isOffline ? Icons.wifi_off : Icons.error_outline,
            title: state.isOffline ? 'No Connection' : 'Something went wrong',
            message: state.message,
            onRetry: () => context.read<BoxBloc>().add(BoxDetailsLoadRequested(boxId)),
          );
        }

        if (state is BoxLoaded) {
          return RefreshIndicator(
            color: CrabSenseColors.primary,
            backgroundColor: CrabSenseColors.surface,
            onRefresh: () async {
              context.read<BoxBloc>().add(BoxDetailsRefreshRequested(boxId));
              await context.read<BoxBloc>().stream.firstWhere(
                (s) => s is BoxLoaded && !s.isRefreshing || s is BoxError,
              );
            },
            child: _BoxContent(box: state.box, isOffline: false),
          );
        }

        // BoxInitial — show skeleton until the first event fires.
        return const _SkeletonDetails();
      },
    ),
  );
}

// ── Loaded content ────────────────────────────────────────────────────────────

class _BoxContent extends StatelessWidget {
  const _BoxContent({required this.box, required this.isOffline});

  final Box box;
  final bool isOffline;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
    children: [
      // 1. Staleness / offline banner
      if (box.isDataStale || isOffline) ...[const _StalenessBanner(), const SizedBox(height: 12)],

      // 2. Box info
      _BoxInfoCard(box: box),
      const SizedBox(height: 12),

      // 3. Crab inventory
      _CrabStatsCard(box: box),
      const SizedBox(height: 12),

      // 4. Water quality
      _WaterQualityCard(box: box),
      const SizedBox(height: 12),

      // 5. AI health status
      _AiHealthCard(box: box),
      const SizedBox(height: 12),

      // 6. Active alerts
      _ActiveAlertsCard(box: box),
      const SizedBox(height: 20),

      // 7. Quick actions
      BoxActionPanel(boxId: box.id, farmId: box.farmId),
      const SizedBox(height: 20),

      // 8. Box timeline
      _TimelineSection(boxId: box.id),
    ],
  );
}

// ── Staleness banner ──────────────────────────────────────────────────────────

class _StalenessBanner extends StatelessWidget {
  const _StalenessBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CrabSenseColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CrabSenseColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, size: 18, color: CrabSenseColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Data may be outdated',
              style: theme.textTheme.bodySmall?.copyWith(
                color: CrabSenseColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Box info card ─────────────────────────────────────────────────────────────

class _BoxInfoCard extends StatelessWidget {
  const _BoxInfoCard({required this.box});

  final Box box;

  Color _statusColor() {
    switch (box.status) {
      case BoxStatus.active:
        return CrabSenseColors.success;
      case BoxStatus.inactive:
        return CrabSenseColors.textDisabled;
      case BoxStatus.maintenance:
        return CrabSenseColors.warning;
      case BoxStatus.harvested:
        return CrabSenseColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(label: 'Box Info'),
          const SizedBox(height: 12),

          // ID row
          _InfoRow(icon: Icons.qr_code_2, label: 'ID', value: box.id),
          const SizedBox(height: 8),

          // Status chip
          Row(
            children: [
              const Icon(Icons.circle, size: 12, color: CrabSenseColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Status',
                style: theme.textTheme.bodySmall?.copyWith(color: CrabSenseColors.textSecondary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _statusColor().withValues(alpha: 0.5)),
                ),
                child: Text(
                  box.status.displayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _statusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Farm + optional pond
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Farm',
            value: box.pondId != null ? '${box.farmId} / Pond ${box.pondId}' : box.farmId,
          ),

          // Location label
          if (box.location.label != null) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.map_outlined, label: 'Location', value: box.location.label!),
          ],
        ],
      ),
    );
  }
}

// ── Crab statistics card ──────────────────────────────────────────────────────

class _CrabStatsCard extends StatelessWidget {
  const _CrabStatsCard({required this.box});

  final Box box;

  Color _capacityColor(double fill) {
    if (fill >= 0.9) {
      return CrabSenseColors.error;
    }
    if (fill >= 0.7) {
      return CrabSenseColors.warning;
    }
    return CrabSenseColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fillRatio = box.capacity > 0
        ? (box.currentCrabCount / box.capacity).clamp(0.0, 1.0)
        : 0.0;
    final capacityColor = _capacityColor(fillRatio);

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(label: 'Crab Inventory'),
          const SizedBox(height: 12),

          // Three stats row
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.set_meal_outlined,
                  value: '${box.currentCrabCount}/${box.capacity}',
                  label: 'Count',
                  color: capacityColor,
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.category_outlined,
                  value: box.species.displayName,
                  label: 'Species',
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.scale_outlined,
                  value: '${box.averageWeight.toStringAsFixed(1)}g',
                  label: 'Avg Weight',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Capacity progress bar
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: fillRatio,
                  backgroundColor: CrabSenseColors.outlineVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(capacityColor),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(fillRatio * 100).round()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: capacityColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddCrabDialog(context, box),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm cua'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showTransferDialog(context, box),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Chuyển hộp'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _showAddCrabDialog(BuildContext context, Box box) async {
  final weightCtrl = TextEditingController(text: '250');
  final tagCtrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Thêm cua vào hộp'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: weightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Khối lượng (g)'),
          ),
          TextField(
            controller: tagCtrl,
            decoration: const InputDecoration(labelText: 'Tag (tuỳ chọn)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Thêm')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final weight = double.tryParse(weightCtrl.text.trim()) ?? 0;
  try {
    await sl<BoxRemoteDataSource>().addCrab(
      box.id,
      CrabModel(
        id: 'temp',
        boxId: box.id,
        species: box.species,
        weight: weight,
        moltingStatus: MoltingStatus.hardShell,
        healthStatus: HealthStatus.normal,
        source: CrabSource.farm,
        addedAt: DateTime.now().toUtc(),
        addedBy: tagCtrl.text.trim(),
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thêm cua')),
    );
    context.read<BoxBloc>().add(BoxDetailsRefreshRequested(box.id));
  } on Exception catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Thêm cua thất bại: $e')),
    );
  }
}

Future<void> _showTransferDialog(BuildContext context, Box box) async {
  final destCtrl = TextEditingController();
  List<CrabModel> crabs = const [];
  try {
    crabs = await sl<BoxRemoteDataSource>().getCrabsByBox(box.id);
  } on Exception {
    crabs = const [];
  }
  if (!context.mounted) return;
  if (crabs.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hộp chưa có cua để chuyển')),
    );
    return;
  }
  final crab = crabs.first;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Chuyển cua sang hộp khác'),
      content: TextField(
        controller: destCtrl,
        decoration: const InputDecoration(labelText: 'Destination boxId (GUID)'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Chuyển')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final dest = destCtrl.text.trim();
  if (dest.isEmpty) return;
  try {
    await sl<BoxRemoteDataSource>().transferCrab(crab.id, box.id, dest);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã chuyển cua')),
    );
    context.read<BoxBloc>().add(BoxDetailsRefreshRequested(box.id));
  } on Exception catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chuyển thất bại: $e')),
    );
  }
}

// ── Water quality card ───────────────────────────────────────────────────────

class _WaterQualityCard extends StatefulWidget {
  const _WaterQualityCard({required this.box});

  final Box box;

  @override
  State<_WaterQualityCard> createState() => _WaterQualityCardState();
}

class _WaterQualityCardState extends State<_WaterQualityCard> {
  String _summary = 'Đang tải…';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final farmId = widget.box.farmId;
    final result = await sl<ApiClient>().safeGet<Map<String, dynamic>>(
      ApiConstants.waterQualityLatest,
      queryParameters: farmId.isEmpty ? null : {'farmingAreaId': farmId},
    );
    if (!mounted) return;
    if (result.failure != null) {
      setState(() {
        _loading = false;
        _summary = 'Không lấy được dữ liệu nước';
      });
      return;
    }
    final body = result.data.data;
    List<dynamic> items = const [];
    if (body != null) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'];
      if (data is List) items = data;
    }
    if (items.isEmpty) {
      setState(() {
        _loading = false;
        _summary = 'Chưa có cảm biến nước cho khu này';
      });
      return;
    }
    final parts = <String>[];
    for (final raw in items.take(4)) {
      if (raw is! Map) continue;
      final type = (raw['sensorType'] ?? raw['SensorType'] ?? '').toString();
      final value = raw['latestValue'] ?? raw['LatestValue'] ?? raw['value'];
      if (type.isEmpty) continue;
      parts.add('$type: $value');
    }
    setState(() {
      _loading = false;
      _summary = parts.isEmpty ? '${items.length} cảm biến đang theo dõi' : parts.join(' · ');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(label: 'Water Quality'),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.sensors, size: 32, color: CrabSenseColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: _loading
                    ? const LinearProgressIndicator(minHeight: 2)
                    : Text(
                        _summary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: CrabSenseColors.textSecondary,
                        ),
                      ),
              ),
              TextButton(
                onPressed: () {
                  final farmId = widget.box.farmId;
                  context.go(
                    farmId.isNotEmpty
                        ? RoutePaths.waterQualityForFarm(farmId)
                        : RoutePaths.waterQuality,
                  );
                },
                child: const Text('View'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── AI health status card ────────────────────────────────────────────────────

class _AiHealthCard extends StatefulWidget {
  const _AiHealthCard({required this.box});

  final Box box;

  @override
  State<_AiHealthCard> createState() => _AiHealthCardState();
}

class _AiHealthCardState extends State<_AiHealthCard> {
  String _summary = 'Đang tải…';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await sl<ApiClient>().safeGet<Map<String, dynamic>>(
      ApiConstants.aiDetections,
      queryParameters: {'boxId': widget.box.id},
    );
    if (!mounted) return;
    if (result.failure != null) {
      setState(() {
        _loading = false;
        _summary = 'Chưa có phân tích AI';
      });
      return;
    }
    final body = result.data.data;
    List<dynamic> items = const [];
    if (body != null) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'];
      if (data is List) items = data;
    }
    if (items.isEmpty) {
      setState(() {
        _loading = false;
        _summary = 'Chưa có phân tích AI — quay video để bắt đầu';
      });
      return;
    }
    final first = Map<String, dynamic>.from(items.first as Map);
    final conf = first['confidence'];
    final type = (first['detectionType'] ?? first['status'] ?? 'AI').toString();
    setState(() {
      _loading = false;
      _summary = '$type · confidence ${conf ?? '—'} (${items.length} kết quả)';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(label: 'AI Health Status'),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.psychology_outlined, size: 32, color: CrabSenseColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: _loading
                    ? const LinearProgressIndicator(minHeight: 2)
                    : Text(
                        _summary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: CrabSenseColors.textSecondary,
                        ),
                      ),
              ),
              TextButton(
                onPressed: () => context.go(RoutePaths.boxVideo(widget.box.id)),
                child: const Text('Capture'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Active alerts card ───────────────────────────────────────────────────────

class _ActiveAlertsCard extends StatefulWidget {
  const _ActiveAlertsCard({required this.box});

  final Box box;

  @override
  State<_ActiveAlertsCard> createState() => _ActiveAlertsCardState();
}

class _ActiveAlertsCardState extends State<_ActiveAlertsCard> {
  String _summary = 'Đang tải…';
  bool _loading = true;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final farmId = widget.box.farmId;
    final result = await sl<ApiClient>().safeGet<Map<String, dynamic>>(
      ApiConstants.alerts,
      queryParameters: {
        'activeOnly': true,
        if (farmId.isNotEmpty) 'farmingAreaId': farmId,
      },
    );
    if (!mounted) return;
    if (result.failure != null) {
      setState(() {
        _loading = false;
        _summary = 'Không tải được cảnh báo';
      });
      return;
    }
    final body = result.data.data;
    List<dynamic> items = const [];
    if (body != null) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'];
      if (data is List) items = data;
    }
    setState(() {
      _loading = false;
      _count = items.length;
      if (items.isEmpty) {
        _summary = 'Không có cảnh báo đang mở';
      } else {
        final first = Map<String, dynamic>.from(items.first as Map);
        final msg = (first['message'] ?? 'Cảnh báo').toString();
        _summary = items.length == 1 ? msg : '$msg (+${items.length - 1})';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _count > 0 ? CrabSenseColors.warning : CrabSenseColors.success;
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(label: 'Active Alerts'),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                _count > 0 ? Icons.notifications_active_outlined : Icons.notifications_none_outlined,
                size: 32,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _loading
                    ? const LinearProgressIndicator(minHeight: 2)
                    : Text(
                        _summary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: CrabSenseColors.textSecondary,
                        ),
                      ),
              ),
              TextButton(
                onPressed: () => context.go(RoutePaths.alerts),
                child: const Text('View All'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

/// Glassmorphic container for each section card.
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: CrabSenseColors.surface.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: CrabSenseColors.primary.withValues(alpha: 0.15)),
    ),
    child: child,
  );
}

/// Section header label.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(
        color: CrabSenseColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// A labelled icon row for key/value info.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: CrabSenseColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(color: CrabSenseColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(color: CrabSenseColors.textPrimary),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}

/// A single statistic item with icon, value, and label.
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.color = CrabSenseColors.textPrimary,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: CrabSenseColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Box timeline section ──────────────────────────────────────────────────────

/// Loads [GET /boxes/{id}/farming-timeline] and renders [BoxTimelineWidget].
class _TimelineSection extends StatefulWidget {
  const _TimelineSection({required this.boxId});

  final String boxId;

  @override
  State<_TimelineSection> createState() => _TimelineSectionState();
}

class _TimelineSectionState extends State<_TimelineSection> {
  List<BoxTimelineEvent> _events = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await sl<ApiClient>().safeGet<Map<String, dynamic>>(
        ApiConstants.boxTimeline(widget.boxId),
      );
      if (result.failure != null) {
        setState(() {
          _loading = false;
          _error = result.failure!.message;
          _events = const [];
        });
        return;
      }

      final body = result.data.data;
      List<dynamic> raw = const [];
      if (body is Map<String, dynamic>) {
        if (body['data'] is List) {
          raw = body['data'] as List;
        } else if (body['items'] is List) {
          raw = body['items'] as List;
        }
      }

      final events = <BoxTimelineEvent>[];
      for (var i = 0; i < raw.length; i++) {
        final map = Map<String, dynamic>.from(raw[i] as Map);
        final typeRaw = (map['eventType'] ?? map['EventType'] ?? '').toString();
        final atRaw = (map['at'] ?? map['At'] ?? '').toString();
        final summary = (map['summary'] ?? map['Summary'] ?? typeRaw).toString();
        final relatedId = (map['relatedId'] ?? map['RelatedId'] ?? map['crabId'] ?? i).toString();
        events.add(
          BoxTimelineEvent(
            id: relatedId.isEmpty ? 'evt_$i' : relatedId,
            boxId: widget.boxId,
            eventType: _mapFarmingEventType(typeRaw),
            title: summary,
            description: typeRaw.isEmpty ? null : typeRaw,
            timestamp: DateTime.tryParse(atRaw) ?? DateTime.now().toUtc(),
          ),
        );
      }

      setState(() {
        _loading = false;
        _events = events;
      });
    } on Exception catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
        _events = const [];
      });
    }
  }

  BoxTimelineEventType _mapFarmingEventType(String raw) {
    final v = raw.toLowerCase();
    if (v.contains('alloc') || v.contains('stock') || v.contains('add')) {
      return BoxTimelineEventType.crabAdded;
    }
    if (v.contains('move') || v.contains('transfer')) {
      return BoxTimelineEventType.crabTransfer;
    }
    if (v.contains('molt')) {
      return BoxTimelineEventType.inspection;
    }
    if (v.contains('harvest')) {
      return BoxTimelineEventType.harvest;
    }
    if (v.contains('status')) {
      return BoxTimelineEventType.alert;
    }
    if (v.contains('video')) {
      return BoxTimelineEventType.videoCapture;
    }
    return BoxTimelineEventType.inspection;
  }

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: CrabSenseColors.surface.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: CrabSenseColors.primary.withValues(alpha: 0.15)),
    ),
    child: _loading
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        : _error != null && _events.isEmpty
        ? Column(
            children: [
              Text(_error!, style: Theme.of(context).textTheme.bodySmall),
              TextButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          )
        : BoxTimelineWidget(events: _events, totalCount: _events.length),
  );
}

// ── Skeleton loading ──────────────────────────────────────────────────────────

/// Skeleton shown during initial load.
class _SkeletonDetails extends StatelessWidget {
  const _SkeletonDetails();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
    children: const [
      SkeletonLoader(height: 100, borderRadius: 16),
      SizedBox(height: 12),
      SkeletonLoader(height: 120, borderRadius: 16),
      SizedBox(height: 12),
      SkeletonLoader(height: 80, borderRadius: 16),
      SizedBox(height: 12),
      SkeletonLoader(height: 80, borderRadius: 16),
      SizedBox(height: 12),
      SkeletonLoader(height: 80, borderRadius: 16),
      SizedBox(height: 20),
      SkeletonLoader(height: 60, borderRadius: 14),
    ],
  );
}
