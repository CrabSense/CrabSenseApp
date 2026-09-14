import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/app_formatters.dart';
import '../../models/crab_individual.dart';
import '../../models/crab_status.dart';
import '../../services/crab_service.dart';
import '../../theme/dashboard_theme.dart';
import 'crab_management_dialogs.dart';

Future<void> showAddCrabDialog(BuildContext context, CrabService service) =>
    showCrabManagementFormDialog(context, service);

Future<void> showUpdateWeightDialog(BuildContext context, CrabService service, CrabIndividual crab) async {
  final formKey = GlobalKey<FormState>();
  final weightCtrl = TextEditingController(text: crab.weightGram.toStringAsFixed(0));
  final shellCtrl = TextEditingController(text: crab.shellSizeCm.toStringAsFixed(1));
  final noteCtrl = TextEditingController();
  var date = DateTime.now();

  await _confirmDialog(
    context,
    title: 'Cập nhật cân nặng',
    subtitle: crab.id,
    child: Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _readOnly('Mã cua', crab.id),
          _field(weightCtrl, 'Trọng lượng mới (gram)', isNumber: true),
          _field(shellCtrl, 'Kích thước mai (cm)', isNumber: true),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Ngày đo: ${formatDate(date)}', style: GoogleFonts.notoSans(fontSize: 12)),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: crab.releaseDate,
                  lastDate: DateTime.now(),
                );
                if (picked != null) date = picked;
              },
              child: const Text('Chọn'),
            ),
          ),
          _field(noteCtrl, 'Ghi chú', required: false),
        ],
      ),
    ),
    onSave: () {
      if (!formKey.currentState!.validate()) return false;
      service.updateWeight(
        crab.id,
        weightGram: double.parse(weightCtrl.text),
        shellSizeCm: double.parse(shellCtrl.text),
        measuredAt: date,
        note: noteCtrl.text,
      );
      return true;
    },
  );
  weightCtrl.dispose();
  shellCtrl.dispose();
  noteCtrl.dispose();
}

Future<void> showRecordMoltDialog(BuildContext context, CrabService service, CrabIndividual crab) async {
  final noteCtrl = TextEditingController();
  var date = DateTime.now();
  var condition = MoltCondition.normal;
  final formKey = GlobalKey<FormState>();

  await _confirmDialog(
    context,
    title: 'Ghi nhận lột xác',
    subtitle: crab.id,
    child: Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Ngày: ${formatDate(date)}', style: GoogleFonts.notoSans(fontSize: 12)),
            trailing: TextButton(
              onPressed: () async {
                final p = await showDatePicker(context: context, initialDate: date, firstDate: crab.releaseDate, lastDate: DateTime.now());
                if (p != null) date = p;
              },
              child: const Text('Chọn'),
            ),
          ),
          _dropdown('Tình trạng sau lột', condition, MoltCondition.values, (v) => condition = v!, (c) => c.label),
          _field(noteCtrl, 'Ghi chú', required: false),
        ],
      ),
    ),
    saveLabel: 'Ghi nhận lột xác',
    onSave: () {
      service.recordMolt(
        crab.id,
        date: date,
        moltCount: crab.moltCount + 1,
        condition: condition,
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );
      return true;
    },
  );
  noteCtrl.dispose();
}

Future<void> showRecordDiseaseDialog(BuildContext context, CrabService service, CrabIndividual crab) async {
  final nameCtrl = TextEditingController();
  final symptomCtrl = TextEditingController();
  final treatmentCtrl = TextEditingController();
  var severity = DiseaseSeverity.mild;
  var date = DateTime.now();
  final formKey = GlobalKey<FormState>();

  await _confirmDialog(
    context,
    title: 'Ghi nhận bệnh',
    subtitle: crab.id,
    child: Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(nameCtrl, 'Loại bệnh'),
          _dropdown('Mức độ', severity, DiseaseSeverity.values, (v) => severity = v!, (s) => s.label),
          _field(symptomCtrl, 'Triệu chứng'),
          _field(treatmentCtrl, 'Hướng xử lý'),
        ],
      ),
    ),
    saveLabel: 'Lưu bệnh án',
    onSave: () {
      if (!formKey.currentState!.validate()) return false;
      service.recordDisease(
        crab.id,
        name: nameCtrl.text.trim(),
        severity: severity,
        symptoms: symptomCtrl.text.trim(),
        treatment: treatmentCtrl.text.trim(),
        date: date,
      );
      return true;
    },
  );
  nameCtrl.dispose();
  symptomCtrl.dispose();
  treatmentCtrl.dispose();
}

