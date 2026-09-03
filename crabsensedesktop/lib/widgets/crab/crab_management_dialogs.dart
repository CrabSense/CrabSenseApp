import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_crab_data.dart';
import '../../models/crab_individual.dart';
import '../../models/crab_status.dart';
import '../../services/crab_service.dart';
import '../../theme/dashboard_theme.dart';

Future<void> showCrabManagementFormDialog(
  BuildContext context,
  CrabService service, {
  CrabIndividual? existing,
}) async {
  final isEdit = existing != null;
  final formKey = GlobalKey<FormState>();
  var batchChoices = List<CrabBatchChoice>.from(service.batchChoices);
  if (!isEdit && batchChoices.isEmpty) {
    final created = await service.ensureDefaultLot();
    batchChoices = List<CrabBatchChoice>.from(service.batchChoices);
    if (created == null && batchChoices.isEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(service.error ?? 'Không tạo được lô cua')),
      );
      return;
    }
  }

  final codeCtrl = TextEditingController(text: existing?.code ?? '');
  final weightCtrl = TextEditingController(text: '${existing?.weightGram.toStringAsFixed(0) ?? '50'}');
  final shellCtrl = TextEditingController(text: '${existing?.shellSizeCm.toStringAsFixed(1) ?? '3.0'}');
  final noteCtrl = TextEditingController(text: existing?.quickNote ?? '');
  var selectedBatch = batchChoices.isNotEmpty
      ? batchChoices.firstWhere(
          (b) => b.batchCode == existing?.batchId,
          orElse: () => batchChoices.first,
        )
      : null;
  var gender = existing?.gender ?? CrabGender.male;
  var health = existing?.healthStatus ?? CrabHealthStatus.healthy;
  var life = existing?.lifeStatus ?? CrabLifeStatus.raising;
  var stage = existing?.developmentStage ?? CrabDevelopmentStage.growing;

  if (!isEdit && selectedBatch != null) {
    final next = await service.generateNextCodeForBatch(selectedBatch.batchId);
    if (next != null && next.isNotEmpty) codeCtrl.text = next;
  }

  if (!context.mounted) return;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: DashboardColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEdit ? 'Cập nhật Cua' : 'Thêm Cua',
          style: GoogleFonts.notoSans(
            color: DashboardColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isEdit && batchChoices.isNotEmpty)
                    _dropdown(
                      'Lô cua',
                      selectedBatch!.batchId,
                      batchChoices.map((b) => b.batchId).toList(),
                      (v) {
                        final pick = batchChoices.firstWhere(
                          (b) => b.batchId == v,
                          orElse: () => batchChoices.first,
                        );
                        setS(() => selectedBatch = pick);
                      },
                      labels: {
                        for (final b in batchChoices) b.batchId: b.label,
                      },
                    )
                  else if (isEdit)
                    _readOnlyTile('Lô cua', existing!.batchId),
                  _field(codeCtrl, 'Mã cua', required: true),
                  _enumDropdown('Giới tính', gender, CrabGender.values, (v) => setS(() => gender = v!), (g) => g.label),
                  _field(weightCtrl, 'Cân nặng (g)', keyboard: TextInputType.number),
                  _field(shellCtrl, 'Kích thước mai (cm)', keyboard: const TextInputType.numberWithOptions(decimal: true)),
                  _enumDropdown('Giai đoạn phát triển', stage, CrabDevelopmentStage.values, (v) => setS(() => stage = v!), (s) => s.label),
                  _enumDropdown('Tình trạng sức khỏe', health, CrabHealthStatus.values, (v) => setS(() => health = v!), (s) => s.label),
                  _enumDropdown('Trạng thái', life, CrabLifeStatus.values, (v) => setS(() => life = v!), (s) => s.label),
                  _field(noteCtrl, 'Ghi chú', maxLines: 2),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx, true);
            },
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.oceanBlue),
            child: const Text('Lưu'),
          ),
        ],
      ),
    ),
  );

  if (ok != true || !context.mounted) return;

  final weight = double.tryParse(weightCtrl.text) ?? 50;
  final shell = double.tryParse(shellCtrl.text) ?? 3;
  final note = noteCtrl.text.trim();

  bool success;
  if (isEdit) {
    success = await service.updateCrab(
      existing!.copyWith(
        displayCode: codeCtrl.text.trim(),
        gender: gender,
        weightGram: weight,
        shellSizeCm: shell,
        developmentStage: stage,
        healthStatus: health,
        lifeStatus: life,
        quickNote: note,
        updatedAt: DateTime.now(),
      ),
    );
  } else {
    success = await service.addCrab(
      batchId: selectedBatch!.batchId,
      crabCode: codeCtrl.text.trim(),
      gender: gender,
      weightGram: weight,
      shellSizeCm: shell,
      healthStatus: health,
      lifeStatus: life,
      developmentStage: stage,
      note: note.isEmpty ? null : note,
    );
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (isEdit ? 'Đã cập nhật cua' : 'Đã thêm cua mới')
              : (service.error ?? 'Lỗi lưu cua'),
        ),
      ),
    );
  }
}

