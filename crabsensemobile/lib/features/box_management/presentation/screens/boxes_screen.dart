import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../home/presentation/widgets/crab_hologram_painter.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/models/boxes_models.dart';
import '../providers/boxes_provider.dart';
import '../widgets/box_filter_chips.dart';
import '../widgets/box_grid.dart';
import '../widgets/box_quick_sheets.dart';
import '../widgets/boxes_empty_state.dart';
import '../widgets/boxes_filter_sheet.dart';
import '../widgets/boxes_header.dart';
import '../widgets/boxes_search_bar.dart';
import '../widgets/boxes_skeleton.dart';
import '../widgets/farm_digital_twin.dart';
import '../widgets/farm_overview_summary.dart';
import '../../../notifications/presentation/providers/unread_notifications_provider.dart';

/// Boxes tab — Farm Digital Twin command surface.
class BoxesScreen extends ConsumerStatefulWidget {
  const BoxesScreen({super.key});

  @override
  ConsumerState<BoxesScreen> createState() => _BoxesScreenState();
}

class _BoxesScreenState extends ConsumerState<BoxesScreen> {
  bool _showSearch = false;
  UserRole? _lastRole;

  void _syncPermissions(UserRole role) {
    if (_lastRole == role) return;
    _lastRole = role;
    final flags = BoxesPermissionFlags(
      canCreateBox: role.isAdmin || role.canManageUsers,
      canEditBox: role.isAdmin || role.canManageUsers,
      canPerformActions: role.canPerformFieldOperations,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(boxesStateProvider.notifier).updatePermissions(flags);
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CrabSenseColors.container,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showCreateBoxSheet(BoxesStateData data) async {
    final rows = await ref.read(boxesStateProvider.notifier).fetchRows();
    if (!mounted) return;
    if (rows.isEmpty) {
      _snack('Chưa có dãy nuôi — tạo Farming Row trước khi thêm Box');
      return;
    }

    String selectedRowId = rows.first.id;
    final codeController = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: kHomeBorderBlue.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.paddingOf(ctx).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: kHomeBorderBlue.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'THÊM BOX',
                      style: TextStyle(
                        color: kHomeBlueLight,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRowId,
                      dropdownColor: kHomeNavy,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Dãy nuôi',
                        labelStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: kHomeNavyDeep.withValues(alpha: 0.75),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: kHomeBorderBlue.withValues(alpha: 0.4),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: kHomeBlue.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      items: rows
                          .map(
                            (r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(r.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModal(() => selectedRowId = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Mã Box (để trống = tự sinh)',
                        labelStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: kHomeNavyDeep.withValues(alpha: 0.75),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: kHomeBorderBlue.withValues(alpha: 0.4),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: kHomeBlue.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: kHomeBlue,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: kHomeBlue.withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Tạo Box'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    final code = codeController.text.trim();
    codeController.dispose();
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(boxesStateProvider.notifier).createBox(
            farmingRowId: selectedRowId,
            code: code.isEmpty ? null : code,
          );
      _snack('Đã tạo Box thành công');
    } catch (e) {
      _snack('Không tạo được Box: $e');
    }
  }

  Future<void> _openViewModeSheet(BoxesViewMode current) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.5)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: kHomeBorderBlue.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'CHẾ ĐỘ HIỂN THỊ',
                    style: TextStyle(
                      color: kHomeBlueLight,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ViewModeSwitcher(
                    mode: current,
                    onChanged: (mode) {
                      Navigator.pop(ctx);
                      ref.read(boxesStateProvider.notifier).setViewMode(mode);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAdvancedFilter(BoxesStateData data) async {
    final result = await showBoxesFilterSheet(
      context,
      initial: data.advancedFilter,
      areas: data.availableAreas,
      previewCount: (f) =>
          ref.read(boxesStateProvider.notifier).previewFilterCount(f),
    );
    if (result != null) {
      ref.read(boxesStateProvider.notifier).applyAdvancedFilter(result);
    }
  }

  void _explainHealth(BoxSummary box) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CrabSenseColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Health Score ${box.healthScore.score}',
          style: const TextStyle(color: CrabSenseColors.textPrimary),
        ),
        content: Text(
          '${box.healthScore.explanation}\n\n'
          'AI Confidence: ${box.healthScore.aiConfidence.round()}%\n'
          'Xu hướng: ${box.healthScore.trend.label}\n'
          'Mức: ${box.healthScore.statusLabel}',
          style: const TextStyle(
            color: CrabSenseColors.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _handleAction(BoxSummary box, String action, bool canAct) {
    switch (action) {
      case 'qr':
        if (!canAct) {
          _snack('Bạn không có quyền thực hiện thao tác này');
          return;
        }
        context.push(RoutePaths.scanner);
      case 'ai':
        if (!canAct) {
          _snack('Bạn không có quyền thực hiện thao tác này');
          return;
        }
        context.push(RoutePaths.boxVideo(box.id));
      case 'water':
        context.push(
          box.farmId.isNotEmpty
              ? RoutePaths.waterQualityForFarm(box.farmId)
              : RoutePaths.waterQuality,
        );
      case 'harvest':
        if (!canAct) {
          _snack('Bạn không có quyền thu hoạch');
          return;
        }
        context.push(
          RoutePaths.harvest,
          extra: {'boxId': box.id, 'farmId': box.farmId},
        );
      case 'detail':
        context.push(RoutePaths.boxDetails(box.id));
      default:
        showBoxQuickActionsSheet(context, box: box, canPerformActions: canAct);
    }
  }

  int _gridColumns(double width) {
    if (width >= 1000) return 4;
    if (width >= 700) return 3;
    if (width >= 420) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final role = authState is Authenticated
        ? authState.user.role
        : UserRole.viewer;
    _syncPermissions(role);

    final asyncState = ref.watch(boxesStateProvider);
    final width = MediaQuery.sizeOf(context).width;
    final columns = _gridColumns(width);

    return Scaffold(
      backgroundColor: const Color(0xFF071426),
      floatingActionButton: asyncState.maybeWhen(
        data: (data) {
          if (!data.canCreateBox) return null;
          return _AddBoxFab(onPressed: () => _showCreateBoxSheet(data));
        },
        orElse: () => null,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CrabHologramPainter(
                  color: kHomeBlueLight.withValues(alpha: 0.05),
                  trayExtent: 32,
                ),
              ),
            ),
          ),
          SafeArea(
            child: asyncState.when(
              loading: () => BoxesSkeleton(gridColumns: columns),
              error: (error, _) => Center(
                child: BoxesSectionErrorCard(
                  message: error.toString(),
                  onRetry: () => ref
                      .read(boxesStateProvider.notifier)
                      .loadData(forceRefresh: true),
                ),
              ),
              data: (data) => _buildContent(data, columns),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BoxesStateData data, int columns) {
    final isMap = data.viewMode == BoxesViewMode.farmMap;
    final gap = isMap ? 8.0 : 12.0;

    return RefreshIndicator(
      onRefresh: () => ref.read(boxesStateProvider.notifier).refresh(),
      color: kHomeBlue,
      backgroundColor: kHomeNavy,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Màn thấp: ẩn overview để Column + Expanded không overflow.
          final hideOverview =
              isMap || constraints.maxHeight < 520;

          return Padding(
            padding: EdgeInsets.fromLTRB(16, isMap ? 8 : 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.isOfflineCached || !data.isOnline)
                  BoxesOfflineBanner(
                    lastSyncedAt: data.lastSyncedAt,
                    onRetry: () =>
                        ref.read(boxesStateProvider.notifier).refresh(),
                  ),
                if (data.sectionError != null)
                  BoxesSectionErrorCard(
                    message: data.sectionError!,
                    onRetry: () =>
                        ref.read(boxesStateProvider.notifier).refresh(),
                  ),
                BoxesHeader(
                  data: data,
                  onFarmSwitched: (id) {
                    ref.read(boxesStateProvider.notifier).switchFarm(id);
                    final name = data.availableFarms
                        .where((f) => f.id == id)
                        .map((f) => f.name)
                        .firstOrNull;
                    _snack('Đã chuyển sang ${name ?? id}');
                  },
                  onSearchPressed: () =>
                      setState(() => _showSearch = !_showSearch),
                  onFilterPressed: () => _openAdvancedFilter(data),
                  onViewModePressed: () => _openViewModeSheet(data.viewMode),
                  onNotificationPressed: () async {
                    await context.push(RoutePaths.alerts);
                    if (mounted) {
                      ref.invalidate(unreadNotificationsCountProvider);
                    }
                  },
                ),
                SizedBox(height: gap),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _showSearch || data.searchQuery.isNotEmpty
                      ? BoxesSearchBar(
                          key: const ValueKey('search-on'),
                          initialQuery: data.searchQuery,
                          recentSearches: data.recentSearches,
                          autofocus: _showSearch,
                          onChanged: (q) => ref
                              .read(boxesStateProvider.notifier)
                              .setSearchQuery(q),
                          onClear: () => ref
                              .read(boxesStateProvider.notifier)
                              .clearSearch(),
                          onRecentSelected: (q) => ref
                              .read(boxesStateProvider.notifier)
                              .setSearchQuery(q),
                        )
                      : const SizedBox.shrink(key: ValueKey('search-off')),
                ),
                if (_showSearch || data.searchQuery.isNotEmpty)
                  SizedBox(height: gap),
                if (!hideOverview) ...[
                  FarmOverviewSummary(
                    overview: data.overview,
                    onStatusTap: (chip) => ref
                        .read(boxesStateProvider.notifier)
                        .toggleQuickFilter(chip),
                  ),
                  SizedBox(height: gap),
                ],
                BoxFilterChips(
                  activeFilters: data.quickFilters,
                  onToggle: (f) => ref
                      .read(boxesStateProvider.notifier)
                      .toggleQuickFilter(f),
                  onClear: () =>
                      ref.read(boxesStateProvider.notifier).clearFilters(),
                ),
                SizedBox(height: isMap ? 6 : 8),
                ViewModeSwitcher(
                  mode: data.viewMode,
                  onChanged: (m) =>
                      ref.read(boxesStateProvider.notifier).setViewMode(m),
                ),
                SizedBox(height: gap),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _buildBody(data, columns),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BoxesStateData data, int columns) {
    if (data.allBoxes.isEmpty) {
      return BoxesEmptyState.noBoxes(
        key: const ValueKey('empty-all'),
        canCreate: data.canCreateBox,
        onCreate: () => _showCreateBoxSheet(data),
      );
    }

    if (data.visibleBoxes.isEmpty) {
      return BoxesEmptyState.search(
        key: const ValueKey('empty-search'),
        onClearSearch: () =>
            ref.read(boxesStateProvider.notifier).clearSearch(),
        onResetFilters: () =>
            ref.read(boxesStateProvider.notifier).clearFilters(),
      );
    }

    switch (data.viewMode) {
      case BoxesViewMode.grid:
        return BoxGrid(
          key: const ValueKey('grid'),
          boxes: data.visibleBoxes,
          columns: columns,
          isLoadingMore: data.isLoadingMore,
          onBoxTap: (box) => context.push(RoutePaths.boxDetails(box.id)),
          onBoxLongPress: (box) => showBoxQuickActionsSheet(
            context,
            box: box,
            canPerformActions: data.canPerformActions,
          ),
          onMenuSelected: (box, action) =>
              _handleAction(box, action, data.canPerformActions),
          onExplainHealth: _explainHealth,
        );
      case BoxesViewMode.list:
        return BoxList(
          key: const ValueKey('list'),
          boxes: data.visibleBoxes,
          isLoadingMore: data.isLoadingMore,
          onBoxTap: (box) => context.push(RoutePaths.boxDetails(box.id)),
          onSwipeAction: (box, action) =>
              _handleAction(box, action, data.canPerformActions),
        );
      case BoxesViewMode.farmMap:
        return FarmDigitalTwin(
          key: const ValueKey('map'),
          boxes: data.visibleBoxes,
          selectedBoxId: data.selectedBoxId,
          onBoxSelected: (box) {
            ref.read(boxesStateProvider.notifier).selectBox(box.id);
            showBoxQuickPreviewSheet(
              context,
              box: box,
              canPerformActions: data.canPerformActions,
            );
          },
        );
    }
  }
}

/// FAB “Thêm hộp” — phong cách hologram navy/cyan (không dùng Material FAB mặc định).
class _AddBoxFab extends StatelessWidget {
  const _AddBoxFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
            ),
            border: Border.all(
              color: kHomeCyan.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: kHomeCyan.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: kHomeBlue.withValues(alpha: 0.2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kHomeCyan.withValues(alpha: 0.14),
                  border: Border.all(
                    color: kHomeCyan.withValues(alpha: 0.45),
                  ),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: kHomeCyan,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Thêm hộp',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
