// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes.dart';
import '../../data/models/crab_management_models.dart';
import '../providers/crab_management_provider.dart';
import '../widgets/crab_action_modals.dart';
import '../widgets/crab_bulk_bar.dart';
import '../widgets/crab_detail_panel.dart';
import '../widgets/crab_empty_states.dart';
import '../widgets/crab_filter_panel.dart';
import '../widgets/crab_kpi_cards.dart';
import '../widgets/crab_management_palette.dart';
import '../widgets/crab_pagination.dart';
import '../widgets/crab_status_tabs.dart';
import '../widgets/crab_table.dart';

/// Quản lý Cua — Main screen
/// Layout: Header → KPI → Filter → Status chips → Table+Detail → Pagination
class CrabManagementScreen extends ConsumerWidget {
  const CrabManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 900;

    return Scaffold(
      backgroundColor: kCmBackground,
      body: SafeArea(
        child: isWide ? _WideLayout(ref: ref) : _NarrowLayout(ref: ref),
      ),
    );
  }
}

// ── Wide layout (tablet / desktop ≥ 900px) ────────────────────────────────────

class _WideLayout extends ConsumerWidget {
  const _WideLayout({required this.ref});
  // ignore: unused_field
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(crabManagementProvider);
    final notifier = ref.read(crabManagementProvider.notifier);
    final hasDetail = state.selectedCrab != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main content
        Expanded(
          child: _MainContent(state: state, notifier: notifier, isWide: true),
        ),
        // Detail panel (fixed 300px when open)
        if (hasDetail)
          SizedBox(
            width: 300,
            child: CrabDetailPanel(
              crab: state.selectedCrab!,
              loading: state.loadingDetail,
              onClose: notifier.closeDetail,
              onViewHistory: () => _goHistory(context, state.selectedCrab!),
              onViewBox: () => _goBox(context, state.selectedCrab!),
              onViewDetail: () => _goCrabDetail(context, state.selectedCrab!),
              onFarmAreaTap: (_) {},
              onRowTap: (_) {},
              onBoxTap: (boxId) => _goBox(context, state.selectedCrab!),
            ),
          ),
      ],
    );
  }

  void _goHistory(BuildContext ctx, CrabRecord crab) =>
      ctx.push(RoutePaths.crabDetails(crab.id));

  void _goBox(BuildContext ctx, CrabRecord crab) =>
      ctx.push(RoutePaths.boxDetails(crab.location.boxId));

  void _goCrabDetail(BuildContext ctx, CrabRecord crab) =>
      ctx.push(RoutePaths.crabDetails(crab.id));
}

// ── Narrow layout (mobile < 900px) ───────────────────────────────────────────

class _NarrowLayout extends ConsumerWidget {
  const _NarrowLayout({required this.ref});
  // ignore: unused_field
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(crabManagementProvider);
    final notifier = ref.read(crabManagementProvider.notifier);

    return _MainContent(state: state, notifier: notifier, isWide: false);
  }
}

// ── Shared main content ───────────────────────────────────────────────────────

class _MainContent extends ConsumerStatefulWidget {
  const _MainContent({
    required this.state,
    required this.notifier,
    required this.isWide,
  });

  final CrabManagementState state;
  final CrabManagementNotifier notifier;
  final bool isWide;

  @override
  ConsumerState<_MainContent> createState() => _MainContentState();
}

