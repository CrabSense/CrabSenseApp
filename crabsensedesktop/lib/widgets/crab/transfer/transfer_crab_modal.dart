import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/crab_individual.dart';
import '../../../models/crab_status.dart';
import '../../../models/production_models.dart';
import '../../../services/cloud_api_client.dart';
import '../../../services/crab_service.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';
import '../crab_auth_image.dart';
import '../crab_status_badge.dart';

enum TransferReasonCode {
  relocation,
  boxFault,
  monitoring,
  preMolt,
  postMolt,
  areaAdjust,
  opsRequest,
  other;

  String get api => switch (this) {
        TransferReasonCode.relocation => 'RELOCATION',
        TransferReasonCode.boxFault => 'BOX_FAULT',
        TransferReasonCode.monitoring => 'MONITORING',
        TransferReasonCode.preMolt => 'PRE_MOLT',
        TransferReasonCode.postMolt => 'POST_MOLT',
        TransferReasonCode.areaAdjust => 'AREA_ADJUST',
        TransferReasonCode.opsRequest => 'OPS_REQUEST',
        TransferReasonCode.other => 'OTHER',
      };

  String get label => switch (this) {
        TransferReasonCode.relocation => 'Điều chỉnh vị trí nuôi',
        TransferReasonCode.boxFault => 'Hộp gặp sự cố',
        TransferReasonCode.monitoring => 'Cua cần theo dõi',
        TransferReasonCode.preMolt => 'Chuẩn bị lột xác',
        TransferReasonCode.postMolt => 'Sau lột xác',
        TransferReasonCode.areaAdjust => 'Điều chỉnh khu vực nuôi',
        TransferReasonCode.opsRequest => 'Theo yêu cầu vận hành',
        TransferReasonCode.other => 'Khác',
      };
}

enum TargetBoxValidity { selectable, current, occupied, alert, inactive }

TargetBoxValidity targetBoxValidity(BoxRecord box, String currentBoxId) {
  if (box.id == currentBoxId) return TargetBoxValidity.current;
  final s = box.status.toLowerCase();
  if (s == 'maintenance' ||
      s == 'quarantine' ||
      s == 'suspended' ||
      s == 'closed' ||
      s == 'harvested') {
    return TargetBoxValidity.inactive;
  }
  if (box.hasCrab) return TargetBoxValidity.occupied;
  if (box.alertCount > 0) return TargetBoxValidity.alert;
  return TargetBoxValidity.selectable;
}

String targetBoxOptionLabel(BoxRecord box, TargetBoxValidity v) => switch (v) {
      TargetBoxValidity.selectable => '${box.boxCode} — Trống',
      TargetBoxValidity.current => '${box.boxCode} — Hộp hiện tại · Không thể chọn',
      TargetBoxValidity.occupied => '${box.boxCode} — Đã có cua · Không thể chọn',
      TargetBoxValidity.alert => '${box.boxCode} — Cảnh báo · Không thể chọn',
      TargetBoxValidity.inactive => '${box.boxCode} — Không hoạt động · Không thể chọn',
    };

String boxStatusLabel(BoxRecord? box) {
  if (box == null) return '—';
  final s = box.status.toLowerCase();
  if (s == 'maintenance') return 'Bảo trì';
  if (s == 'quarantine') return 'Cách ly';
  if (s == 'suspended' || s == 'closed') return 'Ngưng hoạt động';
  if (s == 'empty' && !box.hasCrab) return 'Trống';
  return 'Đang hoạt động';
}

Future<bool> showTransferCrabModal(
  BuildContext context,
  CrabService service, {
  required CrabIndividual crab,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color.fromRGBO(15, 35, 30, 0.45),
    builder: (_) => TransferCrabModal(service: service, initial: crab),
  );
  return ok == true;
}

class TransferCrabModal extends StatefulWidget {
  const TransferCrabModal({
    super.key,
    required this.service,
    required this.initial,
  });

  final CrabService service;
  final CrabIndividual initial;

  @override
  State<TransferCrabModal> createState() => _TransferCrabModalState();
}

class _TransferCrabModalState extends State<TransferCrabModal> {
  late CrabIndividual _crab = widget.initial;
  final _otherReason = TextEditingController();
  final _note = TextEditingController();

  var _bootLoading = true;
  var _rowsLoading = false;
  var _boxesLoading = false;
  var _saving = false;
  String? _error;
  var _conflict = false;

