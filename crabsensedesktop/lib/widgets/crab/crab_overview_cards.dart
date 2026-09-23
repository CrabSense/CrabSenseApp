import 'package:flutter/material.dart';

import '../../models/crab_feeding_activity.dart';
import '../../models/crab_individual.dart';
import '../../models/crab_profile.dart';
import '../../models/crab_status.dart';
import '../../models/production_models.dart';
import '../../services/crab_feeding_activity_controller.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/mgmt_ui.dart';
import 'crab_status_badge.dart';

// ── Shared primitives ────────────────────────────────────────────────────

class OverviewCard extends StatelessWidget {
  const OverviewCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.iconColor = DashboardColors.brand,
    this.padding = const EdgeInsets.all(16),
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;
  final Color iconColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: bvText(fontSize: 14.5, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class OverviewLinkButton extends StatelessWidget {
  const OverviewLinkButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: DashboardColors.brand,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text('$label →', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700)),
    );
  }
}

Widget _kvRow(String label, Widget value, {double labelWidth = 120}) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(label, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          ),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: value)),
        ],
      ),
    );

Widget _kvText(String label, String value, {double labelWidth = 120, Widget? trailing}) => _kvRow(
      label,
      Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
      labelWidth: labelWidth,
    );

/// Skeleton rows cho card đang tải.
class OverviewSkeletonRows extends StatelessWidget {
  const OverviewSkeletonRows({super.key, this.rows = 5});

  final int rows;

  @override
  Widget build(BuildContext context) {
    Widget bar(double w) => Container(
          width: w,
          height: 12,
          decoration: BoxDecoration(color: DashboardColors.mint, borderRadius: BorderRadius.circular(6)),
        );
    return Column(
      children: [
        for (var i = 0; i < rows; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(children: [bar(90), const SizedBox(width: 24), Expanded(child: bar(double.infinity))]),
          ),
      ],
    );
  }
}

// ── Thông tin cơ bản ─────────────────────────────────────────────────────

class CrabBasicInfoCard extends StatelessWidget {
  const CrabBasicInfoCard({super.key, required this.crab, required this.profile, this.onEdit, this.loading = false});

  final CrabIndividual crab;
  final CrabProfile? profile;
  final VoidCallback? onEdit;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final lot = crab.batchId.trim().isEmpty ? (profile?.lotCode ?? '') : crab.batchId;
    return OverviewCard(
      icon: Icons.info_outline_rounded,
      title: 'Thông tin cơ bản',
      trailing: MgmtOutlineButton(
        icon: Icons.edit_outlined,
        label: 'Chỉnh sửa',
        onTap: onEdit,
        height: 30,
        color: DashboardColors.textPrimary,
        borderColor: DashboardColors.cardBorder,
      ),
      child: loading
          ? const OverviewSkeletonRows(rows: 8)
          : Column(
              children: [
                _kvText('Mã cua', crab.code),
                _kvText('Loại', crab.crabType),
                _kvRow('Giới tính', CrabGenderBadge(gender: crab.gender)),
                _kvText('Lô cua', lot.isEmpty ? 'Chưa gắn lô' : lot),
                _kvText('Cân nặng', crab.weightLabel),
                _kvText(
                  'Kích thước',
                  crab.sizeLabel,
                  trailing: Tooltip(
                    message: 'Chiều rộng mai × chiều dài mai (mm)',
                    child: Icon(Icons.help_outline_rounded, size: 14, color: DashboardColors.textMuted),
                  ),
                ),
                _kvText('Số lần lột xác', '${crab.moltCount}'),
                _kvText('Lột xác gần nhất', crab.lastMoltDate == null ? 'Chưa ghi nhận' : fmtDateVn(crab.lastMoltDate)),
              ],
            ),
    );
  }
}

// ── Tình trạng ───────────────────────────────────────────────────────────

