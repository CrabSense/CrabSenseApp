import 'package:flutter/material.dart';

import '../../models/crab_individual.dart';
import '../../models/crab_status.dart';
import '../../services/crab_service.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/mgmt_ui.dart';
import 'transfer/transfer_crab_modal.dart';

const kDeadCauses = <String>[
  'Chưa xác định',
  'Bệnh',
  'Sốc môi trường',
  'Lột xác thất bại',
  'Tổn thương',
  'Khác',
];

Future<bool> showMoveCrabModal(
  BuildContext context,
  CrabService service,
  CrabIndividual crab,
) {
  return showTransferCrabModal(context, service, crab: crab);
}

Future<bool> showMarkMoltingModal(
  BuildContext context,
  CrabService service,
  CrabIndividual crab,
) async {
  var time = DateTime.now();
  final note = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: const Color.fromRGBO(15, 35, 30, 0.45),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xác nhận cua đang lột xác?',
          style: bvText(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: DashboardColors.textPrimary,
          ),
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                crab.code,
                style: bvText(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.brand,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: time,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (d == null) return;
                  if (!ctx.mounted) return;
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.fromDateTime(time),
                  );
                  setS(() {
                    time = DateTime(
                      d.year,
                      d.month,
                      d.day,
                      t?.hour ?? time.hour,
                      t?.minute ?? time.minute,
                    );
                  });
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Thời gian'),
                  child: Text(fmtDateTimeVn(time)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: bvText(color: DashboardColors.textMuted)),
          ),
          MgmtPrimaryButton(
            label: 'Xác nhận',
            onTap: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    ),
  );
  if (ok != true) {
    note.dispose();
    return false;
  }
  final saved = await service.markMolting(
    crab.id,
    date: time,
    note: note.text.trim().isEmpty ? null : note.text.trim(),
  );
  note.dispose();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? 'Đã đánh dấu ${crab.code} đang lột xác' : (service.error ?? 'Lỗi'),
        ),
      ),
    );
  }
  return saved;
}

Future<bool> showMarkDeadModal(
  BuildContext context,
  CrabService service,
  CrabIndividual crab,
) async {
  var time = DateTime.now();
  var cause = kDeadCauses.first;
  final note = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: const Color.fromRGBO(15, 35, 30, 0.45),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xác nhận cua chết',
          style: bvText(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: DashboardColors.risk,
          ),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                crab.code,
                style: bvText(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: time,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (d == null) return;
                  if (!ctx.mounted) return;
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.fromDateTime(time),
                  );
                  setS(() {
                    time = DateTime(
                      d.year,
                      d.month,
                      d.day,
                      t?.hour ?? time.hour,
                      t?.minute ?? time.minute,
                    );
                  });
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Thời gian phát hiện *'),
                  child: Text(fmtDateTimeVn(time)),
                ),
              ),
              const SizedBox(height: 10),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Nguyên nhân'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: cause,
                    isExpanded: true,
                    items: [
                      for (final c in kDeadCauses)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) => setS(() => cause = v ?? cause),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: bvText(color: DashboardColors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.risk),
            child: const Text('Xác nhận cua chết'),
          ),
        ],
      ),
    ),
  );
  if (ok != true) {
    note.dispose();
    return false;
  }
  final detail = note.text.trim().isEmpty ? cause : '$cause — ${note.text.trim()}';
  final saved = await service.markDead(crab.id, cause: detail, date: time);
  note.dispose();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? 'Đã ghi nhận ${crab.code} chết. Record được giữ lại.' : (service.error ?? 'Lỗi'),
        ),
      ),
    );
  }
  return saved;
}

Future<bool> showBulkHealthModal(
  BuildContext context,
  CrabService service,
  List<CrabIndividual> crabs,
) async {
  var health = CrabDisplayHealth.healthy;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cập nhật sức khỏe (${crabs.length} cua)',
          style: bvText(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: DashboardColors.textPrimary,
          ),
        ),
        content: DropdownButton<CrabDisplayHealth>(
          value: health,
          isExpanded: true,
          items: [
            for (final h in CrabDisplayHealth.values)
              DropdownMenuItem(value: h, child: Text(h.label)),
          ],
          onChanged: (v) => setS(() => health = v ?? health),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          MgmtPrimaryButton(
            label: 'Cập nhật',
            onTap: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return false;
  final saved = await service.bulkUpdateHealth(crabs.map((c) => c.id), health);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? 'Đã cập nhật sức khỏe' : (service.error ?? 'Lỗi')),
      ),
    );
  }
  return saved;
}
