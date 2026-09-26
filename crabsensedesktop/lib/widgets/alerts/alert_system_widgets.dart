import 'package:flutter/material.dart';

import '../../models/farm_alert.dart';
import '../../navigation/app_route.dart';
import '../../services/alert_service.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/mgmt_ui.dart';

const _kAmber = Color(0xFFF5B700);
const _kRed = Color(0xFFEF4444);
const _kBlue = Color(0xFF2495E8);

String alertOpenLabel(Duration? d) {
  if (d == null) return 'Không xác định';
  if (d.inHours >= 24) {
    final days = d.inDays;
    final h = d.inHours % 24;
    return h == 0 ? '$days ngày' : '$days ngày $h giờ';
  }
  if (d.inHours >= 1) {
    final m = d.inMinutes % 60;
    return m == 0 ? '${d.inHours} giờ' : '${d.inHours} giờ $m phút';
  }
  if (d.inMinutes < 1) return '${d.inSeconds} giây';
  return '${d.inMinutes} phút';
}

String alertClock(DateTime? dt, {bool seconds = false}) {
  if (dt == null) return 'Không xác định';
  final l = dt.isUtc ? dt.toLocal() : dt;
  String two(int v) => v.toString().padLeft(2, '0');
  final base =
      '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  return seconds ? '$base:${two(l.second)}' : base;
}

class AlertKpiStrip extends StatelessWidget {
  const AlertKpiStrip({super.key, required this.kpi});
  final AlertKpi kpi;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _kpi('Cảnh báo đang mở', '${kpi.active}', Icons.notifications_active_outlined,
          DashboardColors.brand, kpi.activeDelta),
      _kpi('Nghiêm trọng', '${kpi.critical}', Icons.priority_high_rounded, _kRed,
          kpi.criticalDelta),
      _kpi('Cảnh báo', '${kpi.warning}', Icons.warning_amber_outlined, _kAmber,
          kpi.warningDelta),
      _kpi('Đã xác nhận', '${kpi.acknowledged}', Icons.how_to_reg_outlined, _kBlue,
          kpi.acknowledgedDelta),
      _kpi('Đã xử lý hôm nay', '${kpi.resolvedToday}', Icons.task_alt_outlined,
          DashboardColors.brandGreen, kpi.resolvedDelta),
      _kpi(
        'Thời gian phản hồi TB',
        kpi.avgResponseMinutes == null ? 'Chưa có dữ liệu' : '${kpi.avgResponseMinutes} phút',
        Icons.timer_outlined,
        DashboardColors.brand,
        null,
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth < 700 ? 2 : (c.maxWidth < 1100 ? 3 : 6);
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: cols == 6 ? 1.7 : 2.2,
          children: cards,
        );
      },
    );
  }

  Widget _kpi(String label, String value, IconData icon, Color color, int? delta) {
    String? deltaText;
    if (delta != null && delta != 0) {
      deltaText = delta > 0 ? '+$delta so với hôm qua' : '$delta so với hôm qua';
    } else if (delta == 0) {
      deltaText = 'Không đổi';
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: bvText(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: bvText(
              fontSize: value.length > 8 ? 16 : 24,
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary,
            ),
          ),
          if (deltaText != null)
            Text(deltaText,
                style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
        ],
      ),
    );
  }
}

