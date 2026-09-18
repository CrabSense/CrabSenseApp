import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../../notifications/presentation/providers/unread_notifications_provider.dart';
import '../../domain/models/boxes_models.dart';
import '../providers/boxes_provider.dart';
import '../widgets/box_quick_sheets.dart';
import '../widgets/boxes_skeleton.dart';
import '../widgets/box_qr_sheet.dart';
import '../widgets/farm_structure_manage_sheet.dart';

/// Số cột của lưới hộp — dùng chung cho cả lưới và hàm sắp thứ tự đánh số.
const int _boxGridColumns = 4;

/// Boxes tab — Farm map view, light theme.
class BoxesScreen extends ConsumerStatefulWidget {
  const BoxesScreen({super.key});

  @override
  ConsumerState<BoxesScreen> createState() => _BoxesScreenState();
}

class _BoxesScreenState extends ConsumerState<BoxesScreen> {
  UserRole? _lastRole;
  String? _selectedFarmId;

  Future<void> _showCreateStructure(String type) async {
    final controller = TextEditingController();
    final capacityController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();
    String? selectedAreaId = _selectedFarmId;
    final state = ref.read(boxesStateProvider);
    if (selectedAreaId == null && state.hasValue) {
      selectedAreaId = state.value?.selectedFarmId ??
          (state.value?.availableFarms.isNotEmpty == true
              ? state.value!.availableFarms.first.id
              : null);
    }
    final result = await showDialog<({String name, int capacity})>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: Text('Tạo ${type.toLowerCase()}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Tên $type',
                  hintText: type == 'Khu' ? 'Ví dụ: Khu A' : 'Ví dụ: Dãy A1',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập tên $type'
                    : null,
                onFieldSubmitted: (_) {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.pop(dialogContext, (
                      name: controller.text.trim(),
                      capacity: type == 'Dãy'
                          ? int.parse(capacityController.text.trim())
                          : 0,
                    ));
                  }
                },
              ),
              if (type == 'Dãy') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Số hộp trong dãy',
                    hintText: 'Ví dụ: 20',
                    helperText: 'Hệ thống sẽ tạo sẵn đúng số hộp này',
                  ),
                  validator: (value) {
                    final count = int.tryParse(value?.trim() ?? '');
                    if (count == null || count < 1 || count > 500) {
                      return 'Nhập số hộp từ 1 đến 500';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.check_rounded),
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(dialogContext, (
                name: controller.text.trim(),
                capacity: type == 'Dãy'
                    ? int.parse(capacityController.text.trim())
                    : 0,
              ));
            },
            label: const Text('Lưu'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
      capacityController.dispose();
    });
    if (!mounted || result == null) return;
    final name = result.name;

    try {
      if (type == 'Dãy') {
        if (selectedAreaId == null) {
          _snack('Hãy tạo hoặc chọn khu nuôi trước khi tạo dãy');
          return;
        }
        await ref.read(boxesStateProvider.notifier).createRow(
              farmingAreaId: selectedAreaId,
              name: name,
              capacity: result.capacity,
            );
      } else {
        await ref.read(boxesStateProvider.notifier).createArea(name: name);
      }
      if (mounted) _snack('Đã tạo $type $name');
    } catch (error) {
      if (mounted) _snack(farmApiMessage(error));
    }
  }

  void _closeSheetThen(BuildContext sheetContext, VoidCallback next) {
    Navigator.pop(sheetContext);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      next();
    });
  }

  void _showStructureActions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottom = MediaQuery.paddingOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.55,
            ),
            decoration: const BoxDecoration(
              color: kHomeSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: kHomeBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Cấu trúc khu nuôi',
                    style: TextStyle(
                      color: kHomePrimaryDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Khu → Dãy → Hộp',
                    style: TextStyle(color: kHomeTextSub, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  _StructureActionTile(
                    icon: Icons.tune_rounded,
                    title: 'Quản lý khu / dãy / hộp',
                    subtitle: 'Xem, sửa, xóa',
                    onTap: () => _closeSheetThen(sheetContext, () {
                      showFarmStructureManageSheet(context);
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _CompactCreateChip(
                          icon: Icons.add_business_rounded,
                          label: 'Khu',
                          onTap: () => _closeSheetThen(sheetContext, () {
                            _showCreateStructure('Khu');
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CompactCreateChip(
                          icon: Icons.view_stream_rounded,
                          label: 'Dãy',
                          onTap: () => _closeSheetThen(sheetContext, () {
                            _showCreateStructure('Dãy');
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CompactCreateChip(
                          icon: Icons.inventory_2_rounded,
                          label: 'Hộp',
                          onTap: () => _closeSheetThen(sheetContext, () {
                            _showCreateBox();
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _StructureActionTile(
                    icon: Icons.refresh_rounded,
                    title: 'Làm mới sơ đồ',
                    onTap: () => _closeSheetThen(sheetContext, () {
                      ref.read(boxesStateProvider.notifier).refresh();
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreateBox() async {
    final rows = await ref.read(boxesStateProvider.notifier).fetchRows();
    if (!mounted) return;
    if (rows.isEmpty) {
      _snack('Hãy tạo khu và dãy nuôi trước khi tạo hộp');
      return;
    }
    ({String id, String name})? selected = rows.first;
    final codeController = TextEditingController();
    final result = await showDialog<({String rowId, String? code})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tạo hộp nuôi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<({String id, String name})>(
                value: selected,
                decoration: const InputDecoration(labelText: 'Dãy nuôi'),
                items: rows.map((row) => DropdownMenuItem(value: row, child: Text(row.name))).toList(),
                onChanged: (row) => setDialogState(() => selected = row),
              ),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Mã hộp (tuỳ chọn)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, (
                rowId: selected!.id,
                code: codeController.text.trim().isEmpty ? null : codeController.text.trim(),
              )),
              child: const Text('Tạo hộp'),
            ),
          ],
        ),
      ),
    );
    codeController.dispose();
    if (!mounted || result == null) return;
    try {
      await ref.read(boxesStateProvider.notifier).createBox(
            farmingRowId: result.rowId,
            code: result.code,
          );
      if (mounted) _snack('Đã tạo hộp nuôi');
    } catch (error) {
      if (mounted) {
        final message = error.toString().contains('409') ||
                error.toString().toLowerCase().contains('full')
            ? 'Dãy nuôi đã đầy. Hãy chọn dãy khác hoặc tăng sức chứa.'
            : 'Không thể tạo hộp. Vui lòng kiểm tra lại dữ liệu.';
        _snack(message);
      }
    }
  }

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

  String _boxesErrorMessage(Object error) {
    final text = error.toString();
    if (text.contains('401') ||
        text.toLowerCase().contains('unauthorized') ||
        text.toLowerCase().contains('refresh token') ||
        text.toLowerCase().contains('access token')) {
      return 'Phiên đăng nhập hết hạn hoặc chưa gửi token. Đăng nhập lại rồi thử lại.';
    }
    if (text.contains('403') || text.toLowerCase().contains('forbidden')) {
      return 'Tài khoản không có quyền xem sơ đồ hộp nuôi.';
    }
    return farmApiMessage(error);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kHomePrimaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleBoxTap(BoxSummary box) async {
    await context.push(RoutePaths.boxCrabs(box.id, boxCode: box.code));
    if (!mounted) return;
    await ref.read(boxesStateProvider.notifier).refresh();
  }

  Future<void> _handleBoxManage(BoxSummary box) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(title: Text('Hộp ${box.code}')),
            ListTile(
              leading: const Icon(Icons.set_meal_outlined),
              title: const Text('Xem cua trong hộp'),
              onTap: () => Navigator.pop(ctx, 'crabs'),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2_rounded),
              title: const Text('Mã QR hộp'),
              subtitle: const Text('Tạo / xem để in tem'),
              onTap: () => Navigator.pop(ctx, 'qr'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Sửa mã hộp'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: kHomeDanger),
              title: const Text('Xóa hộp', style: TextStyle(color: kHomeDanger)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'crabs') {
      await _handleBoxTap(box);
      return;
    }
    if (action == 'qr') {
      if (!mounted) return;
      await showBoxQrSheet(context, boxId: box.id, boxCode: box.code);
      return;
    }
    if (action == 'edit') {
      final controller = TextEditingController(text: box.code);
      final code = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sửa mã hộp'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Mã hộp'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Lưu'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (code == null || code.isEmpty || !mounted) return;
      try {
        await ref.read(boxesStateProvider.notifier).updateBox(
              id: box.id,
              code: code,
              isOccupied: box.crabCount > 0,
            );
        if (mounted) _snack('Đã cập nhật hộp $code');
      } catch (error) {
        if (mounted) _snack(farmApiMessage(error));
      }
      return;
    }
    if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Xóa hộp ${box.code}?'),
          content: const Text('Chỉ xóa được khi hộp không còn cua sống.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kHomeDanger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xóa'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      try {
        await ref.read(boxesStateProvider.notifier).deleteBox(box.id);
        if (mounted) _snack('Đã xóa hộp ${box.code}');
      } catch (error) {
        if (mounted) _snack(farmApiMessage(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final role = authState is Authenticated ? authState.user.role : UserRole.viewer;
    _syncPermissions(role);

    final asyncState = ref.watch(boxesStateProvider);

    return Scaffold(
      backgroundColor: kHomeBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/home_pattern.jpg'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                opacity: 0.45,
              ),
            ),
          ),
          const ColoredBox(color: Color(0xD6F4F7F2)),
          SafeArea(
            child: Column(
              children: [
                _BoxesTopBar(onManage: _showStructureActions),
                Expanded(
                  child: asyncState.when(
                    loading: () => const BoxesSkeleton(gridColumns: 4),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: kHomeDangerBg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                color: kHomeDanger,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _boxesErrorMessage(e),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: kHomeTextSub),
                            ),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: () => ref
                                  .read(boxesStateProvider.notifier)
                                  .loadData(forceRefresh: true),
                              style: FilledButton.styleFrom(
                                backgroundColor: kHomePrimary,
                                foregroundColor: kHomePrimaryDark,
                              ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (data) => _buildContent(data),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BoxesStateData data) {
    final farms = data.availableFarms;
    final selectedFarm = farms.where((farm) => farm.id == data.selectedFarmId).firstOrNull ??
      (farms.isNotEmpty ? farms.first : null);
    final boxes = data.visibleBoxes;
    final allBoxes = data.allBoxes;
    final occupiedCount = allBoxes.where((b) => b.crabCount > 0).length;
    final emptyCount = allBoxes.length - occupiedCount;
    final activeFilters = data.quickFilters;

    return RefreshIndicator(
      onRefresh: () => ref.read(boxesStateProvider.notifier).refresh(),
      color: kHomePrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FarmHeaderCard(
              farms: farms,
              selectedFarm: selectedFarm,
              totalBoxes: allBoxes.length,
              activeBoxes: occupiedCount,
              emptyBoxes: emptyCount,
              onFarmChanged: (id) {
                _selectedFarmId = id;
                ref.read(boxesStateProvider.notifier).switchFarm(id);
              },
              onStatTap: (filter) {
                ref.read(boxesStateProvider.notifier).toggleQuickFilter(filter);
              },
            ),
            const SizedBox(height: 12),
            _OccupancyFilterRow(
              active: activeFilters,
              onToggle: (f) =>
                  ref.read(boxesStateProvider.notifier).toggleQuickFilter(f),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: HomeSectionHeader(
                    icon: Icons.grid_view_rounded,
                    title: 'Hộp nuôi (${boxes.length})',
                  ),
                ),
                _BoxLayoutOrderBar(
                  value: data.boxLayoutOrder,
                  onChanged: (o) => ref
                      .read(boxesStateProvider.notifier)
                      .setBoxLayoutOrder(o),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const _CompactLegend(),
            const SizedBox(height: 10),

            if (boxes.isEmpty)
              _EmptyBoxState(
                canCreate: data.canCreateBox,
                onCreate: _showStructureActions,
              )
            else
              _BoxFarmGrid(
                boxes: applyBoxLayoutOrder(
                  boxes,
                  data.boxLayoutOrder,
                  _boxGridColumns,
                ),
                onBoxTap: _handleBoxTap,
                onBoxLongPress: data.canEditBox ? _handleBoxManage : null,
              ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(RoutePaths.reports),
                style: FilledButton.styleFrom(
                  backgroundColor: kHomePrimary,
                  foregroundColor: kHomePrimaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                ),
                icon: const Icon(Icons.bar_chart_rounded),
                label: const Text(
                  'Thống kê trang trại',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Soft top bar (Home-aligned) ─────────────────────────────────────────────

class _BoxesTopBar extends StatelessWidget {
  const _BoxesTopBar({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: kHomePrimaryBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kHomeBorder),
            ),
            child: const Icon(
              Icons.map_rounded,
              size: 20,
              color: kHomePrimaryDark,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sơ đồ trang trại',
                  style: TextStyle(
                    color: kHomePrimaryDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Kéo xuống để làm mới',
                  style: TextStyle(
                    color: kHomeTextSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onManage,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: kHomePrimary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: kHomeShadow,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: kHomePrimaryDark,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Quản lý',
                      style: TextStyle(
                        color: kHomePrimaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactCreateChip extends StatelessWidget {
  const _CompactCreateChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: CrabSenseColors.primaryMuted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kHomeBorder),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: kHomePrimaryDark),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: kHomePrimaryDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StructureActionTile extends StatelessWidget {
  const _StructureActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: CrabSenseColors.primaryMuted,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kHomeBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kHomeSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kHomeBorder),
                  ),
                  child: Icon(icon, color: kHomePrimaryDark, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: kHomePrimaryDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: kHomeTextSub,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: kHomeTextHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Farm Header Card ─────────────────────────────────────────────────────────

class _FarmOption {
  static final empty = _FarmAvailableFarmModel(id: '', name: 'Tất cả trang trại');
}

class _FarmAvailableFarmModel {
  final String id;
  final String name;
  _FarmAvailableFarmModel({required this.id, required this.name});
}

class _FarmHeaderCard extends StatelessWidget {
  const _FarmHeaderCard({
    required this.farms,
    required this.selectedFarm,
    required this.totalBoxes,
    required this.activeBoxes,
    required this.emptyBoxes,
    required this.onFarmChanged,
    this.onStatTap,
  });

  final List farms;
  final dynamic selectedFarm;
  final int totalBoxes;
  final int activeBoxes;
  final int emptyBoxes;
  final void Function(String) onFarmChanged;
  final void Function(BoxQuickFilter filter)? onStatTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: homeCardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kHomePrimaryBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.waves_rounded,
                  color: kHomePrimaryDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Khu nuôi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kHomeTextSub,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: CrabSenseColors.primaryMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kHomeBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedFarm == null ||
                            (selectedFarm.id as String).isEmpty
                        ? null
                        : selectedFarm.id as String,
                    icon: const Icon(
                      Icons.expand_more_rounded,
                      color: kHomePrimaryDark,
                      size: 20,
                    ),
                    style: const TextStyle(
                      color: kHomePrimaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    hint: Text(
                      farms.isNotEmpty
                          ? (farms.first as dynamic).name as String
                          : 'Chọn khu',
                      style: const TextStyle(
                        color: kHomePrimaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    items: farms.map<DropdownMenuItem<String>>((f) {
                      return DropdownMenuItem<String>(
                        value: (f as dynamic).id as String,
                        child: Text((f as dynamic).name as String),
                      );
                    }).toList(),
                    onChanged: (id) {
                      if (id != null) onFarmChanged(id);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onStatTap?.call(BoxQuickFilter.all),
                  child: _StatItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Tổng',
                    value: '$totalBoxes',
                    color: kHomePrimaryDark,
                    tint: kHomePrimaryBg,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => onStatTap?.call(BoxQuickFilter.occupied),
                  child: _StatItem(
                    icon: Icons.check_circle_rounded,
                    label: 'Đang nuôi',
                    value: '$activeBoxes',
                    color: kHomePrimaryDark,
                    tint: const Color(0xFFD5F5E3),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => onStatTap?.call(BoxQuickFilter.empty),
                  child: _StatItem(
                    icon: Icons.crop_square_rounded,
                    label: 'Trống',
                    value: '$emptyBoxes',
                    color: kHomeTextSub,
                    tint: const Color(0xFFEEF1ED),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kHomeBorder.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: kHomeTextSub,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Box Farm Grid ─────────────────────────────────────────────────────────────

class _BoxFarmGrid extends StatelessWidget {
  const _BoxFarmGrid({
    required this.boxes,
    required this.onBoxTap,
    this.onBoxLongPress,
  });

  final List<BoxSummary> boxes;
  final void Function(BoxSummary) onBoxTap;
  final void Function(BoxSummary)? onBoxLongPress;

  /// Màu ô hộp — lấy thẳng từ [BoxStatus].
  ///
  /// `BoxStatus` đã là tình trạng XẤU NHẤT của cua trong hộp (xem
  /// `boxStatusFromCrabCondition`), nên lưới, chú giải, huy hiệu trạng thái và
  /// app desktop dùng chung một nguồn màu. Trước đây ô lưới tự parse
  /// `crabCondition` còn huy hiệu lại đọc `healthStatus` nên hai chỗ lệch nhau.
  Color _bgColor(BoxSummary box) {
    if (box.alerts.hasAlerts) return kHomeDangerBg;
    return box.status.background;
  }

  Color _borderColor(BoxSummary box) {
    if (box.alerts.hasAlerts) return kHomeDanger;
    return box.status.color;
  }

  Color _accentColor(BoxSummary box) {
    if (box.alerts.hasAlerts) return kHomeDanger;
    return box.status.color;
  }

  String _boxLabel(BoxSummary box) {
    final code = box.code.trim();
    if (code.isNotEmpty && code.toLowerCase() != 'x') return code;
    final qr = box.qrCode.trim();
    if (qr.isNotEmpty && qr.toLowerCase() != 'x') return qr;
    final name = box.name.trim();
    if (name.isNotEmpty) return name;
    return box.id.substring(0, 4).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _boxGridColumns,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.92,
      ),
      itemCount: boxes.length,
      itemBuilder: (context, i) {
        final box = boxes[i];
        final bg = _bgColor(box);
        final border = _borderColor(box);
        final accent = _accentColor(box);
        final occupied = box.crabCount > 0;
        final label = _boxLabel(box);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onBoxTap(box),
            onLongPress:
                onBoxLongPress == null ? null : () => onBoxLongPress!(box),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: kHomeShadow,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (occupied)
                      Image.asset(
                        'assets/images/crab_icon.png',
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.pets_rounded,
                          size: 26,
                          color: accent,
                        ),
                      )
                    else
                      Icon(
                        Icons.crop_square_rounded,
                        size: 28,
                        color: accent,
                      ),
                    const SizedBox(height: 6),
                    // Mã hộp dài nhất 12 ký tự ("BOX-0001" … "BOX-abcdef12") mà ô
                    // chỉ rộng ~72px, nên ellipsis cũ cắt mất đúng phần số phân
                    // biệt hộp: cả lưới hiện "BOX-00…" giống hệt nhau. Thu nhỏ
                    // vừa ô thay vì cắt, để luôn đọc được hộp nào là hộp nào.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Compact status legend (inline) ───────────────────────────────────────────

class _OccupancyFilterRow extends StatelessWidget {
  const _OccupancyFilterRow({
    required this.active,
    required this.onToggle,
  });

  final Set<BoxQuickFilter> active;
  final ValueChanged<BoxQuickFilter> onToggle;

  @override
  Widget build(BuildContext context) {
    const filters = [
      BoxQuickFilter.all,
      BoxQuickFilter.occupied,
      BoxQuickFilter.empty,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final f in filters)
          FilterChip(
            selected: active.contains(f) ||
                (f == BoxQuickFilter.all &&
                    active.length == 1 &&
                    active.contains(BoxQuickFilter.all)),
            label: Text(f.label),
            onSelected: (_) => onToggle(f),
            selectedColor: kHomePrimaryBg,
            checkmarkColor: kHomePrimaryDark,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: active.contains(f) ||
                      (f == BoxQuickFilter.all &&
                          active.contains(BoxQuickFilter.all))
                  ? kHomePrimaryDark
                  : kHomeTextSub,
            ),
            side: BorderSide(color: kHomeBorder),
            backgroundColor: kHomeSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }
}

class _CompactLegend extends StatelessWidget {
  const _CompactLegend();

  @override
  Widget build(BuildContext context) {
    // Lấy thẳng từ [BoxStatus] — cùng nguồn với màu ô hộp nên chú giải không bao
    // giờ lệch lưới. Bỏ "Sự cố" vì lưới không tô màu đó bao giờ (cua chết / đã
    // bán được BE trả hộp về trống).
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: [
        for (final status in BoxStatus.displayable)
          _DotHint(color: status.color, tip: status.label),
      ],
    );
  }
}

/// Chọn hướng đánh số hộp trên lưới — biểu diễn bằng mũi tên, không dùng chữ.
class _BoxLayoutOrderBar extends StatelessWidget {
  const _BoxLayoutOrderBar({required this.value, required this.onChanged});

  final BoxLayoutOrder value;
  final ValueChanged<BoxLayoutOrder> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: kHomeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kHomeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in BoxLayoutOrder.values) ...[
            if (o != BoxLayoutOrder.values.first) const SizedBox(width: 2),
            Tooltip(
              message: o.tooltip,
              child: InkWell(
                onTap: () => onChanged(o),
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  width: 32,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == o ? kHomePrimaryBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: value == o ? kHomePrimary : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        o.firstArrow,
                        size: 11,
                        color: value == o ? kHomePrimaryDark : kHomeTextHint,
                      ),
                      Icon(
                        o.secondArrow,
                        size: 11,
                        color: value == o ? kHomePrimaryDark : kHomeTextHint,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DotHint extends StatelessWidget {
  const _DotHint({required this.color, required this.tip});

  final Color color;
  final String tip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          tip,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: kHomeTextHint,
          ),
        ),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyBoxState extends StatelessWidget {
  const _EmptyBoxState({required this.canCreate, required this.onCreate});

  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: kHomePrimaryBg,
                shape: BoxShape.circle,
                border: Border.all(color: kHomePrimary),
              ),
              child: const Icon(Icons.grid_view_rounded, color: kHomePrimary, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có hộp nuôi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kHomeTextMain),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tạo khu, dãy rồi hộp để bắt đầu quản lý',
              style: TextStyle(fontSize: 13, color: kHomeTextSub),
            ),
            if (canCreate) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tạo khu / dãy / hộp'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Box Bottom Sheet ─────────────────────────────────────────────────────────

class _BoxBottomSheet extends StatelessWidget {
  const _BoxBottomSheet({
    required this.box,
    required this.onDetail,
    required this.onAction,
    required this.onCrabs,
  });

  final BoxSummary box;
  final VoidCallback onDetail;
  final VoidCallback onAction;
  final VoidCallback onCrabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kHomeBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kHomePrimaryBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kHomePrimary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: kHomePrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hộp ${box.qrCode.isNotEmpty ? box.qrCode : box.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kHomeTextMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: kHomePrimary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          box.status.label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kHomePrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Quick info
          _InfoRow(
            icon: box.crabCount > 0 ? Icons.set_meal_rounded : Icons.inventory_2_outlined,
            label: 'Trạng thái cua',
            value: box.crabCount > 0 ? '${box.crabCount} con' : 'Chưa có cua',
          ),
          _InfoRow(icon: Icons.fitness_center_rounded, label: 'Khối lượng TB', value: '${0.0.toStringAsFixed(0)}g'),
          _InfoRow(icon: Icons.health_and_safety_rounded, label: 'Điểm sức khỏe', value: '${box.healthScore.score}/100'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCrabs,
                  icon: Icon(
                    box.crabCount > 0 ? Icons.pets_rounded : Icons.add_circle_outline_rounded,
                  ),
                  label: Text(box.crabCount > 0 ? 'Xem / nhập cua' : 'Nhập cua'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kHomePrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: Size.zero,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.more_horiz_rounded),
                  label: const Text('Thao tác'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kHomePrimary,
                    side: const BorderSide(color: kHomePrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: Size.zero,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDetail,
                  icon: const Icon(Icons.info_outline_rounded),
                  label: const Text('Chi tiết'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kHomePrimary,
                    side: const BorderSide(color: kHomePrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: Size.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kHomeTextSub),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: kHomeTextSub, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: kHomeTextMain,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
