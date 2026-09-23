import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/crab_individual.dart';
import '../../../models/crab_profile.dart';
import '../../../models/crab_status.dart';
import '../../../services/crab_service.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';
import '../crab_auth_image.dart';
import '../crab_status_badge.dart';

const _kTypes = ['Cua biển', 'Cua xanh', 'Khác'];
const _kLifecycleEdit = [
  CrabLifecycleStatus.growing,
  CrabLifecycleStatus.molting,
  CrabLifecycleStatus.readyHarvest,
];

Future<bool> showEditCrabModal(
  BuildContext context,
  CrabService service, {
  required CrabIndividual crab,
  Future<void> Function()? onRecordMeasurement,
  Future<void> Function()? onMoveBox,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color.fromRGBO(15, 35, 30, 0.45),
    builder: (_) => EditCrabModal(
      service: service,
      initial: crab,
      onRecordMeasurement: onRecordMeasurement,
      onMoveBox: onMoveBox,
    ),
  );
  return saved == true;
}

class EditCrabModal extends StatefulWidget {
  const EditCrabModal({
    super.key,
    required this.service,
    required this.initial,
    this.onRecordMeasurement,
    this.onMoveBox,
  });

  final CrabService service;
  final CrabIndividual initial;
  final Future<void> Function()? onRecordMeasurement;
  final Future<void> Function()? onMoveBox;

  @override
  State<EditCrabModal> createState() => _EditCrabModalState();
}

class _EditCrabModalState extends State<EditCrabModal> {
  late CrabIndividual _crab = widget.initial;
  late String _type = _normType(widget.initial.crabType);
  late CrabGender _gender = widget.initial.gender;
  late CrabDevelopmentStage _stage = _normStage(widget.initial.developmentStage);
  late CrabDisplayHealth _health = widget.initial.displayHealth;
  late CrabLifecycleStatus _life = _normLife(widget.initial.lifecycleStatus);
  late final TextEditingController _note = TextEditingController(text: widget.initial.quickNote);

  var _loading = true;
  var _saving = false;
  String? _loadError;
  String? _saveError;
  String? _typeError;
  String? _genderError;
  String? _stageError;
  String? _healthError;
  String? _lifeError;

  CrabService get _svc => widget.service;

  String get _initNote => widget.initial.quickNote;
  bool get _dirty =>
      _type != _normType(widget.initial.crabType) ||
      _gender != widget.initial.gender ||
      _stage != _normStage(widget.initial.developmentStage) ||
      _health != widget.initial.displayHealth ||
      _life != _normLife(widget.initial.lifecycleStatus) ||
      _note.text.trim() != _initNote.trim();

  static String _normType(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return 'Cua biển';
    return t;
  }

  static CrabDevelopmentStage _normStage(CrabDevelopmentStage s) {
    if (CrabDevelopmentStage.editOptions.contains(s)) return s;
    if (s == CrabDevelopmentStage.preHarvest) return CrabDevelopmentStage.harvestReady;
    return CrabDevelopmentStage.growing;
  }

  static CrabLifecycleStatus _normLife(CrabLifecycleStatus s) {
    if (_kLifecycleEdit.contains(s)) return s;
    return CrabLifecycleStatus.growing;
  }

