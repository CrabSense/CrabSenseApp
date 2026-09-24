import 'package:flutter/material.dart';

import '../../../models/box_alert.dart';
import '../../../models/camera_device.dart';
import '../../../models/crab_feeding_activity.dart';
import '../../../models/crab_growth_molt.dart';
import '../../../models/production_models.dart';
import '../../../services/crab_profile_service.dart';
import '../../../theme/dashboard_theme.dart';
import '../../crab/crab_auth_image.dart';
import '../../crab/crab_overview_cards.dart';
import '../../shared/mgmt_ui.dart';
import 'box_labels.dart';

enum BoxOpenCrabTarget { overview, growth, feeding, history }

class BoxOccupancyEvent {
  const BoxOccupancyEvent({
    required this.at,
    required this.crabId,
    required this.crabCode,
    required this.event,
    required this.actorName,
    required this.note,
    this.fromBox,
    this.toBox,
  });

  final DateTime at;
  final String crabId;
  final String crabCode;
  final String event;
  final String actorName;
  final String note;
  final String? fromBox;
  final String? toBox;

  String get eventLabel => boxOccupancyEventLabel(event);
}

class BoxCrabTab extends StatefulWidget {
  const BoxCrabTab({
    super.key,
    required this.box,
    required this.crab,
    required this.crabLoading,
    required this.profileService,
    required this.token,
    required this.camera,
    required this.cameraLoading,
    required this.alerts,
    this.crabError,
    this.onOpenCrab,
    this.onTransferCrab,
    this.onAddCrab,
    this.onManageLots,
    this.onAddFeeding,
    this.onOpenCamera,
    this.onOpenHistory,
    this.onRetryCrab,
  });

  final BoxRecord box;
  final CrabProfileData? crab;
  final bool crabLoading;
  final String? crabError;
  final CrabProfileService profileService;
  final String token;
  final CameraDevice? camera;
  final bool cameraLoading;
  final List<BoxAlert> alerts;
  final void Function(String crabId, {BoxOpenCrabTarget target})? onOpenCrab;
  final VoidCallback? onTransferCrab;
  final VoidCallback? onAddCrab;
  final VoidCallback? onManageLots;
  final VoidCallback? onAddFeeding;
  final VoidCallback? onOpenCamera;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onRetryCrab;

  @override
  State<BoxCrabTab> createState() => _BoxCrabTabState();
}

class _BoxCrabTabState extends State<BoxCrabTab> {
  CrabGrowthMoltData? _growth;
  CrabFeedingActivityData? _feeding;
  List<BoxOccupancyEvent> _history = const [];
  DateTime? _enteredBoxAt;
  Map<String, dynamic>? _ai;
  var _extraLoading = false;
  var _historyLoading = false;
  String? _historyError;

  String? get _crabId {
    final boxId = (widget.box.crabId ?? '').trim();
    if (boxId.isNotEmpty && boxId != 'null') return boxId;
    final id = (widget.crab?.id ?? '').trim();
    return id.isEmpty || id == 'null' ? null : id;
  }

  @override
  void initState() {
    super.initState();
    _loadExtras();
  }

