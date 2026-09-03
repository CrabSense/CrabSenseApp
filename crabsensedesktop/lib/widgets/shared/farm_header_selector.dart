import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/auth_models.dart';
import '../../theme/dashboard_theme.dart';

/// Dropdown đổi trại (farm) trên header — dùng sau khi đăng nhập Cloud.
class FarmHeaderSelector extends StatelessWidget {
  const FarmHeaderSelector({
    super.key,
    required this.farms,
    required this.selected,
    required this.onChanged,
  });

  final List<FarmSummary> farms;
  final FarmSummary selected;
  final ValueChanged<FarmSummary> onChanged;

  @override
  Widget build(BuildContext context) {
    if (farms.isEmpty) return const SizedBox.shrink();

    if (farms.length == 1) {
      return _FarmChip(label: selected.name, code: selected.code, enabled: false);
    }

    return PopupMenuButton<FarmSummary>(
      tooltip: 'Đổi trại',
      offset: const Offset(0, 44),
      color: DashboardColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: DashboardColors.cardBorder),
      ),
      onSelected: onChanged,
      itemBuilder: (context) => farms
          .map(
            (f) => PopupMenuItem<FarmSummary>(
              value: f,
              child: Row(
                children: [
                  if (f.id == selected.id)
                    Icon(Icons.check_rounded,
                        size: 18, color: DashboardColors.cyan)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.name,
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (f.code.isNotEmpty)
                          Text(
                            f.code,
                            style: GoogleFonts.notoSans(
                              color: DashboardColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: _FarmChip(
        label: selected.name,
        code: selected.code,
        enabled: true,
      ),
    );
  }
}

class _FarmChip extends StatelessWidget {
  const _FarmChip({
    required this.label,
    required this.code,
    required this.enabled,
  });

  final String label;
  final String code;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DashboardColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.agriculture_outlined,
            size: 18,
            color: DashboardColors.cyan.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (code.isNotEmpty)
                  Text(
                    code,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          if (enabled) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: DashboardColors.textMuted,
            ),
          ],
        ],
      ),
    );
  }
}