class AlertFilterToolbar extends StatelessWidget {
  const AlertFilterToolbar({
    super.key,
    required this.service,
    required this.searchController,
  });
  final AlertService service;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: MgmtSearchField(
            controller: searchController,
            hint: 'Tìm cảnh báo, thiết bị, mã cua…',
            onChanged: service.setSearch,
          ),
        ),
        _drop('Mức độ', service.severityFilter, const [
          ('critical', 'Nghiêm trọng'),
          ('warning', 'Cảnh báo'),
          ('info', 'Thông tin'),
        ], service.setSeverity),
        _drop('Trạng thái', service.statusFilter, const [
          ('newAlert', 'Đang mở'),
          ('notified', 'Đã xác nhận'),
          ('inProgress', 'Đang xử lý'),
          ('resolved', 'Đã xử lý'),
          ('falseAlarm', 'Đã tự khôi phục'),
        ], service.setStatus),
        _drop('Loại cảnh báo', service.kindFilter, [
          for (final k in AlertKind.values) (k.name, k.label),
        ], service.setKind),
        _drop('Khu vực', service.areaFilter, [
          for (final a in service.areaOptions) (a, a),
        ], service.setArea),
        _drop('Thiết bị', service.deviceFilter, [
          for (final d in service.deviceOptions) (d, d),
        ], service.setDevice),
        _drop('Thời gian', service.rangeFilter, const [
          ('24h', '24 giờ'),
          ('7d', '7 ngày'),
          ('30d', '30 ngày'),
        ], service.setRange),
        MgmtOutlineButton(
          label: 'Xóa lọc',
          tooltip: 'Xóa bộ lọc cảnh báo',
          onTap: service.hasFilters
              ? () {
                  searchController.clear();
                  service.clearFilters();
                }
              : null,
        ),
      ],
    );
  }

  Widget _drop(
    String label,
    String? value,
    List<(String, String)> items,
    ValueChanged<String?> onChanged,
  ) {
    final shown = items.where((e) => e.$1 == value).firstOrNull?.$2 ?? label;
    return SizedBox(
      width: 160,
      child: MgmtDropdown<String>(
        valueLabel: shown,
        items: [
          ('', 'Tất cả $label'),
          ...items,
        ],
        onSelected: (v) => onChanged(v.isEmpty ? null : v),
      ),
    );
  }
}

class AlertTable extends StatelessWidget {
  const AlertTable({
    super.key,
    required this.service,
    required this.alerts,
    this.selectedId,
    this.asCards = false,
    this.onRowTap,
  });

  final AlertService service;
  final List<FarmAlert> alerts;
  final String? selectedId;
  final bool asCards;
  final ValueChanged<FarmAlert>? onRowTap;

  @override
  Widget build(BuildContext context) {
    if (asCards) {
      return Column(
        children: [
          for (final a in alerts) ...[
            _card(a),
            const SizedBox(height: 8),
          ],
        ],
      );
    }
    return Column(
      children: [
        _head(),
        for (final a in alerts) _row(a),
      ],
    );
  }