/// Giai đoạn sinh trưởng (độc lập với sức khỏe & trạng thái).
String crabGrowthStageLabel(CrabIndividual crab, CrabProfile? profile) {
  final cond = (profile?.condition ?? '').toLowerCase();
  if (crab.lifecycleStatus == CrabLifecycleStatus.molting) return 'Đang lột';
  if (crab.lifecycleStatus == CrabLifecycleStatus.readyHarvest) return 'Sắp thu hoạch';
  if (cond.contains('premolt') || cond.contains('sắp lột')) return 'Chuẩn bị lột';
  if (cond.contains('postmolt') || cond.contains('soft') || cond.contains('sau lột')) return 'Sau lột';
  final days = crab.daysSinceLastMolt;
  if (days != null && days <= 3) return 'Sau lột';
  return switch (crab.developmentStage) {
    CrabDevelopmentStage.preHarvest || CrabDevelopmentStage.harvestReady => 'Sắp thu hoạch',
    _ => 'Sinh trưởng',
  };
}

class CrabStatusCard extends StatelessWidget {
  const CrabStatusCard({super.key, required this.crab, required this.profile, this.loading = false});

  final CrabIndividual crab;
  final CrabProfile? profile;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final alerts = profile?.alerts.length ?? 0;
    final aiAbnormal = alerts > 0 || _isAbnormal(profile?.aiPrediction);
    return OverviewCard(
      icon: Icons.monitor_heart_outlined,
      title: 'Tình trạng',
      child: loading
          ? const OverviewSkeletonRows(rows: 5)
          : Column(
              children: [
                _kvRow('Sức khỏe', CrabHealthBadge(status: crab.displayHealth)),
                _kvRow('Trạng thái', CrabLifecycleBadge(status: crab.lifecycleStatus)),
                _kvText('Giai đoạn', crabGrowthStageLabel(crab, profile)),
                _kvRow(
                  'AI giám sát',
                  profile?.aiAnalyzedAt == null && profile?.aiPrediction == null
                      ? Text('Chưa có dữ liệu AI', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))
                      : MgmtStatusBadge(
                          label: aiAbnormal ? 'Phát hiện bất thường' : 'Không phát hiện bất thường',
                          color: aiAbnormal ? const Color(0xFFF5B700) : DashboardColors.brand,
                        ),
                ),
                _kvText('Cập nhật cuối', fmtDateTimeVn(crab.lastUpdated)),
              ],
            ),
    );
  }

  static bool _isAbnormal(String? p) {
    final s = (p ?? '').toLowerCase();
    return s.contains('abnormal') || s.contains('bất thường') || s.contains('risk') || s.contains('weak');
  }
}

// ── Ăn & vận động gần nhất ───────────────────────────────────────────────

class CrabFeedingSummaryCard extends StatelessWidget {
  const CrabFeedingSummaryCard({
    super.key,
    required this.controller,
    required this.onOpenAnalysis,
    required this.onAddFeeding,
  });

  final CrabFeedingActivityController controller;
  final VoidCallback onOpenAnalysis;
  final VoidCallback onAddFeeding;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final e = controller.latestEvent;
        final th = controller.thresholds;
        final loading = controller.loading && controller.data == null;
        final now = DateTime.now();
        final isToday = e != null && e.time.year == now.year && e.time.month == now.month && e.time.day == now.day;

        // Vận động: ưu tiên điểm sau ăn của event gần nhất có dữ liệu vận động.
        final actEvent = controller.data?.events.where((x) => x.activityScore != null).fold<FeedingEvent?>(
              null,
              (best, x) => best == null || x.time.isAfter(best.time) ? x : best,
            );
        final act = actEvent?.activityScore;

