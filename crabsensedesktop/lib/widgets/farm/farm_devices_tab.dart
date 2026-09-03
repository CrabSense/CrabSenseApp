import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/device_summary.dart';
import '../../models/device_status.dart';
import '../../models/farm_device.dart';
import '../../models/iot_device.dart';
import '../../services/area_management_service.dart';
import '../../services/iot_device_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../utils/farm_device_mapper.dart';
import '../dashboard/glass_card.dart';
import '../shared/accent_strip_container.dart';
import 'farm_device_dialogs.dart';

class FarmDevicesTab extends StatefulWidget {
  const FarmDevicesTab({
    super.key,
    required this.deviceService,
    required this.areaService,
  });

  final IoTDeviceService deviceService;
  final AreaManagementService areaService;

  @override
  State<FarmDevicesTab> createState() => _FarmDevicesTabState();
}

class _FarmDevicesTabState extends State<FarmDevicesTab> {
  static const _pageSize = 8;

  int _page = 1;
  DeviceFilterResult _filter = const DeviceFilterResult();

  @override
  void initState() {
    super.initState();
    widget.deviceService.addListener(_onServiceUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.deviceService.loadDevices();
      if (widget.areaService.areas.isEmpty) {
        widget.areaService.load();
      }
    });
  }

  @override
  void dispose() {
    widget.deviceService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  List<FarmDevice> get _allDevices =>
      widget.deviceService.devices.map(toFarmDevice).toList();

  List<FarmDevice> get _filtered {
    return _allDevices.where((d) {
      if (_filter.status != null && d.status != _filter.status) return false;
      if (_filter.search.isNotEmpty) {
        final q = _filter.search.toLowerCase();
        final haystack =
            '${d.id} ${d.name} ${d.typeLabel} ${d.location}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  List<FarmDevice> get _pageItems {
    final list = _filtered;
    final start = (_page - 1) * _pageSize;
    if (start >= list.length) return [];
    final end = (start + _pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  int get _totalPages =>
      (_filtered.length / _pageSize).ceil().clamp(1, 999);

  String _apiStatus(DeviceStatus status) => switch (status) {
        DeviceStatus.online => 'online',
        DeviceStatus.maintenance => 'maintenance',
        DeviceStatus.offline => 'offline',
      };

  Future<void> _openAddDevice() async {
    if (widget.areaService.areas.isEmpty) {
      await widget.areaService.load();
    }
    final suggested = await widget.deviceService.getNextDeviceCode();
    final draft = await showAddDeviceDialog(
      context,
      suggestedId: suggested ?? 'ESP001',
      areas: widget.areaService.areas,
    );
    if (draft == null || !mounted) return;

    final created = await widget.deviceService.createDevice(
      UpsertDeviceRequest(
        deviceCode: draft.id,
        deviceName: draft.name,
        areaId: draft.areaId,
        status: _apiStatus(draft.status),
      ),
    );
    if (!mounted) return;
    if (created != null) {
      setState(() => _page = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm thiết bị ${created.deviceCode}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.deviceService.error ?? 'Không thể thêm thiết bị',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openFilter() async {
    final result = await showDeviceFilterSheet(context, current: _filter);
    if (result == null || !mounted) return;
    setState(() {
      _filter = result;
      _page = 1;
    });
  }

  Future<void> _exportCsv() async {
    await showExportDevicesDialog(context, _filtered);
  }

  Future<void> _openSettings(FarmDevice device) async {
    if (device.apiId.isEmpty) return;
    if (widget.areaService.areas.isEmpty) {
      await widget.areaService.load();
    }
    final updated = await showDeviceSettingsDialog(
      context,
      device,
      areas: widget.areaService.areas,
    );
    if (updated == null || !mounted) return;

    final saved = await widget.deviceService.updateDevice(
      device.apiId,
      UpsertDeviceRequest(
        deviceCode: updated.id,
        deviceName: updated.name,
        areaId: updated.areaId,
        status: _apiStatus(updated.status),
      ),
    );
    if (!mounted) return;
    if (saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật ${saved.deviceCode}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.deviceService.error ?? 'Không thể cập nhật thiết bị',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _syncDevice(FarmDevice device) async {
    await widget.deviceService.loadDevices();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã làm mới danh sách — ${device.id}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.deviceService;
    final summary = DeviceAreaSummary.fromDevices(_allDevices);
    final filtered = _filtered;
    final farmName = svc.selectedFarmName;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Breadcrumb(farmName: farmName),
              const SizedBox(height: 8),
              Text(
                'Quản lý thiết bị khu vực',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$farmName — thiết bị IoT từ máy chủ (${_allDevices.length} thiết bị)',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 14,
                ),
              ),
              if (svc.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  svc.error!,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.risk,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _DeviceKpiRow(summary: summary),
              const SizedBox(height: 24),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Danh sách thiết bị chi tiết',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (svc.loading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: DashboardColors.cyan,
                            ),
                          )
                        else
                          IconButton(
                            tooltip: 'Làm mới',
                            onPressed: () => svc.loadDevices(),
                            icon: const Icon(
                              Icons.refresh,
                              color: DashboardColors.cyan,
                            ),
                          ),
                        const SizedBox(width: 4),
                        OutlinedButton.icon(
                          onPressed: _openFilter,
                          icon: Icon(
                            Icons.filter_list,
                            size: 16,
                            color: _filter.hasActiveFilter
                                ? DashboardColors.cyan
                                : null,
                          ),
                          label: Text(
                            _filter.hasActiveFilter ? 'Bộ lọc (*)' : 'Bộ lọc',
                          ),
                          style: _outlineStyle,
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _exportCsv,
                          icon: const Icon(Icons.download_outlined, size: 16),
                          label: const Text('Xuất CSV'),
                          style: _outlineStyle,
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: svc.loading ? null : _openAddDevice,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Thêm thiết bị'),
                          style: FilledButton.styleFrom(
                            backgroundColor: DashboardColors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (svc.loading && _allDevices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: DashboardColors.cyan,
                          ),
                        ),
                      )
                    else if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            svc.error != null
                                ? 'Không tải được thiết bị — bấm làm mới'
                                : 'Không có thiết bị phù hợp bộ lọc',
                            style: GoogleFonts.notoSans(
                              color: DashboardColors.textMuted,
                            ),
                          ),
                        ),
                      )
                    else
                      _DeviceTable(
                        devices: _pageItems,
                        onSync: _syncDevice,
                        onSettings: _openSettings,
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Hiển thị ${_pageItems.length} / ${filtered.length} thiết bị'
                          '${_filter.hasActiveFilter ? ' (đã lọc)' : ''}',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        _Pagination(
                          current: _page,
                          total: _totalPages,
                          onPage: (p) => setState(() => _page = p),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        Positioned(
          right: 32,
          bottom: 32,
          child: FloatingActionButton(
            onPressed: svc.loading ? null : _openAddDevice,
            backgroundColor: DashboardColors.purple,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  static final _outlineStyle = OutlinedButton.styleFrom(
    foregroundColor: DashboardColors.textMuted,
    side: BorderSide(color: DashboardColors.cardBorder),
  );
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.farmName});

  final String farmName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          farmName,
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 13),
        ),
        Text('  >  ', style: GoogleFonts.notoSans(color: DashboardColors.textMuted)),
        Text(
          'Thiết bị trại',
          style: GoogleFonts.notoSans(color: DashboardColors.cyan, fontSize: 13),
        ),
      ],
    );
  }
}

class _DeviceKpiRow extends StatelessWidget {
  const _DeviceKpiRow({required this.summary});

  final DeviceAreaSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 1200 ? 4 : c.maxWidth > 700 ? 2 : 1;
        final spacing = 12.0;
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: w,
              child: _KpiCard(
                label: 'Tổng thiết bị',
                value: '${summary.total}',
                subtext: 'Theo trại đang chọn',
                subColor: DashboardColors.healthy,
                accent: DashboardColors.purple,
              ),
            ),
            SizedBox(
              width: w,
              child: _KpiCard(
                label: 'Đang hoạt động',
                value: '${summary.active}',
                subtext: '${summary.activePercent}%',
                progress: summary.activePercent / 100,
                progressColor: DashboardColors.cyan,
                accent: DashboardColors.cyan,
              ),
            ),
            SizedBox(
              width: w,
              child: _KpiCard(
                label: 'Cần bảo trì',
                value: '${summary.maintenance}',
                subtext: 'Khẩn cấp: ${summary.emergencyMaintenance}',
                subColor: DashboardColors.molting,
                accent: DashboardColors.molting,
                leftBorder: true,
              ),
            ),
            SizedBox(
              width: w,
              child: _KpiCard(
                label: 'Hiệu suất kết nối',
                value: '${summary.connectionPercent}%',
                subtext: '${summary.offline} không kết nối',
                progress: summary.connectionPercent / 100,
                progressColor: DashboardColors.blue,
                accent: DashboardColors.blue,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.subtext,
    required this.accent,
    this.subColor,
    this.progress,
    this.progressColor,
    this.leftBorder = false,
  });

  final String label;
  final String value;
  final String subtext;
  final Color accent;
  final Color? subColor;
  final double? progress;
  final Color? progressColor;
  final bool leftBorder;

  @override
  Widget build(BuildContext context) {
    return AccentStripContainer(
      accentColor: leftBorder ? accent : null,
      padding: const EdgeInsets.all(16),
      backgroundColor: DashboardColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.notoSans(
              color: accent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSans(
              color: subColor ?? DashboardColors.textMuted,
              fontSize: 11,
              height: 1.2,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: DashboardColors.cardBorder,
                valueColor: AlwaysStoppedAnimation(progressColor ?? accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeviceTable extends StatelessWidget {
  const _DeviceTable({
    required this.devices,
    required this.onSync,
    required this.onSettings,
  });

  final List<FarmDevice> devices;
  final ValueChanged<FarmDevice> onSync;
  final ValueChanged<FarmDevice> onSettings;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 44,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 88,
        columnSpacing: 28,
        headingTextStyle: GoogleFonts.notoSans(
          color: DashboardColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
        columns: const [
          DataColumn(label: Text('MÃ THIẾT BỊ')),
          DataColumn(label: Text('TÊN / LOẠI')),
          DataColumn(label: Text('KHU GẮN')),
          DataColumn(label: Text('TRẠNG THÁI')),
          DataColumn(label: Text('LẦN CUỐI ĐỒNG BỘ')),
          DataColumn(label: Text('THAO TÁC')),
        ],
        rows: devices.map((d) => _row(context, d)).toList(),
      ),
    );
  }

  Widget _tableIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: DashboardColors.textMuted),
      ),
    );
  }

  DataRow _row(BuildContext context, FarmDevice d) {
    return DataRow(
      cells: [
        DataCell(Text(d.id, style: GoogleFonts.notoSans(color: DashboardColors.cyan))),
        DataCell(
          Row(
            children: [
              Icon(d.icon, size: 16, color: DashboardColors.textMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      d.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSans(
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      d.typeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 9,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(d.location)),
        DataCell(_StatusDot(status: d.status)),
        DataCell(Text(d.lastSync)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tableIcon(Icons.sync, () => onSync(d)),
              _tableIcon(Icons.settings_outlined, () => onSettings(d)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: status.color),
        const SizedBox(width: 6),
        Text(
          status.label,
          style: GoogleFonts.notoSans(
            color: status.color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.current,
    required this.total,
    required this.onPage,
  });

  final int current;
  final int total;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: current > 1 ? () => onPage(current - 1) : null,
          icon: const Icon(Icons.chevron_left),
          color: DashboardColors.textMuted,
        ),
        Text(
          '$current / $total',
          style: GoogleFonts.notoSans(
            color: DashboardColors.textMuted,
            fontSize: 12,
          ),
        ),
        IconButton(
          onPressed: current < total ? () => onPage(current + 1) : null,
          icon: const Icon(Icons.chevron_right),
          color: DashboardColors.textMuted,
        ),
      ],
    );
  }
}
