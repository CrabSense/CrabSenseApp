import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/production_models.dart';
import '../../services/area_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../utils/app_formatters.dart';
import '../shared/mgmt_ui.dart';

const _kDefaultLat = 10.842311;
const _kDefaultLng = 106.804512;

Future<void> showAreaFormDialog(
  BuildContext context,
  AreaManagementService svc, {
  AreaRecord? existing,
  void Function(AreaRecord area, {required bool setupRows})? onAfterCreate,
}) async {
  var preview = 'FARM-…';
  if (existing == null) {
    try {
      preview = await svc.fetchNextAreaCode();
    } catch (_) {}
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => _AreaFormDialog(
      svc: svc,
      existing: existing,
      autoCode: existing?.areaCode ?? preview,
      onAfterCreate: onAfterCreate,
    ),
  );
}

class _AreaFormDialog extends StatefulWidget {
  const _AreaFormDialog({
    required this.svc,
    required this.autoCode,
    this.existing,
    this.onAfterCreate,
  });

  final AreaManagementService svc;
  final AreaRecord? existing;
  final String autoCode;
  final void Function(AreaRecord area, {required bool setupRows})? onAfterCreate;

  bool get isCreate => existing == null;

  @override
  State<_AreaFormDialog> createState() => _AreaFormDialogState();
}

