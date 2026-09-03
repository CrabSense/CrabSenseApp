import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/area_status.dart';
import '../../models/production_models.dart';
import '../../theme/dashboard_theme.dart';
import 'area_table.dart';
import '../dashboard/glass_card.dart';

class AreaDetailBreadcrumb extends StatelessWidget {
  const AreaDetailBreadcrumb({
    super.key,
    this.onDashboard,
    this.onAreaList,
  });

  final VoidCallback? onDashboard;
  final VoidCallback? onAreaList;

  @override
  Widget build(BuildContext context) {
    final link = GoogleFonts.notoSans(
      color: DashboardColors.oceanBlue,
      fontSize: 13,
    );
    final muted = GoogleFonts.notoSans(
      color: DashboardColors.textMuted,
      fontSize: 13,
    );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(onTap: onDashboard, child: Text('Dashboard', style: link)),
        Text('  >  ', style: muted),
        InkWell(onTap: onAreaList, child: Text('Quản lý Khu', style: link)),
        Text('  >  ', style: muted),
        Text(
          'Chi tiết',
          style: muted.copyWith(color: DashboardColors.textPrimary),
        ),
      ],
    );
  }
}

class AreaDetailHeader extends StatelessWidget {
  const AreaDetailHeader({
    super.key,
    required this.area,
    required this.onEdit,
    this.onReport,
  });

  final AreaRecord area;
  final VoidCallback onEdit;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final stacked = c.maxWidth < 720;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              area.areaName,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DashboardColors.seaGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: DashboardColors.seaGreen.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    area.areaCode,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.seaGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (area.description?.trim().isNotEmpty == true)
                  Text(
                    area.description!.trim(),
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ],
        );
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Chỉnh sửa'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DashboardColors.textPrimary,
                side: BorderSide(color: DashboardColors.cardBorder),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Báo cáo'),
              style: FilledButton.styleFrom(
                backgroundColor: DashboardColors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleBlock,
              const SizedBox(height: 16),
              actions,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            actions,
          ],
        );
      },
    );
  }
}

class AreaDetailStatCards extends StatelessWidget {
  const AreaDetailStatCards({super.key, required this.area});

