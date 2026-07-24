import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
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
                color: CrabSenseColors.hintText,
              ),
        ),
      );
    }

    final fmt = DateFormat('HH:mm');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử quét',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: CrabSenseColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        ...entries.take(10).map((e) {
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 44,
              alignment: Alignment.center,
              child: Text(
                fmt.format(e.scannedAt.toLocal()),
                style: const TextStyle(
                  color: CrabSenseColors.hintText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              e.code,
              style: const TextStyle(
                color: CrabSenseColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: TextButton(
              onPressed: () => onRescan(e),
              child: const Text('Quét lại'),
            ),
          );
        }),
      ],
    );
  }
}