  List<AreaRecord> _areas = const [];
  List<RowRecord> _rows = const [];
  List<BoxRecord> _boxes = const [];
  BoxRecord? _currentBox;

  String? _areaId;
  String? _rowId;
  String? _boxId;
  TransferReasonCode? _reason;

  CrabService get _svc => widget.service;

  bool get _blocked =>
      _crab.lifecycleStatus == CrabLifecycleStatus.dead ||
      _crab.lifeStatus == CrabLifeStatus.dead ||
      _crab.lifecycleStatus == CrabLifecycleStatus.harvested ||
      _crab.lifeStatus == CrabLifeStatus.sold ||
      _crab.lifeStatus == CrabLifeStatus.readyForSale;

  bool get _isDead =>
      _crab.lifecycleStatus == CrabLifecycleStatus.dead ||
      _crab.lifeStatus == CrabLifeStatus.dead;

  BoxRecord? get _target =>
      _boxes.where((b) => b.id == _boxId).firstOrNull;

  TargetBoxValidity? get _targetValidity {
    final box = _target;
    if (box == null) return null;
    return targetBoxValidity(box, _crab.boxId);
  }

  bool get _targetOk => _targetValidity == TargetBoxValidity.selectable;

  String get _reasonLabel {
    if (_reason == null) return '';
    if (_reason == TransferReasonCode.other) return _otherReason.text.trim();
    return _reason!.label;
  }

  bool get _canSubmit =>
      !_blocked &&
      !_saving &&
      !_bootLoading &&
      _areaId != null &&
      _rowId != null &&
      _boxId != null &&
      _targetOk &&
      _reason != null &&
      (_reason != TransferReasonCode.other || _otherReason.text.trim().isNotEmpty);

  String get _areaLabel {
    for (final a in _areas) {
      if (a.id == _areaId) return '${a.areaCode} — ${a.areaName}';
    }
    return 'Chọn khu vực';
  }

  String get _rowLabel {
    for (final r in _rows) {
      if (r.id == _rowId) {
        return r.rowName.trim().isEmpty ? r.rowCode : r.rowName;
      }
    }
    return _rowsLoading ? 'Đang tải dãy…' : 'Chọn dãy';
  }

  String get _boxLabel {
    if (_boxesLoading) return 'Đang tải hộp…';
    final box = _target;
    if (box != null) return targetBoxOptionLabel(box, _targetValidity!);
    return _boxes.isEmpty ? 'Không có hộp' : 'Chọn hộp đích';
  }

