import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/models/boxes_models.dart';
import '../providers/boxes_provider.dart';

Future<void> showFarmStructureManageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const FarmStructureManageSheet(),
  );
}

String farmApiMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
  }
  final text = error.toString();
  if (text.contains('no rows') || text.contains('has rows')) {
    return 'Chỉ xóa được khu khi không còn dãy.';
  }
  if (text.contains('no boxes') || text.contains('has boxes')) {
    return 'Chỉ xóa được dãy khi không còn hộp.';
  }
  if (text.contains('live crab') || text.contains('occupied')) {
    return 'Chỉ xóa được hộp khi không còn cua sống.';
  }
  return 'Không thể thực hiện. Kiểm tra dữ liệu rồi thử lại.';
}

/// BE tra 409 "Cannot delete area that still has rows." khi khu con du lieu.
bool _areaHasChildren(Object error) {
  if (error is DioException && error.response?.statusCode == 409) return true;
  final text = error.toString();
  return text.contains('has rows') || text.contains('no rows');
}

class FarmStructureManageSheet extends ConsumerStatefulWidget {
  const FarmStructureManageSheet({super.key});

  @override
  ConsumerState<FarmStructureManageSheet> createState() =>
      _FarmStructureManageSheetState();
}

class _FarmStructureManageSheetState
    extends ConsumerState<FarmStructureManageSheet> {
  List<FarmRowOption> _rows = const [];
  bool _loadingRows = true;

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  Future<void> _loadRows() async {
    setState(() => _loadingRows = true);
    try {
      final rows = await ref.read(boxesStateProvider.notifier).fetchRowDetails();
      if (mounted) setState(() => _rows = rows);
    } catch (_) {
      if (mounted) setState(() => _rows = const []);
    } finally {
      if (mounted) setState(() => _loadingRows = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kHomePrimaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _run(Future<void> Function() action, String okMessage) async {
    try {
      await action();
      await _loadRows();
      if (mounted) _snack(okMessage);
    } catch (error) {
      if (mounted) _snack(farmApiMessage(error));
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
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
    return ok == true;
  }

  Future<void> _editArea(FarmAreaOption area) async {
    final name = await _promptName('Sửa khu nuôi', initial: area.name);
    if (name == null) return;
    await _run(
      () => ref.read(boxesStateProvider.notifier).updateArea(id: area.id, name: name),
      'Đã cập nhật khu $name',
    );
  }

  Future<void> _createArea() async {
    final name = await _promptName('Tạo khu nuôi');
    if (name == null) return;
    await _run(
      () => ref.read(boxesStateProvider.notifier).createArea(name: name),
      'Đã tạo khu $name',
    );
  }

  Future<void> _createRow(List<FarmAreaOption> farms) async {
    if (farms.isEmpty) {
      _snack('Hãy tạo khu nuôi trước');
      return;
    }
    final selectedFarmId =
        ref.read(boxesStateProvider).value?.selectedFarmId ?? farms.first.id;
    final result = await _promptRow(farms: farms, selectedFarmId: selectedFarmId);
    if (result == null) return;
    await _run(
      () => ref.read(boxesStateProvider.notifier).createRow(
            farmingAreaId: result.areaId,
            name: result.name,
            capacity: result.capacity,
          ),
      'Đã tạo dãy ${result.name}',
    );
  }

  Future<void> _editRow(FarmRowOption row, List<FarmAreaOption> farms) async {
    final result = await _promptRow(
      farms: farms,
      selectedFarmId: row.farmingAreaId,
      initialName: row.name,
      initialCapacity: row.capacity < 1 ? 1 : row.capacity,
      title: 'Sửa dãy nuôi',
      lockArea: true,
    );
    if (result == null) return;
    await _run(
      () => ref.read(boxesStateProvider.notifier).updateRow(
            id: row.id,
            name: result.name,
            capacity: result.capacity,
            isActive: row.isActive,
          ),
      'Đã cập nhật dãy ${result.name}',
    );
  }

  Future<void> _createBox(List<FarmRowOption> rows) async {
    if (rows.isEmpty) {
      _snack('Hãy tạo dãy nuôi trước');
      return;
    }
    final result = await _promptBox(rows);
    if (result == null) return;
    await _run(
      () => ref.read(boxesStateProvider.notifier).createBox(
            farmingRowId: result.rowId,
            code: result.code,
          ),
      'Đã tạo hộp nuôi',
    );
  }

  Future<void> _editBox(BoxSummary box) async {
    final controller = TextEditingController(text: box.code);
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa hộp nuôi'),
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
    if (code == null || code.isEmpty) return;
    await _run(
      () => ref.read(boxesStateProvider.notifier).updateBox(
            id: box.id,
            code: code,
            isOccupied: box.crabCount > 0,
          ),
      'Đã cập nhật hộp $code',
    );
  }

  Future<String?> _promptName(String title, {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tên'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(ctx, value);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    return result;
  }

  Future<({String areaId, String name, int capacity})?> _promptRow({
    required List<FarmAreaOption> farms,
    required String selectedFarmId,
    String initialName = '',
    int initialCapacity = 1,
    String title = 'Tạo dãy nuôi',
    bool lockArea = false,
  }) async {
    final nameController = TextEditingController(text: initialName);
    final capacityController = TextEditingController(text: '$initialCapacity');
    var areaId = selectedFarmId;
    final result = await showDialog<({String areaId, String name, int capacity})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: areaId,
                decoration: const InputDecoration(labelText: 'Khu nuôi'),
                items: farms
                    .map((f) => DropdownMenuItem(value: f.id, child: Text(f.name)))
                    .toList(),
                onChanged: lockArea ? null : (id) => setDialog(() => areaId = id ?? areaId),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên dãy'),
              ),
              TextField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Số hộp trong dãy',
                  helperText: 'Tạo dãy mới sẽ tạo sẵn đúng số hộp này',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final capacity = int.tryParse(capacityController.text.trim()) ?? 0;
                if (name.isEmpty || capacity < 1 || capacity > 500) return;
                Navigator.pop(ctx, (areaId: areaId, name: name, capacity: capacity));
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    capacityController.dispose();
    return result;
  }

  Future<({String rowId, String? code})?> _promptBox(List<FarmRowOption> rows) async {
    var selected = rows.first;
    final codeController = TextEditingController();
    final result = await showDialog<({String rowId, String? code})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Tạo hộp nuôi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<FarmRowOption>(
                value: selected,
                decoration: const InputDecoration(labelText: 'Dãy nuôi'),
                items: rows
                    .map((row) => DropdownMenuItem(value: row, child: Text(row.name)))
                    .toList(),
                onChanged: (row) => setDialog(() => selected = row ?? selected),
              ),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Mã hộp (tuỳ chọn)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, (
                rowId: selected.id,
                code: codeController.text.trim().isEmpty ? null : codeController.text.trim(),
              )),
              child: const Text('Tạo hộp'),
            ),
          ],
        ),
      ),
    );
    codeController.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(boxesStateProvider).value;
    final farms = data?.availableFarms ?? const <FarmAreaOption>[];
    final boxes = data?.visibleBoxes ?? const <BoxSummary>[];
    final canWrite = data?.canCreateBox == true || data?.canEditBox == true;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return DefaultTabController(
          length: 3,
          child: Container(
            decoration: const BoxDecoration(
              color: kHomeBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kHomeBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Quản lý khu · dãy · hộp',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kHomeTextMain,
                      ),
                    ),
                  ),
                ),
                const TabBar(
                  labelColor: kHomePrimaryDark,
                  unselectedLabelColor: kHomeTextSub,
                  indicatorColor: kHomePrimary,
                  tabs: [
                    Tab(text: 'Khu'),
                    Tab(text: 'Dãy'),
                    Tab(text: 'Hộp'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _AreaList(
                        farms: farms,
                        canWrite: canWrite,
                        onCreate: _createArea,
                        onEdit: _editArea,
                        onDelete: (area) async {
                          final ok = await _confirm(
                            'Xóa khu ${area.name}?',
                            'Chỉ xóa được khi khu không còn dãy.',
                          );
                          if (!ok) return;
                          try {
                            await ref.read(boxesStateProvider.notifier).deleteArea(area.id);
                            await _loadRows();
                            if (mounted) _snack('Đã xóa khu ${area.name}');
                          } catch (error) {
                            // Khu con du lieu: hoi lai truoc khi xoa ca cay.
                            if (!_areaHasChildren(error)) {
                              if (mounted) _snack(farmApiMessage(error));
                              return;
                            }
                            final force = await _confirm(
                              'Khu ${area.name} vẫn còn dữ liệu',
                              'Khu này còn dãy/hộp/cua. Xóa khu sẽ xóa luôn toàn bộ '
                                  'dãy, hộp và cua bên trong.\n\nKhông khôi phục được.',
                            );
                            if (!force) return;
                            await _run(
                              () => ref.read(boxesStateProvider.notifier)
                                  .deleteArea(area.id, cascade: true),
                              'Đã xóa khu ${area.name} và toàn bộ dữ liệu bên trong',
                            );
                          }
                        },
                      ),
                      _RowList(
                        rows: _rows,
                        loading: _loadingRows,
                        canWrite: canWrite,
                        onCreate: () => _createRow(farms),
                        onEdit: (row) => _editRow(row, farms),
                        onDelete: (row) async {
                          final ok = await _confirm(
                            'Xóa dãy ${row.name}?',
                            'Chỉ xóa được khi dãy không còn hộp.',
                          );
                          if (!ok) return;
                          await _run(
                            () => ref.read(boxesStateProvider.notifier).deleteRow(row.id),
                            'Đã xóa dãy ${row.name}',
                          );
                        },
                      ),
                      _BoxList(
                        boxes: boxes,
                        canWrite: canWrite,
                        onCreate: () => _createBox(_rows),
                        onEdit: _editBox,
                        onDelete: (box) async {
                          final ok = await _confirm(
                            'Xóa hộp ${box.code}?',
                            'Chỉ xóa được khi hộp không còn cua sống.',
                          );
                          if (!ok) return;
                          await _run(
                            () => ref.read(boxesStateProvider.notifier).deleteBox(box.id),
                            'Đã xóa hộp ${box.code}',
                          );
                        },
                      ),
                    ],
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

class _AreaList extends StatelessWidget {
  const _AreaList({
    required this.farms,
    required this.canWrite,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  final List<FarmAreaOption> farms;
  final bool canWrite;
  final VoidCallback onCreate;
  final void Function(FarmAreaOption) onEdit;
  final void Function(FarmAreaOption) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (canWrite)
          ListTile(
            leading: const Icon(Icons.add_business_rounded, color: kHomePrimaryDark),
            title: const Text('Tạo khu nuôi'),
            onTap: onCreate,
          ),
        Expanded(
          child: farms.isEmpty
              ? const Center(child: Text('Chưa có khu nuôi', style: TextStyle(color: kHomeTextSub)))
              : ListView.separated(
                  itemCount: farms.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final area = farms[i];
                    return ListTile(
                      leading: const Icon(Icons.yard_outlined),
                      title: Text(area.name),
                      trailing: canWrite
                          ? PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') onEdit(area);
                                if (value == 'delete') onDelete(area);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: Text('Sửa')),
                                PopupMenuItem(value: 'delete', child: Text('Xóa')),
                              ],
                            )
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _RowList extends StatelessWidget {
  const _RowList({
    required this.rows,
    required this.loading,
    required this.canWrite,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  final List<FarmRowOption> rows;
  final bool loading;
  final bool canWrite;
  final VoidCallback onCreate;
  final void Function(FarmRowOption) onEdit;
  final void Function(FarmRowOption) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (canWrite)
          ListTile(
            leading: const Icon(Icons.view_stream_rounded, color: kHomePrimaryDark),
            title: const Text('Tạo dãy nuôi'),
            onTap: onCreate,
          ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : rows.isEmpty
                  ? const Center(child: Text('Chưa có dãy nuôi', style: TextStyle(color: kHomeTextSub)))
                  : ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final row = rows[i];
                        return ListTile(
                          leading: const Icon(Icons.table_rows_outlined),
                          title: Text(row.name),
                          subtitle: Text(
                            '${row.areaName ?? 'Khu'} · ${row.boxCount}/${row.capacity} hộp',
                          ),
                          trailing: canWrite
                              ? PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') onEdit(row);
                                    if (value == 'delete') onDelete(row);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Sửa')),
                                    PopupMenuItem(value: 'delete', child: Text('Xóa')),
                                  ],
                                )
                              : null,
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _BoxList extends StatelessWidget {
  const _BoxList({
    required this.boxes,
    required this.canWrite,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  final List<BoxSummary> boxes;
  final bool canWrite;
  final VoidCallback onCreate;
  final void Function(BoxSummary) onEdit;
  final void Function(BoxSummary) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (canWrite)
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined, color: kHomePrimaryDark),
            title: const Text('Tạo hộp nuôi'),
            onTap: onCreate,
          ),
        Expanded(
          child: boxes.isEmpty
              ? const Center(child: Text('Chưa có hộp nuôi', style: TextStyle(color: kHomeTextSub)))
              : ListView.separated(
                  itemCount: boxes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final box = boxes[i];
                    return ListTile(
                      leading: const Icon(Icons.grid_view_rounded),
                      title: Text(box.code),
                      subtitle: Text(
                        '${box.location.rowName ?? 'Dãy'} · ${box.crabCount} cua',
                      ),
                      trailing: canWrite
                          ? PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') onEdit(box);
                                if (value == 'delete') onDelete(box);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: Text('Sửa mã')),
                                PopupMenuItem(value: 'delete', child: Text('Xóa')),
                              ],
                            )
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
