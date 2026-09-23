import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/farm_record.dart';
import '../../models/production_models.dart';
import '../../models/row_list_item.dart';
import '../../services/row_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/mgmt_ui.dart';

const _kOverlay = Color.fromRGBO(15, 35, 30, 0.45);
const _kCancelBorder = Color(0xFFBFDCD3);
const _kAmber = Color(0xFFF5B700);

Future<void> showCreateRowDialog(
  BuildContext context,
  RowManagementService service, {
  required String areaId,
}) async {
  var preview = 'DAY-A01';
  try {
    preview = await service.fetchNextCode();
  } catch (_) {}
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: _kOverlay,
    builder: (_) => _RowFormDialog(
      title: 'Thêm dãy mới',
      subtitle:
          'Tạo dãy mới trong khu vực nuôi, có thể tạo sẵn hộp tự động sau khi lưu.',
      autoCode: preview,
      isCreate: true,
      service: service,
      initialAreaId: areaId,
    ),
  );
}

Future<void> showEditRowDialog(
  BuildContext context,
  RowManagementService service,
  RowListItem item,
) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: _kOverlay,
    builder: (_) => _RowFormDialog(
      title: 'Sửa dãy',
      subtitle: 'Cập nhật thông tin dãy ${item.rowCode}.',
      autoCode: item.rowCode,
      isCreate: false,
      service: service,
      initialAreaId: item.areaId,
      initial: item.row,
    ),
  );
}

class _RowFormDialog extends StatefulWidget {
  const _RowFormDialog({
    required this.title,
    required this.subtitle,
    required this.autoCode,
    required this.isCreate,
    required this.service,
    required this.initialAreaId,
    this.initial,
  });

  final String title;
  final String subtitle;
  final String autoCode;
  final bool isCreate;
  final RowManagementService service;
  final String initialAreaId;
  final RowRecord? initial;

  @override
  State<_RowFormDialog> createState() => _RowFormDialogState();
}