  String get _currentBoxCode =>
      _currentBox?.boxCode ?? _crab.boxLabel;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _otherReason.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _bootLoading = true;
      _error = null;
      _conflict = false;
    });
    try {
      await _svc.loadDetail(widget.initial.id);
      final crab = _svc.getById(widget.initial.id) ?? widget.initial;
      final areas = await _svc.fetchAreas();
      var areaId = crab.areaId.isEmpty ? null : crab.areaId;
      areaId ??= areas.isEmpty ? null : areas.first.id;

      List<RowRecord> rows = const [];
      if (areaId != null) rows = await _svc.fetchRows(areaId);

      var rowId = crab.rowId.isEmpty ? null : crab.rowId;
      if (rowId != null && !rows.any((r) => r.id == rowId)) {
        rowId = rows.isEmpty ? null : rows.first.id;
      }
      rowId ??= rows.isEmpty ? null : rows.first.id;

      List<BoxRecord> boxes = const [];
      if (rowId != null) {
        boxes = await _svc.fetchBoxes(areaId: areaId, rowId: rowId);
      }

      BoxRecord? current;
      if (crab.boxId.isNotEmpty) {
        current = boxes.where((b) => b.id == crab.boxId).firstOrNull;
        if (current == null && crab.areaId.isNotEmpty) {
          final currentRowBoxes = crab.rowId.isEmpty
              ? await _svc.fetchBoxes(areaId: crab.areaId)
              : await _svc.fetchBoxes(areaId: crab.areaId, rowId: crab.rowId);
          current = currentRowBoxes.where((b) => b.id == crab.boxId).firstOrNull;
        }
      }

      final firstOk = boxes
          .where((b) => targetBoxValidity(b, crab.boxId) == TargetBoxValidity.selectable)
          .firstOrNull;

      if (!mounted) return;
      setState(() {
        _crab = crab;
        _areas = areas;
        _rows = rows;
        _boxes = boxes;
        _currentBox = current;
        _areaId = areaId;
        _rowId = rowId;
        _boxId = firstOk?.id;
        _bootLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _bootLoading = false;
      });
    }
  }

  Future<void> _onArea(String id) async {
    setState(() {
      _areaId = id;
      _rowId = null;
      _boxId = null;
      _rows = const [];
      _boxes = const [];
      _rowsLoading = true;
      _boxesLoading = true;
      _error = null;
      _conflict = false;
    });
    try {
      final rows = await _svc.fetchRows(id);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _rowsLoading = false;
      });
      if (rows.isEmpty) {
        setState(() => _boxesLoading = false);
        return;
      }
      await _onRow(rows.first.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _rowsLoading = false;
        _boxesLoading = false;
      });
    }
  }

  Future<void> _onRow(String id) async {
    setState(() {
      _rowId = id;
      _boxId = null;
      _boxes = const [];
      _boxesLoading = true;
      _error = null;
      _conflict = false;
    });
    try {
      final boxes = await _svc.fetchBoxes(areaId: _areaId, rowId: id);
      final firstOk = boxes
          .where((b) => targetBoxValidity(b, _crab.boxId) == TargetBoxValidity.selectable)
          .firstOrNull;
      if (!mounted) return;
      setState(() {
        _boxes = boxes;
        _boxId = firstOk?.id;
        _boxesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _boxesLoading = false;
      });
    }
  }

  Future<void> _refreshBoxes() async {
    final rowId = _rowId;
    if (rowId == null) return;
    await _onRow(rowId);
  }

  Future<void> _close() async {
    if (_saving) return;
    Navigator.pop(context, false);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final box = _target;
    if (box == null) return;

    final confirmed = await showTransferConfirmDialog(
      context,
      crabCode: _crab.code,
      fromBox: _currentBoxCode,
      toBox: box.boxCode,
      reason: _reasonLabel,
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
      _conflict = false;
    });
    try {
      final note = _note.text.trim();
      final notes = [
        if (_reasonLabel.isNotEmpty) _reasonLabel,
        if (note.isNotEmpty) note,
      ].join(' — ');
      await _svc.transferToBox(
        _crab.id,
        destinationBoxId: box.id,
        targetFarmAreaId: _areaId,
        targetRowId: _rowId,
        reasonCode: _reason!.api,
        reasonText: _reason == TransferReasonCode.other ? _otherReason.text.trim() : null,
        note: note.isEmpty ? null : note,
        notes: notes.isEmpty ? null : notes,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Đã chuyển ${_crab.code} từ $_currentBoxCode sang ${box.boxCode}.',
          ),
        ),
      );
    } on CloudApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _conflict = e.statusCode == 409;
        _error = _conflict
            ? '${box.boxCode} vừa được sử dụng. Vui lòng chọn hộp khác.'
            : e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final compact = MediaQuery.sizeOf(context).width < 720;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 24,
        vertical: compact ? 10 : 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040, maxHeight: 860),
        child: Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.escape): const _EscIntent(),
          },
          child: Actions(
            actions: {
              _EscIntent: CallbackAction<_EscIntent>(onInvoke: (_) {
                _close();
                return null;
              }),
            },
            child: Focus(
              autofocus: true,
              child: Column(
                children: [
                  _header(),
                  const Divider(height: 1, color: DashboardColors.mint),
                  Expanded(child: _body(wide)),
                  const Divider(height: 1, color: DashboardColors.mint),
                  _footer(compact),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.swap_horiz_rounded, color: DashboardColors.brand, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chuyển hộp cua',
                  style: bvText(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Di chuyển cua sang hộp nuôi khác trong cùng hoặc khác khu vực.',
                  style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: _saving ? null : _close,
            icon: Icon(Icons.close_rounded, color: DashboardColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _body(bool wide) {
    if (_bootLoading) return const _TransferSkeleton();
    if (_error != null && _areas.isEmpty) {
      return Center(
        child: MgmtEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Không thể tải dữ liệu chuyển hộp.',
          message: _error!,
          action: MgmtPrimaryButton(label: 'Thử lại', height: 38, onTap: _bootstrap),
        ),
      );
    }
    if (_blocked) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: MgmtEmptyState(
            icon: Icons.block_rounded,
            title: _isDead ? 'Không thể chuyển hộp' : 'Cua đã thu hoạch',
            message: _isDead
                ? 'Không thể chuyển hộp cho cua đã chết.'
                : 'Cua này đã được thu hoạch.',
          ),
        ),
      );
    }

    final form = TransferCrabForm(
      crab: _crab,
      token: _svc.token,
      currentBox: _currentBox,
      areas: _areas,
      rows: _rows,
      boxes: _boxes,
      areaId: _areaId,
      rowId: _rowId,
      boxId: _boxId,
      areaLabel: _areaLabel,
      rowLabel: _rowLabel,
      boxLabel: _boxLabel,
      rowsLoading: _rowsLoading,
      boxesLoading: _boxesLoading,
      reason: _reason,
      otherReason: _otherReason,
      note: _note,
      target: _target,
      validity: _targetValidity,
      conflict: _conflict,
      error: _error,
      onArea: _onArea,
      onRow: _onRow,
      onBox: (id) => setState(() {
        _boxId = id;
        _conflict = false;
        _error = null;
      }),
      onReason: (v) => setState(() => _reason = v),
      onRefreshBoxes: _refreshBoxes,
      onChanged: () => setState(() {}),
    );
    final summary = TransferCrabSummary(
      crab: _crab,
      currentBoxCode: _currentBoxCode,
    );

    if (!wide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Column(
          children: [
            form,
            const SizedBox(height: 14),
            summary,
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 67,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 12, 16),
            child: form,
          ),
        ),
        Container(width: 1, color: DashboardColors.mint),
        Expanded(
          flex: 33,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 16, 18, 16),
            child: summary,
          ),
        ),
      ],
    );
  }

  Widget _footer(bool compact) {
    final cancel = MgmtOutlineButton(
      label: 'Hủy',
      onTap: _saving ? null : _close,
    );
    final submit = Semantics(
      button: true,
      label: 'Chuyển hộp cua ${_crab.code}',
      child: _saving
          ? Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: DashboardColors.brand.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đang chuyển...',
                    style: bvText(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            )
          : MgmtPrimaryButton(
              label: 'Chuyển hộp',
              icon: Icons.swap_horiz_rounded,
              onTap: _canSubmit ? _submit : null,
            ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                submit,
                const SizedBox(height: 8),
                cancel,
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                cancel,
                const SizedBox(width: 10),
                submit,
              ],
            ),
    );
  }
}

