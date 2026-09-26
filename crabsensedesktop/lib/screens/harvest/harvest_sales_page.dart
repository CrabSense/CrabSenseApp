import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/harvest_sales.dart';
import '../../navigation/app_route.dart';
import '../../services/harvest_sales_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/harvest/harvest_sales_dialogs.dart';
import '../../widgets/harvest/harvest_tab_widgets.dart';
import '../../widgets/harvest/sales_tab_widgets.dart';
import '../../widgets/shared/mgmt_ui.dart';

class HarvestSalesPage extends StatefulWidget {
  const HarvestSalesPage({
    super.key,
    required this.service,
    this.onNavigate,
  });

  final HarvestSalesService service;
  final void Function(AppRoute route)? onNavigate;

  @override
  State<HarvestSalesPage> createState() => _HarvestSalesPageState();
}

class _HarvestSalesPageState extends State<HarvestSalesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    widget.service.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    _tabs.dispose();
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: _HarvestHeader(onNavigate: widget.onNavigate),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: DashboardColors.brand,
            indicatorWeight: 2.4,
            labelColor: DashboardColors.brand,
            unselectedLabelColor: DashboardColors.textMuted,
            labelStyle: bvText(fontWeight: FontWeight.w700, fontSize: 13.5),
            unselectedLabelStyle: bvText(fontWeight: FontWeight.w600, fontSize: 13.5),
            tabs: const [
              Tab(text: 'Thu hoạch'),
              Tab(text: 'Bán hàng'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              HarvestTab(service: service),
              SalesTab(service: service),
            ],
          ),
        ),
      ],
    );
  }
}

class _HarvestHeader extends StatelessWidget {
  const _HarvestHeader({this.onNavigate});
  final void Function(AppRoute route)? onNavigate;

