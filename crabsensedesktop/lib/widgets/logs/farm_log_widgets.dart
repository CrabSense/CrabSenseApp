import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_farm_activity_log_data.dart';
import '../../models/farm_activity_log.dart';
import '../../services/farm_log_service.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';
import '../shared/ai_assistant_avatar.dart';

class FarmLogKpiStrip extends StatelessWidget {
  const FarmLogKpiStrip({super.key, required this.kpi});

  final FarmLogKpi kpi;

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiItem('Tổng nhật ký', '${kpi.totalToday}', DashboardColors.purple),
      _KpiItem('Cho ăn', '${kpi.feeding}', DashboardColors.blue),
      _KpiItem('Lột xác', '${kpi.molting}', const Color(0xFFC4B5FD)),
      _KpiItem('Cân cua', '${kpi.weighing}', DashboardColors.cyan),
      _KpiItem('Xử lý bệnh', '${kpi.treatment}', DashboardColors.risk),
      _KpiItem('Bảo trì', '${kpi.maintenance}', const Color(0xFF94A3B8)),
      _KpiItem('Thu hoạch', '${kpi.harvest}', DashboardColors.healthy),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 700) {
          return Wrap(spacing: 8, runSpacing: 8, children: items);
        }
        return Row(
          children: items
              .map((item) => Expanded(child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: item,
                  )))
              .toList(),
        );
      },
    );
  }
}

class _KpiItem extends StatelessWidget {
  const _KpiItem(this.label, this.value, this.accent);

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DashboardColors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 3, color: accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.notoSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hàng nút Thêm + 4 bộ lọc như mockup.
class FarmLogToolbar extends StatelessWidget {
  const FarmLogToolbar({
    super.key,
    required this.service,
    required this.onAdd,
  });

