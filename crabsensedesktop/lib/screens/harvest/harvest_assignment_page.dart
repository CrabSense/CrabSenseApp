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
  String _assignmentSearch = '';
  DateTime? _assignmentDate;

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
    final generation = widget.service.scopeGeneration;
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
      if (!mounted ||
          version != _loadVersion ||
          area != widget.areaId ||
          generation != widget.service.scopeGeneration) return;
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
    if (_submitting ||
        _loading ||
        _selectedStaffId == null ||
        _selectedCrabIds.isEmpty) return;
    final area = widget.areaId;
    final version = ++_submitVersion;
    final submittedIds = _selectedCrabIds.toList(growable: false);
    final generation = widget.service.scopeGeneration;
    if (!_staff.any((s) => s.id == _selectedStaffId) ||
        !submittedIds.every(
            (id) => _crabs.any((c) => c.id == id && c.areaId == area))) return;

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

      if (!mounted ||
          area != widget.areaId ||
          version != _submitVersion ||
          generation != widget.service.scopeGeneration) return;

      // Bỏ cua vừa giao khỏi danh sách hiện tại để tránh chọn lại ngay.
      setState(() {
        _crabs =
            _crabs.where((crab) => !submittedIds.contains(crab.id)).toList();
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
      if (mounted && version == _submitVersion && area == widget.areaId)
        setState(() => _error = '$e');
    } finally {
      if (mounted && version == _submitVersion && area == widget.areaId)
        setState(() => _submitting = false);
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

    if (widget.areaId.isEmpty)
      return const Center(child: Text('Chưa được phân công khu nuôi.'));
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
                tooltip: 'Theo dõi nhiệm vụ đã giao',
                onPressed:
                    _loading || _submitting ? null : _showAssignmentHistory,
                icon: const Icon(Icons.history_rounded),
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
                      onChanged: _loading || _submitting
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
                                          'Hộp ${crab.boxCode} · ${crab.rowName} · ${crab.rawStatus}',
                                          style: bvText(
                                            fontSize: 12,
                                            color: DashboardColors.textMuted,
                                          ),
                                        ),
                                        onChanged: _loading || _submitting
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

  Future<void> _showAssignmentHistory() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          child: SizedBox(
            width: 760,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _assignmentHistory(dialogContext, setDialogState),
            ),
          ),
        ),
      ),
    );
  }

  Widget _assignmentHistory(
      BuildContext dialogContext, StateSetter setDialogState) {
    final query = _assignmentSearch.trim().toLowerCase();

    final filtered = _assignments.where((item) {
      final code = (item['assignmentCode'] ?? item['AssignmentCode'] ?? '')
          .toString()
          .toLowerCase();
      final id = (item['id'] ?? item['Id'] ?? '').toString().toLowerCase();

      final matchesText =
          query.isEmpty || code.contains(query) || id.contains(query);

      final createdAt = DateTime.tryParse(
        (item['createdAt'] ?? item['CreatedAt'] ?? '').toString(),
      )?.toLocal();

      final matchesDate = _assignmentDate == null ||
          (createdAt != null &&
              createdAt.year == _assignmentDate!.year &&
              createdAt.month == _assignmentDate!.month &&
              createdAt.day == _assignmentDate!.day);

      return matchesText && matchesDate;
    }).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Theo dõi nhiệm vụ thu hoạch',
                style: bvText(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Đóng',
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tìm theo mã nhiệm vụ hoặc ID.
        TextField(
          onChanged: (value) {
            setDialogState(() => _assignmentSearch = value);
          },
          decoration: _decoration('Tìm theo mã hoặc ID nhiệm vụ').copyWith(
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 8),

        // Chọn ngày tạo nhiệm vụ; bấm lại nút Xóa ngày để bỏ lọc.
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final today = DateTime.now();
                final selected = await showDatePicker(
                  context: dialogContext,
                  initialDate: _assignmentDate ?? today,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (selected != null && mounted) {
                  setDialogState(() => _assignmentDate = selected);
                }
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                _assignmentDate == null
                    ? 'Lọc theo ngày'
                    : 'Ngày ${_assignmentDate!.day.toString().padLeft(2, '0')}/'
                        '${_assignmentDate!.month.toString().padLeft(2, '0')}/'
                        '${_assignmentDate!.year}',
              ),
            ),
            if (_assignmentDate != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setDialogState(() => _assignmentDate = null),
                child: const Text('Xóa ngày'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        if (_loading) const LinearProgressIndicator(),
        const SizedBox(height: 8),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    _assignments.isEmpty
                        ? 'Khu này chưa có nhiệm vụ.'
                        : 'Không tìm thấy nhiệm vụ phù hợp.',
                    style: bvText(color: DashboardColors.textMuted),
                  ),
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = filtered[index];

                    String text(String lower, String upper) =>
                        (item[lower] ?? item[upper] ?? '').toString();

                    int number(String lower, String upper) {
                      final value = item[lower] ?? item[upper];
                      if (value is num) return value.toInt();
                      return int.tryParse(value?.toString() ?? '') ?? 0;
                    }

                    final id = text('id', 'Id');
                    final code = text('assignmentCode', 'AssignmentCode');
                    final status = text('status', 'Status');
                    final total = number('lineCount', 'LineCount');
                    final harvested =
                        number('harvestedCount', 'HarvestedCount');
                    final deferred = number('deferredCount', 'DeferredCount');
                    final completedLines = harvested + deferred;

                    final progress = total == 0
                        ? 0.0
                        : (completedLines / total).clamp(0.0, 1.0).toDouble();

                    final staffId =
                        text('assignedToUserId', 'AssignedToUserId');

                    HarvestAssignmentStaff? assignedStaff;
                    for (final staff in _staff) {
                      if (staff.id == staffId) {
                        assignedStaff = staff;
                        break;
                      }
                    }

                    final createdAt = DateTime.tryParse(
                      text('createdAt', 'CreatedAt'),
                    )?.toLocal();

                    final createdLabel = createdAt == null
                        ? 'Không có ngày tạo'
                        : 'Tạo ngày '
                            '${createdAt.day.toString().padLeft(2, '0')}/'
                            '${createdAt.month.toString().padLeft(2, '0')}/'
                            '${createdAt.year}';

                    return Card(
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                code.isEmpty ? 'Nhiệm vụ' : code,
                                style: bvText(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Chip(label: Text(_assignmentStatusLabel(status))),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nhân viên: '
                              '${assignedStaff?.fullName ?? staffId}',
                            ),
                            Text(
                              '$createdLabel · $completedLines/$total cua đã xử lý',
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(value: progress),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openAssignment(item),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _assignmentStatusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'assigned':
        return 'Chờ nhận';
      case 'inprogress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Hoàn tất';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status.isEmpty ? 'Chưa rõ trạng thái' : status;
    }
  }

  Future<void> _openAssignment(Map<String, dynamic> item) async {
    final area = widget.areaId;
    final id = (item['id'] ?? '').toString();
    try {
      final generation = widget.service.scopeGeneration;
      final detail = await widget.service.loadAssignmentDetail(area, id);
      if (!mounted ||
          area != widget.areaId ||
          generation != widget.service.scopeGeneration) return;
      final lines = detail['lines'];
      final vouchers = detail['vouchers'];
      final status = (detail['status'] ?? '').toString().toLowerCase();
      final open = const {'assigned', 'inprogress'}.contains(status);
      final unworked = open &&
          detail['submittedAt'] == null &&
          lines is List &&
          lines.whereType<Map>().every((l) =>
              l['outcome'] == null &&
              l['checkedAt'] == null &&
              l['pendingMoltConfirmed'] != true);
      final audit = detail['workflowAudit'];
      final decision = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: Text((detail['assignmentCode'] ?? 'Chi tiết nhiệm vụ')
                    .toString()),
                content: SizedBox(
                    width: 600,
                    child: SingleChildScrollView(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trạng thái: ${detail['status'] ?? '—'}'),
                        Text('Ghi chú: ${detail['notes'] ?? '—'}'),
                        if (detail['submittedAt'] != null)
                          Text('Gửi lúc: ${detail['submittedAt']}'),
                        if (detail['submissionNotes'] != null)
                          Text('Ghi chú Staff: ${detail['submissionNotes']}'),
                        if (detail['reviewNotes'] != null)
                          Text('Phản hồi Manager: ${detail['reviewNotes']}'),
                        const Divider(),
                        if (lines is List)
                          for (final line in lines.whereType<Map>())
                            ListTile(
                                title: Text(
                                    '${line['crabCode'] ?? '—'} · ${line['status'] ?? '—'}'),
                                subtitle: Text(
                                    'Hộp: ${line['boxCode'] ?? '—'} · Kết quả: ${line['outcome'] ?? '—'} · ${line['weightGram'] ?? line['pendingWeightGram'] ?? '—'} g\n${line['eligibilityReason'] ?? ''}')),
                        if (audit is List && audit.isNotEmpty) ...[
                          const Divider(),
                          const Text('Lịch sử xử lý'),
                          for (final event
                              in audit.whereType<Map>().toList().reversed)
                            ListTile(
                                dense: true,
                                title:
                                    Text('${event['action']} · ${event['at']}'),
                                subtitle: Text(
                                    '${event['reason'] ?? '—'} · Người xử lý: ${event['actorId']}')),
                        ],
                        const Divider(),
                        const Text('Phiếu thu hoạch liên quan'),
                        if (vouchers is List)
                          for (final rawVoucher in vouchers.whereType<Map>())
                            ListTile(
                              title: Text(
                                '${rawVoucher['voucherCode'] ?? rawVoucher['VoucherCode'] ?? '—'}'
                                ' · ${rawVoucher['status'] ?? rawVoucher['Status'] ?? '—'}',
                              ),
                              subtitle: Text(
                                '${rawVoucher['totalQuantity'] ?? rawVoucher['TotalQuantity'] ?? 0} cua'
                                ' · ${rawVoucher['totalWeightKg'] ?? rawVoucher['TotalWeightKg'] ?? 0} kg',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openVoucherDetail(
                                area,
                                Map<String, dynamic>.from(rawVoucher),
                              ),
                            ),
                      ],
                    ))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Đóng')),
                  if (unworked)
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, 'cancel'),
                        child: const Text('Hủy nhiệm vụ')),
                  if (unworked)
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, 'reassign'),
                        child: const Text('Giao lại')),
                ],
              ));
      if (decision == null ||
          !mounted ||
          area != widget.areaId ||
          generation != widget.service.scopeGeneration ||
          _submitting) return;
      if (decision == 'cancel' ||
          decision == 'reassign' ||
          decision.startsWith('skip:')) {
        await _handleAssignmentException(
            area, id, generation, decision, detail);
        return;
      }
      final confirm = decision == 'confirm';
      String? notes;
      if (confirm) {
        final yes = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: const Text('Xác nhận thu hoạch?'),
                  content: const Text(
                      'Kiểm tra kết quả thực tế trước khi xác nhận. Backend sẽ tạo phiếu và giải phóng hộp của cua thu hoạch.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Hủy')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Xác nhận'))
                  ],
                ));
        if (yes != true) return;
      } else {
        var reason = '';
        notes = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: const Text('Yêu cầu Staff bổ sung'),
                  content: TextField(
                      maxLength: 1000,
                      maxLines: 3,
                      onChanged: (v) => reason = v,
                      decoration:
                          const InputDecoration(labelText: 'Lý do bắt buộc')),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Hủy')),
                    FilledButton(
                        onPressed: () {
                          if (reason.trim().isNotEmpty)
                            Navigator.pop(ctx, reason.trim());
                        },
                        child: const Text('Gửi yêu cầu'))
                  ],
                ));
        if (notes == null) return;
      }
      if (!mounted ||
          area != widget.areaId ||
          generation != widget.service.scopeGeneration ||
          _submitting) return;
      final version = ++_submitVersion;
      setState(() => _submitting = true);
      try {
        await widget.service
            .reviewAssignment(area, id, confirm: confirm, notes: notes);
        if (!mounted || version != _submitVersion || area != widget.areaId)
          return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(confirm
                ? 'Đã xác nhận nhiệm vụ.'
                : 'Đã gửi yêu cầu bổ sung.')));
        await _loadData();
      } finally {
        if (mounted && version == _submitVersion && area == widget.areaId)
          setState(() => _submitting = false);
      }
    } catch (e) {
      if (mounted && area == widget.areaId)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _openVoucherDetail(
    String areaId,
    Map<String, dynamic> voucher,
  ) async {
    final voucherId = (voucher['id'] ?? voucher['Id'] ?? '').toString();

    if (voucherId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voucher không có ID hợp lệ.')),
      );
      return;
    }

    try {
      final detail = await widget.service.loadVoucherDetail(
        areaId,
        voucherId,
      );

      if (!mounted || areaId != widget.areaId) return;

      String value(Map<String, dynamic> data, String key) {
        final pascalKey = '${key[0].toUpperCase()}${key.substring(1)}';
        final result = data[key] ?? data[pascalKey];
        return result == null || result.toString().isEmpty
            ? '—'
            : result.toString();
      }

      final rawLines = detail['lines'] ?? detail['Lines'];
      final lines = rawLines is List
          ? rawLines
              .whereType<Map>()
              .map((line) => Map<String, dynamic>.from(line))
              .toList()
          : <Map<String, dynamic>>[];

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(value(detail, 'voucherCode')),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trạng thái: ${value(detail, 'status')}'),
                  Text('Ngày thu hoạch: ${value(detail, 'harvestDate')}'),
                  Text('Khu: ${value(detail, 'areaName')}'),
                  Text('Người thực hiện: ${value(detail, 'performedByName')}'),
                  Text('Số lượng: ${value(detail, 'totalQuantity')} cua'),
                  Text('Tổng khối lượng: ${value(detail, 'totalWeightKg')} kg'),
                  if (value(detail, 'notes') != '—')
                    Text('Ghi chú: ${value(detail, 'notes')}'),
                  const Divider(),
                  const Text(
                    'Chi tiết từng cua',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (lines.isEmpty)
                    const Text('Voucher chưa có dòng cua.')
                  else
                    for (final line in lines)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${value(line, 'crabCode')} · '
                          '${value(line, 'weightGram')} g',
                        ),
                        subtitle: Text(
                          'Hộp: ${value(line, 'boxCode')} · '
                          'Phân loại: ${value(line, 'grade')} · '
                          'Mai: ${value(line, 'carapaceLengthMm')} × '
                          '${value(line, 'carapaceWidthMm')} mm · '
                          'Lột mềm: ${value(line, 'isSoftshell')}',
                        ),
                      ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được chi tiết Voucher: $error')),
      );
    }
  }

  Future<void> _handleAssignmentException(String area, String id,
      int generation, String decision, Map<String, dynamic> detail) async {
    final action = decision.startsWith('skip:') ? 'skip' : decision;
    final lineId = action == 'skip' ? decision.substring(5) : null;
    final staff = action == 'reassign'
        ? (await widget.service.loadStaff(farmingAreaId: area))
            .where((s) => s.id != detail['assignedToUserId']?.toString())
            .toList()
        : <HarvestAssignmentStaff>[];
    if (!mounted ||
        area != widget.areaId ||
        generation != widget.service.scopeGeneration ||
        _submitting) return;
    var reason = '';
    String? staffId;
    final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
                  title: Text(action == 'cancel'
                      ? 'Hủy nhiệm vụ'
                      : action == 'reassign'
                          ? 'Giao lại nhiệm vụ'
                          : 'Xử lý ngoại lệ cua'),
                  content: SizedBox(
                      width: 480,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(action == 'skip'
                            ? 'Chỉ dùng khi cua đã được ghi nhận chết, thất lạc hoặc đổi vị trí. Kết quả cũ được giữ lại, không đưa dòng này vào phiếu.'
                            : 'Chỉ thực hiện khi nhiệm vụ chưa có kết quả. Không thay đổi trạng thái cua hoặc hộp.'),
                        if (action == 'reassign') ...[
                          DropdownButton<String>(
                              isExpanded: true,
                              value: staffId,
                              hint: const Text('Chọn Staff khác'),
                              items: staff
                                  .map((s) => DropdownMenuItem(
                                      value: s.id, child: Text(s.fullName)))
                                  .toList(),
                              onChanged: (value) =>
                                  setDialogState(() => staffId = value)),
                          if (staff.isEmpty)
                            const Text('Không có Staff khác trong khu.'),
                        ],
                        TextField(
                            maxLength: 1000,
                            maxLines: 3,
                            decoration: const InputDecoration(
                                labelText: 'Lý do bắt buộc'),
                            onChanged: (value) =>
                                setDialogState(() => reason = value)),
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Quay lại')),
                    FilledButton(
                        onPressed: reason.trim().isEmpty ||
                                (action == 'reassign' && staffId == null)
                            ? null
                            : () => Navigator.pop(ctx, true),
                        child: const Text('Xác nhận')),
                  ],
                )));
    if (yes != true ||
        !mounted ||
        area != widget.areaId ||
        generation != widget.service.scopeGeneration ||
        _submitting) return;
    final version = ++_submitVersion;
    setState(() => _submitting = true);
    try {
      await widget.service.handleAssignmentException(area, id,
          action: action, reason: reason, staffId: staffId, lineId: lineId);
      if (!mounted || version != _submitVersion || area != widget.areaId)
        return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã cập nhật nhiệm vụ.')));
      await _loadData();
    } finally {
      if (mounted && version == _submitVersion && area == widget.areaId)
        setState(() => _submitting = false);
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
