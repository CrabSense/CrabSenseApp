import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
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

/// Boxes tab — Farm map view, light theme.
class BoxesScreen extends ConsumerStatefulWidget {
  const BoxesScreen({super.key});

  @override
  ConsumerState<BoxesScreen> createState() => _BoxesScreenState();
}

class _BoxesScreenState extends ConsumerState<BoxesScreen> {
  UserRole? _lastRole;
  String? _selectedFarmId;
  final ApiClient _api = sl<ApiClient>();

  Future<void> _showCreateStructure(String type) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Tạo ${type.toLowerCase()}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Tên $type',
            hintText: type == 'Khu' ? 'Ví dụ: Khu A' : 'Ví dụ: Dãy A1',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || name == null || name.isEmpty) return;

    try {
      final payload = <String, dynamic>{'name': name};
      if (type == 'Dãy' && _selectedFarmId != null) {
        payload['farmingAreaId'] = _selectedFarmId;
      }
      await _api.post<dynamic>(
        type == 'Khu' ? '/farming-areas' : '/farming-rows',
        data: payload,
      );
      await ref.read(boxesStateProvider.notifier).refresh();
      if (mounted) _snack('Đã tạo $type $name');
    } catch (error) {
      if (mounted) _snack('Không thể tạo $type: $error');
    }
  }

  void _showStructureActions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text('Tạo cấu trúc khu nuôi'),
              subtitle: Text('Khu → Dãy → Hộp'),
            ),
            ListTile(
              leading: const Icon(Icons.add_business_rounded),
              title: const Text('Tạo khu nuôi'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showCreateStructure('Khu');
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_stream_rounded),
              title: const Text('Tạo dãy nuôi'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showCreateStructure('Dãy');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Tạo hộp nuôi'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showCreateBox();
              },
            ),
          ],
        ),
      ),
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

  void _handleBoxTap(BoxSummary box) {
    context.push(RoutePaths.boxCrabs(box.id, boxCode: box.code));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final role = authState is Authenticated ? authState.user.role : UserRole.viewer;
    _syncPermissions(role);

    final asyncState = ref.watch(boxesStateProvider);

    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kHomePrimary, kHomePrimaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Sơ đồ trang trại',
                      style: TextStyle(
                        color: kHomeTextMain,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_box_rounded, color: Colors.white),
                    onPressed: _showStructureActions,
                    tooltip: 'Tạo khu, dãy hoặc hộp',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
                    onPressed: () {},
                    tooltip: 'Lọc',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: () => ref.read(boxesStateProvider.notifier).refresh(),
                    tooltip: 'Làm mới',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: asyncState.when(
        loading: () => const BoxesSkeleton(gridColumns: 4),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: kHomeDanger, size: 48),
              const SizedBox(height: 12),
              Text(e.toString(), style: const TextStyle(color: kHomeTextSub)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.read(boxesStateProvider.notifier).loadData(forceRefresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (data) => _buildContent(data),
      ),
    );
  }

  Widget _buildContent(BoxesStateData data) {
    final farms = data.availableFarms;
    final selectedFarm = farms.where((farm) => farm.id == data.selectedFarmId).firstOrNull ??
      (farms.isNotEmpty ? farms.first : null);
    final boxes = data.visibleBoxes;
    final activeCount = boxes.where((b) => b.status == BoxHealthStatus.healthy || b.status == BoxHealthStatus.warning).length;

    return RefreshIndicator(
      onRefresh: () => ref.read(boxesStateProvider.notifier).refresh(),
      color: kHomePrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card: farm selector + stats
            _FarmHeaderCard(
              farms: farms,
              selectedFarm: selectedFarm,
              totalBoxes: boxes.length,
              activeBoxes: activeCount,
              onFarmChanged: (id) {
                ref.read(boxesStateProvider.notifier).switchFarm(id);
              },
            ),
            const SizedBox(height: 16),

            // Box grid label
            const Text(
              'Hộp nuôi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kHomeTextMain,
              ),
            ),
            const SizedBox(height: 10),

            // Box grid
            if (boxes.isEmpty)
              _EmptyBoxState(
                canCreate: data.canCreateBox,
                onCreate: () {},
              )
            else
              _BoxFarmGrid(
                boxes: boxes,
                onBoxTap: _handleBoxTap,
              ),

            const SizedBox(height: 16),

            // Legend
            _Legend(),

            const SizedBox(height: 16),

            // Stats button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(RoutePaths.reports),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kHomePrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                icon: const Icon(Icons.bar_chart_rounded),
                label: const Text(
                  'Thống kê trang trại',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
    required this.onFarmChanged,
  });

  final List farms;
  final dynamic selectedFarm;
  final int totalBoxes;
  final int activeBoxes;
  final void Function(String) onFarmChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: homeCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.agriculture_rounded, color: kHomePrimary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Trang trại',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kHomeTextSub,
                ),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: selectedFarm.id.isEmpty ? null : selectedFarm.id,
                underline: const SizedBox.shrink(),
                icon: const Icon(Icons.expand_more_rounded, color: kHomeTextSub, size: 20),
                style: const TextStyle(
                  color: kHomeTextMain,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                hint: Text(
                  farms.isNotEmpty ? (farms.first as dynamic).name : 'Chọn trang trại',
                  style: const TextStyle(color: kHomeTextMain, fontWeight: FontWeight.w700),
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
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: kHomeBorder),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Tổng hộp',
                  value: '$totalBoxes',
                  color: kHomePrimary,
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.check_circle_rounded,
                  label: 'Đang nuôi',
                  value: '$activeBoxes',
                  color: kHomePrimary,
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.warning_rounded,
                  label: 'Cảnh báo',
                  value: '${totalBoxes - activeBoxes}',
                  color: kHomeWarning,
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
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: kHomeTextSub),
        ),
      ],
    );
  }
}