  final FarmLogService service;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final stacked = c.maxWidth < 900;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _addButton(),
              const SizedBox(height: 12),
              FarmLogFilterRow(service: service),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _addButton(),
            const SizedBox(width: 16),
            Expanded(child: FarmLogFilterRow(service: service)),
          ],
        );
      },
    );
  }

  Widget _addButton() {
    return FilledButton.icon(
      onPressed: onAdd,
      style: FilledButton.styleFrom(
        backgroundColor: DashboardColors.purple,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.add, size: 20),
      label: Text(
        'Thêm Nhật Ký',
        style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}

class FarmLogFilterRow extends StatelessWidget {
  const FarmLogFilterRow({super.key, required this.service});

  final FarmLogService service;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final filters = [
          _FilterField(
            prefix: 'Thời gian',
            value: service.timeFilter,
            items: MockFarmActivityLogData.timeFilters,
            onChanged: service.setTimeFilter,
          ),
          _FilterField(
            prefix: 'Loại thao tác',
            value: service.typeFilter,
            items: MockFarmActivityLogData.typeFilters,
            onChanged: service.setTypeFilter,
          ),
          _FilterField(
            prefix: 'Người thực hiện',
            value: service.performerFilter,
            items: MockFarmActivityLogData.performerFilters,
            onChanged: service.setPerformerFilter,
          ),
          _FilterField(
            prefix: 'Khu vực',
            value: service.areaFilter,
            items: MockFarmActivityLogData.areaFilters,
            onChanged: service.setAreaFilter,
          ),
        ];

        if (c.maxWidth < 600) {
          return Wrap(spacing: 10, runSpacing: 10, children: filters);
        }
        return Row(
          children: [
            for (var i = 0; i < filters.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                  child: filters[i],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.prefix,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String prefix;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          dropdownColor: DashboardColors.card,
          borderRadius: BorderRadius.circular(10),
          style: GoogleFonts.notoSans(fontSize: 12, color: DashboardColors.textPrimary),
          icon: Icon(Icons.keyboard_arrow_down,
              color: DashboardColors.textMuted, size: 18),
          items: items.map((o) {
            final label = o == 'Tất cả' ? '$prefix: Tất cả' : '$prefix: $o';
            return DropdownMenuItem(
              value: o,
              child: Text(label, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class FarmLogTypePill extends StatelessWidget {
  const FarmLogTypePill({super.key, required this.type});

  final FarmLogType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: type.color.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 14, color: type.color),
          const SizedBox(width: 6),
          Text(
            type.pillLabel,
            style: GoogleFonts.notoSans(
              color: type.color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class FarmLogTable extends StatelessWidget {
  const FarmLogTable({
    super.key,
    required this.entries,
    required this.service,
    required this.selectedId,
    this.onViewDetail,
  });

  final List<FarmActivityLogEntry> entries;
  final FarmLogService service;
  final String? selectedId;
  final ValueChanged<FarmActivityLogEntry>? onViewDetail;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 44,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 72,
              showCheckboxColumn: false,
              columnSpacing: 28,
              headingTextStyle: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              dataTextStyle: GoogleFonts.notoSans(
                color: DashboardColors.textPrimary,
                fontSize: 12,
              ),
              columns: const [
                DataColumn(label: Text('Thời gian')),
                DataColumn(label: Text('Loại thao tác')),
                DataColumn(label: Text('Người thực hiện')),
                DataColumn(label: Text('Đối tượng / Chi tiết')),
                DataColumn(label: Text('Minh chứng')),
                DataColumn(label: Text('Hành động')),
              ],
              rows: entries.map((e) {
                final isSelected = e.id == selectedId;
                return DataRow(
                  color: WidgetStateProperty.resolveWith((states) {
                    if (isSelected) {
                      return DashboardColors.purple.withValues(alpha: 0.12);
                    }
                    return null;
                  }),
                  onSelectChanged: (_) {
                    service.selectEntry(e.id);
                    onViewDetail?.call(e);
                  },
                  cells: [
                    DataCell(
                      Text(
                        e.time,
                        style: GoogleFonts.notoSans(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(FarmLogTypePill(type: e.type)),
                    DataCell(Text(e.performer)),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(
                          e.subjectDetail.isNotEmpty ? e.subjectDetail : e.content,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(_EvidenceLink(entry: e)),
                    DataCell(
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: DashboardColors.textMuted,
                        ),
                        color: DashboardColors.card,
                        onSelected: (v) {
                          if (v == 'detail') {
                            service.selectEntry(e.id);
                            onViewDetail?.call(e);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'detail',
                            child: Text('Xem chi tiết'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceLink extends StatelessWidget {
  const _EvidenceLink({required this.entry});

  final FarmActivityLogEntry entry;

  @override
  Widget build(BuildContext context) {
    if (entry.evidenceType == EvidenceType.none) {
      return Text('—', style: GoogleFonts.notoSans(color: DashboardColors.textMuted));
    }

    return InkWell(
      onTap: () {},
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            entry.evidenceType == EvidenceType.video
                ? Icons.videocam_outlined
                : Icons.image_outlined,
            size: 15,
            color: DashboardColors.cyan,
          ),
          const SizedBox(width: 6),
          Text(
            entry.evidenceLabel,
            style: GoogleFonts.notoSans(
              color: DashboardColors.cyan,
              fontSize: 11,
              decoration: TextDecoration.underline,
              decorationColor: DashboardColors.cyan.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class FarmLogDetailSheet extends StatelessWidget {
  const FarmLogDetailSheet({super.key, required this.entry});

  final FarmActivityLogEntry entry;

  static Future<void> show(BuildContext context, FarmActivityLogEntry entry) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: DashboardColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => FarmLogDetailSheet(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FarmLogTypePill(type: entry.type),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Nhật ký #${entry.logCode}',
            style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _row('Thời gian', '${entry.logDate} ${entry.time}'),
          _row('Người thực hiện', entry.performer),
          _row('Khu', entry.area),
          if (entry.batchId.isNotEmpty) _row('Lứa nuôi', entry.batchId),
          if (entry.crabId.isNotEmpty) _row('Mã cua', entry.crabId),
          _row('Nội dung', entry.content),
          if (entry.note.isNotEmpty) _row('Ghi chú', entry.note),
          if (entry.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Ảnh đính kèm', style: GoogleFonts.notoSans(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: entry.imageUrls
                  .map(
                    (url) => Chip(
                      avatar: const Icon(Icons.image_outlined, size: 16),
                      label: Text(url, style: const TextStyle(fontSize: 11)),
                      backgroundColor: DashboardColors.darkNavy,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(k, style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12)),
            ),
            Expanded(child: Text(v, style: GoogleFonts.notoSans(fontSize: 12))),
          ],
        ),
      );
}

class FarmLogAiPanel extends StatelessWidget {
  const FarmLogAiPanel({super.key, required this.summary});

  final FarmLogAiSummary summary;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AiAssistantHeader(
            title: 'AI Assistant',
            subtitle: 'CrabFarm Insight',
            avatarSize: 48,
            titleStyle: GoogleFonts.notoSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Tóm tắt 7 ngày',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 10),
          _summaryRow('Cho ăn', summary.feeding7d),
          _summaryRow('Lột xác', summary.molting7d),
          _summaryRow('Sức khỏe', summary.disease7d, suffix: ' ca bệnh'),
          _summaryRow('Bảo trì', summary.maintenance7d),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DashboardColors.darkNavy.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DashboardColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 18, color: DashboardColors.monitoring),
                    const SizedBox(width: 8),
                    Text(
                      'Khuyến nghị',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  summary.recommendation,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 12,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DashboardColors.purple.withValues(alpha: 0.45),
                    DashboardColors.risk.withValues(alpha: 0.35),
                    DashboardColors.cyan.withValues(alpha: 0.25),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _HeatmapPlaceholderPainter()),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 8,
                    child: Text(
                      'Phân tích mật độ Khu B',
                      style: GoogleFonts.notoSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, int count, {String suffix = ''}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '• $label: $count$suffix',
        style: GoogleFonts.notoSans(fontSize: 12),
      ),
    );
  }
}

class _HeatmapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cols = 8;
    final rows = 4;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final t = (r + c) / (rows + cols);
        final paint = Paint()
          ..color = Color.lerp(
            DashboardColors.purple.withValues(alpha: 0.2),
            DashboardColors.risk.withValues(alpha: 0.5),
            t,
          )!;
        canvas.drawRect(
          Rect.fromLTWH(c * cellW + 1, r * cellH + 1, cellW - 2, cellH - 2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
