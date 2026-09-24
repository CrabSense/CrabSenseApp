import 'package:flutter/material.dart';

import '../../../models/area_environment_metric.dart';
import '../../../models/box_alert.dart';
import '../../../models/camera_device.dart';
import '../../../models/production_models.dart';
import '../../../services/crab_profile_service.dart';
import '../../../theme/dashboard_theme.dart';
import '../../crab/crab_auth_image.dart';
import '../../crab/crab_overview_cards.dart';
import '../../shared/mgmt_ui.dart';
import 'box_labels.dart';

class BoxActivityItem {
  const BoxActivityItem({
    required this.at,
    required this.title,
    required this.detail,
    required this.source,
  });

  final DateTime at;
  final String title;
  final String detail;
  final String source;
}

class BoxOverviewTab extends StatelessWidget {
  const BoxOverviewTab({
    super.key,
    required this.box,
    required this.areaName,
    required this.rowLabel,
    required this.crab,
    required this.crabLoading,
    required this.token,
    required this.controllerStatus,
    required this.sensorStatus,
    required this.camera,
    required this.cameraLoading,
    required this.metrics,
    required this.envLoading,
    required this.envError,
    required this.envUpdatedAt,
    required this.sensorSourceCode,
    required this.sensorSourceNote,
    required this.alerts,
    required this.alertsLoading,
    required this.activities,
    required this.activitiesLoading,
    this.onOpenCrab,
    this.onOpenCrabGrowth,
    this.onAddCrab,
    this.onManageLots,
    this.onOpenCamera,
    this.onOpenSensors,
    this.onOpenAlerts,
    this.onOpenHistory,
  });

  final BoxRecord box;
  final String areaName;
  final String rowLabel;
  final CrabProfileData? crab;
  final bool crabLoading;
  final String token;
  final String controllerStatus;
  final String sensorStatus;
  final CameraDevice? camera;
  final bool cameraLoading;
  final List<AreaEnvironmentMetric> metrics;
  final bool envLoading;
  final String? envError;
  final DateTime? envUpdatedAt;
  final String? sensorSourceCode;
  final String sensorSourceNote;
  final List<BoxAlert> alerts;
  final bool alertsLoading;
  final List<BoxActivityItem> activities;
  final bool activitiesLoading;
  final VoidCallback? onOpenCrab;
  final VoidCallback? onOpenCrabGrowth;
  final VoidCallback? onAddCrab;
  final VoidCallback? onManageLots;
  final VoidCallback? onOpenCamera;
  final VoidCallback? onOpenSensors;
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final desktop = w >= 1100;
        final tablet = w >= 760;
        final crabCard = CurrentCrabCard(
          box: box,
          crab: crab,
          loading: crabLoading,
          token: token,
          onOpenCrab: onOpenCrab,
          onOpenGrowth: onOpenCrabGrowth,
          onAddCrab: onAddCrab,
          onManageLots: onManageLots,
        );
        final statusCard = BoxStatusCard(
          box: box,
          crabCode: crab?.crabCode,
          controllerStatus: controllerStatus,
          sensorStatus: sensorStatus,
          cameraStatus: camera == null ? 'offline' : (camera!.isOnline ? 'online' : 'offline'),
          updatedAt: envUpdatedAt ?? box.aiUpdatedAt,
        );
        final cameraCard = BoxCameraPreview(
          camera: camera,
          loading: cameraLoading,
          alerts: alerts,
          onOpen: onOpenCamera,
        );
        final envCard = EnvironmentRealtimeCard(
          metrics: metrics,
          loading: envLoading,
          error: envError,
          updatedAt: envUpdatedAt,
          sourceCode: sensorSourceCode,
          sourceNote: sensorSourceNote,
          onOpen: onOpenSensors,
        );
        final alertCard = RecentAlertsCard(
          alerts: alerts,
          loading: alertsLoading,
          onOpenAll: onOpenAlerts,
        );
        final activityCard = RecentActivityCard(
          items: activities,
          loading: activitiesLoading,
          onOpenAll: onOpenHistory,
        );

