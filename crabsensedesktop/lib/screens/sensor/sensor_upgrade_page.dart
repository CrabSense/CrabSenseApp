import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/sensor_kit_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/sensor/sensor_upgrade_widgets.dart';

class SensorUpgradePage extends StatefulWidget {
  const SensorUpgradePage({super.key, required this.service});

  final SensorKitService service;

  @override
  State<SensorUpgradePage> createState() => _SensorUpgradePageState();
}

class _SensorUpgradePageState extends State<SensorUpgradePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(_onTabChanged);
    widget.service.addListener(_onUpdate);
    widget.service.selectPlan('pro');
  }

  void _onTabChanged() {
    if (!_tabs.indexIsChanging) {
      final plans = widget.service.plans;
      if (_tabs.index < plans.length) {
        widget.service.selectPlan(plans[_tabs.index].id);
      }
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    widget.service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  bool _isCurrentPlan(String planId, String currentPlanName) {
    return switch (planId) {
      'basic' => currentPlanName.contains('Starter') || currentPlanName.contains('Cơ bản'),
      'pro' => currentPlanName.contains('Pro'),
      'enterprise' => currentPlanName.contains('Enterprise'),
      _ => false,
    };
  }

  Future<void> _upgrade() async {
    await widget.service.upgradeToSelected();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã nâng cấp lên ${widget.service.current.planName}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final plans = service.plans;
    final currentName = service.current.planName;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upgrade Sensor Kit',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mở rộng giám sát & kích hoạt AI cho trại',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.upgrade, color: DashboardColors.cyan, size: 32),
            ],
          ),
          const SizedBox(height: 20),
          CurrentKitCard(current: service.current),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: DashboardColors.card.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DashboardColors.cardBorder),
            ),
            child: TabBar(
              controller: _tabs,
              indicatorColor: DashboardColors.purple,
              labelColor: DashboardColors.textPrimary,
              unselectedLabelColor: DashboardColors.textMuted,
              labelStyle: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: [for (final p in plans) Tab(text: p.name)],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 420,
            child: TabBarView(
              controller: _tabs,
              children: [
                for (final plan in plans)
                  SingleChildScrollView(
                    child: SensorPlanCard(
                      plan: plan,
                      selected: service.selectedPlanId == plan.id,
                      isCurrent: _isCurrentPlan(plan.id, currentName),
                      onSelect: () {
                        service.selectPlan(plan.id);
                        _tabs.animateTo(plans.indexOf(plan));
                      },
                      onUpgrade: _upgrade,
                      upgrading: service.upgrading,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SensorCompareTable(rows: service.compareRows),
        ],
      ),
    );
  }
}