// ─── Box Farm Grid ─────────────────────────────────────────────────────────────

class _BoxFarmGrid extends StatelessWidget {
  const _BoxFarmGrid({required this.boxes, required this.onBoxTap});

  final List<BoxSummary> boxes;
  final void Function(BoxSummary) onBoxTap;

  Color _bgColor(BoxSummary box) {
    if (box.alerts.hasAlerts || box.status == BoxHealthStatus.critical) {
      return kHomeDangerBg;
    }
    if (box.crabCount == 0) return const Color(0xFFF0F4F8);
    if (box.status == BoxHealthStatus.warning) return kHomeWarningBg;
    switch (box.status) {
      case BoxHealthStatus.critical: return kHomeDangerBg;
      case BoxHealthStatus.warning: return kHomeWarningBg;
      case BoxHealthStatus.offline: return const Color(0xFFF0F4F8);
      default: return kHomePrimaryBg;
    }
  }

  Color _borderColor(BoxSummary box) {
    if (box.alerts.hasAlerts || box.status == BoxHealthStatus.critical) {
      return kHomeDanger;
    }
    if (box.crabCount == 0) return kHomeBorder;
    if (box.status == BoxHealthStatus.warning) return kHomeWarning;
    switch (box.status) {
      case BoxHealthStatus.critical: return kHomeDanger;
      case BoxHealthStatus.warning: return kHomeWarning;
      case BoxHealthStatus.offline: return kHomeBorder;
      default: return kHomePrimary;
    }
  }

  Color _textColor(BoxSummary box) {
    if (box.alerts.hasAlerts || box.status == BoxHealthStatus.critical) {
      return kHomeDanger;
    }
    if (box.crabCount == 0) return kHomeTextHint;
    if (box.status == BoxHealthStatus.warning) return kHomeWarning;
    switch (box.status) {
      case BoxHealthStatus.critical: return kHomeDanger;
      case BoxHealthStatus.warning: return kHomeWarning;
      case BoxHealthStatus.offline: return kHomeTextHint;
      default: return kHomePrimaryDark;
    }
  }

  String? _statusIcon(BoxSummary box) {
    if (box.alerts.hasAlerts || box.status == BoxHealthStatus.critical) {
      return '🔴';
    }
    if (box.crabCount == 0) return null;
    switch (box.status) {
      case BoxHealthStatus.critical: return '🔴';
      case BoxHealthStatus.warning: return '⚠️';
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.95,
      ),
      itemCount: boxes.length,
      itemBuilder: (context, i) {
        final box = boxes[i];
        final bg = _bgColor(box);
        final border = _borderColor(box);
        final textC = _textColor(box);
        final emoji = _statusIcon(box);
        final label = box.qrCode.isNotEmpty ? box.qrCode : box.id.substring(0, 4).toUpperCase();

        return GestureDetector(
          onTap: () => onBoxTap(box),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (emoji != null)
                  Text(emoji, style: const TextStyle(fontSize: 14))
                else
                  Icon(
                    box.crabCount > 0
                        ? Icons.set_meal_rounded
                        : Icons.inventory_2_outlined,
                    color: textC,
                    size: 16,
                  ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textC,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  box.crabCount > 0 ? '${box.crabCount} con cua' : 'Chưa có cua',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: box.crabCount > 0 ? textC : kHomeTextHint,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Legend ───────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: homeCardDecoration(),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _LegendItem(color: kHomePrimary, label: 'Bình thường'),
          _LegendItem(color: kHomeWarning, label: 'Sắp lột'),
          _LegendItem(color: kHomeDanger, label: 'Cảnh báo'),
          _LegendItem(color: kHomeBorder, label: 'Trống'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: kHomeTextSub, fontWeight: FontWeight.w600),
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
              'Tạo hộp nuôi để bắt đầu quản lý',
              style: TextStyle(fontSize: 13, color: kHomeTextSub),
            ),
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