        Widget body;
        if (loading) {
          body = Row(
            children: [
              Expanded(child: _skeletonTile()),
              const SizedBox(width: 12),
              Expanded(child: _skeletonTile()),
            ],
          );
        } else if (e == null) {
          body = Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DashboardColors.mint),
            ),
            child: Column(
              children: [
                const Icon(Icons.restaurant_rounded, size: 24, color: DashboardColors.brand),
                const SizedBox(height: 6),
                Text('Chưa có dữ liệu cho ăn',
                    style: bvText(fontSize: 13.5, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  'Chưa ghi nhận lần cho ăn nào trong ${controller.periodLabel.toLowerCase()}.',
                  style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                ),
                const SizedBox(height: 10),
                MgmtOutlineButton(icon: Icons.add_rounded, label: 'Ghi nhận cho ăn', onTap: onAddFeeding, height: 32),
              ],
            ),
          );
        } else {
          final pct = e.feedingPercent;
          body = Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.set_meal_rounded,
                  iconColor: DashboardColors.brand,
                  label: 'Mức ăn',
                  value: pct == null ? '—' : '$pct%',
                  badge: pct == null ? null : _feedingLabel(pct, th),
                  badgeColor: pct == null ? null : th.feedingColor(pct),
                  footer: 'Lần ăn cuối: ${fmtDateTimeVn(e.time)}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  icon: Icons.monitor_heart_outlined,
                  iconColor: kFeedingBlue,
                  label: 'Vận động',
                  value: act == null ? '—' : '$act / 100',
                  badge: act == null ? null : th.activityLabel(act),
                  badgeColor: act == null ? null : th.activityColor(act),
                  footer: act == null ? 'Chưa có dữ liệu vận động.' : 'Cập nhật: ${fmtDateTimeVn(actEvent!.time)}',
                ),
              ),
            ],
          );
        }

        return OverviewCard(
          icon: Icons.restaurant_rounded,
          title: isToday ? 'Ăn & vận động hôm nay' : 'Ăn & vận động gần nhất',
          trailing: OverviewLinkButton(label: 'Xem phân tích', onTap: onOpenAnalysis),
          child: body,
        );
      },
    );
  }

  static String _feedingLabel(int pct, FeedingThresholds th) {
    if (pct <= 0) return 'Không ăn';
    if (pct < th.alertPercent) return 'Cảnh báo';
    if (pct < th.watchPercent) return 'Theo dõi';
    if (pct < th.finishPercent) return 'Trung bình';
    return 'Tốt';
  }

  Widget _skeletonTile() => Container(
        height: 84,
        decoration: BoxDecoration(color: DashboardColors.mint, borderRadius: BorderRadius.circular(12)),
      );
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.footer,
    this.badge,
    this.badgeColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String footer;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          value,
                          style: bvText(fontSize: 22, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary, height: 1.15),
                        ),
                        if (badge != null) MgmtStatusBadge(label: badge!, color: badgeColor ?? DashboardColors.brand),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(footer, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
        ],
      ),
    );
  }
}

// ── Vị trí hiện tại ──────────────────────────────────────────────────────

class CrabLocationCard extends StatelessWidget {
  const CrabLocationCard({
    super.key,
    required this.crab,
    required this.profile,
    this.box,
    this.boxLoading = false,
    this.onOpenArea,
    this.onOpenRow,
    this.onOpenBox,
  });

  final CrabIndividual crab;
  final CrabProfile? profile;
  final BoxRecord? box;
  final bool boxLoading;
  final VoidCallback? onOpenArea;
  final VoidCallback? onOpenRow;
  final VoidCallback? onOpenBox;

  @override
  Widget build(BuildContext context) {
    final areaName = profile?.areaName.isNotEmpty == true ? profile!.areaName : crab.areaName;
    final areaCode = crab.areaLabel;
    final areaText = areaName.isNotEmpty && areaName != areaCode ? '$areaCode — $areaName' : areaCode;

    final rows = Column(
      children: [
        _locRow('Khu', areaText, onOpenArea),
        _locRow('Dãy', crab.rowLabel, onOpenRow),
        _locRow('Hộp', crab.boxLabel, onOpenBox, last: true),
      ],
    );

    return OverviewCard(
      icon: Icons.place_outlined,
      title: 'Vị trí hiện tại',
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 560;
          final panel = _BoxQuickPanel(box: box, loading: boxLoading, onOpenBox: onOpenBox, crab: crab);
          return wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: rows),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: panel),
                  ],
                )
              : Column(children: [rows, const SizedBox(height: 12), panel]);
        },
      ),
    );
  }

  Widget _locRow(String label, String value, VoidCallback? onTap, {bool last = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: DashboardColors.mint)),
        ),
        child: Row(
          children: [
            SizedBox(width: 60, child: Text(label, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bvText(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: onTap == null ? DashboardColors.textPrimary : DashboardColors.brand,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 15,
                color: onTap == null ? DashboardColors.cardBorder : DashboardColors.brand),
          ],
        ),
      ),
    );
  }
}

