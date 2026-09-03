import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/farming_batch_group.dart';
import '../../services/batch_management_service.dart';
import '../../services/production_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/batch/farming_batch_detail_widgets.dart';
import '../../widgets/batch/farming_batch_form_dialog.dart';

class FarmingBatchDetailPage extends StatefulWidget {
  const FarmingBatchDetailPage({
    super.key,
    required this.service,
    required this.productionService,
    required this.groupKey,
    this.initialGroup,
    required this.onBack,
  });

  final BatchManagementService service;
  final ProductionManagementService productionService;
  final String groupKey;
  final FarmingBatchGroup? initialGroup;
  final VoidCallback onBack;

  @override
  State<FarmingBatchDetailPage> createState() => _FarmingBatchDetailPageState();
}

class _FarmingBatchDetailPageState extends State<FarmingBatchDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  FarmingBatchGroup? _group;
  List<BatchCrabWithBox> _crabs = [];
  bool _loadingCrabs = false;
  String? _crabError;
  final _crabSearch = TextEditingController();
  var _chartDays = 30;

  @override
  void initState() {
    super.initState();
    _group =
        widget.initialGroup ?? widget.service.findGroup(widget.groupKey);
    _tabs = TabController(length: 6, vsync: this);
    widget.service.addListener(_onServiceUpdate);
    _loadCrabs();
    if (_group == null && !widget.service.loading) {
      widget.service.load();
    }
  }

  @override
  void dispose() {
    widget.service.removeListener(_onServiceUpdate);
    _tabs.dispose();
    _crabSearch.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    final g = widget.service.findGroup(widget.groupKey);
    if (g != null) _group = g;
    if (mounted) setState(() {});
  }

  Future<void> _loadCrabs() async {
    final g = _group;
    if (g == null) return;
    setState(() {
      _loadingCrabs = true;
      _crabError = null;
    });
    try {
      final list = await widget.service.loadCrabsForGroup(g);
      if (!mounted) return;
      setState(() {
        _crabs = list;
        _loadingCrabs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _crabError = '$e';
        _loadingCrabs = false;
      });
    }
  }

  int get _moltingCount => _crabs
      .where((c) => c.crab.status.toLowerCase().contains('molt'))
      .length;

  List<BatchCrabWithBox> get _filteredCrabs {
    final q = _crabSearch.text.trim().toLowerCase();
    if (q.isEmpty) return _crabs;
    return _crabs
        .where(
          (c) =>
              c.crab.crabCode.toLowerCase().contains(q) ||
              c.boxCode.toLowerCase().contains(q),
        )
        .toList();
  }

  void _edit(FarmingBatchGroup group) {
    showFarmingBatchFormDialog(
      context,
      batchSvc: widget.service,
      prodSvc: widget.productionService,
      existing: group.primary,
    ).then((_) {
      if (!mounted) return;
      _group = widget.service.findGroup(widget.groupKey) ?? _group;
      _loadCrabs();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    if (group == null) {
      return Center(
        child: widget.service.loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Không tìm thấy đợt nuôi',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: widget.onBack,
                    child: const Text('Quay lại'),
                  ),
                ],
              ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FarmingBatchDetailTitleRow(
            group: group,
            onBack: widget.onBack,
            onEdit: () => _edit(group),
          ),
          const SizedBox(height: 20),
          FarmingBatchSummaryRow(
            group: group,
            moltingCount: _moltingCount,
            alertCount: group.status == 'failed' ? 3 : 0,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 960;
              final chart = FarmingBatchGrowthSurvivalChart(
                group: group,
                days: _chartDays,
                onDaysChanged: (d) => setState(() => _chartDays = d),
              );
              final feed = FarmingBatchFeedGaugeCard(
                currentKg: group.totalInitial * 0.169,
                targetKg: 120,
              );
              if (!wide) {
                return Column(
                  children: [chart, const SizedBox(height: 16), feed],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: chart),
                    const SizedBox(width: 16),
                    SizedBox(width: 280, child: feed),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          FarmingBatchDetailTabs(
            controller: _tabs,
            group: group,
            crabSearch: _crabSearch,
            onCrabSearchChanged: () => setState(() {}),
            loadingCrabs: _loadingCrabs,
            crabError: _crabError,
            crabs: _filteredCrabs,
            totalCrabs: _crabs.length,
            onRetryCrabs: _loadCrabs,
          ),
        ],
      ),
    );
  }
}
