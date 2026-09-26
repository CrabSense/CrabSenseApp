import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/harvest_sales.dart';
import '../../services/cloud_api_client.dart';
import '../../services/harvest_sales_service.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/mgmt_ui.dart';

const _kOverlay = Color.fromRGBO(15, 35, 30, 0.45);
const _kAmber = Color(0xFFF5B700);
const _kRed = Color(0xFFEF4444);
const _kNoteMax = 500;

const _grades = <(String, String)>[
  ('A', 'Loại 1'),
  ('B', 'Loại 2'),
  ('C', 'Loại 3'),
];

const _customerTypes = <(String, String)>[
  ('retail', 'Khách lẻ'),
  ('wholesale', 'Khách sỉ'),
  ('restaurant', 'Nhà hàng'),
  ('agent', 'Đại lý'),
  ('other', 'Khác'),
];

const _payMethods = <(String, String)>[
  ('cash', 'Tiền mặt'),
  ('transfer', 'Chuyển khoản'),
  ('credit', 'Công nợ'),
  ('other', 'Khác'),
];

const _payStatuses = <(String, String)>[
  ('Pending', 'Chưa thanh toán'),
  ('Partial', 'Thanh toán một phần'),
  ('Paid', 'Đã thanh toán'),
];

const _deliveries = <(String, String)>[
  ('pickup', 'Nhận tại trại'),
  ('delivery', 'Giao tận nơi'),
  ('self', 'Khách tự vận chuyển'),
];

class _EscIntent extends Intent {
  const _EscIntent();
}

String _labelOf(List<(String, String)> items, String code) {
  for (final (v, label) in items) {
    if (v.toLowerCase() == code.toLowerCase()) return label;
  }
  return code;
}

String _gradeLabel(String code) {
  final g = code.trim().toUpperCase();
  return switch (g) {
    'A' || 'GRADE_1' || '1' => 'Loại 1',
    'B' || 'GRADE_2' || '2' => 'Loại 2',
    'C' || 'GRADE_3' || '3' => 'Loại 3',
    '' => '—',
    _ => code,
  };
}

String _normGrade(String raw) {
  final g = raw.trim().toUpperCase();
  return switch (g) {
    'GRADE_1' || '1' || 'LOẠI 1' => 'A',
    'GRADE_2' || '2' || 'LOẠI 2' => 'B',
    'GRADE_3' || '3' || 'LOẠI 3' => 'C',
    _ => g.isEmpty ? 'A' : g,
  };
}

int _lineAmountKg(int weightG, int pricePerKg) {
  final qtyKg = double.parse((weightG / 1000).toStringAsFixed(3));
  return (qtyKg * pricePerKg).round();
}

int _parseInt(TextEditingController c) =>
    int.tryParse(c.text.trim().replaceAll('.', '').replaceAll(',', '')) ?? 0;

Future<void> showCreateSaleModal(
  BuildContext context,
  HarvestSalesService service, {
  HarvestSlipDetail? fromSlip,
  List<InventoryCrab>? initialCrabs,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: _kOverlay,
    builder: (_) => CreateSaleModal(
      service: service,
      fromSlip: fromSlip,
      initialCrabs: initialCrabs ?? const [],
    ),
  );
}

class CreateSaleModal extends StatefulWidget {
  const CreateSaleModal({
    super.key,
    required this.service,
    this.fromSlip,
    this.initialCrabs = const [],
  });

  final HarvestSalesService service;
  final HarvestSlipDetail? fromSlip;
  final List<InventoryCrab> initialCrabs;

  @override
  State<CreateSaleModal> createState() => _CreateSaleModalState();
}

class _CreateSaleModalState extends State<CreateSaleModal> {
  late final TextEditingController _customerSearch;
  late final TextEditingController _note;
  late final TextEditingController _bulkPrice;
  late final TextEditingController _discount;
  late final TextEditingController _shipping;
  late final TextEditingController _paid;
  late final TextEditingController _shipAddress;
  late final TextEditingController _shipName;
  late final TextEditingController _shipPhone;

  final _selected = <InventoryCrab>[];
  final _checked = <String>{};
  final _gradesById = <String, String>{};
  final _prices = <String, TextEditingController>{};

  Customer? _customer;
  var _perKg = true;
  var _discountPercent = false;
  var _payMethod = 'transfer';
  var _payStatus = 'Paid';
  var _delivery = 'pickup';
  var _saving = false;
  var _confirming = false;
  String? _error;

  HarvestSalesService get _svc => widget.service;

