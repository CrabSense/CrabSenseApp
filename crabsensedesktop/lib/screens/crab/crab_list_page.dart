import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/crab_individual.dart';
import '../../utils/crab_management_mapper.dart';
import '../../services/crab_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/crab/crab_dialogs.dart';
import '../../widgets/crab/crab_summary_kpi.dart';
import '../../widgets/crab/crab_table.dart';
import '../../widgets/dashboard/glass_card.dart';

class CrabListPage extends StatelessWidget {
  const CrabListPage({
    super.key,
    required this.service,
    required this.onViewCrab,
    this.onOpenHealth,
  });

  final CrabService service;
  final ValueChanged<CrabIndividual> onViewCrab;
  final ValueChanged<CrabIndividual>? onOpenHealth;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final kpis = crabSummaryKpis(service.crabs);
        final pageItems = service.paginatedCrabs;
        final start = service.filteredCount == 0
            ? 0
            : (service.currentPage - 1) * service.pageSize + 1;
        final end = (service.currentPage * service.pageSize)
            .clamp(0, service.filteredCount);

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Quản lý Cá thể cua',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Theo dõi tăng trưởng, sức khỏe và lịch sử từng con cua trong từng hộp nuôi.',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CrabSummaryKpiRow(items: kpis),
                  const SizedBox(height: 24),
                  _FilterBar(service: service),
                  const SizedBox(height: 20),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Danh sách cua',
                              style: GoogleFonts.notoSans(
                                color: DashboardColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            OutlinedButton.icon(
                              onPressed: () => showExportCrabsDialog(
                                context,
                                service.filteredCrabs,
                              ),
                              icon: const Icon(Icons.download_outlined, size: 16),
                              label: const Text('Xuất Excel'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: DashboardColors.textMuted,
                                side: BorderSide(color: DashboardColors.cardBorder),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () => showAddCrabDialog(context, service),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Thêm Cá Thể'),
                              style: FilledButton.styleFrom(
                                backgroundColor: DashboardColors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CrabDataTable(
                          crabs: pageItems,
                          onView: onViewCrab,
                          onHealth: onOpenHealth,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Hiển thị $start–$end của ${service.crabs.length} cá thể',
                              style: GoogleFonts.notoSans(
                                color: DashboardColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            _Pagination(
                              current: service.currentPage,
                              total: service.totalPages,
                              onPage: service.goToPage,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 32,
              bottom: 32,
              child: FloatingActionButton(
                onPressed: () => showAddCrabDialog(context, service),
                backgroundColor: DashboardColors.purple,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.service});

  final CrabService service;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            child: TextField(
              onChanged: service.setSearch,
              style: GoogleFonts.notoSans(color: DashboardColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Mã cua / mã hộp...',
                hintStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
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
          _filterDropdown(
            'Lọc đợt',
            service.batchOptions,
            service.batchFilter,
            service.setBatchFilter,
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown(
    String label,
    List<String> options,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: options.contains(value) ? value : options.first,
        dropdownColor: DashboardColors.card,
        style: GoogleFonts.notoSans(color: DashboardColors.textPrimary, fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 11),
          filled: true,
          fillColor: DashboardColors.darkNavy,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: options
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.current,
    required this.total,
    required this.onPage,
  });

  final int current;
  final int total;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final pages = total.clamp(1, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: current > 1 ? () => onPage(current - 1) : null,
          icon: Icon(Icons.chevron_left, color: DashboardColors.textMuted),
        ),
        for (var i = 1; i <= pages; i++) ...[
          const SizedBox(width: 4),
          Material(
            color: i == current ? DashboardColors.purple : DashboardColors.card,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: i == current ? null : () => onPage(i),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                child: Text(
                  '$i',
                  style: GoogleFonts.notoSans(
                    color: i == current ? Colors.white : DashboardColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
        IconButton(
          onPressed: current < total ? () => onPage(current + 1) : null,
          icon: Icon(Icons.chevron_right, color: DashboardColors.textMuted),
        ),
      ],
    );
  }
}
