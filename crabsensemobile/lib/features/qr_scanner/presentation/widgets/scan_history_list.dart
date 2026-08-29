import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/entities/scan_quick_result.dart';

class ScanHistoryList extends StatelessWidget {
  const ScanHistoryList({
    required this.entries,
    required this.onRescan,
    super.key,
  });

  final List<ScanHistoryEntry> entries;
  final void Function(ScanHistoryEntry entry) onRescan;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Chưa có lịch sử quét',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.4),
              ),
        ),
      );
    }

    final fmt = DateFormat('HH:mm');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LỊCH SỬ QUÉT',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: kHomeBlueLight,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(height: 8),
        ...entries.take(10).map((e) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: homeTileDecoration(radius: 12),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: SizedBox(
                width: 44,
                child: Text(
                  fmt.format(e.scannedAt.toLocal()),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(
                e.code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kHomeTextMain,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: TextButton(
                onPressed: () => onRescan(e),
                style: TextButton.styleFrom(foregroundColor: kHomeCyan),
                child: const Text('Quét lại'),
              ),
            ),
          );
        }),
      ],
    );
  }
}