  Widget _head() {
    Widget cell(String t, int flex) => Expanded(
          flex: flex,
          child: Text(
            t,
            style: bvText(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: DashboardColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
        );
    final ids = alerts.map((e) => e.id);
    final allChecked = alerts.isNotEmpty && ids.every(service.checked.contains);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Checkbox(
              value: allChecked,
              onChanged: (_) => service.toggleCheckAll(ids),
              visualDensity: VisualDensity.compact,
            ),
          ),
          cell('THỜI GIAN', 2),
          cell('MỨC ĐỘ', 2),
          cell('CẢNH BÁO', 4),
          cell('ĐỐI TƯỢNG', 3),
          cell('KHU VỰC', 2),
          cell('THỜI GIAN MỞ', 2),
          cell('TRẠNG THÁI', 2),
        ],
      ),
    );
  }

  Widget _row(FarmAlert a) {
    final selected = a.id == selectedId;
    return Material(
      color: selected
          ? DashboardColors.lightMint
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          service.selectAlert(a.id);
          onRowTap?.call(a);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? DashboardColors.brand.withValues(alpha: 0.35) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Checkbox(
                  value: service.checked.contains(a.id),
                  onChanged: (_) => service.toggleCheck(a.id),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  a.createdAt == null ? a.time : alertClock(a.createdAt),
                  style: bvText(fontSize: 12, color: DashboardColors.textPrimary),
                ),
              ),
              Expanded(
                flex: 2,
                child: MgmtStatusBadge(label: a.level.labelVi, color: a.level.color),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bvText(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: DashboardColors.textPrimary,
                        )),
                    Text(
                      a.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  '${a.deviceCode.isEmpty ? a.device : a.deviceCode}\n(${a.deviceKindLabel})',
                  style: bvText(fontSize: 12, color: DashboardColors.textPrimary),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  a.areaCode.isNotEmpty && a.areaName.isNotEmpty
                      ? '${a.areaCode}\n${a.areaName}'
                      : a.areaLabel,
                  style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  alertOpenLabel(a.openDuration),
                  style: bvText(fontSize: 12, color: DashboardColors.textPrimary),
                ),
              ),
              Expanded(
                flex: 2,
                child: MgmtStatusBadge(label: a.status.label, color: a.status.dotColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(FarmAlert a) {
    return Material(
      color: a.id == selectedId ? DashboardColors.lightMint : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          service.selectAlert(a.id);
          onRowTap?.call(a);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DashboardColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MgmtStatusBadge(label: a.level.labelVi, color: a.level.color),
                  const Spacer(),
                  MgmtStatusBadge(label: a.status.label, color: a.status.dotColor),
                ],
              ),
              const SizedBox(height: 6),
              Text(a.title,
                  style: bvText(
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  )),
              Text(a.description,
                  style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
              const SizedBox(height: 4),
              Text(
                '${a.areaLabel} · ${alertOpenLabel(a.openDuration)}',
                style: bvText(fontSize: 12, color: DashboardColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlertDetailPanel extends StatelessWidget {
  const AlertDetailPanel({
    super.key,
    required this.alert,
    required this.service,
    this.onNavigate,
    this.compact = false,
    this.canAct = true,
  });

  final FarmAlert alert;
  final AlertService service;
  final void Function(AppRoute route)? onNavigate;
  final bool compact;
  final bool canAct;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: mgmtCardDeco(radius: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                alert.level == AlertLevel.critical
                    ? 'Cảnh báo khẩn cấp'
                    : 'Chi tiết cảnh báo',
                style: bvText(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.textMuted,
                ),
              ),
              const Spacer(),
              MgmtStatusBadge(label: alert.status.label, color: alert.status.dotColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.title,
            style: bvText(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary,
            ),
          ),
          Text(
            alert.description,
            style: bvText(fontSize: 13, color: DashboardColors.textMuted),
          ),
          const SizedBox(height: 14),
          _kv('Mức độ', alert.level.labelVi, color: alert.level.color),
          _kv('Nguồn', alert.sourceLabel),
          _kv(
            'Thiết bị',
            '${alert.deviceCode.isEmpty ? alert.device : alert.deviceCode} (${alert.deviceKindLabel})',
          ),
          _kv('Khu vực', alert.areaLabel),
          _kv('Bắt đầu', alertClock(alert.createdAt, seconds: true)),
          _kv('Thời gian mở', alertOpenLabel(alert.openDuration)),
          if (alert.kind == AlertKind.controller || alert.kind == AlertKind.camera)
            _kv('Heartbeat cuối', alertClock(alert.lastOccurredAt ?? alert.createdAt, seconds: true)),
          if (alert.affected.isNotEmpty)
            _kv('Ảnh hưởng', '${alert.affected.length} cảm biến: ${alert.affected.join(', ')}'),
          if (alert.occurrenceCount > 1)
            _kv('Lặp lại', '${alert.occurrenceCount} lần'),
          const SizedBox(height: 10),
          _typeBlock(context),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._quickLinks(context),
              if (canAct &&
                  alert.isOpen &&
                  alert.status == AlertWorkflowStatus.newAlert)
                MgmtPrimaryButton(
                  label: 'Xác nhận cảnh báo',
                  icon: Icons.check,
                  onTap: () async {
                    final ok = await service.acknowledge(alert.id);
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Đã xác nhận cảnh báo.')),
                      );
                    }
                  },
                ),
              if (canAct &&
                  alert.isOpen &&
                  alert.status != AlertWorkflowStatus.inProgress)
                MgmtOutlineButton(
                  label: 'Bắt đầu xử lý',
                  icon: Icons.handyman_outlined,
                  tooltip: 'Bắt đầu xử lý cảnh báo',
                  onTap: () => service.markInProgress(alert.id),
                ),
              if (canAct && alert.isOpen)
                MgmtOutlineButton(
                  label: 'Đánh dấu đã xử lý',
                  icon: Icons.task_alt,
                  tooltip: 'Đánh dấu đã xử lý cảnh báo',
                  onTap: () => showResolveAlertDialog(context, service, alert),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _history(alert),
          const SizedBox(height: 12),
          CrabAssistantAlertCard(alert: alert, onNavigate: onNavigate),
          const SizedBox(height: 8),
          _technical(alert),
        ],
      ),
    );
  }

  Widget _typeBlock(BuildContext context) {
    switch (alert.kind) {
      case AlertKind.sensor:
        return _box([
          _kv(
            'Hiện tại',
            alert.measuredValue == null
                ? 'Không có giá trị đo'
                : '${alert.measuredValue}${alert.unit.isEmpty ? '' : ' ${alert.unit}'}',
          ),
          _kv(
            'Ngưỡng',
            alert.thresholdMax == null
                ? 'Chưa cấu hình ngưỡng'
                : '≤ ${alert.thresholdMax}${alert.unit.isEmpty ? '' : ' ${alert.unit}'}',
          ),
          if (alert.overThreshold != null)
            _kv('Vượt', '+${alert.overThreshold} ${alert.unit}'),
        ]);
      case AlertKind.waterAnalysis:
        return _box([
          _kv(
            'Kết quả',
            alert.measuredValue == null
                ? 'Không có kết quả'
                : '${alert.measuredValue} ${alert.unit.isEmpty ? 'mg/L' : alert.unit}',
          ),
          _kv(
            'Ngưỡng',
            alert.thresholdMax == null
                ? 'Chưa cấu hình ngưỡng'
                : '≤ ${alert.thresholdMax} ${alert.unit.isEmpty ? 'mg/L' : alert.unit}',
          ),
          if (alert.overThreshold != null)
            _kv('Vượt', '+${alert.overThreshold} ${alert.unit.isEmpty ? 'mg/L' : alert.unit}'),
          if (alert.analysisTestId != null) _kv('Mã phân tích', alert.analysisTestId!),
          if (alert.aiConfidence != null)
            _kv('Độ tin cậy AI', '${(alert.aiConfidence! * 100).round()}%'),
        ]);
      case AlertKind.camera:
        return _box([
          _kv('Camera', alert.deviceCode.isEmpty ? alert.device : alert.deviceCode),
          _kv('Khung hình cuối', alertClock(alert.lastOccurredAt ?? alert.createdAt, seconds: true)),
          _kv('Thời gian mở', alertOpenLabel(alert.openDuration)),
        ]);
      case AlertKind.ras:
        return _box([
          _kv('Thiết bị', alert.deviceCode.isEmpty ? alert.device : alert.deviceCode),
          _kv('Loại', 'Cảnh báo vận hành RAS'),
        ]);
      case AlertKind.crab:
        return _box([
          _kv('Cua / hộp', alert.device.isEmpty ? 'Không xác định' : alert.device),
        ]);
      case AlertKind.controller:
      case AlertKind.system:
        return const SizedBox.shrink();
    }
  }

  List<Widget> _quickLinks(BuildContext context) {
    switch (alert.kind) {
      case AlertKind.controller:
        return [
          MgmtOutlineButton(
            label: 'Xem Controller',
            tooltip: 'Mở trang Controller',
            onTap: () => onNavigate?.call(AppRoute.controllers),
          ),
        ];
      case AlertKind.camera:
        return [
          MgmtOutlineButton(
            label: 'Xem Camera',
            tooltip: 'Mở Camera',
            onTap: () => onNavigate?.call(AppRoute.cameraAi),
          ),
        ];
      case AlertKind.ras:
        return [
          MgmtOutlineButton(
            label: 'Mở Điều khiển RAS',
            tooltip: 'Mở Điều khiển RAS',
            onTap: () => onNavigate?.call(AppRoute.devices),
          ),
        ];
      case AlertKind.waterAnalysis:
        return [
          MgmtOutlineButton(
            label: 'Xem lần phân tích →',
            onTap: () => onNavigate?.call(AppRoute.waterAnalysis),
          ),
        ];
      case AlertKind.crab:
        return [
          MgmtOutlineButton(
            label: 'Xem cua',
            onTap: () => onNavigate?.call(AppRoute.productionCrabManagement),
          ),
          MgmtOutlineButton(
            label: 'Xem hộp',
            onTap: () => onNavigate?.call(AppRoute.boxManagement),
          ),
        ];
      default:
        return const [];
    }
  }

  Widget _history(FarmAlert a) {
    final events = <(String, String, String)>[
      (alertClock(a.createdAt), 'Cảnh báo được tạo', 'System'),
      if (a.acknowledgedAt != null)
        (alertClock(a.acknowledgedAt), 'Cảnh báo được xác nhận', 'Người vận hành'),
      if (a.status == AlertWorkflowStatus.inProgress)
        (alertClock(a.acknowledgedAt ?? a.createdAt), 'Bắt đầu xử lý', 'Người vận hành'),
      if (a.status == AlertWorkflowStatus.falseAlarm)
        (alertClock(a.resolvedAt), 'Thiết bị đã tự khôi phục kết nối.', 'System'),
      if (a.status == AlertWorkflowStatus.resolved)
        (alertClock(a.resolvedAt), 'Cảnh báo được đóng', 'Người vận hành'),
    ];
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: EdgeInsets.zero,
        title: Text(
          'Chi tiết & lịch sử xử lý',
          style: bvText(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: DashboardColors.textPrimary,
          ),
        ),
        children: [
          for (final e in events)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(e.$1,
                        style: bvText(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: DashboardColors.brand,
                        )),
                  ),
                  Expanded(
                    child: Text(
                      '${e.$2}\n${e.$3}',
                      style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _technical(FarmAlert a) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          'Thông tin kỹ thuật',
          style: bvText(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: DashboardColors.textPrimary,
          ),
        ),
        children: [
          _kv('Mã cảnh báo', a.displayCode),
          _kv('Alert ID', a.id),
          _kv('Incident ID', a.incidentId ?? 'Không xác định'),
          _kv('Rule key', _friendlyRule(a.ruleKey)),
          _kv('Nguồn', a.sourceLabel),
          _kv('Mã thiết bị', a.deviceCode.isEmpty ? 'Không xác định' : a.deviceCode),
          _kv('Created', alertClock(a.createdAt, seconds: true)),
          _kv('Last occurrence', alertClock(a.lastOccurredAt ?? a.createdAt, seconds: true)),
          _kv('Occurrence count', '${a.occurrenceCount}'),
        ],
      ),
    );
  }

  Widget _box(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  String _friendlyRule(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Không xác định';
    final key = raw.trim().toLowerCase();
    return switch (key) {
      'realtime_sensor' => 'SENSOR_THRESHOLD',
      'controller_disconnect' => 'CONTROLLER_HEARTBEAT_TIMEOUT',
      'sensor_timeout' => 'SENSOR_NO_DATA',
      'ras_component_error' => 'RAS_COMPONENT_FAULT',
      _ => raw.contains('_') && raw == raw.toLowerCase()
          ? raw.toUpperCase()
          : raw,
    };
  }

  Widget _kv(String k, String v, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(k, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          ),
          Expanded(
            child: Text(
              v,
              style: bvText(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color ?? DashboardColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CrabAssistantAlertCard extends StatelessWidget {
  const CrabAssistantAlertCard({
    super.key,
    required this.alert,
    this.onNavigate,
  });

  final FarmAlert alert;
  final void Function(AppRoute route)? onNavigate;

  @override
  Widget build(BuildContext context) {
    final causes = _causes(alert);
    final actions = _actions(alert);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Crab Assistant AI',
                style: bvText(
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              const MgmtStatusBadge(label: 'BETA', color: DashboardColors.brand),
            ],
          ),
          const SizedBox(height: 8),
          Text('Nhận định',
              style: bvText(fontSize: 12, fontWeight: FontWeight.w700, color: DashboardColors.textMuted)),
          Text(
            alert.aiRecommendation?.isNotEmpty == true
                ? alert.aiRecommendation!
                : '${alert.title} đã mở ${alertOpenLabel(alert.openDuration)}. Đây là gợi ý, không phải kết luận.',
            style: bvText(fontSize: 13, color: DashboardColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text('Khả năng nguyên nhân',
              style: bvText(fontSize: 12, fontWeight: FontWeight.w700, color: DashboardColors.textMuted)),
          for (var i = 0; i < causes.length; i++)
            Text('${i + 1}. ${causes[i]}',
                style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Gợi ý hành động',
              style: bvText(fontSize: 12, fontWeight: FontWeight.w700, color: DashboardColors.textMuted)),
          for (var i = 0; i < actions.length; i++)
            Text('${i + 1}. ${actions[i]}',
                style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary)),
          const SizedBox(height: 10),
          if (alert.kind == AlertKind.controller) ...[
            const SizedBox(height: 10),
            MgmtOutlineButton(
              label: 'Kiểm tra kết nối Controller',
              tooltip: 'Mở trang Controller để kiểm tra kết nối',
              onTap: () => onNavigate?.call(AppRoute.controllers),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _causes(FarmAlert a) {
    switch (a.kind) {
      case AlertKind.controller:
      case AlertKind.camera:
        return [
          'Mất kết nối Wi-Fi tại ${a.areaLabel}',
          'Thiết bị mất nguồn',
          'ESP32 / firmware bị treo',
        ];
      case AlertKind.sensor:
        return ['Giá trị vượt ngưỡng', 'Cảm biến lệch hiệu chuẩn', 'Môi trường thay đổi đột ngột'];
      case AlertKind.waterAnalysis:
        return ['Nồng độ vượt ngưỡng theo dõi', 'Mẫu phản ứng chưa ổn', 'Cần kiểm tra lại phép thử'];
      case AlertKind.ras:
        return ['Bơm/van dừng ngoài kỳ vọng', 'Lỗi relay / lệnh AUTO', 'Mất nguồn thiết bị'];
      default:
        return ['Cần đối chiếu nhật ký thiết bị'];
    }
  }

  List<String> _actions(FarmAlert a) {
    switch (a.kind) {
      case AlertKind.controller:
        return [
          'Kiểm tra nguồn điện Controller',
          'Kiểm tra Wi-Fi khu ${a.areaLabel}',
          'Thử kiểm tra kết nối Controller',
        ];
      case AlertKind.waterAnalysis:
        return ['Xem lần phân tích', 'Kiểm tra ảnh mẫu', 'Chạy lại phép thử nếu cần'];
      case AlertKind.ras:
        return ['Mở Điều khiển RAS', 'Kiểm tra trạng thái bơm/van', 'Không tự gửi lệnh phá hủy'];
      default:
        return ['Xác nhận cảnh báo', 'Ghi nhận nguyên nhân khi xử lý'];
    }
  }
}

Future<void> showResolveAlertDialog(
  BuildContext context,
  AlertService service,
  FarmAlert alert,
) async {
  String reason = 'WIFI_LOSS';
  final action = TextEditingController();
  final note = TextEditingController();
  var recovered = false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSt) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Xử lý cảnh báo',
              style: bvText(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: DashboardColors.textPrimary,
              ),
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Nguyên nhân *',
                      style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: reason,
                    dropdownColor: Colors.white,
                    items: const [
                      DropdownMenuItem(value: 'WIFI_LOSS', child: Text('Mất kết nối Wi-Fi')),
                      DropdownMenuItem(value: 'POWER_LOSS', child: Text('Mất nguồn')),
                      DropdownMenuItem(value: 'DEVICE_HANG', child: Text('Thiết bị treo')),
                      DropdownMenuItem(value: 'THRESHOLD', child: Text('Vượt ngưỡng thật')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
                    ],
                    onChanged: (v) => setSt(() => reason = v ?? reason),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: action,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Cách xử lý *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: note,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: recovered,
                    onChanged: (v) => setSt(() => recovered = v ?? false),
                    title: Text(
                      'Thiết bị đã hoạt động lại',
                      style: bvText(color: DashboardColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              MgmtPrimaryButton(
                label: 'Xác nhận đã xử lý',
                onTap: () {
                  if (action.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
              ),
            ],
          );
        },
      );
    },
  );
  if (ok == true) {
    await service.resolve(
      alert.id,
      reason: reason,
      action: action.text.trim(),
      note: note.text.trim(),
      recovered: recovered,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đánh dấu xử lý.')),
      );
    }
  }
  action.dispose();
  note.dispose();
}