class _BoxQuickPanel extends StatelessWidget {
  const _BoxQuickPanel({required this.box, required this.loading, required this.crab, this.onOpenBox});

  final BoxRecord? box;
  final bool loading;
  final CrabIndividual crab;
  final VoidCallback? onOpenBox;

  @override
  Widget build(BuildContext context) {
    final b = box;
    final active = (b?.status ?? '').toLowerCase();
    final isActive = active.isEmpty || active == 'active' || active == 'occupied' || active.contains('hoạt');
    final crabCount = b == null ? (crab.boxId.isEmpty ? 0 : 1) : (b.crabCount > 0 ? b.crabCount : (b.hasCrab ? 1 : 0));
    final alerts = b?.alertCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.mint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpenBox,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: DashboardColors.mint, borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.inventory_2_outlined, size: 15, color: DashboardColors.brand),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Xem chi tiết hộp',
                      style: bvText(fontSize: 13, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 15, color: DashboardColors.brand),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (loading && b == null)
            const OverviewSkeletonRows(rows: 2)
          else ...[
            _mini('Tình trạng hộp',
                MgmtStatusBadge(label: isActive ? 'Đang hoạt động' : (b?.status ?? '—'), color: isActive ? DashboardColors.brand : kMgmtSlate)),
            const SizedBox(height: 6),
            _mini('Số cua trong hộp',
                Text('$crabCount / 1', style: bvText(fontSize: 13, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary))),
            if (alerts > 0) ...[
              const SizedBox(height: 6),
              _mini('Cảnh báo', MgmtStatusBadge(label: '$alerts cảnh báo', color: const Color(0xFFF5B700))),
            ],
          ],
        ],
      ),
    );
  }

  Widget _mini(String label, Widget value) => Row(
        children: [
          Expanded(child: Text(label, style: bvText(fontSize: 12, color: DashboardColors.textMuted))),
          value,
        ],
      );
}

// ── Cảnh báo & AI ────────────────────────────────────────────────────────

class CrabAIAlertCard extends StatelessWidget {
  const CrabAIAlertCard({
    super.key,
    required this.crab,
    required this.profile,
    required this.feeding,
    this.onViewHistory,
    this.loading = false,
  });

  final CrabIndividual crab;
  final CrabProfile? profile;
  final CrabFeedingActivityController feeding;
  final VoidCallback? onViewHistory;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final alerts = [...?profile?.alerts]..sort((a, b) => b.at.compareTo(a.at));
    final hasAlert = alerts.isNotEmpty;
    final lastAt = profile?.aiAnalyzedAt;
    final aiLevel = (profile?.aiActivityLevel ?? '').toLowerCase();
    final aiLabel = lastAt == null && profile?.aiPrediction == null
        ? null
        : hasAlert || aiLevel.contains('low') || aiLevel.contains('thấp')
            ? 'Cần theo dõi'
            : 'Theo dõi bình thường';

