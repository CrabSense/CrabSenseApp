import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/dashboard_theme.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(
      color: DashboardColors.textMuted,
      fontSize: 11,
      decoration: TextDecoration.underline,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: DashboardColors.cardBorder.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'CRABSENSE © 2026 CrabSense. All rights reserved.',
            style: GoogleFonts.beVietnamPro(
              color: DashboardColors.textMuted,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Wrap(
            spacing: 16,
            children: [
              Text(
                'Privacy Policy',
                style: GoogleFonts.beVietnamPro(fontSize: 11).merge(linkStyle),
              ),
              Text(
                '|',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: DashboardColors.textMuted,
                ),
              ),
              Text(
                'Terms of Service',
                style: GoogleFonts.beVietnamPro(fontSize: 11).merge(linkStyle),
              ),
              Text(
                '|',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: DashboardColors.textMuted,
                ),
              ),
              Text(
                'Support',
                style: GoogleFonts.beVietnamPro(fontSize: 11).merge(linkStyle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