        if (desktop) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 40, child: crabCard),
                  const SizedBox(width: 12),
                  Expanded(flex: 25, child: statusCard),
                  const SizedBox(width: 12),
                  Expanded(flex: 35, child: cameraCard),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 65, child: envCard),
                  const SizedBox(width: 12),
                  Expanded(flex: 35, child: alertCard),
                ],
              ),
              const SizedBox(height: 12),
              activityCard,
            ],
          );
        }
        if (tablet) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: crabCard),
                  const SizedBox(width: 12),
                  Expanded(child: statusCard),
                ],
              ),
              const SizedBox(height: 12),
              cameraCard,
              const SizedBox(height: 12),
              envCard,
              const SizedBox(height: 12),
              alertCard,
              const SizedBox(height: 12),
              activityCard,
            ],
          );
        }
        return Column(
          children: [
            crabCard,
            const SizedBox(height: 12),
            statusCard,
            const SizedBox(height: 12),
            cameraCard,
            const SizedBox(height: 12),
            envCard,
            const SizedBox(height: 12),
            alertCard,
            const SizedBox(height: 12),
            activityCard,
          ],
        );
      },
    );
  }
}

class CurrentCrabCard extends StatelessWidget {
  const CurrentCrabCard({
    super.key,
    required this.box,
    required this.crab,
    required this.loading,
    required this.token,
    this.onOpenCrab,
    this.onOpenGrowth,
    this.onAddCrab,
    this.onManageLots,
  });

