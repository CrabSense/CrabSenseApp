import 'package:flutter/material.dart';

import '../../models/harvest_assignment.dart';
import '../../models/production_models.dart';
import '../../services/harvest_assignment_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/shared/mgmt_ui.dart';

/// Trang riêng để Farm Manager giao cua cho nhân viên thu hoạch.
class HarvestAssignmentPage extends StatefulWidget {
  const HarvestAssignmentPage({
    super.key,
    required this.service,
    required this.areaId,
    required this.areaLabel,
    required this.isManager,
  });

  final HarvestAssignmentService service;

  /// Truyền từ MainShell để trang nhận ra khi người dùng đổi khu.
  final String areaId;
  final String areaLabel;
  final bool isManager;

  @override
  State<HarvestAssignmentPage> createState() => _HarvestAssignmentPageState();
}

class _HarvestAssignmentPageState extends State<HarvestAssignmentPage> {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  final _selectedCrabIds = <String>{};

  List<HarvestAssignmentStaff> _staff = [];
  List<CrabManagementListItem> _crabs = [];
  String? _selectedStaffId;
  String? _error;
  bool _loading = false;
  bool _submitting = false;
  int _loadVersion = 0;
  int _submitVersion = 0;
  List<Map<String, dynamic>> _assignments = [];

  @override
  void initState() {
    super.initState();
    if (widget.isManager) _loadData();
    debugPrint(
      '[harvest-assignment] load start: '
      'manager=${widget.isManager}, area=${widget.areaId}',
    );
  }

  @override
  void didUpdateWidget(covariant HarvestAssignmentPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Đổi khu thì tải lại dữ liệu và bỏ các lựa chọn thuộc khu cũ.
    if (oldWidget.areaId != widget.areaId && widget.isManager) {
      ++_submitVersion;
      _submitting = false;
      _notesController.clear();
      _selectedStaffId = null;
      _selectedCrabIds.clear();
      _staff = [];
      _crabs = [];
      _assignments = [];
      _loadData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final version = ++_loadVersion;
    final area = widget.areaId;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final staff = await widget.service.loadStaff(
        farmingAreaId: area,
      );
      final crabs = await widget.service.loadAliveCrabs(
        farmingAreaId: area,
      );

      final assignments = await widget.service.loadAssignments(area);
      if (!mounted || version != _loadVersion || area != widget.areaId) return;
      setState(() {
        _assignments = assignments;
        _staff = staff;
        _crabs = crabs;
        _selectedCrabIds.retainAll(crabs.map((c) => c.id).toSet());

        // Bảo đảm không giữ một nhân viên không thuộc khu đang chọn.
        if (!_staff.any((item) => item.id == _selectedStaffId)) {
          _selectedStaffId = null;
        }
      });
    } catch (e) {
      if (mounted && version == _loadVersion) setState(() => _error = '$e');
    } finally {
      if (mounted && version == _loadVersion) setState(() => _loading = false);
    }
  }