  final AreaRecord area;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 1000
            ? 4
            : c.maxWidth > 600
                ? 2
                : 1;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: cols == 1 ? 2.6 : 2.1,
          children: [
            _DetailStatCard(
              title: 'TRẠNG THÁI',
              accent: DashboardColors.seaGreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AreaStatusBadge(status: area.status),
                  const SizedBox(height: 8),
                  Text(
                    'Lần tải dữ liệu: vừa xong',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            _DetailStatCard(
              title: 'DÃY NUÔI',
              value: '${area.rowCount}',
              subtitle: 'dãy trong khu',
              icon: Icons.view_week_outlined,
              accent: DashboardColors.purple,
            ),
            _DetailStatCard(
              title: 'HỘP NUÔI',
              value: '${area.boxCount}',
              subtitle: 'hộp nuôi cua',
              icon: Icons.inventory_2_outlined,
              accent: DashboardColors.cyan,
            ),
            _DetailStatCard(
              title: 'THIẾT BỊ',
              value: '${area.esp32Count}',
              subtitle: '${area.cameraCount} camera AI',
              icon: Icons.sensors,
              accent: DashboardColors.oceanBlue,
              trailing: Icon(
                Icons.signal_cellular_alt,
                color: DashboardColors.seaGreen.withValues(alpha: 0.8),
                size: 22,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  const _DetailStatCard({
    required this.title,
    required this.accent,
    this.value,
    this.subtitle,
    this.icon,
    this.child,
    this.trailing,
  });

  final String title;
  final Color accent;
  final String? value;
  final String? subtitle;
  final IconData? icon;
  final Widget? child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: accent.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                if (child != null)
                  child!
                else ...[
                  Text(
                    value ?? '—',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (icon != null)
            Icon(icon, color: accent.withValues(alpha: 0.85), size: 32),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

enum _RowHealth { stable, warning, maintenance }

class _RowHealthUi {
  static ({String label, Color color}) ui(_RowHealth h) => switch (h) {
        _RowHealth.stable => (
            label: 'Ổn định',
            color: DashboardColors.seaGreen,
          ),
        _RowHealth.warning => (
            label: 'Cảnh báo',
            color: DashboardColors.monitoring,
          ),
        _RowHealth.maintenance => (
            label: 'Bảo trì',
            color: DashboardColors.textMuted,
          ),
      };
}

class AreaDetailRowTable extends StatelessWidget {
  const AreaDetailRowTable({
    super.key,
    required this.rows,
    required this.boxes,
  });

  final List<RowRecord> rows;
  final List<BoxRecord> boxes;

  static _RowHealth _health(int boxCount, double perf) {
    if (boxCount == 0) return _RowHealth.maintenance;
    if (perf >= 85) return _RowHealth.stable;
    if (perf >= 40) return _RowHealth.warning;
    return _RowHealth.maintenance;
  }

  static double _performance(List<BoxRecord> rowBoxes) {
    if (rowBoxes.isEmpty) return 0;
    final good = rowBoxes.where((b) {
      final s = b.status.toLowerCase();
      return s == 'active' ||
          s == 'occupied' ||
          s == 'in_use' ||
          s == 'nuôi';
    }).length;
    return (good / rowBoxes.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return _empty('Chưa có dãy trong khu này.');
    }

    final heading = GoogleFonts.notoSans(
      color: DashboardColors.textMuted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowHeight: 44,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 64,
              columnSpacing: 28,
              horizontalMargin: 12,
              dividerThickness: 0.5,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: DashboardColors.cardBorder.withValues(alpha: 0.6),
                ),
              ),
              headingRowColor: WidgetStateProperty.all(
                DashboardColors.darkNavy.withValues(alpha: 0.5),
              ),
              columns: [
                DataColumn(label: Text('MÃ DÃY', style: heading)),
                DataColumn(
                  label: Text('SỐ HỘP', style: heading),
                  numeric: true,
                ),
                DataColumn(label: Text('TRẠNG THÁI', style: heading)),
                DataColumn(label: Text('HIỆU SUẤT', style: heading)),
                DataColumn(label: Text('THAO TÁC', style: heading)),
              ],
              rows: rows.map((r) {
                final rowBoxes =
                    boxes.where((b) => b.rowId == r.id).toList();
                final perf = _performance(rowBoxes);
                final health = _health(rowBoxes.length, perf);
                final ui = _RowHealthUi.ui(health);
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        r.rowCode,
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.cyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${rowBoxes.length} Hộp',
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                    ),
                    DataCell(_HealthPill(label: ui.label, color: ui.color)),
                    DataCell(_PerfBar(percent: perf, color: ui.color)),
                    DataCell(
                      IconButton(
                        tooltip: 'Xem dãy',
                        onPressed: () {},
                        icon: Icon(
                          Icons.visibility_outlined,
                          size: 20,
                          color: DashboardColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class AreaDetailBoxTable extends StatelessWidget {
  const AreaDetailBoxTable({super.key, required this.boxes});

  final List<BoxRecord> boxes;

  @override
  Widget build(BuildContext context) {
    if (boxes.isEmpty) {
      return _empty('Chưa có hộp trong khu này.');
    }

    final heading = GoogleFonts.notoSans(
      color: DashboardColors.textMuted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowHeight: 44,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 60,
              columnSpacing: 24,
              headingRowColor: WidgetStateProperty.all(
                DashboardColors.darkNavy.withValues(alpha: 0.5),
              ),
              columns: [
                DataColumn(label: Text('MÃ HỘP', style: heading)),
                DataColumn(label: Text('VỊ TRÍ', style: heading)),
                DataColumn(label: Text('TRẠNG THÁI', style: heading)),
                DataColumn(label: Text('THAO TÁC', style: heading)),
              ],
              rows: boxes.map((b) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        b.boxCode,
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.cyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(Text(b.position ?? '—')),
                    DataCell(Text(b.status)),
                    DataCell(
                      IconButton(
                        tooltip: 'Xem hộp',
                        onPressed: () {},
                        icon: Icon(
                          Icons.visibility_outlined,
                          size: 20,
                          color: DashboardColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _HealthPill extends StatelessWidget {
  const _HealthPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSans(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PerfBar extends StatelessWidget {
  const _PerfBar({required this.percent, required this.color});

  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final v = (percent / 100).clamp(0.0, 1.0);
    return SizedBox(
      width: 120,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: DashboardColors.cardBorder,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${percent.round()}%',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class AreaDetailDevicePanel extends StatelessWidget {
  const AreaDetailDevicePanel({
    super.key,
    required this.count,
    required this.deviceLabel,
    this.title,
    this.icon = Icons.sensors,
    this.accent = DashboardColors.seaGreen,
  });

  final int count;
  final String deviceLabel;
  final String? title;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: accent.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              title ?? '$count thiết bị',
              style: GoogleFonts.notoSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: DashboardColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              deviceLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AreaDetailBottomPanels extends StatelessWidget {
  const AreaDetailBottomPanels({
    super.key,
    required this.areaName,
    required this.areaCode,
  });

  final String areaName;
  final String areaCode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 900;
        final heatmap = _PanelCard(
          title: 'Sơ đồ nhiệt $areaCode',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        DashboardColors.darkNavy,
                        DashboardColors.purple.withValues(alpha: 0.15),
                      ],
                    ),
                    border: Border.all(color: DashboardColors.cardBorder),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.grid_4x4_rounded,
                      size: 64,
                      color: DashboardColors.cyan.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                children: [
                  _legend(DashboardColors.cyan, 'Tối ưu'),
                  _legend(DashboardColors.monitoring, 'Cao'),
                ],
              ),
            ],
          ),
        );
        final camera = _PanelCard(
          title: 'Camera giám sát AI',
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: DashboardColors.darkNavy,
                  border: Border.all(color: DashboardColors.cardBorder),
                ),
                child: Icon(
                  Icons.videocam_outlined,
                  size: 48,
                  color: DashboardColors.textMuted.withValues(alpha: 0.4),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DashboardColors.risk,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'LIVE',
                    style: GoogleFonts.notoSans(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Text(
                  'CAM-01: $areaName',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );

        if (!wide) {
          return Column(
            children: [
              SizedBox(height: 220, child: heatmap),
              const SizedBox(height: 16),
              SizedBox(height: 200, child: camera),
            ],
          );
        }
        return SizedBox(
          height: 240,
          child: Row(
            children: [
              Expanded(flex: 3, child: heatmap),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: camera),
            ],
          ),
        );
      },
    );
  }

  Widget _legend(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.notoSans(
            color: DashboardColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

Widget _empty(String message) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        message,
        style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
      ),
    ),
  );
}

/// Tab bar styled for area detail (purple accent per mockup).
class AreaDetailTabBar extends StatelessWidget {
  const AreaDetailTabBar({
    super.key,
    required this.controller,
  });

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: true,
      labelColor: DashboardColors.purple,
      unselectedLabelColor: DashboardColors.textMuted,
      indicatorColor: DashboardColors.purple,
      indicatorWeight: 3,
      labelStyle: GoogleFonts.notoSans(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      unselectedLabelStyle: GoogleFonts.notoSans(fontSize: 14),
        tabs: const [
          Tab(text: 'Danh sách dãy'),
          Tab(text: 'Danh sách hộp'),
          Tab(text: 'Thiết bị IoT'),
          Tab(text: 'Cảm biến'),
        ],
    );
  }
}