  final BoxRecord box;
  final CrabProfileData? crab;
  final bool loading;
  final String token;
  final VoidCallback? onOpenCrab;
  final VoidCallback? onOpenGrowth;
  final VoidCallback? onAddCrab;
  final VoidCallback? onManageLots;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return OverviewCard(
        icon: Icons.set_meal_outlined,
        title: 'Cua trong hộp',
        child: Container(height: 140, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(12))),
      );
    }
    final c = crab;
    if (c == null) {
      return OverviewCard(
        icon: Icons.set_meal_outlined,
        title: 'Cua trong hộp',
        child: Column(
          children: [
            const SizedBox(height: 8),
            Icon(Icons.inventory_2_outlined, size: 36, color: DashboardColors.textMuted),
            const SizedBox(height: 8),
            Text('Hộp hiện đang trống', style: bvText(fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Chưa có cua được phân vào ${box.boxCode}.', textAlign: TextAlign.center, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                MgmtPrimaryButton(icon: Icons.add_rounded, label: 'Thêm cua', height: 36, onTap: onAddCrab),
                MgmtOutlineButton(label: 'Chọn từ lô nhập', onTap: onManageLots, height: 36),
              ],
            ),
          ],
        ),
      );
    }

    return OverviewCard(
      icon: Icons.set_meal_outlined,
      title: 'Cua trong hộp',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: c.id == null
                      ? Container(color: DashboardColors.lightMint, child: const Icon(Icons.set_meal_outlined, color: DashboardColors.brand))
                      : CrabAuthImage(
                          crabId: c.id!,
                          index: 0,
                          token: token,
                          fallbackUrl: c.imageUrls.isEmpty ? null : c.imageUrls.first,
                          error: Container(color: DashboardColors.lightMint, child: const Icon(Icons.set_meal_outlined, color: DashboardColors.brand)),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(c.crabCode, style: bvText(fontSize: 16, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
                        MgmtStatusBadge(label: c.statusLabel, color: DashboardColors.brand),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${c.typeLabel}  •  ${c.genderLabel}', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _kv('Cân nặng', c.weight == null || c.weight == 0 ? '—' : '${c.weight!.toStringAsFixed(0)} g'),
              _kv('Rộng mai', c.shellWidth == null || c.shellWidth == 0 ? '—' : '${c.shellWidth!.toStringAsFixed(0)} mm'),
              _kv('Dài mai', c.shellLength == null || c.shellLength == 0 ? '—' : '${c.shellLength!.toStringAsFixed(0)} mm'),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _dot('Sức khỏe', c.healthStatusLabel, DashboardColors.brand),
              _dot('Giai đoạn', c.growthStageLabel, DashboardColors.brandGreen),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            children: [
              OverviewLinkButton(label: 'Xem chi tiết cua', onTap: onOpenCrab),
              OverviewLinkButton(label: 'Lịch sử sinh trưởng', onTap: onOpenGrowth),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
          Text(v, style: bvText(fontSize: 14, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
        ],
      );

  Widget _dot(String k, String v, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$k  ', style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(v, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
        ],
      );
}

class BoxStatusCard extends StatelessWidget {
  const BoxStatusCard({
    super.key,
    required this.box,
    required this.controllerStatus,
    required this.sensorStatus,
    required this.cameraStatus,
    this.crabCode,
    this.updatedAt,
  });

  final BoxRecord box;
  final String? crabCode;
  final String controllerStatus;
  final String sensorStatus;
  final String cameraStatus;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    return OverviewCard(
      icon: Icons.analytics_outlined,
      title: 'Trạng thái hộp',
      child: Column(
        children: [
          _row('Trạng thái', boxOperationalLabel(box.status), color: boxOperationalColor(box.status)),
          _device('Controller', controllerStatus),
          _device('Cảm biến', sensorStatus),
          _device('Camera AI', cameraStatus),
          _row('Cua hiện tại', (crabCode ?? '').isEmpty ? 'Không có' : crabCode!),
          _row('Sức chứa', box.hasCrab ? '1 / 1 cua' : '0 / 1 cua'),
          _row('Cảnh báo', '${box.alertCount}'),
          _row('Cập nhật cuối', fmtDateTimeVn(updatedAt)),
        ],
      ),
    );
  }

  Widget _device(String k, String status) {
    final color = deviceStatusColor(status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(k, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))),
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(deviceStatusLabel(status), style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _row(String k, String v, {Color? color}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(child: Text(k, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted))),
            if (color != null) ...[
              Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
            ],
            Text(v, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
          ],
        ),
      );
}

class BoxCameraPreview extends StatelessWidget {
  const BoxCameraPreview({
    super.key,
    required this.camera,
    required this.loading,
    required this.alerts,
    this.onOpen,
  });

  final CameraDevice? camera;
  final bool loading;
  final List<BoxAlert> alerts;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return OverviewCard(
        icon: Icons.videocam_outlined,
        title: 'Camera AI',
        child: Container(height: 150, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(12))),
      );
    }
    final cam = camera;
    if (cam == null) {
      return OverviewCard(
        icon: Icons.videocam_outlined,
        title: 'Camera AI',
        child: Column(
          children: [
            Text('Camera không khả dụng.', style: bvText(color: DashboardColors.textMuted)),
            OverviewLinkButton(label: 'Xem Camera AI', onTap: onOpen),
          ],
        ),
      );
    }

    final online = cam.isOnline;
    final aiAlert = alerts.where((a) {
      final m = a.message.toLowerCase();
      return m.contains('ai') || m.contains('hành vi') || m.contains('bất thường');
    }).firstOrNull;
    final stamp = cam.lastSeenAt;

    return OverviewCard(
      icon: Icons.videocam_outlined,
      title: 'Camera AI',
      trailing: MgmtStatusBadge(
        label: online ? 'Trực tuyến' : 'Mất kết nối',
        color: online ? DashboardColors.brand : const Color(0xFFEF4444),
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
              child: online
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        const ColoredBox(color: Color(0xFF1A3D36)),
                        Center(child: Icon(Icons.videocam_outlined, size: 36, color: Colors.white.withValues(alpha: 0.7))),
                        if (stamp != null)
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: Text(fmtDateTimeVn(stamp), style: bvText(fontSize: 11, color: Colors.white)),
                          ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 32),
                        const SizedBox(height: 6),
                        Text('Camera không khả dụng.', style: bvText(fontSize: 12.5, color: Colors.white70)),
                        if (stamp != null)
                          Text('Cập nhật cuối: ${fmtDateTimeVn(stamp)}', style: bvText(fontSize: 11, color: Colors.white54)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          if (aiAlert != null) ...[
            Text('Phát hiện hành vi bất thường', style: bvText(fontWeight: FontWeight.w800, color: const Color(0xFFEF4444))),
            const SizedBox(height: 2),
            Text(aiAlert.message, style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary)),
            Text('Phát hiện: ${aiAlert.time}', style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
            OverviewLinkButton(label: 'Xem chi tiết', onTap: onOpen),
          ] else if (online) ...[
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 16, color: DashboardColors.brand),
                const SizedBox(width: 6),
                Text('Không phát hiện bất thường', style: bvText(fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
              ],
            ),
            if (stamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Phát hiện cuối: ${fmtDateTimeVn(stamp)}', style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
              ),
            OverviewLinkButton(label: 'Xem Camera AI', onTap: onOpen),
          ] else
            OverviewLinkButton(label: 'Kiểm tra camera', onTap: onOpen),
        ],
      ),
    );
  }
}

