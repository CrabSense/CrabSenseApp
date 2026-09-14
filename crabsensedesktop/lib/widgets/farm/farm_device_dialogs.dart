import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/device_status.dart';
import '../../models/farm_device.dart';
import '../../models/production_models.dart';
import '../../theme/dashboard_theme.dart';

const _deviceTypes = [
  ('Cảm biến DO', Icons.air_outlined),
  ('Cảm biến pH', Icons.science_outlined),
  ('Cảm biến nhiệt độ', Icons.thermostat_outlined),
  ('Cảm biến độ mặn', Icons.waves_outlined),
  ('Cảm biến NH3', Icons.warning_amber_outlined),
  ('Máy sục khí', Icons.bubble_chart_outlined),
  ('Máy bơm tuần hoàn', Icons.settings_input_component_outlined),
  ('Máy cho ăn tự động', Icons.restaurant_outlined),
];

List<_AreaPick> _areaPicks(List<AreaRecord> areas) => [
      const _AreaPick(),
      for (final a in areas) _AreaPick(area: a),
    ];

Future<FarmDevice?> showAddDeviceDialog(
  BuildContext context, {
  required String suggestedId,
  required List<AreaRecord> areas,
}) async {
  final formKey = GlobalKey<FormState>();
  final idCtrl = TextEditingController(text: suggestedId);
  final nameCtrl = TextEditingController();
  var typeIndex = 0;
  final areaOptions = _areaPicks(areas);
  var areaPick = areaOptions.first;
  var status = DeviceStatus.online;

  final result = await showDialog<FarmDevice>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: DashboardColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Thêm thiết bị mới',
          style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
        ),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(idCtrl, 'Mã thiết bị *', validator: _required),
                _field(nameCtrl, 'Tên thiết bị *', validator: _required),
                _dropdown<String>(
                  label: 'Loại thiết bị',
                  value: _deviceTypes[typeIndex].$1,
                  items: _deviceTypes.map((e) => e.$1).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setDialogState(() {
                      typeIndex = _deviceTypes.indexWhere((e) => e.$1 == v);
                    });
                  },
                ),
                const SizedBox(height: 10),
                _dropdown<_AreaPick>(
                  label: 'Khu gắn',
                  value: areaPick,
                  items: areaOptions,
                  itemLabel: (p) => p.label,
                  onChanged: (v) {
                    if (v != null) setDialogState(() => areaPick = v);
                  },
                ),
                const SizedBox(height: 10),
                _dropdown<DeviceStatus>(
                  label: 'Trạng thái',
                  value: status,
                  items: DeviceStatus.values,
                  itemLabel: (s) => s.label,
                  onChanged: (v) {
                    if (v != null) setDialogState(() => status = v);
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final type = _deviceTypes[typeIndex];
              final area = areaPick.area;
              Navigator.pop(
                ctx,
                FarmDevice(
                  apiId: '',
                  id: idCtrl.text.trim(),
                  name: nameCtrl.text.trim(),
                  typeLabel: type.$1,
                  location: areaPick.label,
                  status: status,
                  lastSync: 'Vừa xong',
                  icon: type.$2,
                  areaId: area?.id,
                  areaCode: area?.areaCode,
                  areaName: area?.areaName,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: DashboardColors.purple,
            ),
            child: const Text('Thêm thiết bị'),
          ),
        ],
      ),
    ),
  );

  idCtrl.dispose();
  nameCtrl.dispose();
  return result;
}