  @override
  void didUpdateWidget(covariant BoxCrabTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.box.id != widget.box.id || oldWidget.crab?.id != widget.crab?.id) {
      _loadExtras();
    }
  }

  Future<void> _loadExtras() async {
    setState(() {
      _extraLoading = true;
      _historyLoading = true;
      _historyError = null;
    });
    await Future.wait([_loadCrabExtras(), _loadHistory()]);
  }

  Future<void> _loadCrabExtras() async {
    final id = _crabId;
    if (id == null) {
      if (mounted) {
        setState(() {
          _growth = null;
          _feeding = null;
          _ai = null;
          _enteredBoxAt = null;
          _extraLoading = false;
        });
      }
      return;
    }
    CrabGrowthMoltData? growth;
    CrabFeedingActivityData? feeding;
    Map<String, dynamic>? ai;
    try {
      growth = await widget.profileService.fetchCrabGrowth(id);
    } catch (_) {}
    try {
      feeding = await widget.profileService.fetchCrabFeeding(id);
    } catch (_) {}
    try {
      final dets = await widget.profileService.fetchAiDetections(boxId: widget.box.id);
      if (dets.isNotEmpty) ai = dets.first;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _growth = growth;
      _feeding = feeding;
      _ai = ai;
      _extraLoading = false;
    });
  }

  Future<void> _loadHistory() async {
    try {
      final rows = await widget.profileService.fetchBoxAllocations(widget.box.id);
      final allocs = rows.map(_alloc).whereType<_Alloc>().toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      final codes = <String, String>{};
      if (widget.crab?.id != null) codes[widget.crab!.id!] = widget.crab!.crabCode;
      for (final a in allocs) {
        if (codes.containsKey(a.crabId)) continue;
        try {
          final detail = await widget.profileService.fetchCrabDetail(a.crabId);
          final code = (detail['code'] ?? detail['Code'] ?? detail['tag'] ?? detail['Tag'] ?? a.crabId).toString();
          codes[a.crabId] = code;
        } catch (_) {
          codes[a.crabId] = a.crabId;
        }
      }
      final events = <BoxOccupancyEvent>[];
      for (final a in allocs) {
        final code = codes[a.crabId] ?? a.crabId;
        events.add(BoxOccupancyEvent(
          at: a.start,
          crabId: a.crabId,
          crabCode: code,
          event: _inEvent(a.note),
          actorName: 'Hệ thống',
          note: a.note,
          toBox: widget.box.boxCode,
        ));
        if (a.end != null) {
          events.add(BoxOccupancyEvent(
            at: a.end!,
            crabId: a.crabId,
            crabCode: code,
            event: _outEvent(a.note),
            actorName: 'Hệ thống',
            note: a.note,
            fromBox: widget.box.boxCode,
          ));
        }
      }
      events.sort((a, b) => b.at.compareTo(a.at));
      DateTime? entered;
      final current = _crabId;
      if (current != null) {
        final open = allocs.where((a) => a.crabId == current && a.end == null).toList();
        if (open.isNotEmpty) entered = open.last.start;
      }
      if (!mounted) return;
      setState(() {
        _history = events;
        _enteredBoxAt = entered;
        _historyLoading = false;
        _historyError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _history = const [];
        _historyLoading = false;
        _historyError = '$e';
      });
    }
  }

  _Alloc? _alloc(Map<String, dynamic> raw) {
    final crabId = (raw['crabId'] ?? raw['CrabId'] ?? '').toString();
    final start = DateTime.tryParse((raw['startTime'] ?? raw['StartTime'] ?? '').toString());
    if (crabId.isEmpty || start == null) return null;
    final endRaw = raw['endTime'] ?? raw['EndTime'];
    return _Alloc(
      crabId: crabId,
      start: start.isUtc ? start.toLocal() : start,
      end: () {
        final e = DateTime.tryParse('${endRaw ?? ''}');
        return e == null ? null : (e.isUtc ? e.toLocal() : e);
      }(),
      note: (raw['notes'] ?? raw['Notes'] ?? raw['note'] ?? raw['Note'] ?? '').toString(),
    );
  }

  String _inEvent(String note) {
    final n = note.toLowerCase();
    if (n.contains('chuyển') || n.contains('transfer')) return 'TRANSFERRED_IN';
    return 'ASSIGNED';
  }

  String _outEvent(String note) {
    final n = note.toLowerCase();
    if (n.contains('chết') || n.contains('dead')) return 'DEAD_REMOVED';
    if (n.contains('thu hoạch') || n.contains('harvest') || n.contains('bán')) return 'HARVESTED';
    if (n.contains('giải phóng') || n.contains('release')) return 'RELEASED';
    return 'TRANSFERRED_OUT';
  }

  void _openCurrent({BoxOpenCrabTarget target = BoxOpenCrabTarget.overview}) {
    final id = _crabId;
    if (id == null) return;
    widget.onOpenCrab?.call(id, target: target);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final desktop = w >= 1100;
        final tablet = w >= 760;
        final occupied = widget.crab != null;
        final history = BoxCrabOccupancyHistory(
          boxCode: widget.box.boxCode,
          events: _history,
          loading: _historyLoading,
          error: _historyError,
          onOpenAll: widget.onOpenHistory,
          onRetry: _loadHistory,
        );

        if (widget.crabLoading && widget.crab == null) {
          return Column(
            children: [
              _CrabTabSkeleton(desktop: desktop, tablet: tablet),
              const SizedBox(height: 12),
              history,
            ],
          );
        }

        if (widget.crabError != null && widget.crab == null) {
          return Column(
            children: [
              OverviewCard(
                icon: Icons.warning_amber_rounded,
                title: 'Cua hiện tại',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Không thể tải thông tin cua hiện tại.', style: bvText(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    MgmtOutlineButton(icon: Icons.refresh_rounded, label: 'Thử lại', onTap: widget.onRetryCrab, height: 36),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              history,
            ],
          );
        }

        if (!occupied) {
          return Column(
            children: [
              BoxCrabEmptyState(
                boxCode: widget.box.boxCode,
                onAddCrab: widget.onAddCrab,
                onManageLots: widget.onManageLots,
                onOpenHistory: widget.onOpenHistory,
              ),
              const SizedBox(height: 12),
              history,
            ],
          );
        }

        final profile = CurrentCrabProfileCard(
          box: widget.box,
          crab: widget.crab,
          token: widget.token,
          enteredBoxAt: _enteredBoxAt,
          latest: _growth?.latest,
          loading: _extraLoading && _growth == null,
          onOpen: () => _openCurrent(),
          onTransfer: widget.onTransferCrab,
          onHistory: () => _openCurrent(target: BoxOpenCrabTarget.history),
        );
        final latest = CrabLatestInfoCard(
          crab: widget.crab,
          growth: _growth,
          feeding: _latestFeeding,
          activity: _latestActivity,
          loading: _extraLoading,
        );
        final ai = CrabAITrackingCard(
          camera: widget.camera,
          cameraLoading: widget.cameraLoading,
          detection: _ai,
          alerts: widget.alerts,
          onOpen: widget.onOpenCamera,
        );
        final feed = CrabFeedingActivitySummary(
          feeding: _latestFeeding,
          activity: _latestActivity,
          insight: _feeding?.insight,
          insightLevel: _feeding?.insightLevel,
          loading: _extraLoading,
          onOpen: () => _openCurrent(target: BoxOpenCrabTarget.feeding),
          onAddFeeding: widget.onAddFeeding,
        );
        final health = CrabHealthSummary(healthStatus: widget.crab?.healthStatus ?? widget.crab?.status);

        if (desktop) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 42, child: profile),
                  const SizedBox(width: 12),
                  Expanded(flex: 26, child: latest),
                  const SizedBox(width: 12),
                  Expanded(flex: 32, child: ai),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 60, child: feed),
                  const SizedBox(width: 12),
                  Expanded(flex: 40, child: health),
                ],
              ),
              const SizedBox(height: 12),
              history,
            ],
          );
        }
        if (tablet) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: profile),
                  const SizedBox(width: 12),
                  Expanded(child: latest),
                ],
              ),
              const SizedBox(height: 12),
              ai,
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: feed),
                  const SizedBox(width: 12),
                  Expanded(child: health),
                ],
              ),
              const SizedBox(height: 12),
              history,
            ],
          );
        }
        return Column(
          children: [
            profile,
            const SizedBox(height: 12),
            latest,
            const SizedBox(height: 12),
            ai,
            const SizedBox(height: 12),
            feed,
            const SizedBox(height: 12),
            health,
            const SizedBox(height: 12),
            history,
          ],
        );
      },
    );
  }

  FeedingEvent? get _latestFeeding {
    final events = _feeding?.events ?? const <FeedingEvent>[];
    for (final e in events) {
      if (e.feedingPercent != null) return e;
    }
    return events.isEmpty ? null : events.first;
  }

  ({int score, DateTime at})? get _latestActivity {
    final events = _feeding?.events ?? const <FeedingEvent>[];
    for (final e in events) {
      final s = e.activityScore;
      if (s != null) return (score: s, at: e.time);
    }
    final trend = _feeding?.activityTrend.where((p) => p.score != null).toList() ?? const [];
    if (trend.isEmpty) return null;
    final last = trend.last;
    return (score: last.score!, at: last.bucket);
  }
}