class EnvironmentRealtimeCard extends StatelessWidget {
  const EnvironmentRealtimeCard({
    super.key,
    required this.metrics,
    required this.loading,
    required this.sourceNote,
    this.error,
    this.updatedAt,
    this.sourceCode,
    this.onOpen,
  });

  final List<AreaEnvironmentMetric> metrics;
  final bool loading;
  final String? error;
  final DateTime? updatedAt;
  final String? sourceCode;
  final String sourceNote;
  final VoidCallback? onOpen;

  AreaEnvironmentMetric? _pick(bool Function(AreaEnvironmentMetric) test) {
    for (final m in metrics) {
      if (test(m)) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ph = _pick((m) => (m.sensorType ?? m.label).toLowerCase().contains('ph'));
    final sal = _pick((m) => (m.sensorType ?? m.label).toLowerCase().contains('salin'));
    final tds = _pick((m) => (m.sensorType ?? m.label).toLowerCase().contains('tds'));
    final temp = _pick((m) {
      final t = (m.sensorType ?? m.label).toLowerCase();
      return t.contains('temp') || t.contains('nhiệt');
    });
    final dox = _pick((m) {
      final t = (m.sensorType ?? m.label).toLowerCase();
      return t == 'do' || t.contains('oxygen') || t.contains('oxy');
    });

    return OverviewCard(
      icon: Icons.sensors_outlined,
      title: 'Môi trường realtime',
      trailing: OverviewLinkButton(label: 'Xem chi tiết', onTap: onOpen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (loading)
            Row(children: [for (var i = 0; i < 4; i++) Expanded(child: Padding(padding: EdgeInsets.only(right: i == 3 ? 0 : 8), child: Container(height: 88, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(12)))))])
          else if (error != null && metrics.isEmpty)
            Text(error!, style: bvText(color: const Color(0xFFEF4444)))
          else if (metrics.isEmpty)
            Text('Chưa có dữ liệu cảm biến.', style: bvText(color: DashboardColors.textMuted))
          else
            LayoutBuilder(
              builder: (context, c) {
                final tiles = <Widget>[
                  EnvironmentMetricCard(label: 'pH', metric: ph, format: (v) => fmtPh(sanitizePh(v) ?? v), unit: ''),
                  if (sal != null)
                    EnvironmentMetricCard(label: 'Độ mặn', metric: sal, format: fmtSalinity, unit: 'ppt')
                  else
                    EnvironmentMetricCard(label: 'TDS', metric: tds, format: fmtTds, unit: 'ppm'),
                  EnvironmentMetricCard(label: 'Nhiệt độ', metric: temp, format: fmtTemp, unit: '°C'),
                  EnvironmentMetricCard(label: 'DO', metric: dox, format: fmtDo, unit: 'mg/L'),
                ];
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in tiles)
                      SizedBox(width: (c.maxWidth - 24) / 4 < 120 ? (c.maxWidth - 8) / 2 : (c.maxWidth - 24) / 4, child: t),
                  ],
                );
              },
            ),
          const SizedBox(height: 10),
          if (sourceCode != null && sourceCode!.trim().isNotEmpty)
            Text('Nguồn dữ liệu: $sourceCode', style: bvText(fontSize: 12, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
          Text(sourceNote, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
          if (updatedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                isSensorStale(updatedAt) ? 'Dữ liệu đã cũ — không cập nhật trong 5 phút.' : relativeAgo(updatedAt),
                style: bvText(fontSize: 11.5, color: isSensorStale(updatedAt) ? const Color(0xFFF5B700) : DashboardColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class EnvironmentMetricCard extends StatelessWidget {
  const EnvironmentMetricCard({
    super.key,
    required this.label,
    required this.metric,
    required this.format,
    required this.unit,
  });

  final String label;
  final AreaEnvironmentMetric? metric;
  final String Function(double value) format;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final m = metric;
    final missing = m == null || m.value == 0 && m.recordedAt == null;
    final status = missing ? 'no_data' : m.status;
    final color = sensorSemanticColor(status);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            missing ? 'Chưa có dữ liệu.' : '${format(m.value)}${unit.isEmpty ? '' : ' $unit'}',
            style: bvText(fontSize: missing ? 12 : 18, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: sensorSemanticFill(status), borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(sensorSemanticLabel(status), style: bvText(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
          ),
          if (!missing && m.recordedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(formatTime(m.recordedAt!), style: bvText(fontSize: 10.5, color: DashboardColors.textMuted)),
            ),
        ],
      ),
    );
  }

  String formatTime(DateTime at) {
    final l = at.isUtc ? at.toLocal() : at;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(l.hour)}:${two(l.minute)}';
  }
}

class RecentAlertsCard extends StatelessWidget {
  const RecentAlertsCard({
    super.key,
    required this.alerts,
    required this.loading,
    this.onOpenAll,
  });

  final List<BoxAlert> alerts;
  final bool loading;
  final VoidCallback? onOpenAll;

  @override
  Widget build(BuildContext context) {
    return OverviewCard(
      icon: Icons.notifications_none_rounded,
      title: 'Cảnh báo gần đây',
      trailing: OverviewLinkButton(label: 'Xem tất cả', onTap: onOpenAll),
      child: loading
          ? Column(children: [for (var i = 0; i < 3; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(height: 36, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(8))))])
          : alerts.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.check_circle_rounded, size: 16, color: DashboardColors.brand),
                      const SizedBox(width: 6),
                      Text('Không có cảnh báo gần đây', style: bvText(fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
                    ]),
                    const SizedBox(height: 4),
                    Text('Hộp đang hoạt động bình thường.', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
                  ],
                )
              : Column(
                  children: [
                    for (final a in alerts.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 108, child: Text(a.time, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted))),
                            Expanded(child: Text(a.message, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary))),
                            MgmtStatusBadge(
                              label: a.statusLabel,
                              color: a.statusLabel == 'Đang mở' ? const Color(0xFFEF4444) : DashboardColors.brand,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    super.key,
    required this.items,
    required this.loading,
    this.onOpenAll,
  });

  final List<BoxActivityItem> items;
  final bool loading;
  final VoidCallback? onOpenAll;

  @override
  Widget build(BuildContext context) {
    return OverviewCard(
      icon: Icons.history_rounded,
      title: 'Hoạt động gần đây',
      trailing: OverviewLinkButton(label: 'Xem tất cả', onTap: onOpenAll),
      child: loading
          ? Column(children: [for (var i = 0; i < 3; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(height: 44, decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(8))))])
          : items.isEmpty
              ? Text('Chưa có hoạt động gần đây.', style: bvText(color: DashboardColors.textMuted))
              : Column(
                  children: [
                    for (final e in items.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 124, child: Text(fmtDateTimeVn(e.at), style: bvText(fontSize: 11.5, color: DashboardColors.textMuted))),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.title, style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
                                  if (e.detail.isNotEmpty)
                                    Text(e.detail, style: bvText(fontSize: 12, height: 1.35, color: DashboardColors.textMuted)),
                                ],
                              ),
                            ),
                            Text(e.source, style: bvText(fontSize: 11.5, fontWeight: FontWeight.w600, color: DashboardColors.textMuted)),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}