Future<FarmDevice?> showDeviceSettingsDialog(
  BuildContext context,
  FarmDevice device, {
  required List<AreaRecord> areas,
}) async {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController(text: device.name);
  var typeIndex = _deviceTypes.indexWhere((e) => e.$1 == device.typeLabel);
  if (typeIndex < 0) typeIndex = 0;
  final areaOptions = _areaPicks(areas);
  var areaPick = areaOptions.firstWhere(
    (p) => p.id == device.areaId,
    orElse: () => areaOptions.first,
  );
  var status = device.status;
  var autoSync = true;
  var alertsEnabled = device.status != DeviceStatus.offline;
  var syncMinutes = 5;

  final result = await showDialog<FarmDevice>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: DashboardColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(device.icon, color: DashboardColors.cyan, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cài đặt thiết bị',
                style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _readOnlyField('Mã thiết bị', device.id),
                  _field(nameCtrl, 'Tên thiết bị *', validator: _required),
                  _dropdown<String>(
                    label: 'Loại thiết bị',
                    value: _deviceTypes[typeIndex].$1,
                    items: _deviceTypes.map((e) => e.$1).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() {
                        typeIndex = _deviceTypes.indexWhere((e) => e.$1 == v);
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _dropdown<_AreaPick>(
                    label: 'Khu gắn',
                    value: areaPick,
                    items: areaOptions,
                    itemLabel: (p) => p.label,
                    onChanged: (v) {
                      if (v != null) setDialogState(() => areaPick = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  _dropdown<DeviceStatus>(
                    label: 'Trạng thái',
                    value: status,
                    items: DeviceStatus.values,
                    itemLabel: (s) => s.label,
                    onChanged: (v) {
                      if (v != null) setDialogState(() => status = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'TÙY CHỌN ĐỒNG BỘ',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Tự động đồng bộ',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      autoSync ? 'Mỗi $syncMinutes phút' : 'Tắt',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    value: autoSync,
                    activeThumbColor: DashboardColors.purple,
                    onChanged: (v) => setDialogState(() => autoSync = v),
                  ),
                  if (autoSync)
                    _dropdown<int>(
                      label: 'Chu kỳ đồng bộ',
                      value: syncMinutes,
                      items: const [1, 5, 15, 30],
                      itemLabel: (m) => '$m phút',
                      onChanged: (v) {
                        if (v != null) setDialogState(() => syncMinutes = v);
                      },
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Bật cảnh báo ngưỡng',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      'Gửi thông báo khi vượt ngưỡng cảm biến',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    value: alertsEnabled,
                    activeThumbColor: DashboardColors.purple,
                    onChanged: (v) => setDialogState(() => alertsEnabled = v),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final type = _deviceTypes[typeIndex];
              final area = areaPick.area;
              Navigator.pop(
                ctx,
                FarmDevice(
                  apiId: device.apiId,
                  id: device.id,
                  name: nameCtrl.text.trim(),
                  typeLabel: type.$1,
                  location: areaPick.label,
                  status: status,
                  lastSync: device.lastSync,
                  icon: type.$2,
                  areaId: area?.id,
                  areaCode: area?.areaCode,
                  areaName: area?.areaName,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: DashboardColors.purple,
            ),
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    ),
  );

  nameCtrl.dispose();
  return result;
}

Future<DeviceFilterResult?> showDeviceFilterSheet(
  BuildContext context, {
  required DeviceFilterResult current,
}) {
  return showModalBottomSheet<DeviceFilterResult>(
    context: context,
    backgroundColor: DashboardColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _DeviceFilterSheet(initial: current),
  );
}

class DeviceFilterResult {
  const DeviceFilterResult({this.status, this.search = ''});

  final DeviceStatus? status;
  final String search;

  DeviceFilterResult copyWith({DeviceStatus? status, String? search}) {
    return DeviceFilterResult(
      status: status ?? this.status,
      search: search ?? this.search,
    );
  }

  bool get hasActiveFilter =>
      status != null || search.trim().isNotEmpty;
}

Future<void> showExportDevicesDialog(
  BuildContext context,
  List<FarmDevice> devices,
) async {
  final csv = _buildCsv(devices);
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Xuất CSV thiết bị',
        style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Đã tạo file demo: devices_${_fileDate()}.csv (${devices.length} dòng)',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DashboardColors.darkNavy,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DashboardColors.cardBorder),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  csv,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.cyan,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Đóng'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: csv));
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép CSV vào clipboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Sao chép CSV'),
          style: FilledButton.styleFrom(
            backgroundColor: DashboardColors.purple,
          ),
        ),
      ],
    ),
  );
}

Future<void> showExportHistoryReportDialog(
  BuildContext context, {
  required int eventCount,
  required String timeRange,
  required String eventType,
}) async {
  final report = '''
BÁO CÁO LỊCH SỬ HOẠT ĐỘNG
Khu vực: Khu đang chọn
Thời gian: $timeRange
Loại sự kiện: $eventType
Tổng sự kiện: $eventCount

--- Tóm tắt ---
• Cảnh báo: 12
• Bảo trì: 45
• Cho ăn: 120

--- Phân tích AI ---
Tần suất cảnh báo Oxy tăng 15% so với tuần trước (14h–16h).
Đề xuất: kiểm tra hệ thống sục khí dự phòng khu B.

Xuất lúc: ${DateTime.now()}
''';

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Xuất báo cáo lịch sử',
        style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
      ),
      content: SizedBox(
        width: 480,
        child: SelectableText(
          report,
          style: GoogleFonts.notoSans(
            color: DashboardColors.textMuted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: report));
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép báo cáo vào clipboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Sao chép'),
          style: FilledButton.styleFrom(
            backgroundColor: DashboardColors.purple,
          ),
        ),
      ],
    ),
  );
}

