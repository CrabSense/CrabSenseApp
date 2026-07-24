import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';

enum ScanQuickAction {
  details,
  aiDetection,
  videoAi,
  water,
  harvest,
  cameraLive,
  note,
  createTask,
  scanAgain,
}

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({
    required this.onAction,
    super.key,
  });

  final void Function(ScanQuickAction action) onAction;

  static const _items = <(ScanQuickAction, IconData, String)>[
    (ScanQuickAction.details, Icons.description_outlined, 'Xem chi tiết'),
    (ScanQuickAction.aiDetection, Icons.smart_toy_outlined, 'Phát hiện AI'),
    (ScanQuickAction.videoAi, Icons.videocam_outlined, 'Quay Video AI'),
    (ScanQuickAction.water, Icons.science_outlined, 'Kiểm tra nước'),
    (ScanQuickAction.harvest, Icons.inventory_2_outlined, 'Thu hoạch'),
    (ScanQuickAction.cameraLive, Icons.camera_alt_outlined, 'Camera trực tiếp'),
    (ScanQuickAction.note, Icons.edit_note_rounded, 'Ghi chú'),
    (ScanQuickAction.createTask, Icons.assignment_add, 'Tạo công việc'),
    (ScanQuickAction.scanAgain, Icons.qr_code_scanner_rounded, 'Quét tiếp'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, i) {
        final item = _items[i];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onAction(item.$1),
            child: Ink(
              decoration: homeTileDecoration(radius: 16, accent: kHomeBlue),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.$2,
                      color: kHomeCyan,
                      size: 24,
                      shadows: [
                        Shadow(
                          color: kHomeCyan.withValues(alpha: 0.45),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.$3,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