Future<void> showUpdateStatusDialog(BuildContext context, CrabService service, CrabIndividual crab) async {
  var health = crab.healthStatus;
  var life = crab.lifeStatus;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: DashboardColors.card,
        title: Text('Cập nhật trạng thái', style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dropdown('Sức khỏe', health, CrabHealthStatus.values, (v) => setS(() => health = v!), (s) => s.label),
              const SizedBox(height: 12),
              _dropdown('Trạng thái nuôi/bán', life, CrabLifeStatus.values, (v) => setS(() => life = v!), (s) => s.label),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              await service.updateCrab(
                crab.copyWith(healthStatus: health, lifeStatus: life),
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã cập nhật trạng thái'), behavior: SnackBarBehavior.floating),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
            child: const Text('Lưu'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showMarkDeadDialog(BuildContext context, CrabService service, CrabIndividual crab) async {
  final causeCtrl = TextEditingController();
  var date = DateTime.now();

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text('Xác nhận', style: GoogleFonts.notoSans(color: DashboardColors.risk)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bạn có chắc muốn đánh dấu cua ${crab.id} là đã chết?',
            style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _field(causeCtrl, 'Nguyên nhân'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(
          onPressed: () {
            if (causeCtrl.text.trim().isEmpty) return;
            Navigator.pop(ctx, true);
          },
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.risk),
          child: const Text('Xác nhận'),
        ),
      ],
    ),
  );

  if (ok == true) {
    await service.markDead(crab.id, cause: causeCtrl.text.trim(), date: date);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${crab.id} đã đánh dấu chết'), behavior: SnackBarBehavior.floating),
      );
    }
  }
  causeCtrl.dispose();
}

Future<void> showMarkReadyForSaleDialog(BuildContext context, CrabService service, CrabIndividual crab) async {
  final checks = [
    ('Trọng lượng >= 150g', crab.weightGram >= 150),
    ('Health Score >= 85', crab.healthScore >= 85),
    ('Không bệnh trong 7 ngày', !crab.diseases.any((d) => d.status != DiseaseRecordStatus.resolved && DateTime.now().difference(d.date).inDays <= 7)),
    ('Qua kỳ lột xác an toàn', crab.daysSinceLastMolt == null || crab.daysSinceLastMolt! >= 3),
  ];

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text('Đánh dấu sẵn sàng bán', style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Điều kiện gợi ý:', style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12)),
            const SizedBox(height: 12),
            for (final c in checks)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      c.$2 ? Icons.check_circle : Icons.cancel_outlined,
                      size: 18,
                      color: c.$2 ? DashboardColors.healthy : DashboardColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c.$1, style: GoogleFonts.notoSans(fontSize: 12))),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        FilledButton.icon(
          onPressed: crab.canMarkReadyForSale
              ? () async {
                  await service.markReadyForSale(crab.id);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã đánh dấu sẵn sàng bán'), behavior: SnackBarBehavior.floating),
                  );
                }
              : null,
          icon: const Icon(Icons.sell_outlined, size: 18),
          label: const Text('Đánh dấu sẵn sàng bán'),
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
        ),
      ],
    ),
  );
}

Future<void> showExportCrabsDialog(BuildContext context, List<CrabIndividual> crabs) async {
  final buf = StringBuffer('crab_id,box,batch,gender,weight_g,health,life_status\n');
  for (final c in crabs) {
    buf.writeln('${c.id},${c.boxId},${c.batchId},${c.gender.label},${c.weightGram},${c.healthStatus.label},${c.lifeStatus.label}');
  }
  final csv = buf.toString();
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      title: const Text('Xuất Excel (CSV)'),
      content: SelectableText(csv, style: GoogleFonts.notoSans(fontSize: 11, color: DashboardColors.cyan)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        FilledButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: csv));
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Sao chép'),
        ),
      ],
    ),
  );
}

Future<bool> _confirmDialog(
  BuildContext context, {
  required String title,
  required String subtitle,
  required Widget child,
  required bool Function() onSave,
  String saveLabel = 'Lưu',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.notoSans(color: DashboardColors.textPrimary, fontWeight: FontWeight.w600)),
          Text(subtitle, style: GoogleFonts.notoSans(color: DashboardColors.cyan, fontSize: 12)),
        ],
      ),
      content: SizedBox(width: 420, child: child),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(
          onPressed: () {
            if (onSave()) Navigator.pop(ctx, true);
          },
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
          child: Text(saveLabel),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$saveLabel — thành công'), behavior: SnackBarBehavior.floating),
    );
  }
  return ok ?? false;
}

Widget _field(TextEditingController ctrl, String label, {bool required = true, bool isNumber = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : null,
      validator: required ? (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null : null,
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

Widget _readOnly(String label, String value) {
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
      child: Text(value, style: GoogleFonts.notoSans(color: DashboardColors.cyan, fontSize: 13)),
    ),
  );
}

Widget _dropdown<T>(
  String label,
  T value,
  List<T> items,
  ValueChanged<T?> onChanged,
  String Function(T) labelOf,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<T>(
      isExpanded: true,
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