  List<CrabManagementListItem> get _visibleCrabs {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _crabs;

    return _crabs.where((crab) {
      return crab.crabCode.toLowerCase().contains(query) ||
          crab.boxCode.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  Future<void> _submit() async {
    if (_submitting || _loading || _selectedStaffId == null || _selectedCrabIds.isEmpty) return;
    final area = widget.areaId;
    final version = ++_submitVersion;
    final submittedIds = _selectedCrabIds.toList(growable: false);

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await widget.service.createAssignment(
        farmingAreaId: area,
        assignedToUserId: _selectedStaffId!,
        crabIds: submittedIds,
        notes: _notesController.text,
      );

      final code = (result['assignmentCode'] ??
              result['AssignmentCode'] ??
              'Nhiệm vụ mới')
          .toString();

      if (!mounted || area != widget.areaId || version != _submitVersion) return;

      // Bỏ cua vừa giao khỏi danh sách hiện tại để tránh chọn lại ngay.
      setState(() {
        _crabs = _crabs.where((crab) => !submittedIds.contains(crab.id)).toList();
        _selectedCrabIds.clear();
        _selectedStaffId = null;
        _notesController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã giao nhiệm vụ $code.')),
      );
      await _loadData();
    } catch (e) {
      // Hiển thị lỗi BE, ví dụ cua đã nằm trong task khác.
      if (mounted && version == _submitVersion && area == widget.areaId) setState(() => _error = '$e');
    } finally {
      if (mounted && version == _submitVersion && area == widget.areaId) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isManager) {
      return Center(
        child: Text(
          'Chỉ Manager mới được giao nhiệm vụ thu hoạch.',
          style: bvText(color: DashboardColors.textMuted),
        ),
      );
    }

    if (widget.areaId.isEmpty) return const Center(child: Text('Chưa được phân công khu nuôi.'));
    final crabs = _visibleCrabs;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _assignmentHistory(),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(
              Icons.assignment_add,
              color: DashboardColors.brand,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phân công thu hoạch',
                    style: bvText(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: DashboardColors.textPrimary,
                    ),
                  ),
                  Text(
                    widget.areaLabel,
                    style: bvText(color: DashboardColors.textMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Tải lại',
              onPressed: _loading || _submitting ? null : _loadData,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Card form sử dụng cùng nền, viền và typography với màn quản trị.
        Container(
          padding: const EdgeInsets.all(18),
          decoration: mgmtCardDeco(radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nhân viên nhận việc',
                style: bvText(
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              if (_loading)
                const LinearProgressIndicator()
              else if (_staff.isEmpty)
                Text(
                  'Khu này chưa có nhân viên được phân công.',
                  style: bvText(color: DashboardColors.textMuted),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedStaffId,
                  decoration: _decoration('Chọn nhân viên'),
                  items: [
                    for (final staff in _staff)
                      DropdownMenuItem(
                        value: staff.id,
                        child: Text(
                          staff.userCode == null || staff.userCode!.isEmpty
                              ? staff.fullName
                              : '${staff.fullName} · ${staff.userCode}',
                        ),
                      ),
                  ],
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() {
                            _selectedStaffId = value;
                            _error = null;
                          }),
                ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chọn cua (${_selectedCrabIds.length} đã chọn)',
                      style: bvText(
                        fontWeight: FontWeight.w700,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: _decoration('Tìm theo mã cua hoặc mã hộp')
                    .copyWith(prefixIcon: const Icon(Icons.search_rounded)),
              ),
              const SizedBox(height: 10),

              // Giới hạn chiều cao để danh sách dài không làm tràn trang.
              Container(
                height: 320,
                decoration: BoxDecoration(
                  border: Border.all(color: DashboardColors.cardBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : crabs.isEmpty
                        ? Center(
                            child: Text(
                              'Không có cua Alive trong khu này.',
                              style: bvText(
                                color: DashboardColors.textMuted,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: crabs.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: DashboardColors.cardBorder,
                            ),
                            itemBuilder: (context, index) {
                              final crab = crabs[index];
                              return CheckboxListTile(
                                dense: true,
                                activeColor: DashboardColors.brand,
                                value: _selectedCrabIds.contains(crab.id),
                                title: Text(
                                  crab.crabCode,
                                  style: bvText(
                                    fontWeight: FontWeight.w700,
                                    color: DashboardColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  'Hộp ${crab.boxCode} · ${crab.rowName}',
                                  style: bvText(
                                    fontSize: 12,
                                    color: DashboardColors.textMuted,
                                  ),
                                ),
                                onChanged: _submitting
                                    ? null
                                    : (checked) {
                                        setState(() {
                                          if (checked == true) {
                                            _selectedCrabIds.add(crab.id);
                                          } else {
                                            _selectedCrabIds.remove(crab.id);
                                          }
                                          _error = null;
                                        });
                                      },
                              );
                            },
                          ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                minLines: 2,
                maxLines: 3,
                decoration: _decoration('Ghi chú (không bắt buộc)'),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: bvText(
                    color: DashboardColors.risk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _loading ||
                          _submitting ||
                          _staff.isEmpty ||
                          _selectedStaffId == null ||
                          _selectedCrabIds.isEmpty
                      ? null
                      : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.assignment_turned_in_outlined),
                  label: Text(_submitting ? 'Đang giao...' : 'Giao nhiệm vụ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashboardColors.brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _assignmentHistory() {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Theo dõi nhiệm vụ đã giao', style: bvText(fontSize: 17, fontWeight: FontWeight.w700)),
        if (_loading) const LinearProgressIndicator(),
        if (!_loading && _assignments.isEmpty) const Text('Chưa có nhiệm vụ trong khu.'),
        for (final item in _assignments)
          ListTile(
            title: Text((item['assignmentCode'] ?? 'Nhiệm vụ').toString()),
            subtitle: Text('Trạng thái: ${item['status'] ?? '—'} · Cua: ${item['lineCount'] ?? 0} · Đã thu: ${item['harvestedCount'] ?? 0} · Hoãn: ${item['deferredCount'] ?? 0}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openAssignment(item),
          ),
      ],
    )));
  }

  Future<void> _openAssignment(Map<String, dynamic> item) async {
    final area = widget.areaId;
    final id = (item['id'] ?? '').toString();
    try {
      final detail = await widget.service.loadAssignmentDetail(area, id);
      if (!mounted || area != widget.areaId) return;
      final lines = detail['lines'];
      final vouchers = detail['vouchers'];
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
        title: Text((detail['assignmentCode'] ?? 'Chi tiết nhiệm vụ').toString()),
        content: SizedBox(width: 600, child: SingleChildScrollView(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Trạng thái: ${detail['status'] ?? '—'}'),
            Text('Ghi chú: ${detail['notes'] ?? '—'}'),
            const Divider(),
            if (lines is List) for (final line in lines.whereType<Map>())
              ListTile(title: Text('${line['crabCode'] ?? '—'} · ${line['status'] ?? '—'}'),
                subtitle: Text('Hộp: ${line['boxCode'] ?? '—'} · Khối lượng: ${line['weightGram'] ?? line['pendingWeightGram'] ?? '—'} g\n${line['eligibilityReason'] ?? ''}')),
            const Divider(),
            const Text('Phiếu thu hoạch liên quan'),
            if (vouchers is List) for (final v in vouchers.whereType<Map>())
              ListTile(title: Text('${v['voucherCode'] ?? '—'} · ${v['status'] ?? '—'}'),
                subtitle: Text('${v['totalQuantity'] ?? 0} cua · ${v['totalWeightKg'] ?? 0} kg')),
          ],
        ))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
      ));
    } catch (e) {
      if (mounted && area == widget.areaId) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  /// Dùng chung kiểu input với các màn hình quản trị hiện tại.
  InputDecoration _decoration(String hint) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: DashboardColors.cardBorder),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: bvText(
        fontSize: 12.5,
        color: DashboardColors.textMuted,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(
          color: DashboardColors.brand,
          width: 1.4,
        ),
      ),
    );
  }
}