class _AreaFormDialogState extends State<_AreaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _address;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _notes;
  late final TextEditingController _capacity;

  late String _status;
  var _culture = 'Cua lột';
  var _water = 'Nước lợ';
  var _owner = 'Nguyễn Văn A';
  DateTime _startDate = DateTime.now();
  var _goToRows = true;
  var _linkRas = false;
  var _linkController = false;
  var _addCamera = false;
  var _envSetup = false;
  var _saving = false;
  var _locating = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.areaName ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _lat = TextEditingController(
      text: e?.latitude == null ? '' : e!.latitude!.toStringAsFixed(6),
    );
    _lng = TextEditingController(
      text: e?.longitude == null ? '' : e!.longitude!.toStringAsFixed(6),
    );
    _notes = TextEditingController(text: e?.description ?? '');
    _capacity = TextEditingController(
      text: (e == null || e.boxCount <= 0) ? '100' : '${e.boxCount}',
    );
    _status = _uiStatus(e?.status ?? 'active');
    if (e?.establishedAt != null) _startDate = e!.establishedAt!;
    _lat.addListener(_onCoordChanged);
    _lng.addListener(_onCoordChanged);
  }

  @override
  void dispose() {
    _lat.removeListener(_onCoordChanged);
    _lng.removeListener(_onCoordChanged);
    _name.dispose();
    _location.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    _notes.dispose();
    _capacity.dispose();
    super.dispose();
  }

  void _onCoordChanged() {
    if (mounted) setState(() {});
  }

  String _uiStatus(String raw) {
    final k = raw.toLowerCase();
    if (k == 'maintenance' || k == 'suspended') return 'maintenance';
    if (k == 'disabled' || k == 'closed') return 'disabled';
    return 'active';
  }

  String _apiStatus() => switch (_status) {
        'maintenance' => 'Suspended',
        'disabled' => 'Closed',
        _ => 'Active',
      };

  double? get _latVal => double.tryParse(_lat.text.trim().replaceAll(',', '.'));
  double? get _lngVal => double.tryParse(_lng.text.trim().replaceAll(',', '.'));

  InputDecoration _dec({required String hint, Widget? prefix, Widget? suffix}) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: bvText(fontSize: 13, color: DashboardColors.textMuted),
      prefixIcon: prefix,
      suffixIcon: suffix,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: b(DashboardColors.cardBorder),
      enabledBorder: b(DashboardColors.cardBorder),
      focusedBorder: b(DashboardColors.brandGreen, 1.4),
      errorBorder: b(DashboardColors.risk),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          style: bvText(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: DashboardColors.textPrimary,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: DashboardColors.risk, fontWeight: FontWeight.w800),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: DashboardColors.brand,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: DashboardColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickOnMap() async {
    final result = await showDialog<(double, double)>(
      context: context,
      builder: (_) => _MapPickerDialog(
        latitude: _latVal ?? _kDefaultLat,
        longitude: _lngVal ?? _kDefaultLng,
        areaCode: widget.autoCode,
      ),
    );
    if (result == null) return;
    setState(() {
      _lat.text = result.$1.toStringAsFixed(6);
      _lng.text = result.$2.toStringAsFixed(6);
    });
  }

  Future<void> _useCurrent() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw 'Chưa được cấp quyền vị trí.';
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() {
        _lat.text = pos.latitude.toStringAsFixed(6);
        _lng.text = pos.longitude.toStringAsFixed(6);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lấy được vị trí hiện tại. $e')),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final lat = _latVal;
    final lng = _lngVal;
    if (lat != null && (lat < -90 || lat > 90)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠ Vĩ độ phải trong khoảng -90 đến 90.')),
      );
      return;
    }
    if (lng != null && (lng < -180 || lng > 180)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠ Kinh độ phải trong khoảng -180 đến 180.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final area = widget.isCreate
          ? await widget.svc.createArea(
              areaName: _name.text.trim(),
              description: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              status: _apiStatus(),
              location: _location.text.trim(),
              address: _address.text.trim().isEmpty ? null : _address.text.trim(),
              establishedAt: _startDate,
              latitude: lat,
              longitude: lng,
            )
          : await widget.svc.updateArea(
              widget.existing!,
              areaName: _name.text.trim(),
              description: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              status: _apiStatus(),
              location: _location.text.trim(),
              address: _address.text.trim().isEmpty ? null : _address.text.trim(),
              establishedAt: _startDate,
              latitude: lat,
              longitude: lng,
            );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isCreate ? 'Đã tạo khu ${area.areaCode}' : 'Đã cập nhật khu'),
        ),
      );
      if (widget.isCreate) {
        widget.onAfterCreate?.call(area, setupRows: _goToRows);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.isCreate;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120, maxHeight: 860),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: DashboardColors.mint,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.add_rounded, color: DashboardColors.brand),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCreate ? 'Thêm khu nuôi mới' : 'Cập nhật khu nuôi',
                          style: bvText(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: DashboardColors.textPrimary,
                          ),
                        ),
                        Text(
                          isCreate
                              ? 'Tạo khu nuôi và xác định vị trí để bắt đầu quản lý.'
                              : 'Chỉnh sửa thông tin và vị trí khu ${widget.existing!.areaCode}.',
                          style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: DashboardColors.textMuted),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: DashboardColors.mint),
            Expanded(
              child: Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 54,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 16, 12, 16),
                        child: Column(
                          children: [
                            _sectionCard(
                              index: '1',
                              title: 'Thông tin cơ bản',
                              child: _basicInfo(),
                            ),
                            const SizedBox(height: 12),
                            _sectionCard(
                              index: '3',
                              title: 'Cấu hình khu nuôi',
                              child: _config(),
                            ),
                            if (isCreate) ...[
                              const SizedBox(height: 12),
                              _sectionCard(
                                index: '4',
                                title: 'Thiết lập sau khi tạo khu',
                                child: _afterCreate(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, color: DashboardColors.mint),
                    Expanded(
                      flex: 46,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 22, 16),
                        child: _sectionCard(
                          index: '2',
                          title: 'Vị trí khu nuôi',
                          icon: Icons.place_outlined,
                          child: _locationBlock(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: DashboardColors.mint)),
              ),
              child: Row(
                children: [
                  Text(
                    '* Trường bắt buộc',
                    style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                  ),
                  const Spacer(),
                  MgmtOutlineButton(
                    label: 'Hủy',
                    onTap: _saving ? null : () => Navigator.pop(context),
                    color: DashboardColors.textMuted,
                    height: 40,
                  ),
                  const SizedBox(width: 8),
                  MgmtPrimaryButton(
                    icon: isCreate ? Icons.add_rounded : Icons.check_rounded,
                    label: isCreate ? 'Tạo khu' : 'Lưu thay đổi',
                    onTap: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String index,
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
              Icon(icon ?? Icons.tune_rounded, size: 16, color: DashboardColors.brand),
              const SizedBox(width: 6),
              Text(
                '$index. $title',
                style: bvText(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _basicInfo() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Tên khu', required: true),
                  TextFormField(
                    controller: _name,
                    decoration: _dec(hint: 'Khu nuôi mới'),
                    style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? '⚠ Vui lòng nhập tên khu.'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Mã khu', required: true),
                  TextFormField(
                    readOnly: true,
                    initialValue: widget.autoCode,
                    decoration: _dec(
                      hint: 'FARM-006',
                      suffix: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          'Tạo mã tự động',
                          style: bvText(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: DashboardColors.brand,
                          ),
                        ),
                      ),
                    ),
                    style: bvText(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.brand,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mã khu hệ thống cấp, không sửa tay.',
                    style: bvText(fontSize: 11, color: DashboardColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _dropdown('Loại hình nuôi', _culture, const ['Cua lột', 'Cua thịt', 'Hỗn hợp'], (v) => _culture = v)),
            const SizedBox(width: 10),
            Expanded(
              child: _dropdown(
                'Trạng thái',
                _status,
                const ['active', 'maintenance', 'disabled'],
                (v) => _status = v,
                labelOf: (v) => switch (v) {
                  'maintenance' => 'Bảo trì',
                  'disabled' => 'Ngưng sử dụng',
                  _ => 'Đang hoạt động',
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _config() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _dropdown('Nguồn nước', _water, const ['Nước lợ', 'Nước mặn', 'Nước ngọt'], (v) => _water = v)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Sức chứa dự kiến'),
                  TextFormField(
                    controller: _capacity,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _dec(hint: '100', suffix: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text('hộp', style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
                    )),
                    style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Ngày bắt đầu vận hành'),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: _dec(
                        hint: formatDate(_startDate),
                        suffix: const Icon(Icons.calendar_today_outlined, size: 16),
                      ),
                      child: Text(
                        formatDate(_startDate),
                        style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _dropdown('Người phụ trách', _owner, const ['Nguyễn Văn A', 'Chủ trại'], (v) => _owner = v)),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Ghi chú'),
                  TextFormField(
                    controller: _notes,
                    decoration: _dec(hint: 'Nhập mô tả ngắn gọn về khu nuôi...'),
                    style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _afterCreate() {
    Widget item(bool value, String title, String? sub, ValueChanged<bool> onChanged, {bool emphasized = false}) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: value,
                    onChanged: (v) => onChanged(v ?? false),
                    activeColor: DashboardColors.brand,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: bvText(
                          fontSize: 13,
                          fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                      if (sub != null)
                        Text(sub, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        item(
          _goToRows,
          'Chuyển đến thiết lập dãy nuôi sau khi tạo khu',
          'Sau khi tạo, bạn có thể thêm dãy, hộp, Controller, RAS, Camera và cấu hình môi trường.',
          (v) => setState(() => _goToRows = v),
          emphasized: true,
        ),
        item(_linkRas, 'Liên kết hệ thống RAS', null, (v) => setState(() => _linkRas = v)),
        item(_linkController, 'Liên kết Controller', null, (v) => setState(() => _linkController = v)),
        item(_addCamera, 'Thêm camera', null, (v) => setState(() => _addCamera = v)),
        item(_envSetup, 'Cấu hình nguồn môi trường', null, (v) => setState(() => _envSetup = v)),
      ],
    );
  }

  Widget _locationBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xác định vị trí khu để hiển thị chính xác trên bản đồ trại.',
          style: bvText(fontSize: 12, color: DashboardColors.textMuted),
        ),
        const SizedBox(height: 12),
        _label('Tên / mô tả vị trí', required: true),
        TextFormField(
          controller: _location,
          decoration: _dec(hint: 'Đối diện tòa nhà Vinhomes S305'),
          style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? '⚠ Vui lòng nhập tên / mô tả vị trí.'
              : null,
        ),
        const SizedBox(height: 12),
        _label('Địa chỉ'),
        TextFormField(
          controller: _address,
          decoration: _dec(
            hint: 'Nhập địa chỉ khu nuôi...',
            prefix: Icon(Icons.search_rounded, size: 18, color: DashboardColors.textMuted),
          ),
          style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary),
        ),
        const SizedBox(height: 12),
        _label('Tọa độ GPS'),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _lat,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: _dec(hint: 'Vĩ độ'),
                style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _lng,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: _dec(hint: 'Kinh độ'),
                style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: MgmtPrimaryButton(
                icon: Icons.place_outlined,
                label: 'Chọn trên bản đồ',
                onTap: _pickOnMap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MgmtOutlineButton(
                icon: _locating ? Icons.hourglass_top_rounded : Icons.my_location_rounded,
                label: 'Lấy vị trí hiện tại',
                onTap: _locating ? null : _useCurrent,
                height: 42,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MapPreview(
          latitude: _latVal,
          longitude: _lngVal,
          areaCode: widget.autoCode,
          placeLabel: _location.text.trim(),
          onOpenPicker: _pickOnMap,
        ),
      ],
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged, {
    String Function(String v)? labelOf,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: _dec(hint: label),
          items: [
            for (final i in items)
              DropdownMenuItem(
                value: i,
                child: Text(
                  labelOf?.call(i) ?? i,
                  style: bvText(fontSize: 13, color: DashboardColors.textPrimary),
                ),
              ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => onChanged(v));
          },
        ),
      ],
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.latitude,
    required this.longitude,
    required this.areaCode,
    required this.placeLabel,
    required this.onOpenPicker,
  });

  final double? latitude;
  final double? longitude;
  final String areaCode;
  final String placeLabel;
  final VoidCallback onOpenPicker;

  @override
  Widget build(BuildContext context) {
    final has = latitude != null && longitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bản đồ vị trí',
          style: bvText(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: DashboardColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 210,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (has)
                  Image.network(
                    _esriTileUrl(latitude!, longitude!, 16),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                else
                  _placeholder(),
                if (has)
                  const Center(
                    child: Icon(Icons.location_on_rounded, size: 36, color: Color(0xFF087F5B)),
                  ),
                if (has)
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          areaCode,
                          style: bvText(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: DashboardColors.brand,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: onOpenPicker,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.open_in_full_rounded, size: 16, color: DashboardColors.brand),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (has)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8F0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DashboardColors.brandGreen.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 18, color: DashboardColors.brandGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đã xác định vị trí',
                        style: bvText(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                      Text(
                        placeLabel.isEmpty ? areaCode : placeLabel,
                        style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                      ),
                      Text(
                        '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
                        style: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onOpenPicker,
                  child: Text(
                    'Thay đổi vị trí',
                    style: bvText(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.brand,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            'Chưa ghim vị trí — chọn trên bản đồ hoặc nhập tọa độ.',
            style: bvText(fontSize: 12, color: DashboardColors.textMuted),
          ),
      ],
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: const Color(0xFFD9EEE6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 36, color: DashboardColors.brand.withValues(alpha: 0.55)),
            const SizedBox(height: 6),
            Text(
              'BẢN ĐỒ PREVIEW',
              style: bvText(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: DashboardColors.brand,
              ),
            ),
            Text(areaCode, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _MapPickerDialog extends StatefulWidget {
  const _MapPickerDialog({
    required this.latitude,
    required this.longitude,
    required this.areaCode,
  });

  final double latitude;
  final double longitude;
  final String areaCode;

  @override
  State<_MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<_MapPickerDialog> {
  late double _lat = widget.latitude;
  late double _lng = widget.longitude;
  var _zoom = 16;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 720,
        height: 560,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined, color: DashboardColors.brand),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chọn vị trí trên bản đồ',
                      style: bvText(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      return GestureDetector(
                        onTapDown: (d) {
                          final next = _pixelToLatLng(d.localPosition, c.biggest);
                          setState(() {
                            _lat = next.$1;
                            _lng = next.$2;
                          });
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              _esriTileUrl(_lat, _lng, _zoom),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const ColoredBox(
                                color: Color(0xFFD9EEE6),
                                child: Center(child: Text('Không tải được bản đồ')),
                              ),
                            ),
                            const Center(
                              child: Icon(Icons.location_on_rounded, size: 40, color: DashboardColors.brand),
                            ),
                            Positioned(
                              top: 12,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.areaCode,
                                    style: bvText(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: DashboardColors.brand,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Column(
                                children: [
                                  _zoomBtn(Icons.add, () => setState(() => _zoom = (_zoom + 1).clamp(3, 19))),
                                  const SizedBox(height: 6),
                                  _zoomBtn(Icons.remove, () => setState(() => _zoom = (_zoom - 1).clamp(3, 19))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_lat.toStringAsFixed(6)}, ${_lng.toStringAsFixed(6)}\nNhấp vào bản đồ để đặt ghim.',
                      style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                    ),
                  ),
                  MgmtOutlineButton(
                    label: 'Hủy',
                    onTap: () => Navigator.pop(context),
                    color: DashboardColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  MgmtPrimaryButton(
                    label: 'Xác nhận vị trí',
                    onTap: () => Navigator.pop(context, (_lat, _lng)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: DashboardColors.textPrimary),
        ),
      ),
    );
  }

  (double, double) _pixelToLatLng(Offset local, Size size) {
    final n = 1 << _zoom;
    final tile = _latLngToTile(_lat, _lng, _zoom);
    final dx = (local.dx / size.width - 0.5);
    final dy = (local.dy / size.height - 0.5);
    final x = tile.$1 + dx;
    final y = tile.$2 + dy;
    final lng = x / n * 360.0 - 180.0;
    final latRad = math.atan(_sinh(math.pi * (1 - 2 * y / n)));
    final lat = latRad * 180.0 / math.pi;
    return (lat.clamp(-85.0, 85.0), lng.clamp(-180.0, 180.0));
  }
}

(int, int) _latLngToTile(double lat, double lng, int z) {
  final n = 1 << z;
  final x = ((lng + 180.0) / 360.0 * n).floor();
  final latRad = lat * math.pi / 180.0;
  final y = ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * n).floor();
  return (x.clamp(0, n - 1), y.clamp(0, n - 1));
}

String _esriTileUrl(double lat, double lng, int z) {
  final t = _latLngToTile(lat, lng, z);
  return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/$z/${t.$2}/${t.$1}';
}

double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