class _Alloc {
  const _Alloc({required this.crabId, required this.start, this.end, required this.note});
  final String crabId;
  final DateTime start;
  final DateTime? end;
  final String note;
}

class CurrentCrabProfileCard extends StatelessWidget {
  const CurrentCrabProfileCard({
    super.key,
    required this.box,
    required this.crab,
    required this.token,
    this.enteredBoxAt,
    this.latest,
    this.loading = false,
    this.onOpen,
    this.onTransfer,
    this.onHistory,
  });

  final BoxRecord box;
  final CrabProfileData? crab;
  final String token;
  final DateTime? enteredBoxAt;
  final GrowthMeasurement? latest;
  final bool loading;
  final VoidCallback? onOpen;
  final VoidCallback? onTransfer;
  final VoidCallback? onHistory;

  @override
  Widget build(BuildContext context) {
    if (loading && crab == null) {
      return OverviewCard(
        icon: Icons.set_meal_outlined,
        title: 'Cua hiện tại',
        child: Container(height: 220, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(12))),
      );
    }
    final c = crab;
    if (c == null) return const SizedBox.shrink();
    final weight = latest != null && latest!.weightGram > 0 ? latest!.weightGram : c.weight;
    final width = latest?.shellWidthMm ?? c.shellWidth;
    final length = latest?.shellLengthMm ?? c.shellLength;
    final health = boxCrabHealth(c.healthStatus);
    final days = daysInBox(enteredBoxAt);
    return OverviewCard(
      icon: Icons.set_meal_outlined,
      title: 'Cua hiện tại',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _photo(context, c),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(c.crabCode, style: bvText(fontSize: 18, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
                        MgmtStatusBadge(label: c.statusLabel, color: DashboardColors.brand),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${c.typeLabel}  •  ${c.genderLabel}', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
                    const SizedBox(height: 12),
                    _kv('Cân nặng', _gram(weight)),
                    _kv('Rộng mai', _mm(width)),
                    _kv('Dài mai', _mm(length)),
                    _kvDot('Sức khỏe', health.label, health.color),
                    _kvDot('Giai đoạn', c.growthStageLabel, DashboardColors.brandGreen),
                    _kv('Vào hộp', fmtDateTimeVn(enteredBoxAt)),
                    _kv('Thời gian trong hộp', days == null ? '—' : '$days ngày'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MgmtPrimaryButton(label: 'Xem chi tiết cua →', height: 36, onTap: onOpen),
              MgmtOutlineButton(icon: Icons.swap_horiz_rounded, label: 'Chuyển cua', height: 36, onTap: onTransfer),
              MgmtOutlineButton(
                icon: Icons.history_rounded,
                label: 'Lịch sử cua',
                height: 36,
                color: DashboardColors.textMuted,
                borderColor: DashboardColors.cardBorder,
                onTap: onHistory,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photo(BuildContext context, CrabProfileData c) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 180,
        height: 150,
        child: c.id == null
            ? Container(color: DashboardColors.lightMint, child: const Icon(Icons.set_meal_outlined, color: DashboardColors.brand, size: 36))
            : CrabAuthImage(
                crabId: c.id!,
                index: 0,
                token: token,
                fallbackUrl: c.imageUrls.isEmpty ? null : c.imageUrls.first,
                error: Container(color: DashboardColors.lightMint, child: const Icon(Icons.set_meal_outlined, color: DashboardColors.brand, size: 36)),
              ),
      ),
    );
    return Stack(
      children: [
        image,
        Positioned(
          right: 8,
          bottom: 8,
          child: Material(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: c.id == null ? null : () => _zoom(context, c),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Text('Xem ảnh lớn', style: bvText(fontSize: 11, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _zoom(BuildContext context, CrabProfileData c) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 420,
                  height: 320,
                  child: CrabAuthImage(
                    crabId: c.id!,
                    index: 0,
                    token: token,
                    fallbackUrl: c.imageUrls.isEmpty ? null : c.imageUrls.first,
                    error: Container(color: DashboardColors.lightMint, child: const Icon(Icons.set_meal_outlined, color: DashboardColors.brand, size: 48)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          children: [
            SizedBox(width: 132, child: Text(k, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))),
            Expanded(child: Text(v, style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary))),
          ],
        ),
      );

  Widget _kvDot(String k, String v, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          children: [
            SizedBox(width: 132, child: Text(k, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))),
            Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(v, style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
          ],
        ),
      );

  String _gram(double? v) => v == null || v == 0 ? '—' : '${v.toStringAsFixed(0)} g';
  String _mm(double? v) => v == null || v == 0 ? '—' : '${v.toStringAsFixed(0)} mm';
}

class CrabLatestInfoCard extends StatelessWidget {
  const CrabLatestInfoCard({
    super.key,
    required this.crab,
    this.growth,
    this.feeding,
    this.activity,
    this.loading = false,
  });

  final CrabProfileData? crab;
  final CrabGrowthMoltData? growth;
  final FeedingEvent? feeding;
  final ({int score, DateTime at})? activity;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading && growth == null && feeding == null) {
      return OverviewCard(
        icon: Icons.analytics_outlined,
        title: 'Thông tin gần nhất',
        child: Column(children: [for (var i = 0; i < 5; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(height: 36, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(8))))]),
      );
    }
    final latest = growth?.latest;
    final prev = growth?.previous;
    final weight = latest != null && latest.weightGram > 0 ? latest.weightGram : crab?.weight;
    final width = latest?.shellWidthMm ?? crab?.shellWidth;
    final length = latest?.shellLengthMm ?? crab?.shellLength;
    final moltCount = growth?.molts.isNotEmpty == true ? growth!.molts.length : crab?.moltCount;
    final lastMolt = growth?.lastMolt?.at ?? DateTime.tryParse(crab?.lastMoltDate ?? '');
    return OverviewCard(
      icon: Icons.analytics_outlined,
      title: 'Thông tin gần nhất',
      child: Column(
        children: [
          _metric(
            icon: Icons.monitor_weight_outlined,
            label: 'Cân nặng',
            value: weight == null || weight == 0 ? '—' : '${weight.toStringAsFixed(0)} g',
            date: latest?.measuredAt,
            delta: _delta(growth?.weightDelta, 'g'),
          ),
          _metric(
            icon: Icons.straighten_rounded,
            label: 'Kích thước mai',
            value: _shell(width, length),
            date: latest?.measuredAt,
            delta: _shellDelta(growth?.widthDelta, growth?.lengthDelta, prev),
          ),
          _metric(
            icon: Icons.autorenew_rounded,
            label: 'Số lần lột xác',
            value: moltCount == null || moltCount == 0 ? '—' : '$moltCount lần',
            date: lastMolt,
            datePrefix: lastMolt == null ? null : 'Gần nhất',
          ),
          _metric(
            icon: Icons.restaurant_rounded,
            label: 'Lần ăn gần nhất',
            value: feeding?.feedingPercent == null ? '—' : '${feeding!.feedingPercent}%',
            date: feeding?.time,
          ),
          _metric(
            icon: Icons.directions_run_rounded,
            label: 'Vận động (AI)',
            value: activity == null ? '—' : '${activity!.score} / 100',
            date: activity?.at,
          ),
        ],
      ),
    );
  }

  Widget _metric({
    required IconData icon,
    required String label,
    required String value,
    DateTime? date,
    String? delta,
    String? datePrefix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: DashboardColors.brand),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(child: Text(value, style: bvText(fontSize: 14, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary))),
                    if (delta != null)
                      Text(
                        delta,
                        style: bvText(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: delta.startsWith('↑')
                              ? DashboardColors.brand
                              : delta.startsWith('↓')
                                  ? const Color(0xFFEF4444)
                                  : DashboardColors.textMuted,
                        ),
                      ),
                  ],
                ),
                if (date != null)
                  Text(
                    '${datePrefix ?? ''}${datePrefix == null ? '' : ': '}${datePrefix == 'Gần nhất' ? fmtDateVn(date) : fmtDateTimeVn(date)}',
                    style: bvText(fontSize: 11, color: DashboardColors.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shell(double? w, double? l) {
    if ((w == null || w == 0) && (l == null || l == 0)) return '—';
    final a = w == null || w == 0 ? '—' : w.toStringAsFixed(0);
    final b = l == null || l == 0 ? '—' : l.toStringAsFixed(0);
    return '$a × $b mm';
  }

  String? _delta(double? v, String unit) {
    if (v == null) return '—';
    if (v == 0) return '—';
    final sign = v > 0 ? '↑ +' : '↓ ';
    return '$sign${v.abs().toStringAsFixed(0)} $unit';
  }

  String? _shellDelta(double? dw, double? dl, GrowthMeasurement? prev) {
    if (prev == null || (dw == null && dl == null)) return '—';
    final v = dw ?? dl;
    if (v == null || v == 0) return '—';
    final sign = v > 0 ? '↑ +' : '↓ ';
    return '$sign${v.abs().toStringAsFixed(0)} mm';
  }
}

class CrabAITrackingCard extends StatelessWidget {
  const CrabAITrackingCard({
    super.key,
    required this.camera,
    required this.cameraLoading,
    required this.alerts,
    this.detection,
    this.onOpen,
  });

  final CameraDevice? camera;
  final bool cameraLoading;
  final Map<String, dynamic>? detection;
  final List<BoxAlert> alerts;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    if (cameraLoading && camera == null) {
      return OverviewCard(
        icon: Icons.videocam_outlined,
        title: 'AI theo dõi',
        child: Container(height: 180, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(12))),
      );
    }
    final cam = camera;
    if (cam == null) {
      return OverviewCard(
        icon: Icons.videocam_outlined,
        title: 'AI theo dõi',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Camera AI không khả dụng.', style: bvText(color: DashboardColors.textMuted)),
            OverviewLinkButton(label: 'Xem Camera AI', onTap: onOpen),
          ],
        ),
      );
    }
    final parsed = _parse(detection);
    final alert = alerts.where((a) {
      final m = a.message.toLowerCase();
      return m.contains('ai') || m.contains('hành vi') || m.contains('bất thường');
    }).firstOrNull;
    final abnormal = parsed?.abnormal == true || alert != null;
    final source = cam.cameraCode;
    final lastAt = parsed?.at ?? alert?.occurredAt ?? cam.lastSeenAt;

    return OverviewCard(
      icon: Icons.videocam_outlined,
      title: 'AI theo dõi',
      trailing: MgmtStatusBadge(
        label: cam.isOnline ? 'Trực tuyến' : 'Mất kết nối',
        color: cam.isOnline ? DashboardColors.brand : const Color(0xFFEF4444),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 132,
              width: double.infinity,
              color: const Color(0xFF12332D),
              alignment: Alignment.center,
              child: cam.isOnline
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        const ColoredBox(color: Color(0xFF1A3D36)),
                        Center(child: Icon(Icons.videocam_outlined, size: 36, color: Colors.white.withValues(alpha: 0.7))),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Text(source, style: bvText(fontSize: 11, color: Colors.white)),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 32),
                        const SizedBox(height: 6),
                        Text('Camera AI không khả dụng.', style: bvText(fontSize: 12.5, color: Colors.white70)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          if (abnormal) ...[
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFF5B700)),
                const SizedBox(width: 6),
                Expanded(child: Text('Phát hiện hành vi bất thường', style: bvText(fontWeight: FontWeight.w800, color: DashboardColors.textPrimary))),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              parsed?.message ?? alert?.message ?? 'Cua di chuyển liên tục bất thường.',
              style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary),
            ),
            if (parsed?.confidence != null)
              Text('Confidence: ${parsed!.confidence}%', style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
            if (lastAt != null)
              Text('Phát hiện: ${fmtDateTimeVn(lastAt)}', style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
            Text('Nguồn: $source', style: bvText(fontSize: 11.5, fontWeight: FontWeight.w700)),
            OverviewLinkButton(label: 'Xem chi tiết', onTap: onOpen),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 16, color: DashboardColors.brand),
                const SizedBox(width: 6),
                Expanded(child: Text('Không phát hiện bất thường', style: bvText(fontWeight: FontWeight.w700))),
              ],
            ),
            if (lastAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Phát hiện cuối: ${fmtDateTimeVn(lastAt)}', style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
              ),
            Text('Nguồn: $source', style: bvText(fontSize: 11.5, fontWeight: FontWeight.w700)),
            OverviewLinkButton(label: 'Xem Camera AI', onTap: onOpen),
          ],
        ],
      ),
    );
  }

  _AiSnap? _parse(Map<String, dynamic>? j) {
    if (j == null) return null;
    final type = (j['detectionType'] ?? j['DetectionType'] ?? '').toString().toLowerCase();
    final at = DateTime.tryParse((j['detectedAt'] ?? j['DetectedAt'] ?? '').toString());
    final conf = j['confidence'] ?? j['Confidence'];
    var pct = conf is num ? conf.toDouble() : null;
    if (pct != null && pct <= 1) pct = pct * 100;
    final abnormal = type.contains('abnormal') ||
        type.contains('anomal') ||
        type.contains('dead') ||
        type.contains('mortal') ||
        type.contains('escaped') ||
        type.contains('skip');
    String? note;
    final rj = (j['resultJson'] ?? j['ResultJson'])?.toString();
    if (rj != null) {
      final m = RegExp(r'"note"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(rj);
      note = m?.group(1)?.replaceAll(r'\"', '"');
    }
    return _AiSnap(
      at: at == null ? null : (at.isUtc ? at.toLocal() : at),
      abnormal: abnormal,
      confidence: pct?.round(),
      message: (note ?? '').trim().isEmpty ? null : note,
    );
  }
}