class TransferCrabForm extends StatelessWidget {
  const TransferCrabForm({
    super.key,
    required this.crab,
    required this.token,
    required this.currentBox,
    required this.areas,
    required this.rows,
    required this.boxes,
    required this.areaId,
    required this.rowId,
    required this.boxId,
    required this.areaLabel,
    required this.rowLabel,
    required this.boxLabel,
    required this.rowsLoading,
    required this.boxesLoading,
    required this.reason,
    required this.otherReason,
    required this.note,
    required this.target,
    required this.validity,
    required this.conflict,
    required this.error,
    required this.onArea,
    required this.onRow,
    required this.onBox,
    required this.onReason,
    required this.onRefreshBoxes,
    required this.onChanged,
  });

  final CrabIndividual crab;
  final String token;
  final BoxRecord? currentBox;
  final List<AreaRecord> areas;
  final List<RowRecord> rows;
  final List<BoxRecord> boxes;
  final String? areaId;
  final String? rowId;
  final String? boxId;
  final String areaLabel;
  final String rowLabel;
  final String boxLabel;
  final bool rowsLoading;
  final bool boxesLoading;
  final TransferReasonCode? reason;
  final TextEditingController otherReason;
  final TextEditingController note;
  final BoxRecord? target;
  final TargetBoxValidity? validity;
  final bool conflict;
  final String? error;
  final ValueChanged<String> onArea;
  final ValueChanged<String> onRow;
  final ValueChanged<String> onBox;
  final ValueChanged<TransferReasonCode> onReason;
  final VoidCallback onRefreshBoxes;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 720;
    final rowName = rows.where((r) => r.id == rowId).map((r) {
      return r.rowCode.trim().isNotEmpty ? r.rowCode : r.rowName;
    }).firstOrNull ?? crab.rowLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TransferCrabIdentityCard(crab: crab, token: token),
        const SizedBox(height: 16),
        CurrentBoxCard(crab: crab, box: currentBox),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Icon(Icons.south_rounded, color: DashboardColors.brand, size: 22),
          ),
        ),
        _stepTitle(2, 'Chọn hộp đích'),
        const SizedBox(height: 10),
        TargetLocationSelector(
          areas: areas,
          rows: rows,
          boxes: boxes,
          currentBoxId: crab.boxId,
          areaLabel: areaLabel,
          rowLabel: rowLabel,
          boxLabel: boxLabel,
          rowsLoading: rowsLoading,
          boxesLoading: boxesLoading,
          stack: narrow,
          onArea: onArea,
          onRow: onRow,
          onBox: onBox,
        ),
        if (rows.isEmpty && !rowsLoading && areaId != null)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: _Hint('Không có dãy trong khu vực này.'),
          ),
        if (rows.isNotEmpty &&
            !boxesLoading &&
            boxes.every((b) => targetBoxValidity(b, crab.boxId) != TargetBoxValidity.selectable))
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _Hint('Không có hộp trống phù hợp trong dãy $rowName.'),
          ),
        if (target != null) ...[
          const SizedBox(height: 12),
          TargetBoxPreview(box: target!, validity: validity ?? TargetBoxValidity.inactive),
        ],
        const SizedBox(height: 16),
        TransferReasonField(
          value: reason,
          other: otherReason,
          onChanged: onReason,
          onOther: onChanged,
        ),
        const SizedBox(height: 16),
        TransferNoteField(controller: note, onChanged: onChanged),
        const SizedBox(height: 12),
        TransferNotice(
          fromBox: currentBox?.boxCode ?? crab.boxLabel,
          toBox: target?.boxCode,
          crabCode: crab.code,
        ),
        if (conflict) ...[
          const SizedBox(height: 12),
          _ConflictBanner(message: error ?? 'Không thể chuyển hộp.', onRefresh: onRefreshBoxes),
        ] else if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!, style: bvText(fontSize: 12.5, color: DashboardColors.risk)),
        ],
      ],
    );
  }
}

