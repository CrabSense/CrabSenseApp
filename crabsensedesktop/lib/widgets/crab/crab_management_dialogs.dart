import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/app_formatters.dart';
import '../../models/crab_individual.dart';
import '../../models/crab_status.dart';
import '../../services/crab_service.dart';
import '../../theme/dashboard_theme.dart';
import 'add/add_crab_modal.dart';
import 'edit/edit_crab_modal.dart';

Future<void> showCrabManagementFormDialog(
  BuildContext context,
  CrabService service, {
  CrabIndividual? existing,
  String? initialLotId,
  Future<void> Function()? onRecordMeasurement,
  Future<void> Function()? onMoveBox,
  VoidCallback? onManageLots,
}) async {
  if (existing == null) {
    await showAddCrabModal(
      context,
      service,
      initialLotId: initialLotId,
      onManageLots: onManageLots,
    );
    return;
  }

  final ok = await showEditCrabModal(
    context,
    service,
    crab: existing,
    onRecordMeasurement: onRecordMeasurement,
    onMoveBox: onMoveBox,
  );
  if (!context.mounted || !ok) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Đã cập nhật thông tin ${existing.code}.')),
  );
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
                subtitle: Text(formatDate(recordedAt)),
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
  final imagePaths = <String>[];

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: DashboardColors.card,
        title: Text('Ghi nhận lột xác', style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày lột xác'),
                  subtitle: Text(formatDate(moltDate)),
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
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ảnh lột xác',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: DashboardColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < imagePaths.length; i++)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(imagePaths[i]),
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: InkWell(
                              onTap: () => setS(() => imagePaths.removeAt(i)),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (imagePaths.length < 10)
                      InkWell(
                        onTap: () async {
                          final remain = 10 - imagePaths.length;
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: const [
                              'jpg',
                              'jpeg',
                              'png',
                              'webp',
                              'gif',
                              'heic',
                              'heif',
                            ],
                            allowMultiple: true,
                          );
                          if (result == null) return;
                          final added = <String>[];
                          for (final f in result.files) {
                            final path = f.path;
                            if (path == null || path.isEmpty) continue;
                            if (imagePaths.contains(path) || added.contains(path)) continue;
                            added.add(path);
                            if (added.length >= remain) break;
                          }
                          if (added.isEmpty) return;
                          setS(() => imagePaths.addAll(added));
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: DashboardColors.darkNavy.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: DashboardColors.textMuted.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_outlined, color: DashboardColors.cyan, size: 22),
                              const SizedBox(height: 4),
                              Text(
                                'Thêm',
                                style: GoogleFonts.notoSans(
                                  fontSize: 11,
                                  color: DashboardColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tối đa 10 ảnh · jpeg, png, webp · tải lên Drive khi lưu',
                    style: GoogleFonts.notoSans(
                      fontSize: 11,
                      color: DashboardColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
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
      imagePaths: List<String>.from(imagePaths),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (imagePaths.isEmpty
                    ? 'Đã ghi nhận lột xác. Xuất cua lột ở Thu hoạch & Bán hàng hoặc menu cua.'
                    : 'Đã ghi nhận lột xác và tải ${imagePaths.length} ảnh lên Drive.')
                : (service.error ?? 'Lỗi'),
          ),
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
      initialValue: selected,
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
      initialValue: value,
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