class _AiSnap {
  const _AiSnap({this.at, required this.abnormal, this.confidence, this.message});
  final DateTime? at;
  final bool abnormal;
  final int? confidence;
  final String? message;
}

class CrabFeedingActivitySummary extends StatelessWidget {
  const CrabFeedingActivitySummary({
    super.key,
    this.feeding,
    this.activity,
    this.insight,
    this.insightLevel,
    this.loading = false,
    this.onOpen,
    this.onAddFeeding,
  });

  final FeedingEvent? feeding;
  final ({int score, DateTime at})? activity;
  final String? insight;
  final String? insightLevel;
  final bool loading;
  final VoidCallback? onOpen;
  final VoidCallback? onAddFeeding;

  @override
  Widget build(BuildContext context) {
    if (loading && feeding == null && activity == null) {
      return OverviewCard(
        icon: Icons.restaurant_rounded,
        title: 'Ăn & vận động gần nhất',
        child: Container(height: 88, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(12))),
      );
    }
    final th = FeedingThresholds.defaults;
    final pct = feeding?.feedingPercent;
    final act = activity?.score;
    return OverviewCard(
      icon: Icons.restaurant_rounded,
      title: 'Ăn & vận động gần nhất',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 520;
              final blocks = [
                _block(
                  label: 'Mức ăn',
                  child: pct == null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Chưa có dữ liệu cho ăn gần đây.', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
                            const SizedBox(height: 8),
                            MgmtOutlineButton(icon: Icons.add_rounded, label: 'Ghi nhận cho ăn', height: 32, onTap: onAddFeeding),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$pct%', style: bvText(fontSize: 22, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            _badge(pct >= th.finishPercent ? 'Tốt' : (pct >= th.watchPercent ? 'Theo dõi' : 'Cảnh báo'), th.feedingColor(pct)),
                            if (feeding?.time != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text('Lần ăn cuối: ${fmtDateTimeVn(feeding!.time)}', style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
                              ),
                          ],
                        ),
                ),
                _block(
                  label: 'Vận động (AI)',
                  child: act == null
                      ? Text('Chưa có dữ liệu vận động.', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$act / 100', style: bvText(fontSize: 22, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            _badge(th.activityLabel(act), th.activityColor(act)),
                            if (activity?.at != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text('Cập nhật: ${fmtDateVn(activity!.at)}', style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
                              ),
                          ],
                        ),
                ),
                _block(
                  label: 'AI nhận định',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _badge(_insightTitle, _insightColor, dot: true),
                      const SizedBox(height: 8),
                      Text(_insightBody, style: bvText(fontSize: 12.5, height: 1.4, color: DashboardColors.textMuted)),
                    ],
                  ),
                ),
              ];
              if (!wide) {
                return Column(children: [for (var i = 0; i < blocks.length; i++) Padding(padding: EdgeInsets.only(bottom: i == 2 ? 0 : 8), child: blocks[i])]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < blocks.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: blocks[i]),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          OverviewLinkButton(label: 'Xem phân tích cua', onTap: onOpen),
        ],
      ),
    );
  }

  Widget _block({required String label, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FBF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _badge(String label, Color color, {bool dot = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: 0.35))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
          ],
          Text(label, style: bvText(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  String get _insightTitle {
    final l = (insightLevel ?? '').toLowerCase();
    if (l == 'warning' || l == 'watch') return 'Cần theo dõi';
    if (feeding == null && activity == null) return 'Chưa đủ dữ liệu';
    return 'Hoạt động ổn định';
  }

  Color get _insightColor {
    final l = (insightLevel ?? '').toLowerCase();
    if (l == 'warning') return const Color(0xFFEF4444);
    if (l == 'watch') return const Color(0xFFF5B700);
    return DashboardColors.brand;
  }

  String get _insightBody {
    final t = (insight ?? '').trim();
    if (t.isNotEmpty) return t;
    if (feeding == null && activity == null) return 'Chưa có đủ dữ liệu ăn và vận động để nhận định.';
    return 'Cua ăn tốt và di chuyển bình thường theo phân tích AI.';
  }
}

class CrabHealthSummary extends StatelessWidget {
  const CrabHealthSummary({super.key, this.healthStatus});

  final String? healthStatus;

  @override
  Widget build(BuildContext context) {
    final h = boxCrabHealth(healthStatus);
    return OverviewCard(
      icon: Icons.favorite_outline_rounded,
      title: 'Tình trạng sức khỏe',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: h.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(color: h.color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(h.watch ? h.title : h.label, style: bvText(fontWeight: FontWeight.w800, color: h.color)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(h.body, style: bvText(fontSize: 13, height: 1.45, color: DashboardColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.health_and_safety_outlined, size: 42, color: h.color.withValues(alpha: 0.45)),
        ],
      ),
    );
  }
}

class BoxCrabOccupancyHistory extends StatelessWidget {
  const BoxCrabOccupancyHistory({
    super.key,
    required this.boxCode,
    required this.events,
    required this.loading,
    this.error,
    this.onOpenAll,
    this.onRetry,
  });

  final String boxCode;
  final List<BoxOccupancyEvent> events;
  final bool loading;
  final String? error;
  final VoidCallback? onOpenAll;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return OverviewCard(
      icon: Icons.history_rounded,
      title: 'Lịch sử cua trong hộp',
      trailing: OverviewLinkButton(label: 'Xem tất cả', onTap: onOpenAll),
      child: loading
          ? Column(children: [for (var i = 0; i < 3; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(height: 40, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(8))))])
          : error != null && events.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Không tải được lịch sử cua trong hộp.', style: bvText(color: DashboardColors.textMuted)),
                    const SizedBox(height: 8),
                    MgmtOutlineButton(icon: Icons.refresh_rounded, label: 'Thử lại', height: 34, onTap: onRetry),
                  ],
                )
              : events.isEmpty
                  ? Text('Chưa có lịch sử cua trong $boxCode.', style: bvText(color: DashboardColors.textMuted))
                  : LayoutBuilder(
                      builder: (context, c) {
                        if (c.maxWidth < 720) {
                          return Column(
                            children: [
                              for (final e in events.take(8))
                                InkWell(
                                  onTap: () => _showEvent(context, e),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(fmtDateTimeVn(e.at), style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
                                        Text('${e.crabCode}  ·  ${e.eventLabel}', style: bvText(fontWeight: FontWeight.w700)),
                                        if (e.note.trim().isNotEmpty)
                                          Text(e.note, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _header(),
                            const SizedBox(height: 4),
                            for (final e in events.take(10))
                              InkWell(
                                onTap: () => _showEvent(context, e),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  child: Row(
                                    children: [
                                      _cell(fmtDateTimeVn(e.at), 150, muted: true),
                                      _cell(e.crabCode, 120, bold: true),
                                      _cell(e.eventLabel, 160),
                                      _cell(e.actorName, 140),
                                      Expanded(child: Text(e.note.trim().isEmpty ? '—' : e.note, style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary))),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
    );
  }

  Widget _header() {
    const style = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.3);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(color: const Color(0xFFF3FBF8), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          _cell('THỜI GIAN', 150, header: true, style: style),
          _cell('CUA', 120, header: true, style: style),
          _cell('SỰ KIỆN', 160, header: true, style: style),
          _cell('NGƯỜI THỰC HIỆN', 140, header: true, style: style),
          Expanded(child: Text('GHI CHÚ', style: bvText(fontSize: 11, fontWeight: FontWeight.w800, color: DashboardColors.textMuted, letterSpacing: 0.3))),
        ],
      ),
    );
  }

  Widget _cell(String text, double width, {bool muted = false, bool bold = false, bool header = false, TextStyle? style}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: style ??
            bvText(
              fontSize: header ? 11 : 12.5,
              fontWeight: bold || header ? FontWeight.w700 : FontWeight.w500,
              color: header || muted ? DashboardColors.textMuted : DashboardColors.textPrimary,
            ),
      ),
    );
  }

  void _showEvent(BuildContext context, BoxOccupancyEvent e) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Chi tiết sự kiện', style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.crabCode, style: bvText(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                [
                  if (e.fromBox != null) e.fromBox!,
                  boxCode,
                  if (e.toBox != null && e.toBox != boxCode) e.toBox!,
                ].join('  →  '),
                style: bvText(color: DashboardColors.textMuted),
              ),
              const SizedBox(height: 12),
              _kv('Sự kiện', e.eventLabel),
              _kv('Thời gian', fmtDateTimeVn(e.at)),
              _kv('Người thực hiện', e.actorName),
              _kv('Ghi chú', e.note.trim().isEmpty ? '—' : e.note),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 130, child: Text(k, style: bvText(color: DashboardColors.textMuted))),
            Expanded(child: Text(v, style: bvText(fontWeight: FontWeight.w700))),
          ],
        ),
      );
}

