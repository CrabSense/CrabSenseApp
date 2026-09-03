import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_iot_devices_data.dart';
import '../../models/iot_device.dart';
import '../../services/iot_device_service.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';
import '../shared/ai_assistant_avatar.dart';

// ─── Overview & KPI ─────────────────────────────────────────────────────────

class IotOverviewDashboard extends StatelessWidget {
  const IotOverviewDashboard({super.key, required this.overview});

  final IotDeviceOverview overview;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Dashboard Tổng Quan Thiết Bị',
            style: GoogleFonts.notoSans(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              final items = [
                _stat('Tổng thiết bị', '${overview.total}'),
                _stat('Online', '${overview.online}'),
                _stat('Offline', '${overview.offline}'),
                _stat('Đang hoạt động', '${overview.running}'),
                _stat('Đang dừng', '${overview.stopped}'),
                _stat('Có lỗi', '${overview.error}'),
                _stat(
                  'Điện năng hôm nay',
                  '${overview.energyTodayKwh.toStringAsFixed(1)} kWh',
                  highlight: true,
                ),
              ];
              if (c.maxWidth > 900) {
                return Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: items,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items
                    .map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: w,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: GoogleFonts.notoSans(
            color: DashboardColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.notoSans(
            color: highlight ? DashboardColors.cyan : DashboardColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class IotKpiStrip extends StatelessWidget {
  const IotKpiStrip({super.key, required this.kpi});

  final IotDeviceKpi kpi;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final items = [
          _KpiCard('Trực tuyến', kpi.online, DashboardColors.healthy,
              Icons.check_circle_outline),
          _KpiCard('Ngoại tuyến', kpi.offline, DashboardColors.dead,
              Icons.cloud_off_outlined),
          _KpiCard('Đang chạy', kpi.running, DashboardColors.purple,
              Icons.play_circle_outline),
          _KpiCard('Lỗi', kpi.error, DashboardColors.risk, Icons.error_outline),
        ];
        if (c.maxWidth < 700) {
          return Wrap(spacing: 10, runSpacing: 10, children: items);
        }
        return Row(
          children: items
              .map((e) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: e,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard(this.label, this.value, this.color, this.icon);

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 10,
                ),
              ),
              Text(
                '$value',
                style: GoogleFonts.notoSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class IotCategoryChips extends StatelessWidget {
  const IotCategoryChips({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: MockIotDevicesData.categoryFilters.map((c) {
          final active = c == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onSelect(c),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? DashboardColors.purple.withValues(alpha: 0.35)
                      : DashboardColors.cardBorder.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? DashboardColors.purple
                        : DashboardColors.cardBorder,
                  ),
                ),
                child: Text(
                  c == 'Tất cả' ? 'Tất cả' : c,
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    color: active
                        ? DashboardColors.textPrimary
                        : DashboardColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Device card (mockup style) ─────────────────────────────────────────────

class IotDeviceCard extends StatelessWidget {
  const IotDeviceCard({
    super.key,
    required this.device,
    required this.service,
    required this.selected,
  });

  final IotDevice device;
  final IotDeviceService service;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final online = device.connection == IotConnectionStatus.online;
    final switchEnabled = online && service.emergencyStop == false;

    return GlassCard(
      highlight: selected,
      borderColor: selected ? DashboardColors.purple : null,
      onTap: () => service.selectDevice(device.id),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: DashboardColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(device.type.icon, color: DashboardColors.cyan, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.typeLabel,
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      device.name,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: device.connection.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        device.connection.label,
                        style: GoogleFonts.notoSans(
                          color: device.connection.color,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Switch(
                    value: device.isOn && online,
                    onChanged: switchEnabled
                        ? (_) => service.togglePower(device.id)
                        : null,
                    activeThumbColor: DashboardColors.purple,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ],
          ),
          if (device.errorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: DashboardColors.risk.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DashboardColors.risk.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: DashboardColors.risk, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      device.errorMessage!,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.risk,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniStat('Công suất', '${device.powerWatts}W'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStat('Số lần chạy', _formatCount(device.runCount)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.schedule, size: 12, color: DashboardColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  device.scheduleInfo,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (device.isRunning) ...[
            const SizedBox(height: 6),
            Text(
              'Running',
              style: GoogleFonts.notoSans(
                color: DashboardColors.blue,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: online && !service.emergencyStop
                      ? () => service.toggleMode(device.id)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: device.mode == IotControlMode.auto
                        ? DashboardColors.purple.withValues(alpha: 0.35)
                        : DashboardColors.cardBorder,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    device.mode.modeButtonLabel,
                    style: GoogleFonts.notoSans(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => service.selectDevice(device.id),
                icon: const Icon(Icons.settings_outlined, size: 18),
                color: DashboardColors.textMuted,
                style: IconButton.styleFrom(
                  backgroundColor: DashboardColors.cardBorder.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          if (device.showFixNow || device.showTestButton) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (device.showFixNow)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => service.fixNow(device.id),
                      child: const Text('Xử lý ngay', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                if (device.showFixNow && device.showTestButton)
                  const SizedBox(width: 8),
                if (device.showTestButton)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        service.testDevice(device.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Thử máy ${device.name}')),
                        );
                      },
                      child: const Text('Thử máy', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                if (device.hasNoError && device.type == IotDeviceType.drumFilter)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.check_circle,
                        color: DashboardColors.healthy, size: 18),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 9,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detail, schedule, stats, alerts ────────────────────────────────────────

class IotDeviceDetailPanel extends StatelessWidget {
  const IotDeviceDetailPanel({
    super.key,
    required this.device,
    required this.service,
  });

  final IotDevice device;
  final IotDeviceService service;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Chi tiết thiết bị',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Text(
            device.name,
            style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            device.typeLabel,
            style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _row('ID', device.meta.deviceCode),
          _row('Firmware', device.meta.firmware),
          _row('IP', device.meta.ip),
          _row('MQTT', device.meta.mqttStatus),
          _row('Last Seen', device.meta.lastSeen),
          _row('Vị trí', device.location),
          _row('Mode', device.mode.label),
          _row('Công suất', '${device.powerWatts}W'),
          if (device.flowRate != null) _row('Lưu lượng', device.flowRate!),
          if (device.lastRunTime.isNotEmpty)
            _row('Lần chạy gần nhất', device.lastRunTime),
          _row('Số lần hoạt động', '${device.runCount}'),
          const Divider(height: 24),
          Text(
            'Điều khiển',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _DetailControls(device: device, service: service),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                k,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Text(v, style: GoogleFonts.notoSans(fontSize: 12)),
            ),
          ],
        ),
      );
}

class _DetailControls extends StatelessWidget {
  const _DetailControls({required this.device, required this.service});

  final IotDevice device;
  final IotDeviceService service;

  @override
  Widget build(BuildContext context) {
    if (device.connection == IotConnectionStatus.offline) {
      return Text(
        'Thiết bị offline — không thể điều khiển',
        style: GoogleFonts.notoSans(color: DashboardColors.dead, fontSize: 12),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton(
          onPressed: () => service.togglePower(device.id),
          child: Text(device.isOn ? 'OFF' : 'ON'),
        ),
        OutlinedButton(
          onPressed: () => service.setMode(device.id, IotControlMode.auto),
          child: const Text('AUTO'),
        ),
        OutlinedButton(
          onPressed: () => service.setMode(device.id, IotControlMode.manual),
          child: const Text('MANUAL'),
        ),
        if (device.type == IotDeviceType.drumFilter)
          OutlinedButton(
            onPressed: () => service.triggerWash(device.id),
            child: const Text('Rửa ngay'),
          ),
        if (device.type == IotDeviceType.feeder)
          OutlinedButton(
            onPressed: () => service.feedNow(device.id),
            child: const Text('Cho ăn ngay'),
          ),
        if (device.type == IotDeviceType.valve) ...[
          for (final p in [0, 25, 50, 75, 100])
            OutlinedButton(
              onPressed: () => service.setValveOpen(device.id, p),
              child: Text(p == 0 ? 'Đóng' : '$p%'),
            ),
        ],
      ],
    );
  }
}

class IotSchedulePanel extends StatelessWidget {
  const IotSchedulePanel({
    super.key,
    required this.deviceName,
    required this.entries,
    required this.calendarBlocks,
  });

  final String deviceName;
  final List<IotScheduleEntry> entries;
  final List<IotCalendarBlock> calendarBlocks;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Lịch hoạt động — $deviceName',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ...entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(
                    e.time,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.cyan,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(e.action, style: GoogleFonts.notoSans(fontSize: 12)),
                ],
              ),
            ),
          ),
          const Divider(height: 20),
          Text(
            'Calendar View',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...calendarBlocks.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(
                    b.range,
                    style: GoogleFonts.notoSans(fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    b.label,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 11,
                    ),
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

class IotStatsPanel extends StatelessWidget {
  const IotStatsPanel({super.key, required this.stats});

  final IotDeviceStats stats;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Thống kê thiết bị',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _r('Tổng thời gian chạy', '${stats.totalRuntimeHours} giờ'),
          _r('Điện năng', '${stats.totalEnergyKwh} kWh'),
          _r('Số lần ON', '${stats.powerOnCount}'),
          _r('Số lần lỗi', '${stats.errorCount}'),
          _r('Hiệu suất', '${stats.efficiencyPercent}%'),
        ],
      ),
    );
  }

  Widget _r(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                k,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
            Text(v, style: GoogleFonts.notoSans(fontSize: 12)),
          ],
        ),
      );
}

class IotSystemAlertsPanel extends StatelessWidget {
  const IotSystemAlertsPanel({super.key, required this.alerts});

  final List<IotDeviceAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Hệ thống cảnh báo',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 10),
          ...alerts.map((a) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: a.severity.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      a.message,
                      style: GoogleFonts.notoSans(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class IotActivityLogTable extends StatelessWidget {
  const IotActivityLogTable({super.key, required this.logs});

  final List<IotActivityLog> logs;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Nhật ký hoạt động',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('Xem tất cả')),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 36,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 48,
              headingTextStyle: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              dataTextStyle: GoogleFonts.notoSans(fontSize: 11),
              columns: const [
                DataColumn(label: Text('Thời gian')),
                DataColumn(label: Text('Thiết bị')),
                DataColumn(label: Text('Hành động')),
                DataColumn(label: Text('Trạng thái')),
              ],
              rows: logs.map((log) {
                return DataRow(
                  cells: [
                    DataCell(Text(log.time)),
                    DataCell(Text(log.deviceName)),
                    DataCell(Text(log.action)),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (log.success
                                  ? DashboardColors.healthy
                                  : DashboardColors.risk)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          log.success ? 'Hoàn tất' : 'Thất bại',
                          style: TextStyle(
                            color: log.success
                                ? DashboardColors.healthy
                                : DashboardColors.risk,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Right column ───────────────────────────────────────────────────────────

class IotAssistantPanel extends StatelessWidget {
  const IotAssistantPanel({
    super.key,
    required this.insight,
    required this.recommendation,
  });

  final String insight;
  final String recommendation;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AiAssistantHeader(
            title: 'Trợ lý Cua AI',
            subtitle: 'Trực tuyến — AI Core v2.4',
            avatarSize: 44,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DashboardColors.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: DashboardColors.purple.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              insight,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Khuyến nghị',
            style: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DashboardColors.darkNavy.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline,
                    color: DashboardColors.cyan, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.cyan,
                      fontSize: 12,
                    ),
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

class IotAutomationPanel extends StatelessWidget {
  const IotAutomationPanel({super.key, required this.service});

  final IotDeviceService service;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Tự động hóa',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                color: DashboardColors.textMuted,
              ),
            ],
          ),
          ...service.rules.map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule.title,
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          rule.description,
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: rule.enabled,
                    onChanged: (_) => service.toggleRule(rule.id),
                    activeTrackColor: DashboardColors.purple.withValues(alpha: 0.5),
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

class IotCoreHealthPanel extends StatelessWidget {
  const IotCoreHealthPanel({
    super.key,
    required this.cpuPercent,
    required this.zigbeePercent,
  });

  final int cpuPercent;
  final int zigbeePercent;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'HỆ THỐNG CỐT LÕI',
            style: GoogleFonts.notoSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: DashboardColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          _bar('CPU Load', cpuPercent, DashboardColors.purple),
          const SizedBox(height: 12),
          _bar(
            'Sóng Zigbee',
            zigbeePercent,
            DashboardColors.healthy,
            subtitle: 'Mạnh ($zigbeePercent%)',
          ),
        ],
      ),
    );
  }

  Widget _bar(String label, int percent, Color color, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: GoogleFonts.notoSans(fontSize: 12)),
            const Spacer(),
            Text(
              subtitle ?? '$percent%',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 6,
            backgroundColor: DashboardColors.cardBorder,
            color: color,
          ),
        ),
      ],
    );
  }
}

class IotEmergencyStopButton extends StatelessWidget {
  const IotEmergencyStopButton({super.key, required this.service});

  final IotDeviceService service;

  @override
  Widget build(BuildContext context) {
    if (service.emergencyStop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DashboardColors.risk.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DashboardColors.risk),
            ),
            child: Text(
              'EMERGENCY STOP — Tất cả thiết bị đã dừng',
              style: GoogleFonts.notoSans(
                color: DashboardColors.risk,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: service.resetEmergency,
            child: const Text('Khôi phục điều khiển'),
          ),
        ],
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        onPressed: () {
          service.emergencyStopAll();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('EMERGENCY STOP đã kích hoạt')),
          );
        },
        style: FilledButton.styleFrom(
          backgroundColor: DashboardColors.risk,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        icon: const Icon(Icons.close, size: 18),
        label: const Text('EMERGENCY STOP'),
      ),
    );
  }
}

class IotStatusLegend extends StatelessWidget {
  const IotStatusLegend({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      (DashboardColors.healthy, 'Online'),
      (DashboardColors.blue, 'Đang chạy'),
      (DashboardColors.dead, 'Đang dừng'),
      (DashboardColors.monitoring, 'Bảo trì'),
      (DashboardColors.molting, 'Cảnh báo'),
      (DashboardColors.risk, 'Lỗi'),
      (Color(0xFF475569), 'Offline'),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: items.map((e) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: e.$1, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                e.$2,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