class _DeviceFilterSheet extends StatefulWidget {
  const _DeviceFilterSheet({required this.initial});

  final DeviceFilterResult initial;

  @override
  State<_DeviceFilterSheet> createState() => _DeviceFilterSheetState();
}

class _DeviceFilterSheetState extends State<_DeviceFilterSheet> {
  late DeviceStatus? _status;
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _status = widget.initial.status;
    _searchCtrl = TextEditingController(text: widget.initial.search);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bộ lọc thiết bị',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Trạng thái',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Tất cả'),
                selected: _status == null,
                onSelected: (_) => setState(() => _status = null),
              ),
              for (final s in DeviceStatus.values)
                FilterChip(
                  label: Text(s.label),
                  selected: _status == s,
                  onSelected: (_) => setState(() => _status = s),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Tìm theo mã, tên, vị trí',
              labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted),
              filled: true,
              fillColor: DashboardColors.darkNavy,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      const DeviceFilterResult(),
                    );
                  },
                  child: const Text('Xóa lọc'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      DeviceFilterResult(
                        status: _status,
                        search: _searchCtrl.text.trim(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: DashboardColors.purple,
                  ),
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _buildCsv(List<FarmDevice> devices) {
  final buf = StringBuffer(
    'device_id,name,type,location,status,last_sync\n',
  );
  for (final d in devices) {
    buf.writeln(
      '${d.id},${d.name},${d.typeLabel},${d.location},${d.status.label},${d.lastSync}',
    );
  }
  return buf.toString();
}

String _fileDate() {
  final n = DateTime.now();
  return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
}

String? _required(String? v) =>
    v == null || v.trim().isEmpty ? 'Bắt buộc' : null;

Widget _readOnlyField(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        filled: true,
        fillColor: DashboardColors.darkNavy.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        value,
        style: GoogleFonts.notoSans(
          color: DashboardColors.cyan,
          fontSize: 13,
        ),
      ),
    ),
  );
}

Widget _field(
  TextEditingController ctrl,
  String label, {
  String? Function(String?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: ctrl,
      validator: validator,
      style: GoogleFonts.notoSans(color: DashboardColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        filled: true,
        fillColor: DashboardColors.darkNavy,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}

Widget _dropdown<T>({
  required String label,
  required T value,
  required List<T> items,
  required ValueChanged<T?> onChanged,
  String Function(T)? itemLabel,
}) {
  return DropdownButtonFormField<T>(
    value: value,
    dropdownColor: DashboardColors.card,
    style: GoogleFonts.notoSans(color: DashboardColors.textPrimary, fontSize: 13),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted),
      filled: true,
      fillColor: DashboardColors.darkNavy,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
    items: items
        .map(
          (e) => DropdownMenuItem(
            value: e,
            child: Text(itemLabel != null ? itemLabel(e) : e.toString()),
          ),
        )
        .toList(),
    onChanged: onChanged,
  );
}

class _AreaPick {
  const _AreaPick({this.area});

  final AreaRecord? area;

  String? get id => area?.id;

  String get label => area == null
      ? 'Chưa gắn khu'
      : '${area!.areaCode} — ${area!.areaName}';
}

String generateDeviceId(List<FarmDevice> existing) {
  final year = DateTime.now().year;
  var n = existing.length + 1;
  var id = '#SN-$year-${n.toString().padLeft(3, '0')}';
  while (existing.any((d) => d.id == id)) {
    n++;
    id = '#SN-$year-${n.toString().padLeft(3, '0')}';
  }
  return id;
}