class TransferCrabIdentityCard extends StatelessWidget {
  const TransferCrabIdentityCard({super.key, required this.crab, required this.token});

  final CrabIndividual crab;
  final String token;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.mint),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.set_meal_outlined, size: 16, color: DashboardColors.brand),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Cua: ${crab.code}',
                        style: bvText(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    CrabLifecycleBadge(status: crab.lifecycleStatus),
                    CrabHealthBadge(status: crab.displayHealth),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Loại: ${crab.crabType}  ·  Giới tính: ${crab.gender.label}',
                  style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: CrabAuthImage(
                crabId: crab.id,
                index: 0,
                token: token,
                width: 56,
                height: 56,
                error: Container(
                  color: Colors.white,
                  child: const Icon(Icons.set_meal_outlined, color: DashboardColors.brand),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CurrentBoxCard extends StatelessWidget {
  const CurrentBoxCard({super.key, required this.crab, required this.box});

  final CrabIndividual crab;
  final BoxRecord? box;

  @override
  Widget build(BuildContext context) {
    final area = crab.areaCode.trim().isNotEmpty ? crab.areaCode : crab.areaLabel;
    final row = (box?.rowCode ?? crab.rowLabel).trim().isEmpty ? crab.rowLabel : (box?.rowCode ?? crab.rowLabel);
    final code = box?.boxCode ?? crab.boxLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(1, 'Hộp hiện tại'),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.place_outlined, size: 16, color: DashboardColors.brand),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$area  ›  $row  ›  $code',
                style: bvText(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _InfoGrid(
          children: [
            _InfoCell(
              icon: Icons.circle,
              iconColor: DashboardColors.brand,
              label: 'Trạng thái',
              value: boxStatusLabel(box),
            ),
            _InfoCell(
              icon: Icons.inventory_2_outlined,
              label: 'Sức chứa',
              value: box == null || box!.hasCrab ? '1 / 1' : '0 / 1',
            ),
            _InfoCell(
              icon: Icons.set_meal_outlined,
              label: 'Cua hiện tại',
              value: crab.code,
            ),
            _InfoCell(
              icon: Icons.warning_amber_rounded,
              label: 'Cảnh báo',
              value: '${box?.alertCount ?? crab.alertCount}',
            ),
          ],
        ),
      ],
    );
  }
}

class TargetLocationSelector extends StatelessWidget {
  const TargetLocationSelector({
    super.key,
    required this.areas,
    required this.rows,
    required this.boxes,
    required this.currentBoxId,
    required this.areaLabel,
    required this.rowLabel,
    required this.boxLabel,
    required this.rowsLoading,
    required this.boxesLoading,
    required this.stack,
    required this.onArea,
    required this.onRow,
    required this.onBox,
  });

  final List<AreaRecord> areas;
  final List<RowRecord> rows;
  final List<BoxRecord> boxes;
  final String currentBoxId;
  final String areaLabel;
  final String rowLabel;
  final String boxLabel;
  final bool rowsLoading;
  final bool boxesLoading;
  final bool stack;
  final ValueChanged<String> onArea;
  final ValueChanged<String> onRow;
  final ValueChanged<String> onBox;

  @override
  Widget build(BuildContext context) {
    final areaField = _LabeledSelect<String>(
      label: 'Khu vực',
      required: true,
      valueLabel: areaLabel,
      loading: false,
      items: [
        for (final a in areas)
          _SelectItem(a.id, '${a.areaCode} — ${a.areaName}', enabled: true),
      ],
      onSelected: onArea,
    );
    final rowField = _LabeledSelect<String>(
      label: 'Dãy',
      required: true,
      valueLabel: rowLabel,
      loading: rowsLoading,
      items: [
        for (final r in rows)
          _SelectItem(
            r.id,
            r.rowName.trim().isEmpty ? r.rowCode : r.rowName,
            enabled: true,
          ),
      ],
      onSelected: onRow,
    );
    final boxField = _LabeledSelect<String>(
      label: 'Hộp đích',
      required: true,
      valueLabel: boxLabel,
      loading: boxesLoading,
      items: [
        for (final b in boxes)
          _SelectItem(
            b.id,
            targetBoxOptionLabel(b, targetBoxValidity(b, currentBoxId)),
            enabled: targetBoxValidity(b, currentBoxId) == TargetBoxValidity.selectable,
          ),
      ],
      onSelected: onBox,
    );

    if (stack) {
      return Column(
        children: [
          areaField,
          const SizedBox(height: 10),
          rowField,
          const SizedBox(height: 10),
          boxField,
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: areaField),
            const SizedBox(width: 10),
            Expanded(child: rowField),
          ],
        ),
        const SizedBox(height: 10),
        boxField,
      ],
    );
  }
}