class _RowFormDialogState extends State<_RowFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _orderCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _capacityCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _boxCountCtrl;
  late final TextEditingController _prefixCtrl;

  late String _areaId;
  late FarmStatus _status;
  var _autoCreate = true;
  var _saving = false;
  var _autovalidate = AutovalidateMode.disabled;

  late final String _initName;
  late final String _initOrder;
  late final String _initLocation;
  late final String _initCapacity;
  late final String _initDesc;
  late final String _initAreaId;
  late final FarmStatus _initStatus;
  late final bool _initAuto;
  late final String _initBoxCount;
  late final String _initPrefix;

  @override
  void initState() {
    super.initState();
    final row = widget.initial;
    final areas = widget.service.areas;
    _areaId = areas.any((a) => a.id == widget.initialAreaId)
        ? widget.initialAreaId
        : (areas.isNotEmpty ? areas.first.id : widget.initialAreaId);

    _initName = row?.rowName ?? '';
    _initOrder = '${row?.sortOrder ?? 1}';
    _initLocation = row?.location ?? '';
    _initCapacity = row == null || row.capacity <= 0 ? '10' : '${row.capacity}';
    _initDesc = row?.description ?? '';
    _initAreaId = _areaId;
    _initStatus = row?.status == FarmStatus.closed
        ? FarmStatus.suspended
        : (row?.status ?? FarmStatus.active);
    _initAuto = widget.isCreate;
    _initBoxCount = _initCapacity;
    _initPrefix = 'BOX';

    _nameCtrl = TextEditingController(text: _initName);
    _orderCtrl = TextEditingController(text: _initOrder);
    _locationCtrl = TextEditingController(text: _initLocation);
    _capacityCtrl = TextEditingController(text: _initCapacity);
    _descCtrl = TextEditingController(text: _initDesc);
    _boxCountCtrl = TextEditingController(text: _initBoxCount);
    _prefixCtrl = TextEditingController(text: _initPrefix);
    _status = _initStatus;
    _autoCreate = _initAuto;
    _descCtrl.addListener(_onDescChanged);
  }

  @override
  void dispose() {
    _descCtrl.removeListener(_onDescChanged);
    _nameCtrl.dispose();
    _orderCtrl.dispose();
    _locationCtrl.dispose();
    _capacityCtrl.dispose();
    _descCtrl.dispose();
    _boxCountCtrl.dispose();
    _prefixCtrl.dispose();
    super.dispose();
  }

  void _onDescChanged() {
    if (mounted) setState(() {});
  }

  bool get _dirty {
    if (_nameCtrl.text.trim() != _initName) return true;
    if (_orderCtrl.text.trim() != _initOrder) return true;
    if (_locationCtrl.text.trim() != _initLocation) return true;
    if (_capacityCtrl.text.trim() != _initCapacity) return true;
    if (_descCtrl.text.trim() != _initDesc) return true;
    if (_areaId != _initAreaId) return true;
    if (_status != _initStatus) return true;
    if (widget.isCreate) {
      if (_autoCreate != _initAuto) return true;
      if (_boxCountCtrl.text.trim() != _initBoxCount) return true;
      if (_prefixCtrl.text.trim() != _initPrefix) return true;
    }
    return false;
  }

  int? get _maxBoxes => int.tryParse(_capacityCtrl.text.trim());

  InputDecoration _dec({
    String? hint,
    Widget? prefix,
    Widget? suffix,
    String? counterText,
  }) {
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
      counterText: counterText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: b(DashboardColors.cardBorder),
      enabledBorder: b(DashboardColors.cardBorder),
      focusedBorder: b(DashboardColors.brandGreen, 1.4),
      errorBorder: b(DashboardColors.risk),
      focusedErrorBorder: b(DashboardColors.risk, 1.4),
      errorStyle: bvText(fontSize: 11.5, color: DashboardColors.risk, height: 1.3),
    );
  }

  Widget _iconBox(IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 4),
      child: Icon(icon, size: 18, color: color ?? DashboardColors.brand),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          style: bvText(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: DashboardColors.textPrimary,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: DashboardColors.risk,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _helper(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: bvText(fontSize: 11.5, color: DashboardColors.textMuted, height: 1.35),
      ),
    );
  }

  Future<bool> _confirmClose() async {
    if (_saving) return false;
    if (!_dirty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Đóng form?',
          style: bvText(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: DashboardColors.textPrimary,
          ),
        ),
        content: Text(
          'Bạn có thay đổi chưa được lưu.\nBạn có chắc muốn đóng?',
          style: bvText(fontSize: 13.5, color: DashboardColors.textMuted, height: 1.45),
        ),
        actions: [
          MgmtOutlineButton(
            label: 'Ở lại',
            onTap: () => Navigator.pop(ctx, false),
            color: DashboardColors.textMuted,
            height: 40,
          ),
          MgmtPrimaryButton(
            label: 'Đóng',
            onTap: () => Navigator.pop(ctx, true),
            height: 40,
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _tryClose() async {
    if (!await _confirmClose()) return;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) return;
    if (_areaId.isEmpty) return;

    final name = _nameCtrl.text.trim();
    final capacity = int.parse(_capacityCtrl.text.trim());
    final order = int.parse(_orderCtrl.text.trim());
    final location = _locationCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final auto = widget.isCreate && _autoCreate;
    final boxCount = auto ? int.parse(_boxCountCtrl.text.trim()) : 0;
    final prefix = _prefixCtrl.text.trim();

    setState(() => _saving = true);
    try {
      if (widget.isCreate) {
        final row = await widget.service.create(
          areaId: _areaId,
          name: name,
          location: location.isEmpty ? null : location,
          capacity: capacity,
          description: desc.isEmpty ? null : desc,
          status: _status,
          sortOrder: order,
        );
        var boxesMade = 0;
        String? boxError;
        if (auto && boxCount > 0) {
          try {
            final boxes = await widget.service.createBoxesForRow(
              rowId: row.id,
              count: boxCount,
              prefix: prefix,
            );
            boxesMade = boxes.length;
          } catch (e) {
            boxError = '$e';
          }
        }
        if (!mounted) return;
        Navigator.pop(context);
        final msg = boxError != null
            ? '✓ Đã tạo dãy $name nhưng chưa tạo đủ hộp. $boxError'
            : (auto
                ? '✓ Đã tạo dãy $name và $boxesMade hộp thành công.'
                : '✓ Đã tạo dãy $name thành công.');
        _toast(msg, ok: boxError == null);
      } else {
        await widget.service.update(
          widget.initial!,
          name: name,
          location: location,
          capacity: capacity,
          description: desc,
          status: _status,
          sortOrder: order,
        );
        if (!mounted) return;
        Navigator.pop(context);
        _toast('✓ Đã cập nhật dãy $name.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('$e', ok: false);
    }
  }

  void _toast(String message, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? DashboardColors.brand : DashboardColors.risk,
        content: Text(
          message,
          style: bvText(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final modalW = size.width < 600
        ? size.width - 24
        : size.width < 900
            ? size.width * 0.9
            : 740.0;
    final maxH = size.height * 0.9;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _tryClose();
      },
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _saving ? null : _tryClose,
                behavior: HitTestBehavior.opaque,
              ),
            ),
            Dialog(
              backgroundColor: Colors.white,
              insetPadding: EdgeInsets.symmetric(
                horizontal: size.width < 600 ? 12 : 28,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
              child: Container(
                width: modalW,
                constraints: BoxConstraints(maxWidth: modalW, maxHeight: maxH),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F231E).withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _header(),
                    Flexible(
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _autovalidate,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
                          child: LayoutBuilder(
                            builder: (context, c) {
                              final narrow = c.maxWidth < 540;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _codeBox(),
                                  const SizedBox(height: 16),
                                  _areaField(),
                                  const SizedBox(height: 14),
                                  _nameAndOrder(narrow),
                                  const SizedBox(height: 14),
                                  _locationField(),
                                  const SizedBox(height: 14),
                                  _capacityAndStatus(narrow),
                                  const SizedBox(height: 14),
                                  _descriptionField(),
                                  if (widget.isCreate) ...[
                                    const SizedBox(height: 16),
                                    _autoBoxesSection(narrow),
                                  ],
                                  const SizedBox(height: 8),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    _footer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 10, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: DashboardColors.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.view_week_rounded,
              color: DashboardColors.brand,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: bvText(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: bvText(
                    fontSize: 13,
                    color: DashboardColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: _saving ? null : _tryClose,
            focusColor: DashboardColors.mint,
            icon: Icon(Icons.close_rounded, color: DashboardColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _codeBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Mã dãy (hệ thống tự tạo)'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: DashboardColors.lightMint,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DashboardColors.mint),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 18, color: DashboardColors.brand),
              const SizedBox(width: 10),
              Text(
                widget.autoCode,
                style: bvText(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.brand,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        _helper('Mã dãy sẽ được hệ thống tự động tạo theo quy tắc của khu vực.'),
      ],
    );
  }

  Widget _areaField() {
    final areas = widget.service.areas;
    final value = areas.any((a) => a.id == _areaId) ? _areaId : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Khu thuộc về', required: true),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          decoration: _dec(
            hint: 'Chọn khu nuôi',
            prefix: _iconBox(Icons.home_outlined),
          ),
          style: bvText(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: DashboardColors.textPrimary,
          ),
          items: [
            for (final a in areas)
              DropdownMenuItem(
                value: a.id,
                child: Text(
                  '${a.areaCode} — ${a.areaName}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: widget.isCreate && !_saving
              ? (v) {
                  if (v != null) setState(() => _areaId = v);
                }
              : null,
          validator: (v) {
            if (v == null || v.isEmpty) {
              return '⚠ Vui lòng chọn khu thuộc về.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _nameAndOrder(bool narrow) {
    final name = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Tên dãy', required: true),
        TextFormField(
          controller: _nameCtrl,
          enabled: !_saving,
          textInputAction: TextInputAction.next,
          style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary),
          decoration: _dec(
            hint: 'Nhập tên dãy (ví dụ: A1, A11, A21...)',
            prefix: _iconBox(Icons.view_week_outlined),
          ),
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.isEmpty) return '⚠ Vui lòng nhập tên dãy.';
            if (widget.service.isNameTakenInArea(
              _areaId,
              t,
              excludeRowId: widget.initial?.id,
            )) {
              return '⚠ Tên dãy đã tồn tại trong khu vực này.';
            }
            return null;
          },
        ),
      ],
    );
    final order = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Thứ tự hiển thị'),
        TextFormField(
          controller: _orderCtrl,
          enabled: !_saving,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary),
          decoration: _dec(
            hint: '1',
            prefix: _iconBox(Icons.swap_vert_rounded),
            suffix: _stepperButtons(_orderCtrl, min: 1),
          ),
          validator: (v) {
            final n = int.tryParse(v?.trim() ?? '');
            if (n == null || n < 1) {
              return '⚠ Thứ tự hiển thị phải ≥ 1.';
            }
            return null;
          },
        ),
        _helper('Dùng để sắp xếp dãy trong khu.'),
      ],
    );
    if (narrow) {
      return Column(
        children: [
          name,
          const SizedBox(height: 14),
          order,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 65, child: name),
        const SizedBox(width: 14),
        Expanded(flex: 35, child: order),
      ],
    );
  }

  Widget _locationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Vị trí / Ghi chú vị trí'),
        TextFormField(
          controller: _locationCtrl,
          enabled: !_saving,
          textInputAction: TextInputAction.next,
          style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary),
          decoration: _dec(
            hint: 'Ví dụ: Phía Đông khu nuôi, cạnh dãy A11...',
            prefix: _iconBox(Icons.place_outlined),
          ),
        ),
      ],
    );
  }

  Widget _capacityAndStatus(bool narrow) {
    final capacity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Sức chứa tối đa', required: true),
        TextFormField(
          controller: _capacityCtrl,
          enabled: !_saving,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary),
          decoration: _dec(
            hint: '10',
            prefix: _iconBox(Icons.inventory_2_outlined),
            suffix: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                'hộp',
                style: bvText(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DashboardColors.textMuted,
                ),
              ),
            ),
          ),
          onChanged: (_) {
            if (_autovalidate == AutovalidateMode.onUserInteraction) {
              _formKey.currentState?.validate();
            }
          },
          validator: (v) {
            final n = int.tryParse(v?.trim() ?? '');
            if (n == null || n <= 0) {
              return '⚠ Sức chứa phải lớn hơn 0.';
            }
            if (n > 500) return '⚠ Sức chứa không được vượt quá 500.';
            return null;
          },
        ),
        _helper('Số hộp tối đa có thể bố trí trong dãy này.'),
      ],
    );
    final status = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Trạng thái', required: true),
        DropdownButtonFormField<FarmStatus>(
          initialValue: _status,
          isExpanded: true,
          dropdownColor: Colors.white,
          decoration: _dec(prefix: _iconBox(Icons.power_settings_new_rounded)),
          style: bvText(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: DashboardColors.textPrimary,
          ),
          items: const [
            FarmStatus.active,
            FarmStatus.suspended,
          ]
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s == FarmStatus.active
                              ? DashboardColors.brand
                              : _kAmber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(s.label),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: _saving
              ? null
              : (v) {
                  if (v != null) setState(() => _status = v);
                },
          validator: (v) => v == null ? '⚠ Vui lòng chọn trạng thái.' : null,
        ),
        _helper('Chọn trạng thái hoạt động của dãy.'),
      ],
    );
    if (narrow) {
      return Column(
        children: [
          capacity,
          const SizedBox(height: 14),
          status,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: capacity),
        const SizedBox(width: 14),
        Expanded(child: status),
      ],
    );
  }

  Widget _descriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Mô tả'),
        TextFormField(
          controller: _descCtrl,
          enabled: !_saving,
          maxLength: 255,
          minLines: 3,
          maxLines: 4,
          style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary, height: 1.4),
          decoration: _dec(
            hint: 'Nhập mô tả về dãy (tùy chọn)...',
          ).copyWith(
            counter: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_descCtrl.text.length}/255',
                style: bvText(fontSize: 11, color: DashboardColors.textMuted),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _autoBoxesSection(bool narrow) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: DashboardColors.lightMint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DashboardColors.mint),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _saving
                    ? null
                    : () => setState(() {
                          _autoCreate = !_autoCreate;
                          if (_autoCreate && _boxCountCtrl.text.trim().isEmpty) {
                            _boxCountCtrl.text = _capacityCtrl.text.trim().isEmpty
                                ? '10'
                                : _capacityCtrl.text.trim();
                          }
                        }),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _autoCreate,
                          onChanged: _saving
                              ? null
                              : (v) => setState(() => _autoCreate = v ?? false),
                          activeColor: DashboardColors.brand,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          side: const BorderSide(
                            color: DashboardColors.brandGreen,
                            width: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tạo hộp tự động cho dãy này',
                              style: bvText(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: DashboardColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hệ thống sẽ tạo sẵn các hộp theo số lượng và tiền tố bạn chọn sau khi lưu.',
                              style: bvText(
                                fontSize: 12,
                                color: DashboardColors.textMuted,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_autoCreate) ...[
              const SizedBox(height: 14),
              _autoBoxFields(narrow),
            ],
          ],
        ),
      ),
    );
  }

  Widget _autoBoxFields(bool narrow) {
    final count = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Số hộp cần tạo'),
        TextFormField(
          controller: _boxCountCtrl,
          enabled: !_saving,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary),
          decoration: _dec(
            hint: '10',
            prefix: _iconBox(Icons.layers_outlined),
            suffix: _stepperButtons(_boxCountCtrl, min: 1, max: _maxBoxes),
          ),
          validator: (v) {
            if (!_autoCreate) return null;
            final n = int.tryParse(v?.trim() ?? '');
            if (n == null || n <= 0) return '⚠ Số hộp phải lớn hơn 0.';
            final max = _maxBoxes;
            if (max != null && n > max) {
              return '⚠ Số hộp không được vượt quá sức chứa tối đa ($max).';
            }
            return null;
          },
        ),
        _helper('Không được vượt quá sức chứa tối đa.'),
      ],
    );
    final prefix = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Tiền tố mã hộp'),
        TextFormField(
          controller: _prefixCtrl,
          enabled: !_saving,
          textCapitalization: TextCapitalization.characters,
          style: bvText(fontSize: 13.5, color: DashboardColors.textPrimary),
          decoration: _dec(
            hint: 'BOX',
            prefix: _iconBox(Icons.sell_outlined),
          ),
          validator: (v) {
            if (!_autoCreate) return null;
            if ((v ?? '').trim().isEmpty) {
              return '⚠ Vui lòng nhập tiền tố mã hộp.';
            }
            return null;
          },
        ),
        _helper('Ví dụ: BOX → BOX-001, BOX-002...'),
      ],
    );
    if (narrow) {
      return Column(
        children: [
          count,
          const SizedBox(height: 12),
          prefix,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: count),
        const SizedBox(width: 12),
        Expanded(child: prefix),
      ],
    );
  }

  Widget _stepperButtons(TextEditingController ctrl, {int min = 1, int? max}) {
    void bump(int d) {
      final n = int.tryParse(ctrl.text.trim()) ?? min;
      var next = n + d;
      if (next < min) next = min;
      if (max != null && next > max) next = max;
      ctrl.text = '$next';
      setState(() {});
    }

    return SizedBox(
      width: 28,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _saving ? null : () => bump(1),
            child: Icon(Icons.arrow_drop_up_rounded, size: 18, color: DashboardColors.textMuted),
          ),
          InkWell(
            onTap: _saving ? null : () => bump(-1),
            child: Icon(Icons.arrow_drop_down_rounded, size: 18, color: DashboardColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        border: Border(top: BorderSide(color: DashboardColors.mint)),
      ),
      child: Row(
        children: [
          const Spacer(),
          MgmtOutlineButton(
            label: 'Hủy',
            onTap: _saving ? null : _tryClose,
            color: DashboardColors.brand,
            borderColor: _kCancelBorder,
            height: 46,
          ),
          const SizedBox(width: 10),
          _submitButton(),
        ],
      ),
    );
  }

  Widget _submitButton() {
    final label = _saving
        ? (widget.isCreate ? 'Đang tạo...' : 'Đang lưu...')
        : (widget.isCreate ? 'Thêm dãy' : 'Lưu thay đổi');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _saving ? null : _save,
        borderRadius: BorderRadius.circular(12),
        focusColor: DashboardColors.mint,
        child: Opacity(
          opacity: _saving ? 0.92 : 1,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: DashboardColors.brand,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: DashboardColors.brand.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_saving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: bvText(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