  @override
  Widget build(BuildContext context) {
    final link = bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: DashboardColors.brand);
    final muted = bvText(fontSize: 12.5, color: DashboardColors.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            InkWell(
              onTap: () => onNavigate?.call(AppRoute.dashboard),
              child: Text('Trang chủ', style: link),
            ),
            Text('  >  ', style: muted),
            Text(
              'Thu hoạch & Bán hàng',
              style: muted.copyWith(
                color: DashboardColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DashboardColors.lightMint,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.agriculture_outlined, color: DashboardColors.brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thu hoạch & Bán hàng',
                    style: bvText(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Quản lý quy trình thu hoạch cua và bán hàng, theo dõi sản lượng và truy xuất nguồn gốc.',
                    style: bvText(fontSize: 13, color: DashboardColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class HarvestTab extends StatefulWidget {
  const HarvestTab({super.key, required this.service});

  final HarvestSalesService service;

  @override
  State<HarvestTab> createState() => _HarvestTabState();
}

class _HarvestTabState extends State<HarvestTab> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _readyKey = GlobalKey();
  final _selectedCrabs = <String>{};
  final _selectedRows = <String>{};
  Timer? _debounce;
  HarvestSlipDetail? _detail;
  var _showAllReady = false;

  HarvestSalesService get service => widget.service;

  @override
  void initState() {
    super.initState();
    _search.text = service.search;
    _search.addListener(_onSearchChanged);
    if (service.pagedHarvests.isNotEmpty) {
      _detail = service.pagedHarvests.first;
    }
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    _scroll.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      service.setSearch(_search.text);
    });
  }

  List<HarvestableCrab> get _picked =>
      service.readyCrabs.where((c) => _selectedCrabs.contains(c.id)).toList();

  void _scrollToReady() {
    final ctx = _readyKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  void _onKpi(HarvestKpiFocus focus) {
    service.applyKpi(focus);
    if (focus == HarvestKpiFocus.harvestable ||
        focus == HarvestKpiFocus.softshell) {
      _scrollToReady();
    }
  }

  Future<void> _create({List<HarvestableCrab>? crabs, bool softshell = false}) {
    return showCreateHarvestSlipDialog(
      context,
      service,
      softshellMode: softshell,
      initialCrabs: crabs ?? _picked,
    );
  }

  Future<void> _transfer(HarvestSlipDetail slip) {
    return showCreateSalesOrderDialog(context, service, fromSlip: slip);
  }

  Future<void> _complete(HarvestSlipDetail slip) async {
    final ok = await showCompleteHarvestDialog(context, slip);
    if (ok != true || !mounted) return;
    try {
      await service.completeHarvest(slip.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã hoàn tất ${slip.code}.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _cancel(HarvestSlipDetail slip) async {
    try {
      await service.cancelHarvest(slip.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã hủy ${slip.code}.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _export() async {
    final csv = service.exportCsv();
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Xuất phiếu thu hoạch',
      fileName: 'harvest-slips.csv',
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (path == null) return;
    await File(path).writeAsString(csv);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xuất ${service.filteredHarvestCount} phiếu.')),
    );
  }

  void _toastSlip(HarvestSlipDetail slip, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action ${slip.code}')),
    );
  }

  void _onRowAction(HarvestSlipDetail slip, HarvestRowAction action) {
    setState(() => _detail = slip);
    switch (action) {
      case HarvestRowAction.detail:
        break;
      case HarvestRowAction.print:
        _toastSlip(slip, 'In phiếu');
      case HarvestRowAction.pdf:
        _toastSlip(slip, 'Tải PDF');
      case HarvestRowAction.edit:
        _create();
      case HarvestRowAction.cancel:
        _cancel(slip);
      case HarvestRowAction.sale:
        _transfer(slip);
      case HarvestRowAction.complete:
        _complete(slip);
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = service;
    HarvestSlipDetail? detail = _detail;
    if (detail != null) {
      final still = svc.filteredHarvests.where((h) => h.id == detail!.id);
      detail = still.isEmpty
          ? (svc.pagedHarvests.isEmpty ? null : svc.pagedHarvests.first)
          : still.first;
    } else if (svc.pagedHarvests.isNotEmpty) {
      detail = svc.pagedHarvests.first;
    }

    return LayoutBuilder(
      builder: (context, box) {
        final desktop = box.maxWidth >= 1100;
        final tablet = box.maxWidth >= 800;
        return ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          children: [
            HarvestKpiRow(
              kpi: svc.harvestKpi,
              loading: svc.loading && svc.harvestKpi.harvestable == 0,
              onTap: _onKpi,
            ),
            const SizedBox(height: 14),
            HarvestFilterToolbar(
              search: _search,
              service: svc,
              onCreate: () => _create(),
              onClearSearch: () => service.setSearch(''),
              onExport: _export,
            ),
            const SizedBox(height: 14),
            KeyedSubtree(
              key: _readyKey,
              child: ReadyToHarvestSection(
                service: svc,
                selected: _selectedCrabs,
                showAll: _showAllReady,
                onToggleShowAll: () => setState(() => _showAllReady = !_showAllReady),
                onToggle: (c, v) => setState(() {
                  if (v) {
                    _selectedCrabs.add(c.id);
                  } else {
                    _selectedCrabs.remove(c.id);
                  }
                }),
                onViewCrab: (c) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${c.code} · ${c.boxCode} · ${c.lotCode.isEmpty ? '—' : c.lotCode}',
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_picked.isNotEmpty) ...[
              const SizedBox(height: 12),
              HarvestSelectionBar(
                crabs: _picked,
                onCreate: () => _create(crabs: _picked),
                onClear: () => setState(_selectedCrabs.clear),
              ),
            ],
            const SizedBox(height: 14),
            if (desktop)
              SizedBox(
                height: 620,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 7,
                      child: HarvestSlipTable(
                        service: svc,
                        selectedId: detail?.id,
                        onSelect: (s) => setState(() => _detail = s),
                        onAction: _onRowAction,
                        rowSelected: _selectedRows,
                        onToggleRow: (s, v) => setState(() {
                          if (v) {
                            _selectedRows.add(s.id);
                          } else {
                            _selectedRows.remove(s.id);
                          }
                        }),
                        onToggleAll: (v) => setState(() {
                          if (v) {
                            _selectedRows.addAll(svc.pagedHarvests.map((e) => e.id));
                          } else {
                            for (final e in svc.pagedHarvests) {
                              _selectedRows.remove(e.id);
                            }
                          }
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: HarvestDetailPanel(
                        slip: detail,
                        onClose: () => setState(() => _detail = null),
                        onTransfer: () {
                          if (detail != null) _transfer(detail);
                        },
                        onComplete: () {
                          if (detail != null) _complete(detail);
                        },
                        onPrint: () {
                          if (detail != null) _toastSlip(detail, 'In phiếu');
                        },
                        onPdf: () {
                          if (detail != null) _toastSlip(detail, 'Tải PDF');
                        },
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              HarvestSlipTable(
                service: svc,
                selectedId: detail?.id,
                onSelect: (s) {
                  setState(() => _detail = s);
                  if (!tablet) _openDetailSheet(s);
                },
                onAction: _onRowAction,
                rowSelected: _selectedRows,
                onToggleRow: (s, v) => setState(() {
                  if (v) {
                    _selectedRows.add(s.id);
                  } else {
                    _selectedRows.remove(s.id);
                  }
                }),
                onToggleAll: (v) => setState(() {
                  if (v) {
                    _selectedRows.addAll(svc.pagedHarvests.map((e) => e.id));
                  } else {
                    for (final e in svc.pagedHarvests) {
                      _selectedRows.remove(e.id);
                    }
                  }
                }),
              ),
              if (tablet && detail != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 480,
                  child: HarvestDetailPanel(
                    slip: detail,
                    onClose: () => setState(() => _detail = null),
                    onTransfer: () => _transfer(detail!),
                    onComplete: () => _complete(detail!),
                    onPrint: () => _toastSlip(detail!, 'In phiếu'),
                    onPdf: () => _toastSlip(detail!, 'Tải PDF'),
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  void _openDetailSheet(HarvestSlipDetail slip) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.88,
        child: HarvestDetailPanel(
          slip: slip,
          onClose: () => Navigator.pop(ctx),
          onTransfer: () {
            Navigator.pop(ctx);
            _transfer(slip);
          },
          onComplete: () {
            Navigator.pop(ctx);
            _complete(slip);
          },
          onPrint: () => _toastSlip(slip, 'In phiếu'),
          onPdf: () => _toastSlip(slip, 'Tải PDF'),
        ),
      ),
    );
  }
}
