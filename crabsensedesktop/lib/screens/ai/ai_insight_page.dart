import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/ai_assistant_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/ai/ai_assistant_widgets.dart';
import '../../widgets/shared/ai_assistant_avatar.dart';

class AiInsightPage extends StatefulWidget {
  const AiInsightPage({super.key, required this.service});

  final AiAssistantService service;

  @override
  State<AiInsightPage> createState() => _AiInsightPageState();
}

class _AiInsightPageState extends State<AiInsightPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
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
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const AiAssistantAvatar(size: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Insight',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Crab Assistant — phân tích & hỗ trợ quyết định',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: DashboardColors.card.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DashboardColors.cardBorder),
                ),
                child: TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: DashboardColors.cyan,
                  labelColor: DashboardColors.textPrimary,
                  unselectedLabelColor: DashboardColors.textMuted,
                  labelStyle: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Tổng quan'),
                    Tab(text: 'Chat AI'),
                    Tab(text: 'Khuyến nghị'),
                    Tab(text: 'Cảnh báo AI'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: TabBarView(
              controller: _tabs,
              children: [
                SingleChildScrollView(
                  child: AiOverviewTab(
                    summary: service.overviewSummary,
                    kpi: service.overviewKpi,
                  ),
                ),
                AiChatTab(
                  messages: service.messages,
                  quickPrompts: service.quickPrompts,
                  onSend: service.sendMessage,
                ),
                AiRecommendationsTab(
                  items: service.filteredRecommendations,
                  onApply: (id) {
                    service.applyRecommendation(id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã áp dụng khuyến nghị (demo)')),
                    );
                  },
                ),
                AiAlertsTab(
                  alerts: service.aiAlerts,
                  onDismiss: (id) {
                    service.dismissAlert(id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã bỏ qua cảnh báo')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
