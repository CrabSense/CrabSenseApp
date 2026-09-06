import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/farm_activity_log.dart';
import '../../services/crab_service.dart';
import '../../services/farm_layout_service.dart';
import '../../services/farm_log_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/dashboard/glass_card.dart';
import '../../widgets/logs/farm_log_dialogs.dart';
import '../../widgets/logs/farm_log_widgets.dart';

class FarmActivityLogPage extends StatefulWidget {
  const FarmActivityLogPage({
    super.key,
    required this.service,
    this.layoutService,
    this.crabService,
  });

  final FarmLogService service;
  final FarmLayoutService? layoutService;
  final CrabService? crabService;

  @override
  State<FarmActivityLogPage> createState() => _FarmActivityLogPageState();
}

class _FarmActivityLogPageState extends State<FarmActivityLogPage> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    widget.layoutService?.addListener(_onUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.service.load();
      widget.layoutService?.load();
    });
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    widget.layoutService?.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final groups = service.groupedByDay();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhật ký nuôi',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Timeline sự kiện — tự động và thủ công. Không ghi từng mẫu realtime.',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => showAddFarmLogDialog(
                  context,
                  service,
                  layout: widget.layoutService,
                  crabService: widget.crabService,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm nhật ký'),
              ),
            ],
          ),
          if (service.error != null) ...[
            const SizedBox(height: 12),
            Text(
              service.error!,
              style: GoogleFonts.notoSans(color: DashboardColors.risk, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          _Filters(service: service),
          const SizedBox(height: 20),
          if (service.loading && service.filteredEntries.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Chưa có nhật ký khớp bộ lọc.',
                  style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
                ),
              ),
            )
          else
            for (final day in groups.entries) ...[
              Text(
                day.key.toUpperCase(),
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              for (final e in day.value)
                _TimelineCard(
                  entry: e,
                  onTap: () => FarmLogDetailSheet.show(context, e),
                ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.service});

  final FarmLogService service;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              onChanged: service.setSearch,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm…',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: DashboardColors.darkNavy,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          _Drop(
            label: service.typeFilter,
            items: [
              'Tất cả',
              ...FarmLogType.manualChoices.map((t) => t.label),
              FarmLogType.aiEvent.label,
              FarmLogType.rasControl.label,
              FarmLogType.waterAnalysis.label,
            ],
            onSelected: service.setTypeFilter,
          ),
          _Drop(
            label: service.timeFilter,
            items: const ['Hôm nay', '7 ngày', '30 ngày', 'Tất cả'],
            onSelected: service.setTimeFilter,
          ),
          _Drop(
            label: service.locationFilter,
            items: service.locationOptions,
            onSelected: service.setLocationFilter,
          ),
        ],
      ),
    );
  }
}

class _Drop extends StatelessWidget {
  const _Drop({
    required this.label,
    required this.items,
    required this.onSelected,
  });

  final String label;
  final List<String> items;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: DashboardColors.card,
      itemBuilder: (context) => [
        for (final i in items) PopupMenuItem(value: i, child: Text(i)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: DashboardColors.darkNavy,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DashboardColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GoogleFonts.notoSans(fontSize: 13)),
            const Icon(Icons.expand_more, size: 16),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.entry, required this.onTap});

  final FarmActivityLogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(Icons.circle, size: 10, color: entry.type.color),
                const SizedBox(height: 4),
                Text(
                  entry.time,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Icon(entry.type.icon, color: entry.type.color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.type.label,
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        entry.source.label,
                        style: GoogleFonts.notoSans(
                          color: entry.isAuto
                              ? DashboardColors.purple
                              : DashboardColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (entry.placeLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.placeLabel,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    entry.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textPrimary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  if (entry.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${entry.imageUrls.length} ảnh đính kèm',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.cyan,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (entry.performer.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.performer,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