class TargetBoxPreview extends StatelessWidget {
  const TargetBoxPreview({super.key, required this.box, required this.validity});

  final BoxRecord box;
  final TargetBoxValidity validity;

  @override
  Widget build(BuildContext context) {
    final ok = validity == TargetBoxValidity.selectable;
    final badgeColor = ok ? DashboardColors.brand : DashboardColors.risk;
    final badgeLabel = ok ? 'Có thể sử dụng' : 'Không thể sử dụng';
    final message = switch (validity) {
      TargetBoxValidity.occupied => 'Hộp này đang có cua. Vui lòng chọn hộp khác.',
      TargetBoxValidity.current => 'Đây là hộp hiện tại. Vui lòng chọn hộp khác.',
      TargetBoxValidity.alert => 'Hộp này đang có cảnh báo. Vui lòng chọn hộp khác.',
      TargetBoxValidity.inactive => 'Hộp này không hoạt động. Vui lòng chọn hộp khác.',
      TargetBoxValidity.selectable => null,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ok ? DashboardColors.mint : const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 18, color: badgeColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  box.boxCode,
                  style: bvText(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
              MgmtStatusBadge(label: badgeLabel, color: badgeColor),
            ],
          ),
          const SizedBox(height: 10),
          _InfoGrid(
            children: [
              _InfoCell(
                icon: Icons.circle,
                iconColor: ok ? DashboardColors.brand : DashboardColors.risk,
                label: 'Trạng thái',
                value: boxStatusLabel(box),
              ),
              _InfoCell(
                icon: Icons.inventory_2_outlined,
                label: 'Sức chứa',
                value: box.hasCrab ? '1 / 1' : '0 / 1',
              ),
              _InfoCell(
                icon: Icons.set_meal_outlined,
                label: 'Cua hiện tại',
                value: box.hasCrab ? (box.crabTag ?? 'Đã có cua') : 'Không có',
              ),
              _InfoCell(
                icon: Icons.warning_amber_rounded,
                label: 'Cảnh báo',
                value: '${box.alertCount}',
              ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(message, style: bvText(fontSize: 12.5, color: DashboardColors.risk)),
          ],
        ],
      ),
    );
  }
}