    return AnimatedBuilder(
      animation: feeding,
      builder: (context, _) {
        final level = feeding.data?.insightLevel ?? 'none';
        final (trendIcon, trendText, trendColor) = switch (level) {
          'warning' => (Icons.south_east_rounded, 'Giảm — cần theo dõi', DashboardColors.risk),
          'watch' => (Icons.trending_down_rounded, 'Cần theo dõi', const Color(0xFFF5B700)),
          'ok' => (Icons.north_east_rounded, 'Ổn định', DashboardColors.brand),
          _ => (Icons.remove_rounded, 'Chưa đủ dữ liệu', DashboardColors.textMuted),
        };

        return OverviewCard(
          icon: Icons.notifications_active_outlined,
          title: 'Cảnh báo & AI',
          iconColor: hasAlert ? const Color(0xFFF5B700) : DashboardColors.brand,
          child: loading
              ? const OverviewSkeletonRows(rows: 4)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!hasAlert)
                      _banner(
                        icon: Icons.check_circle_rounded,
                        color: DashboardColors.brand,
                        title: 'Không có cảnh báo đang hoạt động',
                        subtitle: 'Cua đang trong tình trạng bình thường.',
                      )
                    else ...[
                      _banner(
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFFF5B700),
                        title: '${alerts.length} cảnh báo cần theo dõi',
                        subtitle: alerts.first.title,
                      ),
                      const SizedBox(height: 8),
                      _kvText('Phát hiện lúc', fmtDateTimeVn(alerts.first.at), labelWidth: 130),
                      if (alerts.first.detail != null) _kvText('Chi tiết', alerts.first.detail!, labelWidth: 130),
                    ],
                    const SizedBox(height: 12),
                    _kvRow(
                      'AI Camera',
                      aiLabel == null
                          ? Text('Chưa có dữ liệu AI', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))
                          : MgmtStatusBadge(
                              label: aiLabel,
                              color: aiLabel == 'Cần theo dõi' ? const Color(0xFFF5B700) : DashboardColors.brand),
                      labelWidth: 130,
                    ),
                    _kvText('Phát hiện gần nhất', lastAt == null ? 'Chưa có' : fmtDateTimeVn(lastAt), labelWidth: 130),
                    _kvRow(
                      'Xu hướng 7 ngày',
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(trendIcon, size: 15, color: trendColor),
                          const SizedBox(width: 4),
                          Text(trendText, style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: trendColor)),
                        ],
                      ),
                      labelWidth: 130,
                    ),
                    const SizedBox(height: 4),
                    MgmtOutlineButton(
                      icon: Icons.history_rounded,
                      label: hasAlert ? 'Xem chi tiết' : 'Xem lịch sử phát hiện',
                      onTap: onViewHistory,
                      height: 34,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _banner({required IconData icon, required Color color, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: bvText(fontSize: 13, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
                Text(subtitle, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hoạt động gần đây ────────────────────────────────────────────────────

class CrabActivityItem {
  const CrabActivityItem({
    required this.at,
    required this.title,
    required this.detail,
    required this.icon,
    this.color = DashboardColors.brand,
    this.feedingEvent,
    this.timelineEvent,
  });

  final DateTime at;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final FeedingEvent? feedingEvent;
  final CrabTimelineEvent? timelineEvent;
}

/// Gộp timeline hồ sơ + lần cho ăn thành danh sách hoạt động gần đây.
List<CrabActivityItem> buildRecentActivity(CrabProfile? profile, CrabFeedingActivityData? feeding, {int limit = 5}) {
  final items = <CrabActivityItem>[];
  for (final e in profile?.timeline ?? const <CrabTimelineEvent>[]) {
    final k = e.kind.toLowerCase();
    if (k == 'feeding') continue; // lấy từ feeding events (có % ăn)
    final (icon, color) = switch (k) {
      'molt' || 'molting' => (Icons.autorenew_rounded, const Color(0xFF7C3AED)),
      'transfer' || 'move' || 'allocation' => (Icons.swap_horiz_rounded, kFeedingBlue),
      'health' || 'inspection' => (Icons.monitor_heart_outlined, DashboardColors.brand),
      'weight' => (Icons.monitor_weight_outlined, kFeedingBlue),
      'alert' || 'warning' => (Icons.warning_amber_rounded, const Color(0xFFF5B700)),
      'ai' => (Icons.auto_awesome_rounded, const Color(0xFF7C3AED)),
      _ => (Icons.circle_outlined, kMgmtSlate),
    };
    items.add(CrabActivityItem(at: e.at, title: e.title, detail: e.detail ?? '', icon: icon, color: color, timelineEvent: e));
  }
  for (final f in feeding?.events ?? const <FeedingEvent>[]) {
    String g(double? v) => v == null ? '—' : v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
    final detail = f.servedGram == null
        ? (f.feedingPercent == null ? f.foodType : '${f.feedingPercent}%')
        : '${g(f.eatenGram)} / ${g(f.servedGram)} g${f.feedingPercent == null ? '' : ' (${f.feedingPercent}%)'}';
    items.add(CrabActivityItem(
      at: f.time,
      title: f.isAi ? 'AI ghi nhận cho ăn' : 'Cho ăn',
      detail: detail,
      icon: Icons.restaurant_rounded,
      color: DashboardColors.brand,
      feedingEvent: f,
    ));
  }
  items.sort((a, b) => b.at.compareTo(a.at));
  return items.take(limit).toList();
}

class CrabRecentActivity extends StatelessWidget {
  const CrabRecentActivity({
    super.key,
    required this.items,
    required this.onViewAll,
    required this.onTapItem,
    this.loading = false,
  });

  final List<CrabActivityItem> items;
  final VoidCallback onViewAll;
  final ValueChanged<CrabActivityItem> onTapItem;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return OverviewCard(
      icon: Icons.history_rounded,
      title: 'Hoạt động gần đây',
      trailing: OverviewLinkButton(label: 'Xem tất cả', onTap: onViewAll),
      child: loading
          ? const OverviewSkeletonRows(rows: 5)
          : items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Chưa có hoạt động nào được ghi nhận.',
                      style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
                )
              : Column(
                  children: [
                    for (var i = 0; i < items.length; i++) _row(items[i], i == items.length - 1),
                  ],
                ),
    );
  }

  Widget _row(CrabActivityItem it, bool last) {
    String two(int v) => v.toString().padLeft(2, '0');
    final ts = '${two(it.at.day)}/${two(it.at.month)}  ${two(it.at.hour)}:${two(it.at.minute)}';
    return InkWell(
      onTap: () => onTapItem(it),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(ts, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
            ),
          ),
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: it.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(it.icon, size: 12, color: it.color),
              ),
              if (!last) Container(width: 2, height: 22, color: DashboardColors.mint),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 10, top: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(it.detail.isEmpty ? '—' : it.detail, maxLines: 1, overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ghi chú ──────────────────────────────────────────────────────────────

class CrabNoteCard extends StatelessWidget {
  const CrabNoteCard({super.key, required this.note, required this.onEdit, this.loading = false});

  final String? note;
  final VoidCallback onEdit;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final has = note != null && note!.trim().isNotEmpty;
    return OverviewCard(
      icon: Icons.notes_rounded,
      title: 'Ghi chú',
      trailing: MgmtOutlineButton(
        icon: has ? Icons.edit_outlined : Icons.add_rounded,
        label: has ? 'Chỉnh sửa' : 'Thêm ghi chú',
        onTap: onEdit,
        height: 30,
        color: DashboardColors.textPrimary,
        borderColor: DashboardColors.cardBorder,
      ),
      child: loading
          ? const OverviewSkeletonRows(rows: 1)
          : Text(
              has ? note!.trim() : 'Chưa có ghi chú.',
              style: bvText(
                fontSize: 13,
                height: 1.45,
                color: has ? DashboardColors.textPrimary : DashboardColors.textMuted,
              ),
            ),
    );
  }
}

/// Modal "Ghi chú cua" (max 500 ký tự). Trả về text mới hoặc null nếu hủy.
Future<String?> showCrabNoteDialog(BuildContext context, {String? initial}) {
  final ctrl = TextEditingController(text: initial ?? '');
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Ghi chú cua', style: bvText(fontSize: 16, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
      content: SizedBox(
        width: 440,
        child: TextField(
          controller: ctrl,
          maxLines: 5,
          maxLength: 500,
          autofocus: true,
          style: bvText(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'VD: Cua hoạt động bình thường, theo dõi lần lột xác tiếp theo.',
            hintStyle: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: DashboardColors.brandGreen, width: 1.4),
            ),
          ),
        ),
      ),
      actions: [
        MgmtOutlineButton(label: 'Hủy', onTap: () => Navigator.of(ctx).pop()),
        MgmtPrimaryButton(label: 'Lưu ghi chú', height: 38, onTap: () => Navigator.of(ctx).pop(ctrl.text.trim())),
      ],
    ),
  );
}