  @override
  void initState() {
    super.initState();
    _refresh(initial: true);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool initial = false}) async {
    setState(() {
      if (initial || _crab.id.isEmpty) _loading = true;
      _loadError = null;
    });
    try {
      await _svc.loadDetail(widget.initial.id);
      final next = _svc.getById(widget.initial.id) ?? widget.initial;
      if (!mounted) return;
      setState(() {
        _crab = next;
        if (!_dirty) {
          _type = _normType(next.crabType);
          _gender = next.gender;
          _stage = _normStage(next.developmentStage);
          _health = next.displayHealth;
          _life = _normLife(next.lifecycleStatus);
          _note.text = next.quickNote;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = '$e';
      });
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Bạn có thay đổi chưa được lưu.',
          style: bvText(fontSize: 16, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
        ),
        actions: [
          MgmtOutlineButton(label: 'Tiếp tục chỉnh sửa', onTap: () => Navigator.pop(ctx, false)),
          MgmtPrimaryButton(label: 'Bỏ thay đổi', height: 38, onTap: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    return r == true;
  }

  Future<void> _close() async {
    if (_saving) return;
    if (!await _confirmDiscard()) return;
    if (mounted) Navigator.pop(context, false);
  }

  bool _validate() {
    setState(() {
      _typeError = _type.trim().isEmpty ? 'Chọn loại cua.' : null;
      _genderError = null;
      _stageError = null;
      _healthError = null;
      _lifeError = _kLifecycleEdit.contains(_life) ? null : 'Chọn trạng thái.';
    });
    return _typeError == null && _lifeError == null;
  }

  Future<void> _save() async {
    if (_saving || !_dirty || !_validate()) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final next = _crab.copyWith(
      crabType: _type.trim(),
      gender: _gender,
      developmentStage: _stage,
      healthStatus: switch (_health) {
        CrabDisplayHealth.healthy => CrabHealthStatus.healthy,
        CrabDisplayHealth.monitoring => CrabHealthStatus.monitoring,
        CrabDisplayHealth.weak || CrabDisplayHealth.alert => CrabHealthStatus.atRisk,
      },
      lifecycleStatus: _life,
      lifeStatus: CrabLifeStatus.raising,
      quickNote: _note.text.trim(),
      updatedAt: DateTime.now(),
    );
    final ok = await _svc.updateCrabProfile(next);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _saving = false;
        _saveError = _svc.error ?? 'Không thể lưu thay đổi.';
      });
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _measure() async {
    await widget.onRecordMeasurement?.call();
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _move() async {
    if (!await _confirmDiscard()) return;
    if (!mounted) return;
    Navigator.pop(context, false);
    await widget.onMoveBox?.call();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040, maxHeight: 820),
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
                  Expanded(
                    child: _loading
                        ? const _EditSkeleton()
                        : _loadError != null
                            ? Center(
                                child: MgmtEmptyState(
                                  icon: Icons.error_outline_rounded,
                                  title: 'Không thể tải thông tin cua.',
                                  message: _loadError!,
                                  action: MgmtPrimaryButton(label: 'Thử lại', height: 38, onTap: _refresh),
                                ),
                              )
                            : wide
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 65,
                                        child: SingleChildScrollView(
                                          padding: const EdgeInsets.fromLTRB(22, 16, 12, 16),
                                          child: CrabBasicEditForm(
                                            crab: _crab,
                                            type: _type,
                                            types: _typeOptions,
                                            gender: _gender,
                                            stage: _stage,
                                            health: _health,
                                            life: _life,
                                            note: _note,
                                            typeError: _typeError,
                                            genderError: _genderError,
                                            stageError: _stageError,
                                            healthError: _healthError,
                                            lifeError: _lifeError,
                                            onType: (v) => setState(() => _type = v),
                                            onGender: (v) => setState(() => _gender = v),
                                            onStage: (v) => setState(() => _stage = v),
                                            onHealth: (v) => setState(() => _health = v),
                                            onLife: (v) => setState(() => _life = v),
                                            onNote: (_) => setState(() {}),
                                            onRecordMeasurement: widget.onRecordMeasurement == null ? null : _measure,
                                            onMoveBox: widget.onMoveBox == null ? null : _move,
                                          ),
                                        ),
                                      ),
                                      Container(width: 1, color: DashboardColors.mint),
                                      Expanded(
                                        flex: 35,
                                        child: SingleChildScrollView(
                                          padding: const EdgeInsets.fromLTRB(14, 16, 18, 16),
                                          child: CrabEditSummaryPanel(
                                            crab: _crab,
                                            profile: _svc.profileOf(_crab.id),
                                            token: _svc.token,
                                            type: _type,
                                            gender: _gender,
                                            health: _health,
                                            life: _life,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                                    child: Column(
                                      children: [
                                        CrabBasicEditForm(
                                          crab: _crab,
                                          type: _type,
                                          types: _typeOptions,
                                          gender: _gender,
                                          stage: _stage,
                                          health: _health,
                                          life: _life,
                                          note: _note,
                                          typeError: _typeError,
                                          genderError: _genderError,
                                          stageError: _stageError,
                                          healthError: _healthError,
                                          lifeError: _lifeError,
                                          onType: (v) => setState(() => _type = v),
                                          onGender: (v) => setState(() => _gender = v),
                                          onStage: (v) => setState(() => _stage = v),
                                          onHealth: (v) => setState(() => _health = v),
                                          onLife: (v) => setState(() => _life = v),
                                          onNote: (_) => setState(() {}),
                                          onRecordMeasurement: widget.onRecordMeasurement == null ? null : _measure,
                                          onMoveBox: widget.onMoveBox == null ? null : _move,
                                        ),
                                        const SizedBox(height: 14),
                                        CrabEditSummaryPanel(
                                          crab: _crab,
                                          profile: _svc.profileOf(_crab.id),
                                          token: _svc.token,
                                          type: _type,
                                          gender: _gender,
                                          health: _health,
                                          life: _life,
                                        ),
                                      ],
                                    ),
                                  ),
                  ),
                  const Divider(height: 1, color: DashboardColors.mint),
                  _footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> get _typeOptions {
    final list = [..._kTypes];
    if (!list.contains(_type)) list.insert(0, _type);
    return list;
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 10, 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: DashboardColors.mint, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.edit_outlined, color: DashboardColors.brand, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cập nhật thông tin cua',
                  style: bvText(fontSize: 22, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
                ),
                Text(
                  'Cập nhật thông tin cơ bản và tình trạng của cua.',
                  style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _saving ? null : _close,
            icon: Icon(Icons.close_rounded, color: DashboardColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      child: Row(
        children: [
          if (_saveError != null)
            Expanded(
              child: Text(
                '⚠ $_saveError Vui lòng thử lại.',
                style: bvText(fontSize: 12.5, color: DashboardColors.risk),
              ),
            )
          else
            const Spacer(),
          MgmtOutlineButton(label: 'Hủy', onTap: _saving ? null : _close),
          const SizedBox(width: 10),
          MgmtPrimaryButton(
            label: _saving ? 'Đang lưu...' : 'Lưu thay đổi',
            icon: _saving ? Icons.hourglass_top_rounded : Icons.check_rounded,
            height: 40,
            onTap: (!_dirty || _saving || _loading) ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _EscIntent extends Intent {
  const _EscIntent();
}

class CrabBasicEditForm extends StatelessWidget {
  const CrabBasicEditForm({
    super.key,
    required this.crab,
    required this.type,
    required this.types,
    required this.gender,
    required this.stage,
    required this.health,
    required this.life,
    required this.note,
    this.typeError,
    this.genderError,
    this.stageError,
    this.healthError,
    this.lifeError,
    required this.onType,
    required this.onGender,
    required this.onStage,
    required this.onHealth,
    required this.onLife,
    required this.onNote,
    this.onRecordMeasurement,
    this.onMoveBox,
  });

  final CrabIndividual crab;
  final String type;
  final List<String> types;
  final CrabGender gender;
  final CrabDevelopmentStage stage;
  final CrabDisplayHealth health;
  final CrabLifecycleStatus life;
  final TextEditingController note;
  final String? typeError;
  final String? genderError;
  final String? stageError;
  final String? healthError;
  final String? lifeError;
  final ValueChanged<String> onType;
  final ValueChanged<CrabGender> onGender;
  final ValueChanged<CrabDevelopmentStage> onStage;
  final ValueChanged<CrabDisplayHealth> onHealth;
  final ValueChanged<CrabLifecycleStatus> onLife;
  final ValueChanged<String> onNote;
  final VoidCallback? onRecordMeasurement;
  final VoidCallback? onMoveBox;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _card(
          icon: Icons.info_outline_rounded,
          title: 'Thông tin cơ bản',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _readonlyField(
                label: 'Mã cua',
                value: crab.code,
                locked: true,
                helper: 'Mã cua do hệ thống tạo và không thể thay đổi.',
              ),
              const SizedBox(height: 12),
              LayoutBuilder(builder: (context, c) {
                final stack = c.maxWidth < 520;
                final typeField = _select<String>(
                  label: 'Loại cua *',
                  value: type,
                  items: [for (final t in types) (t, t)],
                  onChanged: onType,
                  error: typeError,
                );
                final genderField = _select<CrabGender>(
                  label: 'Giới tính *',
                  value: gender,
                  items: [for (final g in CrabGender.values) (g, g.label)],
                  onChanged: onGender,
                  error: genderError,
                );
                if (stack) {
                  return Column(children: [typeField, const SizedBox(height: 12), genderField]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: typeField),
                    const SizedBox(width: 12),
                    Expanded(child: genderField),
                  ],
                );
              }),
              const SizedBox(height: 12),
              _select<CrabDevelopmentStage>(
                label: 'Giai đoạn phát triển *',
                value: stage,
                items: [for (final s in CrabDevelopmentStage.editOptions) (s, s.label)],
                onChanged: onStage,
                helper: 'Chọn giai đoạn phát triển hiện tại của cua.',
                error: stageError,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CrabStatusEditForm(
          health: health,
          life: life,
          healthError: healthError,
          lifeError: lifeError,
          onHealth: onHealth,
          onLife: onLife,
        ),
        const SizedBox(height: 12),
        CrabLatestGrowthSummary(crab: crab, onRecord: onRecordMeasurement),
        const SizedBox(height: 12),
        CrabOriginLocationSummary(crab: crab, onMove: onMoveBox),
        const SizedBox(height: 12),
        CrabNoteField(controller: note, onChanged: onNote),
      ],
    );
  }
}

class CrabStatusEditForm extends StatelessWidget {
  const CrabStatusEditForm({
    super.key,
    required this.health,
    required this.life,
    this.healthError,
    this.lifeError,
    required this.onHealth,
    required this.onLife,
  });

  final CrabDisplayHealth health;
  final CrabLifecycleStatus life;
  final String? healthError;
  final String? lifeError;
  final ValueChanged<CrabDisplayHealth> onHealth;
  final ValueChanged<CrabLifecycleStatus> onLife;

  @override
  Widget build(BuildContext context) {
    return _card(
      icon: Icons.favorite_rounded,
      title: 'Tình trạng',
      child: LayoutBuilder(builder: (context, c) {
        final stack = c.maxWidth < 520;
        final healthField = _select<CrabDisplayHealth>(
          label: 'Tình trạng sức khỏe *',
          value: health,
          items: [for (final h in CrabDisplayHealth.values) (h, h.label)],
          onChanged: onHealth,
          error: healthError,
        );
        final lifeField = _select<CrabLifecycleStatus>(
          label: 'Trạng thái *',
          value: life,
          items: [for (final s in _kLifecycleEdit) (s, s.label)],
          onChanged: onLife,
          error: lifeError,
        );
        if (stack) {
          return Column(children: [healthField, const SizedBox(height: 12), lifeField]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: healthField),
            const SizedBox(width: 12),
            Expanded(child: lifeField),
          ],
        );
      }),
    );
  }
}

class CrabLatestGrowthSummary extends StatelessWidget {
  const CrabLatestGrowthSummary({super.key, required this.crab, this.onRecord});

  final CrabIndividual crab;
  final VoidCallback? onRecord;

  @override
  Widget build(BuildContext context) {
    final at = _lastMeasure(crab);
    return _card(
      icon: Icons.trending_up_rounded,
      title: 'Thông tin sinh trưởng gần nhất',
      trailing: onRecord == null
          ? null
          : MgmtOutlineButton(label: 'Ghi nhận số đo mới', icon: Icons.add_rounded, onTap: onRecord, height: 34),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _metric(Icons.monitor_weight_outlined, 'Cân nặng', crab.weightLabel, at)),
              const SizedBox(width: 12),
              Expanded(child: _metric(Icons.straighten_rounded, 'Kích thước mai', crab.sizeLabel, at)),
            ],
          ),
          const SizedBox(height: 12),
          const CrabEditNotice(
            text: 'Để cập nhật cân nặng hoặc kích thước mới, vui lòng sử dụng chức năng “Ghi nhận sinh trưởng” tại tab Sinh trưởng & Lột xác.',
          ),
        ],
      ),
    );
  }
}

class CrabOriginLocationSummary extends StatelessWidget {
  const CrabOriginLocationSummary({super.key, required this.crab, this.onMove});

  final CrabIndividual crab;
  final VoidCallback? onMove;

  @override
  Widget build(BuildContext context) {
    return _card(
      icon: Icons.place_outlined,
      title: 'Nguồn gốc & vị trí hiện tại',
      trailing: onMove == null
          ? null
          : MgmtOutlineButton(label: 'Chuyển hộp', icon: Icons.swap_horiz_rounded, onTap: onMove, height: 34),
      child: Column(
        children: [
          _readonlyField(label: 'Lô cua', value: crab.batchId.isEmpty ? '—' : crab.batchId, locked: true),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _readonlyField(
                  label: 'Ngày nhập trại',
                  value: fmtDateVn(crab.releaseDate),
                  helper: '${crab.ageDays} ngày trong hệ thống',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _readonlyField(
                  label: 'Vị trí hiện tại',
                  value: [crab.areaCode, crab.rowLabel, crab.boxLabel].where((e) => e.trim().isNotEmpty && e != '—').join('  >  '),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CrabNoteField extends StatelessWidget {
  const CrabNoteField({super.key, required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _card(
      icon: Icons.notes_rounded,
      title: 'Ghi chú',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: controller,
            onChanged: onChanged,
            maxLength: 500,
            maxLines: 4,
            style: bvText(fontSize: 13, color: DashboardColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Nhập ghi chú về tình trạng hoặc đặc điểm của cua...',
              hintStyle: bvText(fontSize: 13, color: DashboardColors.textMuted),
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DashboardColors.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DashboardColors.cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DashboardColors.brand, width: 1.4)),
            ),
          ),
          Text('${controller.text.length} / 500', style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
        ],
      ),
    );
  }
}

class CrabEditSummaryPanel extends StatelessWidget {
  const CrabEditSummaryPanel({
    super.key,
    required this.crab,
    required this.token,
    this.profile,
    required this.type,
    required this.gender,
    required this.health,
    required this.life,
  });

  final CrabIndividual crab;
  final String token;
  final CrabProfile? profile;
  final String type;
  final CrabGender gender;
  final CrabDisplayHealth health;
  final CrabLifecycleStatus life;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: mgmtCardDeco(radius: 14),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  child: CrabAuthImage(
                  crabId: crab.id,
                  index: 0,
                  token: token,
                  fallbackUrl: profile?.avatarUrl ?? profile?.imageUrls.firstOrNull,
                  height: 140,
                  fit: BoxFit.cover,
                  error: const ColoredBox(
                    color: DashboardColors.lightMint,
                    child: Icon(Icons.set_meal_rounded, size: 48, color: DashboardColors.brand),
                  ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  CrabLifecycleBadge(status: life),
                  CrabHealthBadge(status: health),
                ],
              ),
              const SizedBox(height: 8),
              Text(crab.code, style: bvText(fontSize: 18, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
              Text(
                '$type  •  Giới tính: ${gender.label}',
                style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
              Text('Thông số hiện tại', style: bvText(fontSize: 13.5, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
              const SizedBox(height: 10),
              _sideRow(Icons.monitor_weight_outlined, 'Cân nặng', crab.weightLabel, 'Cập nhật ${fmtDateVn(_lastMeasure(crab))}'),
              _sideRow(Icons.straighten_rounded, 'Kích thước mai', crab.sizeLabel, 'Cập nhật ${fmtDateVn(_lastMeasure(crab))}'),
              _sideRow(Icons.autorenew_rounded, 'Số lần lột xác', '${crab.moltCount}', null),
              _sideRow(Icons.event_outlined, 'Ngày nhập trại', fmtDateVn(crab.releaseDate), '${crab.ageDays} ngày trong hệ thống'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const CrabEditNotice(
          title: 'Lưu ý',
          lines: [
            'Mã cua, lô cua và ngày nhập trại không thể thay đổi.',
            'Cân nặng và kích thước được cập nhật tại tab Sinh trưởng & Lột xác.',
            'Chuyển hộp sử dụng chức năng riêng.',
            'Việc thay đổi sức khỏe hoặc giai đoạn sẽ được ghi nhận trong Lịch sử & Nhật ký.',
            'Đánh dấu thu hoạch hoặc cua chết sử dụng quy trình chuyên biệt.',
          ],
        ),
      ],
    );
  }
}

class CrabEditNotice extends StatelessWidget {
  const CrabEditNotice({super.key, this.title, this.text, this.lines});

  final String? title;
  final String? text;
  final List<String>? lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8E9E4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF2495E8)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(title!, style: bvText(fontSize: 13, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
                  ),
                if (text != null) Text(text!, style: bvText(fontSize: 12, height: 1.45, color: DashboardColors.textPrimary)),
                if (lines != null)
                  for (final l in lines!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $l', style: bvText(fontSize: 12, height: 1.4, color: DashboardColors.textPrimary)),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditSkeleton extends StatelessWidget {
  const _EditSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box({double h = 88}) => Container(
          height: h,
          decoration: BoxDecoration(color: DashboardColors.mint, borderRadius: BorderRadius.circular(14)),
        );
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Expanded(flex: 65, child: Column(children: [box(h: 160), const SizedBox(height: 12), box(), const SizedBox(height: 12), box()])),
          const SizedBox(width: 14),
          Expanded(flex: 35, child: Column(children: [box(h: 180), const SizedBox(height: 12), box(h: 160)])),
        ],
      ),
    );
  }
}

Widget _card({
  required IconData icon,
  required String title,
  required Widget child,
  Widget? trailing,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
    decoration: mgmtCardDeco(radius: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: DashboardColors.brand),
            const SizedBox(width: 7),
            Expanded(
              child: Text(title, style: bvText(fontSize: 13.5, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
            ),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

Widget _readonlyField({
  required String label,
  required String value,
  bool locked = false,
  String? helper,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: bvText(fontSize: 12, fontWeight: FontWeight.w600, color: DashboardColors.textMuted)),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: DashboardColors.lightMint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DashboardColors.cardBorder),
        ),
        child: Row(
          children: [
            if (locked) ...[
              Icon(Icons.lock_outline_rounded, size: 14, color: DashboardColors.textMuted),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(value, style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
            ),
          ],
        ),
      ),
      if (helper != null) ...[
        const SizedBox(height: 4),
        Text(helper, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
      ],
    ],
  );
}

Widget _select<T>({
  required String label,
  required T value,
  required List<(T, String)> items,
  required ValueChanged<T> onChanged,
  String? helper,
  String? error,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: bvText(fontSize: 12, fontWeight: FontWeight.w600, color: DashboardColors.textMuted)),
      const SizedBox(height: 6),
      MgmtDropdown<T>(
        valueLabel: items.where((e) => e.$1 == value).map((e) => e.$2).firstOrNull ?? '$value',
        items: items,
        onSelected: onChanged,
      ),
      if (helper != null) ...[
        const SizedBox(height: 4),
        Text(helper, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
      ],
      if (error != null) ...[
        const SizedBox(height: 4),
        Text(error, style: bvText(fontSize: 11.5, color: DashboardColors.risk)),
      ],
    ],
  );
}

Widget _metric(IconData icon, String label, String value, DateTime? at) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: DashboardColors.lightMint,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: DashboardColors.cardBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: DashboardColors.brand),
            const SizedBox(width: 6),
            Text(label, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: bvText(fontSize: 18, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
        Text('Cập nhật: ${fmtDateVn(at)}', style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
      ],
    ),
  );
}

Widget _sideRow(IconData icon, String label, String value, String? sub) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: DashboardColors.brand),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
              Text(value, style: bvText(fontSize: 14, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
              if (sub != null) Text(sub, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
            ],
          ),
        ),
      ],
    ),
  );
}

DateTime? _lastMeasure(CrabIndividual crab) {
  if (crab.weightHistory.isNotEmpty) return crab.weightHistory.last.date;
  if (crab.healthLogs.isNotEmpty) return crab.healthLogs.last.recordedAt;
  return crab.updatedAt ?? crab.releaseDate;
}