class TransferReasonField extends StatelessWidget {
  const TransferReasonField({
    super.key,
    required this.value,
    required this.other,
    required this.onChanged,
    required this.onOther,
  });

  final TransferReasonCode? value;
  final TextEditingController other;
  final ValueChanged<TransferReasonCode> onChanged;
  final VoidCallback onOther;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(3, 'Lý do chuyển hộp', required: true),
        const SizedBox(height: 8),
        _LabeledSelect<TransferReasonCode>(
          label: null,
          valueLabel: value?.label ?? 'Chọn lý do',
          items: [
            for (final r in TransferReasonCode.values) _SelectItem(r, r.label, enabled: true),
          ],
          onSelected: onChanged,
        ),
        if (value == TransferReasonCode.other) ...[
          const SizedBox(height: 10),
          Text(
            'Lý do khác *',
            style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: other,
            onChanged: (_) => onOther(),
            maxLines: 2,
            style: bvText(fontSize: 13, color: DashboardColors.textPrimary),
            decoration: _inputDeco('Nhập lý do chuyển hộp...'),
          ),
        ],
      ],
    );
  }
}

class TransferNoteField extends StatelessWidget {
  const TransferNoteField({super.key, required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(4, 'Ghi chú'),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          maxLength: 500,
          maxLines: 4,
          style: bvText(fontSize: 13, color: DashboardColors.textPrimary),
          decoration: _inputDeco('Nhập ghi chú về việc chuyển hộp...').copyWith(counterText: ''),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${controller.text.length} / 500',
            style: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class TransferNotice extends StatelessWidget {
  const TransferNotice({
    super.key,
    required this.fromBox,
    required this.toBox,
    required this.crabCode,
  });

  final String fromBox;
  final String? toBox;
  final String crabCode;

  @override
  Widget build(BuildContext context) {
    final dest = toBox ?? 'hộp đích';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF2495E8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sau khi chuyển, $fromBox sẽ trở thành Trống và $dest sẽ được cập nhật là đang nuôi $crabCode.',
              style: bvText(fontSize: 12.5, height: 1.45, color: DashboardColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class TransferCrabSummary extends StatelessWidget {
  const TransferCrabSummary({
    super.key,
    required this.crab,
    required this.currentBoxCode,
  });

  final CrabIndividual crab;
  final String currentBoxCode;

  @override
  Widget build(BuildContext context) {
    final days = DateTime.now().difference(crab.releaseDate).inDays;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: mgmtCardDeco(radius: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.set_meal_outlined, size: 16, color: DashboardColors.brand),
                  const SizedBox(width: 6),
                  Text(
                    'Thông tin cua',
                    style: bvText(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: DashboardColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _kv('Mã cua', crab.code),
              _kv('Loại cua', crab.crabType),
              _kv('Giới tính', crab.gender.label),
              _kv('Cân nặng', crab.weightLabel),
              _kv('Kích thước mai', crab.sizeLabel),
              _kv('Số lần lột xác', '${crab.moltCount}'),
              _kv('Ngày nhập trại', fmtDateVn(crab.releaseDate)),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  days < 0 ? '—' : '$days ngày trong hệ thống',
                  style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: mgmtCardDeco(radius: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF2495E8)),
                  const SizedBox(width: 6),
                  Text(
                    'Lưu ý',
                    style: bvText(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: DashboardColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _bullet('Chỉ có thể chọn các hộp đang hoạt động và chưa có cua.'),
              _bullet('Không thể chọn chính hộp hiện tại $currentBoxCode.'),
              _bullet('Sau khi chuyển, thông tin sẽ được cập nhật trong Lịch sử & Nhật ký.'),
              _bullet('Nếu hộp đích có cảnh báo hoặc lỗi, vui lòng chọn hộp khác.'),
              _bullet('Việc chuyển hộp sẽ được ghi lại với thời gian, người thực hiện, lý do và hộp trước/sau.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(k, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          ),
          Expanded(
            child: Text(
              v,
              style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: bvText(fontSize: 13, color: DashboardColors.textMuted)),
          Expanded(
            child: Text(text, style: bvText(fontSize: 12.5, height: 1.4, color: DashboardColors.textMuted)),
          ),
        ],
      ),
    );
  }
}

Future<bool?> showTransferConfirmDialog(
  BuildContext context, {
  required String crabCode,
  required String fromBox,
  required String toBox,
  required String reason,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: const Color.fromRGBO(15, 35, 30, 0.45),
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Xác nhận chuyển hộp?',
        style: bvText(fontSize: 17, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(crabCode, style: bvText(fontSize: 15, fontWeight: FontWeight.w800, color: DashboardColors.brand)),
          const SizedBox(height: 10),
          Text(fromBox, style: bvText(fontSize: 13.5, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Icon(Icons.south_rounded, size: 18, color: DashboardColors.brand),
          ),
          Text(toBox, style: bvText(fontSize: 13.5, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
          const SizedBox(height: 10),
          Text('Lý do: $reason', style: bvText(fontSize: 13, color: DashboardColors.textMuted)),
          const SizedBox(height: 10),
          Text('Sau khi chuyển:', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
          const SizedBox(height: 4),
          Text('• $fromBox → Trống', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          Text('• $toBox → Đang nuôi $crabCode', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
        ],
      ),
      actions: [
        MgmtOutlineButton(label: 'Hủy', onTap: () => Navigator.pop(ctx, false)),
        MgmtPrimaryButton(label: 'Xác nhận chuyển', height: 38, onTap: () => Navigator.pop(ctx, true)),
      ],
    ),
  );
}

class _ConflictBanner extends StatelessWidget {
  const _ConflictBanner({required this.message, required this.onRefresh});

  final String message;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Không thể chuyển hộp',
            style: bvText(fontSize: 13.5, fontWeight: FontWeight.w800, color: DashboardColors.risk),
          ),
          const SizedBox(height: 4),
          Text(message, style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary)),
          const SizedBox(height: 10),
          MgmtOutlineButton(label: 'Làm mới danh sách hộp', onTap: onRefresh),
        ],
      ),
    );
  }
}

class _SelectItem<T> {
  const _SelectItem(this.value, this.label, {required this.enabled});
  final T value;
  final String label;
  final bool enabled;
}

class _LabeledSelect<T> extends StatelessWidget {
  const _LabeledSelect({
    this.label,
    this.required = false,
    required this.valueLabel,
    required this.items,
    required this.onSelected,
    this.loading = false,
  });

  final String? label;
  final bool required;
  final String valueLabel;
  final List<_SelectItem<T>> items;
  final ValueChanged<T> onSelected;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text.rich(
            TextSpan(
              text: label,
              style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
              children: [
                if (required)
                  TextSpan(text: ' *', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.risk)),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        PopupMenuButton<T>(
          tooltip: '',
          enabled: !loading && items.isNotEmpty,
          offset: const Offset(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          onSelected: onSelected,
          itemBuilder: (_) => [
            for (final item in items)
              PopupMenuItem<T>(
                value: item.value,
                enabled: item.enabled,
                height: 38,
                child: Text(
                  item.label,
                  style: bvText(
                    fontSize: 13,
                    color: item.enabled ? DashboardColors.textPrimary : DashboardColors.textMuted,
                  ),
                ),
              ),
          ],
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DashboardColors.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    valueLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bvText(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: DashboardColors.textPrimary,
                    ),
                  ),
                ),
                if (loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: DashboardColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [
          for (final child in children)
            SizedBox(width: 140, child: child),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: iconColor ?? DashboardColors.textMuted),
            const SizedBox(width: 4),
            Text(label, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted));
  }
}

class _TransferSkeleton extends StatelessWidget {
  const _TransferSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.4),
      ),
    );
  }
}

Widget _stepTitle(int n, String title, {bool required = false}) {
  return Text.rich(
    TextSpan(
      text: '$n. $title',
      style: bvText(fontSize: 14, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
      children: [
        if (required)
          TextSpan(text: ' *', style: bvText(fontSize: 14, fontWeight: FontWeight.w800, color: DashboardColors.risk)),
      ],
    ),
  );
}

InputDecoration _inputDeco(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: bvText(fontSize: 13, color: DashboardColors.textMuted),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: DashboardColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: DashboardColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DashboardColors.brand, width: 1.4),
      ),
    );

class _EscIntent extends Intent {
  const _EscIntent();
}