class _MainContentState extends ConsumerState<_MainContent> {
  @override
  Widget build(BuildContext context) {
    // Re-read from provider so this widget always has fresh state
    final state = ref.watch(crabManagementProvider);
    final notifier = ref.read(crabManagementProvider.notifier);

    return Column(
      children: [
        // ── Page header ──────────────────────────────────────────────────────
        _PageHeader(
          onAddCrab: () => context.push(RoutePaths.addCrab),
          onAddMultiple: _showAddMultiple,
          onImportBatch: () => _showImportBatch(context),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.refresh,
            color: kCmPrimary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── KPI cards ────────────────────────────────────────────
                  state.kpi.when(
                    loading: () => const CrabKpiSkeleton(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (kpi) => CrabKpiCards(
                      kpi: kpi,
                      activeStatus: state.filter.quickStatus,
                      onQuickFilter: (status) {
                        notifier.onQuickStatusSelected(status);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Filter panel ─────────────────────────────────────────
                  CrabFilterPanel(
                    filter: state.filter,
                    dropdown: state.dropdown,
                    notifier: notifier,
                  ),
                  const SizedBox(height: 10),

                  // ── Status chips ─────────────────────────────────────────
                  state.kpi.maybeWhen(
                    data: (kpi) => CrabStatusTabs(
                      kpi: kpi,
                      activeStatus: state.filter.quickStatus,
                      onSelected: notifier.onQuickStatusSelected,
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 10),

                  // ── Bulk action bar ──────────────────────────────────────
                  if (state.selectedIds.isNotEmpty) ...[
                    CrabBulkActionBar(
                      count: state.selectedIds.length,
                      onTransfer: () => _showBulkTransfer(context, state),
                      onUpdateHealth: () => _showBulkHealth(context),
                      onExport: () => _showExport(context, state),
                      onClear: notifier.clearSelection,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // ── Table / List ─────────────────────────────────────────
                  state.page.when(
                    loading: () => const CrabTableSkeleton(rows: 8),
                    error: (e, _) => CrabErrorState(
                      onRetry: notifier.refresh,
                      message: e.toString().contains('401')
                          ? 'Phiên đăng nhập hết hạn. Đăng nhập lại.'
                          : null,
                    ),
                    data: (page) {
                      if (page.total == 0 && state.filter.isEmpty) {
                        return CrabEmptyState(
                          onAddCrab: () => context.push(RoutePaths.addCrab),
                          onImportBatch: () => _showImportBatch(context),
                        );
                      }
                      if (page.items.isEmpty) {
                        return CrabNoResultState(
                          onClearFilter: notifier.clearFilters,
                        );
                      }
                      return widget.isWide
                          ? _buildWideTable(context, page, state, notifier)
                          : _buildMobileList(context, page, state, notifier);
                    },
                  ),

                  const SizedBox(height: 14),

                  // ── Pagination ───────────────────────────────────────────
                  state.page.maybeWhen(
                    data: (page) => page.items.isEmpty
                        ? const SizedBox.shrink()
                        : CrabPaginationBar(
                            currentPage: state.currentPage,
                            totalPages: page.totalPages,
                            total: page.total,
                            pageSize: state.pageSize,
                            onPageChanged: notifier.goToPage,
                            onPageSizeChanged: notifier.setPageSize,
                          ),
                    orElse: () => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Table (wide) ────────────────────────────────────────────────────────────

  Widget _buildWideTable(
    BuildContext context,
    CrabPage page,
    CrabManagementState state,
    CrabManagementNotifier notifier,
  ) {
    return CrabDataTable(
      crabs: page.items,
      selectedIds: state.selectedIds,
      onToggleRow: notifier.toggleSelectRow,
      onToggleAll: notifier.toggleSelectAll,
      onRowTap: (crab) => notifier.selectCrab(crab),
      onViewDetail: (crab) => notifier.selectCrab(crab),
      onActionMenu: (crab, offset) =>
          _showActionMenu(context, crab, offset, notifier),
      selectedCrabId: state.selectedCrab?.id,
      sortColumn: state.sortColumn,
      sortAscending: state.sortAscending,
    );
  }

  // ── List (mobile) ───────────────────────────────────────────────────────────

  Widget _buildMobileList(
    BuildContext context,
    CrabPage page,
    CrabManagementState state,
    CrabManagementNotifier notifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: kCmSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kCmBorder),
        boxShadow: const [
          BoxShadow(color: kCmShadow, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: page.items.asMap().entries.map((e) {
          final crab = e.value;
          return Column(
            children: [
              CrabListTile(
                crab: crab,
                isSelected: state.selectedIds.contains(crab.id),
                isHighlighted: state.selectedCrab?.id == crab.id,
                onTap: () => _showMobileDetail(context, crab, notifier),
                onLongPress: () => notifier.toggleSelectRow(crab.id),
                onActionMenu: (offset) =>
                    _showActionMenu(context, crab, offset, notifier),
              ),
              if (e.key < page.items.length - 1)
                const Divider(height: 1, color: kCmBorder),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Action menu ─────────────────────────────────────────────────────────────

  Future<void> _showActionMenu(
    BuildContext context,
    CrabRecord crab,
    Offset offset,
    CrabManagementNotifier notifier,
  ) async {
    await showCrabActionMenu(
      context: context,
      crab: crab,
      offset: offset,
      onViewDetail: () {
        notifier.selectCrab(crab);
        if (MediaQuery.sizeOf(context).width < 900) {
          _showMobileDetail(context, crab, notifier);
        }
      },
      onUpdateInfo: () => context.push(RoutePaths.crabDetails(crab.id)),
      onViewHistory: () => context.push(RoutePaths.crabDetails(crab.id)),
      onViewBox: () => context.push(RoutePaths.boxDetails(crab.location.boxId)),
      onTransfer: () => _showTransfer(context, crab, notifier),
      onMarkMolting: () => _handleMarkMolting(context, crab, notifier),
      onMarkReadyToHarvest: () =>
          _handleMarkReadyToHarvest(context, crab, notifier),
      onMarkDead: () => _handleMarkDead(context, crab, notifier),
    );
  }

  // ── Mobile bottom sheet detail ───────────────────────────────────────────────

  void _showMobileDetail(
    BuildContext context,
    CrabRecord crab,
    CrabManagementNotifier notifier,
  ) {
    notifier.selectCrab(crab);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scrollCtrl) {
          final st = ref.watch(crabManagementProvider);
          final current = st.selectedCrab ?? crab;
          return Container(
            decoration: const BoxDecoration(
              color: kCmSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kCmBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    child: CrabDetailPanel(
                      crab: current,
                      loading: st.loadingDetail,
                      onClose: () => Navigator.pop(ctx),
                      onViewHistory: () {
                        Navigator.pop(ctx);
                        context.push(RoutePaths.crabDetails(current.id));
                      },
                      onViewBox: () {
                        Navigator.pop(ctx);
                        context.push(
                          RoutePaths.boxDetails(current.location.boxId),
                        );
                      },
                      onViewDetail: () {
                        Navigator.pop(ctx);
                        context.push(RoutePaths.crabDetails(current.id));
                      },
                      onFarmAreaTap: (_) {},
                      onRowTap: (_) {},
                      onBoxTap: (boxId) {
                        Navigator.pop(ctx);
                        context.push(RoutePaths.boxDetails(boxId));
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Mark Molting ─────────────────────────────────────────────────────────────

  Future<void> _handleMarkMolting(
    BuildContext context,
    CrabRecord crab,
    CrabManagementNotifier notifier,
  ) async {
    final result = await showMarkMoltingDialog(context, crab);
    if (result == null || !context.mounted) return;
    try {
      await notifier.markMolting(
        crabId: crab.id,
        detectedAt: result.detectedAt,
        note: result.note,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(_successSnack('✓ Đã đánh dấu ${crab.id} đang lột xác.'));
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_errorSnack('Lỗi: $e'));
      }
    }
  }

  // ── Mark Ready to Harvest ─────────────────────────────────────────────────

  Future<void> _handleMarkReadyToHarvest(
    BuildContext context,
    CrabRecord crab,
    CrabManagementNotifier notifier,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: kCmSurface,
        title: Text(
          'Đánh dấu sắp thu hoạch?',
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: kCmTextPrimary,
          ),
        ),
        content: Text(
          '${crab.id} sẽ được chuyển sang trạng thái Sắp thu hoạch.',
          style: GoogleFonts.nunito(fontSize: 13, color: kCmTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Hủy',
              style: GoogleFonts.nunito(
                color: kCmTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kCmTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Xác nhận',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref
          .read(crabManagementDataSourceProvider)
          .markReadyToHarvest(crab.id);
      await notifier.refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _successSnack('✓ Đã đánh dấu ${crab.id} sắp thu hoạch.'),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_errorSnack('Lỗi: $e'));
      }
    }
  }

  // ── Mark Dead ────────────────────────────────────────────────────────────────

  Future<void> _handleMarkDead(
    BuildContext context,
    CrabRecord crab,
    CrabManagementNotifier notifier,
  ) async {
    final result = await showMarkDeadDialog(context, crab);
    if (result == null || !context.mounted) return;
    try {
      await notifier.markDead(
        crabId: crab.id,
        detectedAt: result.detectedAt,
        reason: result.reason,
        note: result.note,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(_successSnack('Đã ghi nhận ${crab.id} đã chết.'));
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_errorSnack('Lỗi: $e'));
      }
    }
  }

  // ── Transfer ─────────────────────────────────────────────────────────────────

  Future<void> _showTransfer(
    BuildContext context,
    CrabRecord crab,
    CrabManagementNotifier notifier,
  ) async {
    final ds = ref.read(crabManagementDataSourceProvider);
    final farms = ref.read(crabManagementProvider).dropdown.farmAreas;
    final toBoxId = await showTransferCrabDialog(
      context,
      crab,
      farms,
      (farmId) => ds.getRows(farmAreaId: farmId),
      (rowId) => ds.getBoxes(rowId: rowId),
    );
    if (toBoxId == null || !context.mounted) return;
    try {
      await notifier.transferCrab(crabId: crab.id, toBoxId: toBoxId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(_successSnack('✓ Đã chuyển ${crab.id} sang hộp mới.'));
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_errorSnack('Lỗi: $e'));
      }
    }
  }

  // ── Bulk actions ──────────────────────────────────────────────────────────────

  void _showBulkTransfer(BuildContext context, CrabManagementState state) {
    ScaffoldMessenger.of(context).showSnackBar(
      _infoSnack('Chức năng chuyển hộp hàng loạt đang phát triển.'),
    );
  }

  void _showBulkHealth(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      _infoSnack('Chức năng cập nhật sức khỏe hàng loạt đang phát triển.'),
    );
  }

  void _showExport(BuildContext context, CrabManagementState state) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(_infoSnack('Đang xuất ${state.selectedIds.length} cua...'));
  }

  void _showAddMultiple() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(_infoSnack('Thêm nhiều cua đang phát triển.'));
  }

  void _showImportBatch(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(_infoSnack('Mở luồng nhập lô...'));
  }

  // ── Snack helpers ─────────────────────────────────────────────────────────────

  static SnackBar _successSnack(String msg) => SnackBar(
    content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
    backgroundColor: kCmPrimary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    duration: const Duration(seconds: 3),
  );

  static SnackBar _errorSnack(String msg) => SnackBar(
    content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
    backgroundColor: kCmRed,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  static SnackBar _infoSnack(String msg) => SnackBar(
    content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
    backgroundColor: kCmPrimaryDark,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}

// ── Page header ───────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.onAddCrab,
    required this.onAddMultiple,
    required this.onImportBatch,
  });
  final VoidCallback onAddCrab;
  final VoidCallback onAddMultiple;
  final VoidCallback onImportBatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: kCmSurface,
        border: Border(bottom: BorderSide(color: kCmBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Text(
                  'Dashboard',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: kCmPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                ' › ',
                style: GoogleFonts.nunito(fontSize: 12, color: kCmTextHint),
              ),
              Text(
                'Quản lý Cua',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: kCmTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kCmPrimaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🦀', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý Cua',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: kCmTextPrimary,
                      ),
                    ),
                    Text(
                      'Giám sát và quản lý từng cá thể cua trong hệ thống.',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: kCmTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              Wrap(
                spacing: 8,
                children: [
                  // Nhập lô
                  OutlinedButton.icon(
                    onPressed: onImportBatch,
                    icon: const Icon(Icons.upload_file_rounded, size: 14),
                    label: Text(
                      'Nhập lô',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kCmPrimaryDark,
                      side: const BorderSide(color: kCmPrimaryDark),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  // Thêm nhiều
                  OutlinedButton.icon(
                    onPressed: onAddMultiple,
                    icon: const Icon(Icons.playlist_add_rounded, size: 14),
                    label: Text(
                      'Thêm nhiều',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kCmPrimaryDark,
                      side: const BorderSide(color: kCmPrimaryDark),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  // + Thêm Cua (primary)
                  ElevatedButton.icon(
                    onPressed: onAddCrab,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      '+ Thêm Cua',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kCmPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
