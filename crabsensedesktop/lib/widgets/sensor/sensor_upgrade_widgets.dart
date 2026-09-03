import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/sensor_kit.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';

class CurrentKitCard extends StatelessWidget {
  const CurrentKitCard({super.key, required this.current});

  final CurrentSensorKit current;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DashboardColors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sensors, color: DashboardColors.purple, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gói hiện tại: ${current.planName}',
                  style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cảm biến: ${current.activeSensors}/${current.maxSensors} · FW ${current.firmwareVersion}',
                  style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 11),
                ),
                Text(
                  'Đồng bộ: ${current.lastSync}',
                  style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SensorPlanCard extends StatelessWidget {
  const SensorPlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onSelect,
    required this.onUpgrade,
    required this.upgrading,
    required this.isCurrent,
  });

  final SensorKitPlan plan;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onUpgrade;
  final bool upgrading;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      highlight: plan.recommended,
      borderColor: selected ? DashboardColors.cyan : null,
      onTap: onSelect,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: GoogleFonts.notoSans(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              if (plan.recommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DashboardColors.cyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ĐỀ XUẤT',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.cyan,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DashboardColors.healthy.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ĐANG DÙNG',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.healthy,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.priceLabel,
            style: GoogleFonts.notoSans(
              color: DashboardColors.cyan,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.description,
            style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 14),
          ...plan.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: plan.includesAi ? DashboardColors.cyan : DashboardColors.purple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: GoogleFonts.notoSans(fontSize: 11))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (selected && !isCurrent)
            FilledButton(
              onPressed: upgrading ? null : onUpgrade,
              style: FilledButton.styleFrom(
                backgroundColor: DashboardColors.purple,
                minimumSize: const Size.fromHeight(40),
              ),
              child: upgrading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      plan.id == 'enterprise' ? 'Liên hệ tư vấn' : 'Nâng cấp ngay',
                      style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
                    ),
            ),
        ],
      ),
    );
  }
}

class SensorCompareTable extends StatelessWidget {
  const SensorCompareTable({super.key, required this.rows});

  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'So sánh gói',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: DashboardColors.cardBorder)),
                ),
                children: [
                  _h('Tính năng'),
                  _h('Cơ bản'),
                  _h('Pro'),
                  _h('Enterprise'),
                ],
              ),
              ...rows.map(
                (row) => TableRow(
                  children: [
                    for (var i = 0; i < row.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          row[i],
                          style: GoogleFonts.notoSans(
                            fontSize: 11,
                            fontWeight: i == 0 ? FontWeight.w600 : FontWeight.normal,
                            color: i == 0
                                ? DashboardColors.textMuted
                                : DashboardColors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _h(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          t,
          style: GoogleFonts.notoSans(
            color: DashboardColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
