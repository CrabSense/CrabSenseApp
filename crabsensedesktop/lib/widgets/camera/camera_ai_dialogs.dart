import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/camera_ai.dart';
import '../../services/camera_ai_service.dart';
import '../../theme/dashboard_theme.dart';

Future<void> showAiEventDetailDialog(
  BuildContext context,
  CameraAiService service,
  AiCameraEvent event,
) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Sự kiện AI: ${event.detectionType.label}',
        style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row('Camera', event.cameraLabel),
            _row('Hộp', event.boxId),
            _row('Mã cua', event.crabId),
            _row('Thời gian', event.time),
            _row('Độ tin cậy', '${(event.confidence * 100).round()}%'),
            _row('Mức độ', event.level.label),
            if (event.note != null) _row('Ghi chú', event.note!),
            const SizedBox(height: 16),
            Container(
              height: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DashboardColors.darkNavy,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DashboardColors.cardBorder),
              ),
              child: Text(
                '[Snapshot phát hiện]',
                style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Video: 5 giây trước — 5 giây sau (demo)',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            service.updateEventStatus(event.id, AiEventStatus.falsePositive);
            Navigator.pop(ctx);
            _snack(context, 'Đã báo sai AI');
          },
          child: const Text('Báo sai AI'),
        ),
        OutlinedButton(
          onPressed: () {
            service.updateEventStatus(event.id, AiEventStatus.confirmed);
            Navigator.pop(ctx);
            _snack(context, 'Đã xác nhận');
          },
          child: const Text('Xác nhận đúng'),
        ),
        FilledButton(
          onPressed: () {
            service.updateEventStatus(event.id, AiEventStatus.pending);
            Navigator.pop(ctx);
            _snack(context, 'Đã tạo cảnh báo (demo)');
          },
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
          child: const Text('Tạo cảnh báo'),
        ),
      ],
    ),
  );
}

Widget _row(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12)),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.notoSans(color: DashboardColors.cyan, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
  );
}