class BoxCrabEmptyState extends StatelessWidget {
  const BoxCrabEmptyState({
    super.key,
    required this.boxCode,
    this.onAddCrab,
    this.onManageLots,
    this.onOpenHistory,
  });

  final String boxCode;
  final VoidCallback? onAddCrab;
  final VoidCallback? onManageLots;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return OverviewCard(
      icon: Icons.set_meal_outlined,
      title: 'Cua hiện tại',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 42, color: DashboardColors.textMuted),
            const SizedBox(height: 10),
            Text('Hộp hiện đang trống', style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('$boxCode chưa có cua được phân vào.', textAlign: TextAlign.center, style: bvText(fontSize: 13, color: DashboardColors.textMuted)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                MgmtPrimaryButton(icon: Icons.add_rounded, label: 'Thêm cua', height: 36, onTap: onAddCrab),
                MgmtOutlineButton(label: 'Chọn từ lô nhập', height: 36, onTap: onManageLots),
                MgmtOutlineButton(icon: Icons.history_rounded, label: 'Xem lịch sử hộp', height: 36, onTap: onOpenHistory),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CrabTabSkeleton extends StatelessWidget {
  const _CrabTabSkeleton({required this.desktop, required this.tablet});
  final bool desktop;
  final bool tablet;

  Widget _box(double h) => Container(height: h, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(16)));

  @override
  Widget build(BuildContext context) {
    if (desktop) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(flex: 42, child: _box(280)),
              const SizedBox(width: 12),
              Expanded(flex: 26, child: _box(280)),
              const SizedBox(width: 12),
              Expanded(flex: 32, child: _box(280)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(flex: 60, child: _box(140)),
              const SizedBox(width: 12),
              Expanded(flex: 40, child: _box(140)),
            ],
          ),
        ],
      );
    }
    if (tablet) {
      return Column(
        children: [
          Row(children: [Expanded(child: _box(240)), const SizedBox(width: 12), Expanded(child: _box(240))]),
          const SizedBox(height: 12),
          _box(160),
        ],
      );
    }
    return Column(children: [_box(220), const SizedBox(height: 12), _box(160), const SizedBox(height: 12), _box(140)]);
  }
}
