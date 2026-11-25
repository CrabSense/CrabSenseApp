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
      _selectedStaffId = null;
      _selectedCrabIds.clear();
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
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final staff = await widget.service.loadStaff(
        farmingAreaId: widget.areaId,
      );
      final crabs = await widget.service.loadAliveCrabs(
        farmingAreaId: widget.areaId,
      );

      if (!mounted) return;
      setState(() {
        _staff = staff;
        _crabs = crabs;

        // Bảo đảm không giữ một nhân viên không thuộc khu đang chọn.
        if (!_staff.any((item) => item.id == _selectedStaffId)) {
          _selectedStaffId = null;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
    if (_selectedStaffId == null || _selectedCrabIds.isEmpty) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await widget.service.createAssignment(
        farmingAreaId: widget.areaId,
        assignedToUserId: _selectedStaffId!,
        crabIds: _selectedCrabIds.toList(growable: false),
        notes: _notesController.text,
      );

      final code = (result['assignmentCode'] ??
              result['AssignmentCode'] ??
              'Nhiệm vụ mới')
          .toString();

      if (!mounted) return;

      // Bỏ cua vừa giao khỏi danh sách hiện tại để tránh chọn lại ngay.
      setState(() {
        _crabs.removeWhere((crab) => _selectedCrabIds.contains(crab.id));
        _selectedCrabIds.clear();
        _selectedStaffId = null;
        _notesController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã giao nhiệm vụ $code.')),
      );
    } catch (e) {
      // Hiển thị lỗi BE, ví dụ cua đã nằm trong task khác.
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
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

    final crabs = _visibleCrabs;

    return Column(
      children: [
        // Tiêu đề đứng yên, không nằm trong vùng cuộn.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
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
        ),

        // Phần form chiếm khoảng trống giữa tiêu đề và footer.
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Container(
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
                          : (value) {
                              setState(() {
                                _selectedStaffId = value;
                                _error = null;
                              });
                            },
                    ),

                  const SizedBox(height: 16),
                  Text(
                    'Chọn cua cần giao nhiệm vụ',
                    style: bvText(
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tìm kiếm nằm ngoài ListView nên không cuộn theo danh sách.
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration:
                        _decoration('Tìm theo mã cua hoặc mã hộp').copyWith(
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Đây là vùng cuộn duy nhất trong trang.
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: DashboardColors.cardBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
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

                                    return Material(
                                      color: Colors.transparent,
                                      child: CheckboxListTile(
                                        dense: true,
                                        visualDensity: const VisualDensity(
                                          horizontal: -2,
                                          vertical: -3,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        minVerticalPadding: 0,
                                        activeColor: DashboardColors.brand,
                                        value:
                                            _selectedCrabIds.contains(crab.id),
                                        title: Text(
                                          crab.crabCode,
                                          style: bvText(
                                            fontWeight: FontWeight.w700,
                                            color: DashboardColors.textPrimary,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Hộp ${crab.boxCode} · Trạng thái: ${crab.rawStatus}',
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
                                                    _selectedCrabIds
                                                        .add(crab.id);
                                                  } else {
                                                    _selectedCrabIds
                                                        .remove(crab.id);
                                                  }
                                                  _error = null;
                                                });
                                              },
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    minLines: 1,
                    maxLines: 2,
                    decoration: _decoration('Ghi chú (không bắt buộc)'),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: bvText(
                        color: DashboardColors.risk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Footer nằm ngoài vùng cuộn.
        SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: DashboardColors.cardBorder),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedCrabIds.length} cua đã chọn',
                    style: bvText(
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
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
                  label: Text(
                    _submitting ? 'Đang giao...' : 'Giao nhiệm vụ',
                  ),
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
              ],
            ),
          ),
        ),
      ],
    );
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