Future<void> showRecordHealthDialog(
  BuildContext context,
  CrabService service,
  CrabIndividual crab,
) async {
  final formKey = GlobalKey<FormState>();
  final weightCtrl = TextEditingController(text: crab.weightGram.toStringAsFixed(0));
  final shellCtrl = TextEditingController(text: crab.shellSizeCm.toStringAsFixed(1));
  final shellCondCtrl = TextEditingController(text: 'Bình thường');
  final diseaseCtrl = TextEditingController(text: 'Không');
  final noteCtrl = TextEditingController();
  var recordedAt = DateTime.now();

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Ghi nhận sức khỏe', style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(weightCtrl, 'Cân nặng hiện tại (g)', keyboard: TextInputType.number),
              _field(shellCtrl, 'Kích thước mai hiện tại (cm)', keyboard: const TextInputType.numberWithOptions(decimal: true)),
              _field(shellCondCtrl, 'Tình trạng mai'),
              _field(diseaseCtrl, 'Tình trạng bệnh'),
              _field(noteCtrl, 'Ghi chú', maxLines: 2),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Thời gian ghi nhận', style: GoogleFonts.notoSans(fontSize: 12, color: DashboardColors.textMuted)),
                subtitle: Text(MockCrabData.formatDate(recordedAt)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: recordedAt,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (d != null) {
                      recordedAt = DateTime(d.year, d.month, d.day, recordedAt.hour, recordedAt.minute);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(ctx, true);
          },
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.seaGreen),
          child: const Text('Lưu'),
        ),
      ],
    ),
  );

  if (ok == true) {
    final success = await service.recordHealth(
      crab.id,
      weightGram: double.tryParse(weightCtrl.text) ?? crab.weightGram,
      shellSizeCm: double.tryParse(shellCtrl.text) ?? crab.shellSizeCm,
      shellCondition: shellCondCtrl.text.trim(),
      diseaseNote: diseaseCtrl.text.trim(),
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      recordedAt: recordedAt,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Đã ghi nhận sức khỏe' : (service.error ?? 'Lỗi')),
        ),
      );
    }
  }
}

Future<void> showRecordMoltDialog(
  BuildContext context,
  CrabService service,
  CrabIndividual crab,
) async {
  final noteCtrl = TextEditingController();
  var moltDate = DateTime.now();
  var moltCount = crab.moltCount + 1;
  var condition = MoltCondition.normal;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: DashboardColors.card,
        title: Text('Ghi nhận lột xác', style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ngày lột xác'),
                subtitle: Text(MockCrabData.formatDate(moltDate)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: moltDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setS(() => moltDate = d);
                  },
                ),
              ),
              _dropdown(
                'Số lần lột xác',
                '$moltCount',
                List.generate(8, (i) => '${i + 1}'),
                (v) => setS(() => moltCount = int.parse(v!)),
              ),
              _enumDropdown('Tình trạng sau lột', condition, MoltCondition.values, (v) => setS(() => condition = v!), (c) => c.label),
              _field(noteCtrl, 'Ghi chú', maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.molting),
            child: const Text('Lưu'),
          ),
        ],
      ),
    ),
  );

  if (ok == true) {
    final success = await service.recordMolt(
      crab.id,
      date: moltDate,
      moltCount: moltCount,
      condition: condition,
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Đã ghi nhận lột xác' : (service.error ?? 'Lỗi')),
        ),
      );
    }
  }
}

Future<bool> confirmCrabAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Xác nhận',
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(title, style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
      content: Text(message, style: GoogleFonts.notoSans(color: DashboardColors.textMuted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: danger ? DashboardColors.risk : DashboardColors.oceanBlue,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return r == true;
}

Widget _readOnlyTile(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: DashboardColors.darkNavy.withValues(alpha: 0.35),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        value,
        style: GoogleFonts.notoSans(color: DashboardColors.cyan, fontSize: 13),
      ),
    ),
  );
}

Widget _field(
  TextEditingController ctrl,
  String label, {
  bool required = false,
  int maxLines = 1,
  TextInputType? keyboard,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      inputFormatters: keyboard == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null
          : null,
      style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: DashboardColors.darkNavy.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}

Widget _dropdown(
  String label,
  String value,
  List<String> items,
  ValueChanged<String?> onChanged, {
  Map<String, String>? labels,
}) {
  final opts = <String>[];
  final seen = <String>{};
  for (final e in items) {
    if (seen.add(e)) opts.add(e);
  }
  if (opts.isEmpty) return const SizedBox.shrink();
  final selected = opts.contains(value) ? value : opts.first;
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      isExpanded: true,
      value: selected,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: DashboardColors.darkNavy.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dropdownColor: DashboardColors.card,
      items: opts
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                labels?[e] ?? e,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    ),
  );
}

Widget _enumDropdown<T>(
  String label,
  T value,
  List<T> items,
  ValueChanged<T?> onChanged,
  String Function(T) labelOf,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<T>(
      isExpanded: true,
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: DashboardColors.darkNavy.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dropdownColor: DashboardColors.card,
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                labelOf(e),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    ),
  );
}