  @override
  void initState() {
    super.initState();
    _customerSearch = TextEditingController();
    _note = TextEditingController();
    final seed = _svc.allSalesOrders
        .where((o) => o.avgPricePerKg > 0)
        .map((o) => o.avgPricePerKg)
        .firstOrNull;
    _bulkPrice = TextEditingController(text: seed == null ? '' : '$seed');
    _discount = TextEditingController(text: '0');
    _shipping = TextEditingController(text: '0');
    _paid = TextEditingController(text: '0');
    _shipAddress = TextEditingController();
    _shipName = TextEditingController();
    _shipPhone = TextEditingController();
    final slip = widget.fromSlip;
    if (slip != null) {
      for (final c in _svc.inventoryForSlip(slip)) {
        _addCrab(c);
      }
    }
    for (final c in widget.initialCrabs) {
      if (c.canSelect) _addCrab(c);
    }
    _syncPaid();
  }

  @override
  void dispose() {
    _customerSearch.dispose();
    _note.dispose();
    _bulkPrice.dispose();
    _discount.dispose();
    _shipping.dispose();
    _paid.dispose();
    _shipAddress.dispose();
    _shipName.dispose();
    _shipPhone.dispose();
    for (final c in _prices.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _addCrab(InventoryCrab c) {
    if (_selected.any((e) => e.id == c.id)) return;
    _selected.add(c);
    _checked.add(c.id);
    _gradesById[c.id] = _normGrade(c.grade);
    final seed = _parseInt(_bulkPrice);
    _prices[c.id] = TextEditingController(text: seed > 0 ? '$seed' : '');
  }

  void _removeCrab(String id) {
    _selected.removeWhere((e) => e.id == id);
    _checked.remove(id);
    _gradesById.remove(id);
    _prices.remove(id)?.dispose();
  }

  int _priceOf(InventoryCrab c) => _parseInt(_prices[c.id] ?? _bulkPrice);

  int _lineTotal(InventoryCrab c) {
    final price = _priceOf(c);
    if (price <= 0) return 0;
    if (_perKg) return _lineAmountKg(c.weightG, price);
    return price;
  }

  int get _subtotal => _selected.fold<int>(0, (s, c) => s + _lineTotal(c));

  int get _discountVnd {
    final raw = _parseInt(_discount);
    if (_discountPercent) return ((_subtotal * raw) / 100).round();
    return raw;
  }

  int get _shippingVnd => _delivery == 'pickup' ? 0 : _parseInt(_shipping);

  int get _grand => (_subtotal - _discountVnd + _shippingVnd).clamp(0, 1 << 31);

  int get _paidVnd {
    if (_payStatus == 'Paid') return _grand;
    if (_payStatus == 'Pending') return 0;
    return _parseInt(_paid).clamp(0, _grand);
  }

  int get _remaining => (_grand - _paidVnd).clamp(0, _grand);

  int get _totalG => _selected.fold<int>(0, (s, c) => s + c.weightG);

  int get _avgPrice {
    if (_selected.isEmpty || _totalG <= 0) return 0;
    if (_perKg) {
      final priced = _selected.where((c) => _priceOf(c) > 0);
      if (priced.isEmpty) return 0;
      return (priced.fold<int>(0, (s, c) => s + _priceOf(c)) / priced.length)
          .round();
    }
    return (_subtotal * 1000 / _totalG).round();
  }

  void _syncPaid() {
    if (_payStatus == 'Paid') {
      _paid.text = _grand == 0 ? '0' : '$_grand';
    } else if (_payStatus == 'Pending') {
      _paid.text = '0';
    }
  }

  Future<void> _pickCrabs() async {
    final chosen = await showDialog<Set<String>>(
      context: context,
      barrierColor: _kOverlay,
      builder: (_) => SelectSaleCrabsDialog(
        crabs: _svc.inventory,
        already: _selected.map((c) => c.id).toSet(),
      ),
    );
    if (chosen == null) return;
    setState(() {
      for (final c in _svc.inventory) {
        if (chosen.contains(c.id)) _addCrab(c);
      }
      for (final drop in _selected.where((c) => !chosen.contains(c.id)).toList()) {
        _removeCrab(drop.id);
      }
      _syncPaid();
    });
  }

  void _applyPrice({bool selectedOnly = false}) {
    final price = _parseInt(_bulkPrice);
    if (price <= 0) {
      setState(() => _error = 'Nhập đơn giá hợp lệ trước khi áp dụng.');
      return;
    }
    setState(() {
      _error = null;
      for (final c in _selected) {
        if (selectedOnly && !_checked.contains(c.id)) continue;
        _prices[c.id]?.text = '$price';
      }
      _syncPaid();
    });
  }

  Future<void> _createCustomer() async {
    final created = await showDialog<Customer>(
      context: context,
      barrierColor: _kOverlay,
      builder: (_) => CreateCustomerDialog(service: _svc),
    );
    if (created == null || !mounted) return;
    setState(() {
      _customer = created;
      _customerSearch.text = created.name;
      _error = null;
    });
  }

  String _composedNote() {
    final parts = <String>[];
    final note = _note.text.trim();
    if (note.isNotEmpty) parts.add(note);
    if (_delivery == 'delivery') {
      parts.add(
        'Giao tận nơi'
        '${_shipAddress.text.trim().isEmpty ? '' : '\nĐịa chỉ: ${_shipAddress.text.trim()}'}'
        '${_shipName.text.trim().isEmpty ? '' : '\nNgười nhận: ${_shipName.text.trim()}'}'
        '${_shipPhone.text.trim().isEmpty ? '' : '\nSĐT: ${_shipPhone.text.trim()}'}',
      );
    }
    return parts.join('\n\n');
  }

  Map<String, int> get _submitPrices {
    return {
      for (final c in _selected)
        c.id: _perKg
            ? _priceOf(c)
            : (c.weightG <= 0
                ? _priceOf(c)
                : ((_priceOf(c) * 1000) / c.weightG).round()),
    };
  }

  String? _validateDraft() {
    if (_customer == null || _customer!.name.trim().isEmpty) {
      return 'Chọn khách hàng trước khi lưu nháp.';
    }
    return null;
  }

  String? _validateConfirm() {
    final draft = _validateDraft();
    if (draft != null) return draft;
    if (_selected.isEmpty) return 'Chọn ít nhất một con cua chờ bán.';
    if (_selected.any((c) => !c.canSelect)) {
      return _selected.firstWhere((c) => !c.canSelect).disableReason;
    }
    if (_selected.any((c) => _priceOf(c) <= 0)) {
      return 'Mỗi cua cần đơn giá > 0.';
    }
    if (_grand <= 0) return 'Đơn bán hàng thông thường không được tổng 0đ.';
    if (_payStatus == 'Partial' && _paidVnd <= 0) {
      return 'Thanh toán một phần cần nhập số tiền đã thu.';
    }
    if (_delivery == 'delivery' && _shipAddress.text.trim().isEmpty) {
      return 'Nhập địa chỉ giao hàng.';
    }
    return null;
  }

  Future<void> _submit({required bool draft}) async {
    if (_saving) return;
    final err = draft ? _validateDraft() : _validateConfirm();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    if (!draft) {
      final ok = await _confirmSale();
      if (ok != true || !mounted) return;
    }
    setState(() {
      _saving = true;
      _confirming = !draft;
      _error = null;
    });
    try {
      final code = await _svc.createSaleOrder(
        orderDate: DateTime.now(),
        customerName: _customer!.name,
        customerPhone: _customer!.phone,
        customerAddress: _delivery == 'delivery'
            ? _shipAddress.text.trim()
            : _customer!.address,
        paymentStatus: _payStatus,
        paymentMethod: _payMethod,
        orderStatus: draft ? 'Draft' : 'Completed',
        sellerName: _svc.performerName,
        notes: _composedNote().isEmpty ? null : _composedNote(),
        discountAmount: _discountVnd,
        shippingFee: _shippingVnd,
        paidAmount: _paidVnd,
        deliveryStatus: _delivery,
        customerType: _customer!.typeLabel,
        crabs: _selected,
        weights: {for (final c in _selected) c.id: c.weightG},
        grades: _gradesById,
        prices: _submitPrices,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            draft
                ? '✓ Đã lưu $code dưới dạng nháp.'
                : '✓ Đã tạo $code thành công.',
          ),
        ),
      );
    } on CloudApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _confirming = false;
        _error = _mapError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _confirming = false;
        _error = '⚠ Không thể tạo đơn bán hàng.\n$e';
      });
    }
  }

  String _mapError(CloudApiException e) {
    final msg = e.message;
    if (e.statusCode == 409 || msg.contains('đơn khác') || msg.contains('nằm trong đơn')) {
      return '⚠ Cua vừa được thêm vào đơn khác.\nVui lòng làm mới danh sách.';
    }
    return '⚠ Không thể tạo đơn bán hàng.\n$msg';
  }

  Future<bool?> _confirmSale() {
    return showDialog<bool>(
      context: context,
      barrierColor: _kOverlay,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xác nhận tạo ${_svc.nextSalePreview}?',
          style: bvText(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Khách hàng: ${_customer?.name ?? '—'}\n'
          'Số cua: ${_selected.length}\n'
          'Tổng KL: ${(_totalG / 1000).toStringAsFixed(2)} kg\n'
          'Tổng tiền: ${formatVnd(_grand)}\n'
          'Thanh toán: ${_labelOf(_payStatuses, _payStatus)}',
          style: bvText(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.brand),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 980;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 18,
        vertical: compact ? 8 : 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: size.width < 1180 ? size.width - 20 : 1260,
          maxHeight: size.height * 0.92,
        ),
        child: Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.escape): const _EscIntent(),
          },
          child: Actions(
            actions: {
              _EscIntent: CallbackAction<_EscIntent>(onInvoke: (_) {
                if (!_saving) Navigator.pop(context);
                return null;
              }),
            },
            child: Focus(
              autofocus: true,
              child: Column(
                children: [
                  _header(),
                  const Divider(height: 1, color: DashboardColors.mint),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 14 : 20,
                        16,
                        compact ? 14 : 20,
                        16,
                      ),
                      child: Column(
                        children: [
                          if (_error != null) ...[
                            _errorBanner(_error!),
                            const SizedBox(height: 12),
                          ],
                          if (compact) ...[
                            _customerSection(),
                            const SizedBox(height: 16),
                            _crabSection(compact),
                            const SizedBox(height: 16),
                            _pricingCard(),
                            const SizedBox(height: 12),
                            _summaryCard(),
                            const SizedBox(height: 12),
                            _paymentCard(),
                            const SizedBox(height: 16),
                            _deliverySection(),
                            const SizedBox(height: 16),
                            _noteSection(),
                          ] else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: Column(
                                    children: [
                                      _customerSection(),
                                      const SizedBox(height: 16),
                                      _crabSection(false),
                                      const SizedBox(height: 16),
                                      _deliverySection(),
                                      const SizedBox(height: 16),
                                      _noteSection(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      _pricingCard(),
                                      const SizedBox(height: 12),
                                      _summaryCard(),
                                      const SizedBox(height: 12),
                                      _paymentCard(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: DashboardColors.mint),
                  _footer(compact),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: DashboardColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tạo đơn bán hàng',
                  style: bvText(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                Text(
                  'Tạo đơn từ cua đã thu hoạch và đang chờ bán.',
                  style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Mã đơn (tự động)', style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
              Text(
                _svc.nextSalePreview,
                style: bvText(fontSize: 13.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(width: 10),
          const MgmtStatusBadge(label: 'Nháp', color: _kAmber),
          IconButton(
            tooltip: 'Đóng',
            onPressed: _saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _customerSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Thông tin khách hàng', Icons.person_outline_rounded),
          const SizedBox(height: 10),
          Text('Khách hàng *', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _customerPicker()),
              const SizedBox(width: 8),
              MgmtOutlineButton(
                onTap: _saving ? null : _createCustomer,
                icon: Icons.add_rounded,
                label: 'Khách hàng mới',
              ),
            ],
          ),
          if (_customer != null) ...[
            const SizedBox(height: 12),
            _customerCard(_customer!),
          ],
        ],
      ),
    );
  }

  Widget _customerPicker() {
    final q = _customerSearch.text.trim().toLowerCase();
    final items = _svc.customers.where((c) {
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          c.address.toLowerCase().contains(q);
    }).toList();
    return PopupMenuButton<Customer>(
      tooltip: '',
      offset: const Offset(0, 44),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (c) => setState(() {
        _customer = c;
        _customerSearch.text = c.name;
        _error = null;
      }),
      itemBuilder: (_) => [
        PopupMenuItem<Customer>(
          enabled: false,
          child: SizedBox(
            width: 360,
            child: TextField(
              controller: _customerSearch,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: _deco('Tìm khách hàng...').copyWith(
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
              ),
            ),
          ),
        ),
        if (items.isEmpty)
          PopupMenuItem<Customer>(
            enabled: false,
            child: Text('Không có khách phù hợp.', style: bvText(color: DashboardColors.textMuted)),
          )
        else
          for (final c in items.take(12))
            PopupMenuItem<Customer>(
              value: c,
              child: Text('${c.name}  ·  ${_labelOf(_customerTypes, c.typeLabel)}'),
            ),
      ],
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DashboardColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 18, color: DashboardColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _customer?.name ?? 'Chọn khách hàng',
                style: bvText(
                  fontWeight: FontWeight.w600,
                  color: _customer == null
                      ? DashboardColors.textMuted
                      : DashboardColors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: DashboardColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _customerCard(Customer c) {
    final stats = _svc.customerStats(c);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.mint),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(c.name, style: bvText(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    MgmtStatusBadge(
                      label: _labelOf(_customerTypes, c.typeLabel),
                      color: DashboardColors.brand,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (c.phone.isNotEmpty) c.phone,
                    if (c.address.isNotEmpty) c.address,
                  ].join('  ·  '),
                  style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                ),
              ],
            ),
          ),
          _miniStat('Tổng đơn', '${stats.orders}'),
          _miniStat('Tổng cua', '${stats.crabs}'),
          _miniStat('Tổng KL', '${(stats.weightG / 1000).toStringAsFixed(1)} kg'),
          _miniStat('Doanh thu', formatVnd(stats.revenue)),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
          Text(value, style: bvText(fontWeight: FontWeight.w800, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _crabSection(bool compact) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _sectionTitle('Danh sách cua', Icons.set_meal_outlined),
              const SizedBox(width: 8),
              _chip('${_selected.length}'),
              const Spacer(),
              MgmtOutlineButton(
                onTap: _saving ? null : _pickCrabs,
                icon: Icons.add_rounded,
                label: 'Chọn cua từ kho',
              ),
              const SizedBox(width: 8),
              MgmtOutlineButton(
                onTap: _saving || _selected.isEmpty
                    ? null
                    : () => setState(() {
                          for (final c in _selected.toList()) {
                            _removeCrab(c.id);
                          }
                          _syncPaid();
                        }),
                icon: Icons.delete_outline_rounded,
                label: 'Xóa tất cả',
                color: _kRed,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Chọn cua từ danh sách cua chờ bán. Đơn giá có thể áp dụng theo kg hoặc theo con.',
            style: bvText(fontSize: 12, color: DashboardColors.textMuted),
          ),
          const SizedBox(height: 12),
          if (_selected.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: DashboardColors.lightMint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Chưa chọn cua. Bấm “Chọn cua từ kho”.',
                textAlign: TextAlign.center,
                style: bvText(color: DashboardColors.textMuted),
              ),
            )
          else if (compact)
            Column(children: [for (var i = 0; i < _selected.length; i++) _crabCard(i, _selected[i])])
          else
            _crabTable(),
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: DashboardColors.brand),
                const SizedBox(width: 6),
                Text(
                  'Đã chọn ${_checked.length} cua • ${(_checked.fold<int>(0, (s, id) {
                        final c = _selected.where((e) => e.id == id);
                        return s + (c.isEmpty ? 0 : c.first.weightG);
                      }) / 1000).toStringAsFixed(2)} kg',
                  style: bvText(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _saving ? null : () => _applyPrice(selectedOnly: _checked.isNotEmpty),
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text('Áp dụng đơn giá cho tất cả'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _crabTable() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 860),
            child: Column(
              children: [
                _tableHead(),
                for (var i = 0; i < _selected.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: DashboardColors.mint),
                  _tableRow(i, _selected[i]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tableHead() {
    const labels = ['', '#', 'Cua', 'Nguồn (HAR)', 'Hộp', 'KL (g)', 'Phân loại', 'Đơn giá', 'Thành tiền', ''];
    const widths = [36.0, 32.0, 140.0, 88.0, 88.0, 64.0, 110.0, 140.0, 96.0, 40.0];
    return Container(
      color: DashboardColors.lightMint,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            SizedBox(
              width: widths[i],
              child: Text(
                labels[i],
                style: bvText(fontSize: 11.5, fontWeight: FontWeight.w700, color: DashboardColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableRow(int i, InventoryCrab c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Checkbox(
              value: _checked.contains(c.id),
              activeColor: DashboardColors.brand,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _checked.add(c.id);
                } else {
                  _checked.remove(c.id);
                }
              }),
            ),
          ),
          SizedBox(width: 32, child: Text('${i + 1}', style: bvText(color: DashboardColors.textMuted))),
          SizedBox(
            width: 140,
            child: Text(c.code, style: bvText(fontWeight: FontWeight.w800, fontSize: 12.5)),
          ),
          SizedBox(
            width: 88,
            child: Text(c.harvestCode.isEmpty ? '—' : c.harvestCode, style: bvText(fontSize: 12.5)),
          ),
          SizedBox(
            width: 88,
            child: Text(c.boxCode.isEmpty ? '—' : c.boxCode, style: bvText(fontSize: 12.5)),
          ),
          SizedBox(width: 64, child: Text('${c.weightG}', style: bvText(fontWeight: FontWeight.w700))),
          SizedBox(
            width: 110,
            child: MgmtDropdown<String>(
              valueLabel: _gradeLabel(_gradesById[c.id] ?? 'A'),
              items: _grades,
              onSelected: (v) => setState(() => _gradesById[c.id] = v),
            ),
          ),
          SizedBox(width: 140, child: _priceField(_prices[c.id]!, _perKg ? 'đ/kg' : 'đ/con')),
          SizedBox(
            width: 96,
            child: Text(
              formatVnd(_lineTotal(c)),
              style: bvText(fontWeight: FontWeight.w800, fontSize: 12.5),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              tooltip: 'Gỡ khỏi đơn',
              onPressed: _saving ? null : () => setState(() {
                _removeCrab(c.id);
                _syncPaid();
              }),
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: _kRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _crabCard(int i, InventoryCrab c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: DashboardColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('${i + 1}. ${c.code}', style: bvText(fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() {
                  _removeCrab(c.id);
                  _syncPaid();
                }),
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: _kRed),
              ),
            ],
          ),
          Text(
            '${c.harvestCode.isEmpty ? '—' : c.harvestCode}  ·  ${c.boxCode}  ·  ${c.weightG}g',
            style: bvText(fontSize: 12, color: DashboardColors.textMuted),
          ),
          const SizedBox(height: 8),
          _priceField(_prices[c.id]!, _perKg ? 'đ/kg' : 'đ/con'),
          const SizedBox(height: 6),
          Text('Thành tiền: ${formatVnd(_lineTotal(c))}', style: bvText(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _pricingCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Hình thức tính giá', Icons.payments_outlined),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _radioPrice(true, 'Theo kg', 'Khuyến nghị')),
              Expanded(child: _radioPrice(false, 'Theo con', null)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _perKg ? 'Đơn giá (VNĐ/kg) *' : 'Đơn giá (VNĐ/con) *',
            style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _priceField(_bulkPrice, _perKg ? 'đ/kg' : 'đ/con')),
              const SizedBox(width: 8),
              MgmtOutlineButton(
                onTap: _saving ? null : () => _applyPrice(),
                label: 'Áp dụng',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _radioPrice(bool perKg, String title, String? hint) {
    final on = _perKg == perKg;
    return InkWell(
      onTap: () => setState(() {
        _perKg = perKg;
        _syncPaid();
      }),
      child: Row(
        children: [
          Icon(
            on ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: on ? DashboardColors.brand : DashboardColors.textMuted,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: bvText(fontWeight: FontWeight.w700, fontSize: 12.5)),
              if (hint != null)
                Text(hint, style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Tóm tắt đơn hàng', Icons.receipt_long_outlined),
          const SizedBox(height: 10),
          _kv('Số cua', '${_selected.length} con'),
          _kv('Tổng trọng lượng', '${(_totalG / 1000).toStringAsFixed(3)} kg'),
          _kv('Đơn giá trung bình', _avgPrice == 0 ? '—' : '${formatVnd(_avgPrice)}/kg'),
          _kv('Tạm tính', formatVnd(_subtotal)),
          const SizedBox(height: 8),
          Text('Giảm giá', style: bvText(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _numField(_discount, _discountPercent ? '%' : 'đ')),
              const SizedBox(width: 8),
              _toggle('đ', !_discountPercent, () => setState(() {
                _discountPercent = false;
                _syncPaid();
              })),
              _toggle('%', _discountPercent, () => setState(() {
                _discountPercent = true;
                _syncPaid();
              })),
            ],
          ),
          const SizedBox(height: 8),
          Text('Phí vận chuyển', style: bvText(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _numField(
            _shipping,
            'đ',
            enabled: _delivery != 'pickup',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: DashboardColors.mint),
          ),
          Row(
            children: [
              Text('Tổng cộng', style: bvText(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(
                formatVnd(_grand),
                style: bvText(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.brand,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Thông tin thanh toán', Icons.account_balance_wallet_outlined),
          const SizedBox(height: 10),
          Text('Phương thức thanh toán *', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          MgmtDropdown<String>(
            valueLabel: _labelOf(_payMethods, _payMethod),
            leading: Icons.account_balance_outlined,
            items: _payMethods,
            onSelected: (v) => setState(() => _payMethod = v),
          ),
          const SizedBox(height: 10),
          Text('Trạng thái thanh toán *', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          MgmtDropdown<String>(
            valueLabel: _labelOf(_payStatuses, _payStatus),
            items: _payStatuses,
            onSelected: (v) => setState(() {
              _payStatus = v;
              _syncPaid();
            }),
          ),
          const SizedBox(height: 10),
          Text('Số tiền đã thanh toán *', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _numField(_paid, 'đ', enabled: _payStatus == 'Partial', onChanged: (_) {
            final v = _parseInt(_paid);
            if (v > _grand) _paid.text = '$_grand';
            setState(() {});
          }),
          const SizedBox(height: 10),
          _kv('Còn lại', formatVnd(_remaining)),
        ],
      ),
    );
  }

  Widget _deliverySection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Giao nhận', Icons.local_shipping_outlined),
          const SizedBox(height: 10),
          Text('Hình thức giao nhận *', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          MgmtDropdown<String>(
            valueLabel: _labelOf(_deliveries, _delivery),
            items: _deliveries,
            onSelected: (v) => setState(() {
              _delivery = v;
              if (v == 'pickup') _shipping.text = '0';
              _syncPaid();
            }),
          ),
          const SizedBox(height: 10),
          if (_delivery == 'pickup')
            _infoBox(Icons.home_outlined, 'Nhận tại trại', 'Khách hàng sẽ đến lấy hàng tại trại.')
          else if (_delivery == 'self')
            _infoBox(
              Icons.airport_shuttle_outlined,
              'Khách tự vận chuyển',
              'Khách hàng tự bố trí phương tiện vận chuyển.',
            )
          else ...[
            Text('Địa chỉ giao *', style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _shipAddress,
              decoration: _deco('Nhập địa chỉ giao hàng'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _shipName,
                    decoration: _deco('Người nhận'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _shipPhone,
                    decoration: _deco('SĐT người nhận'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _noteSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Ghi chú', Icons.notes_rounded),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            maxLength: _kNoteMax,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: _deco('Nhập ghi chú về đơn bán hàng...').copyWith(
              counterText: '${_note.text.length}/$_kNoteMax',
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(bool compact) {
    final actions = [
      MgmtOutlineButton(
        onTap: _saving ? null : () => Navigator.pop(context),
        icon: Icons.close_rounded,
        label: 'Hủy',
        color: DashboardColors.textMuted,
      ),
      const SizedBox(width: 8),
      MgmtOutlineButton(
        onTap: _saving ? null : () => _submit(draft: true),
        icon: Icons.save_outlined,
        label: _saving && !_confirming ? 'Đang lưu...' : 'Lưu nháp',
      ),
      const SizedBox(width: 8),
      MgmtPrimaryButton(
        onTap: _saving ? null : () => _submit(draft: false),
        icon: Icons.check_rounded,
        label: _saving && _confirming ? 'Đang tạo...' : 'Xác nhận bán hàng',
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: compact
          ? Wrap(alignment: WrapAlignment.end, runSpacing: 8, children: actions)
          : Row(children: [const Spacer(), ...actions]),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: DashboardColors.brand),
        const SizedBox(width: 6),
        Text(title, style: bvText(fontSize: 14, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: DashboardColors.mint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: bvText(fontWeight: FontWeight.w800, color: DashboardColors.brand, fontSize: 12)),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(k, style: bvText(color: DashboardColors.textMuted, fontSize: 12.5))),
          Text(v, style: bvText(fontWeight: FontWeight.w700, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _infoBox(IconData icon, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: DashboardColors.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: bvText(fontWeight: FontWeight.w800)),
                Text(body, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle(String label, bool on, VoidCallback tap) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? DashboardColors.brand : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: on ? DashboardColors.brand : DashboardColors.cardBorder),
          ),
          child: Text(
            label,
            style: bvText(
              fontWeight: FontWeight.w800,
              color: on ? Colors.white : DashboardColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceField(TextEditingController c, String suffix) => _numField(c, suffix);

  Widget _numField(
    TextEditingController c,
    String suffix, {
    bool enabled = true,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: c,
      enabled: enabled && !_saving,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (v) {
        onChanged?.call(v);
        setState(_syncPaid);
      },
      style: bvText(fontSize: 13.5, fontWeight: FontWeight.w600),
      decoration: _deco(null).copyWith(suffixText: suffix),
    );
  }

  Widget _errorBanner(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kRed.withValues(alpha: 0.25)),
      ),
      child: Text(text, style: bvText(color: _kRed, height: 1.4)),
    );
  }

  InputDecoration _deco(String? hint) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: bvText(color: DashboardColors.textMuted, fontSize: 13),
      isDense: true,
      filled: true,
      fillColor: enabledSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: border(DashboardColors.cardBorder),
      enabledBorder: border(DashboardColors.cardBorder),
      focusedBorder: border(DashboardColors.brand, 1.4),
    );
  }

  Color get enabledSoft => Colors.white;
}

class CreateCustomerDialog extends StatefulWidget {
  const CreateCustomerDialog({super.key, required this.service});
  final HarvestSalesService service;

  @override
  State<CreateCustomerDialog> createState() => _CreateCustomerDialogState();
}

class _CreateCustomerDialogState extends State<CreateCustomerDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  var _type = 'retail';
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Tên khách hàng là bắt buộc.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final c = await widget.service.upsertCustomer(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        customerType: _type,
      );
      if (!mounted) return;
      Navigator.pop(context, c);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Khách hàng mới', style: bvText(fontWeight: FontWeight.w800, fontSize: 16)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: bvText(color: _kRed)),
              ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên khách hàng *'),
            ),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
            ),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Địa chỉ'),
            ),
            const SizedBox(height: 10),
            Text('Loại khách *', style: bvText(fontWeight: FontWeight.w700, fontSize: 12.5)),
            const SizedBox(height: 6),
            MgmtDropdown<String>(
              valueLabel: _labelOf(_customerTypes, _type),
              items: _customerTypes,
              onSelected: (v) => setState(() => _type = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(
          onPressed: _busy ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.brand),
          child: Text(_busy ? 'Đang lưu...' : 'Tạo khách'),
        ),
      ],
    );
  }
}

class SelectSaleCrabsDialog extends StatefulWidget {
  const SelectSaleCrabsDialog({
    super.key,
    required this.crabs,
    required this.already,
  });

  final List<InventoryCrab> crabs;
  final Set<String> already;

  @override
  State<SelectSaleCrabsDialog> createState() => _SelectSaleCrabsDialogState();
}

class _SelectSaleCrabsDialogState extends State<SelectSaleCrabsDialog> {
  late final Set<String> _sel;
  final _q = TextEditingController();
  String? _har;
  String? _product;
  String? _grade;

  @override
  void initState() {
    super.initState();
    _sel = {...widget.already};
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<InventoryCrab> get _items {
    final q = _q.text.trim().toLowerCase();
    return widget.crabs.where((c) {
      if (_har != null && c.harvestCode != _har) return false;
      if (_product == 'soft' && !c.isSoftshell) return false;
      if (_product == 'meat' && c.isSoftshell) return false;
      if (_grade != null && _normGrade(c.grade) != _grade) return false;
      if (q.isEmpty) return true;
      return c.code.toLowerCase().contains(q) ||
          c.boxCode.toLowerCase().contains(q) ||
          c.harvestCode.toLowerCase().contains(q) ||
          c.lotCode.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final hars = {
      for (final c in widget.crabs)
        if (c.harvestCode.isNotEmpty) c.harvestCode,
    }.toList()
      ..sort();
    final chosen = widget.crabs.where((c) => _sel.contains(c.id));
    final kg = chosen.fold<int>(0, (s, c) => s + c.weightG) / 1000;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 680),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Chọn cua chờ bán', style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: MgmtSearchField(
                      controller: _q,
                      onChanged: (_) => setState(() {}),
                      hint: 'Tìm mã cua...',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MgmtDropdown<String?>(
                      valueLabel: _har ?? 'Phiếu thu hoạch',
                      items: [
                        (null, 'Tất cả phiếu'),
                        for (final h in hars) (h, h),
                      ],
                      onSelected: (v) => setState(() => _har = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MgmtDropdown<String?>(
                      valueLabel: _product == 'soft'
                          ? 'Cua lột'
                          : _product == 'meat'
                              ? 'Cua thịt'
                              : 'Loại sản phẩm',
                      items: const [
                        (null, 'Tất cả'),
                        ('meat', 'Cua thịt'),
                        ('soft', 'Cua lột'),
                      ],
                      onSelected: (v) => setState(() => _product = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MgmtDropdown<String?>(
                      valueLabel: _grade == null ? 'Phân loại' : _gradeLabel(_grade!),
                      items: const [
                        (null, 'Tất cả'),
                        ('A', 'Loại 1'),
                        ('B', 'Loại 2'),
                        ('C', 'Loại 3'),
                      ],
                      onSelected: (v) => setState(() => _grade = v),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text('Không còn cua chờ bán phù hợp.', style: bvText(color: DashboardColors.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      itemCount: items.length,
                      separatorBuilder: (_, i) => const Divider(height: 1, color: DashboardColors.mint),
                      itemBuilder: (_, i) {
                        final c = items[i];
                        return CheckboxListTile(
                          dense: true,
                          value: _sel.contains(c.id),
                          onChanged: !c.canSelect
                              ? null
                              : (v) => setState(() {
                                    if (v == true) {
                                      _sel.add(c.id);
                                    } else {
                                      _sel.remove(c.id);
                                    }
                                  }),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(c.code, style: bvText(fontWeight: FontWeight.w800, fontSize: 13)),
                          subtitle: Text(
                            c.canSelect
                                ? '${c.harvestCode.isEmpty ? '—' : c.harvestCode}  ·  ${c.boxCode}  ·  ${c.weightG}g  ·  ${c.productLabel}  ·  ${c.gradeLabel}'
                                : c.disableReason,
                            style: bvText(
                              fontSize: 12,
                              color: c.canSelect ? DashboardColors.textMuted : _kRed,
                            ),
                          ),
                          secondary: Text(
                            saleEligibilityLabel(c.eligibility),
                            style: bvText(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: c.eligibility == SaleEligibility.ready
                                  ? DashboardColors.brand
                                  : c.eligibility == SaleEligibility.review
                                      ? _kAmber
                                      : _kRed,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: const BoxDecoration(
                color: DashboardColors.lightMint,
                border: Border(top: BorderSide(color: DashboardColors.mint)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đã chọn: ${_sel.length} cua\nTổng KL: ${kg.toStringAsFixed(2)} kg',
                      style: bvText(fontSize: 12.5, height: 1.4),
                    ),
                  ),
                  MgmtOutlineButton(
                    onTap: () => Navigator.pop(context),
                    label: 'Hủy',
                    color: DashboardColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  MgmtPrimaryButton(
                    onTap: () => Navigator.pop(context, _sel),
                    label: 'Thêm ${_sel.length} cua',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
