import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/batch_status.dart';

class BatchStatusBadge extends StatelessWidget {
  const BatchStatusBadge({super.key, required this.status});

  final BatchStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.notoSans(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
