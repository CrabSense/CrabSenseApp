import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/ai_assistant.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';
import '../shared/ai_assistant_avatar.dart';

class AiOverviewTab extends StatelessWidget {
  const AiOverviewTab({
    super.key,
    required this.summary,
    required this.kpi,
  });

  final String summary;
  final List<AiInsightCard> kpi;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AiAssistantAvatar(size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crab Assistant — Tổng quan',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final cards = kpi
                .map(
                  (item) => _KpiTile(
                    title: item.title,
                    value: item.value,
                    trend: item.trend,
                    trendUp: item.trendUp,
                  ),
                )
                .toList();
            if (c.maxWidth < 700) {
              return Wrap(spacing: 10, runSpacing: 10, children: cards);
            }
            return Row(
              children: cards
                  .map(
                    (card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: card,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.title,
    required this.value,
    required this.trend,
    required this.trendUp,
  });

  final String title;
  final String value;
  final String trend;
  final bool trendUp;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 10)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            trend,
            style: GoogleFonts.notoSans(
              fontSize: 10,
              color: trendUp ? DashboardColors.healthy : DashboardColors.molting,
            ),
          ),
        ],
      ),
    );
  }
}

class AiChatTab extends StatefulWidget {
  const AiChatTab({
    super.key,
    required this.messages,
    required this.quickPrompts,
    required this.onSend,
  });

  final List<AiChatMessage> messages;
  final List<String> quickPrompts;
  final ValueChanged<String> onSend;

  @override
  State<AiChatTab> createState() => _AiChatTabState();
}

class _AiChatTabState extends State<AiChatTab> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final msg = text ?? _controller.text;
    widget.onSend(msg);
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.quickPrompts
              .map(
                (p) => ActionChip(
                  label: Text(p, style: GoogleFonts.notoSans(fontSize: 11)),
                  onPressed: () => _send(p),
                  backgroundColor: DashboardColors.darkNavy,
                  side: BorderSide(color: DashboardColors.cardBorder),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: widget.messages.length,
              itemBuilder: (context, i) {
                final m = widget.messages[i];
                return _ChatBubble(message: m);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Hỏi Crab Assistant...',
                  hintStyle: GoogleFonts.notoSans(fontSize: 12),
                  filled: true,
                  fillColor: DashboardColors.darkNavy,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: DashboardColors.cardBorder),
                  ),
                ),
                onSubmitted: _send,
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: () => _send(),
              style: FilledButton.styleFrom(backgroundColor: DashboardColors.cyan),
              child: const Icon(Icons.send_rounded, size: 20),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final user = message.isUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: user
              ? DashboardColors.purple.withValues(alpha: 0.35)
              : DashboardColors.darkNavy.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DashboardColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text, style: GoogleFonts.notoSans(fontSize: 12, height: 1.45)),
            const SizedBox(height: 4),
            Text(
              message.time,
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class AiRecommendationsTab extends StatelessWidget {
  const AiRecommendationsTab({
    super.key,
    required this.items,
    required this.onApply,
  });

  final List<AiRecommendation> items;
  final ValueChanged<String> onApply;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Không có khuyến nghị phù hợp bộ lọc.',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        ),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final r = items[i];
        final color = switch (r.priority) {
          AiInsightPriority.high => DashboardColors.risk,
          AiInsightPriority.medium => DashboardColors.molting,
          AiInsightPriority.low => DashboardColors.cyan,
        };
        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(r.icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.title,
                            style: GoogleFonts.notoSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            r.module,
                            style: GoogleFonts.notoSans(color: color, fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.detail,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        onPressed: () => onApply(r.id),
                        style: FilledButton.styleFrom(
                          backgroundColor: DashboardColors.purple,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: const Text('Áp dụng', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AiAlertsTab extends StatelessWidget {
  const AiAlertsTab({
    super.key,
    required this.alerts,
    required this.onDismiss,
  });

  final List<AiAlertInsight> alerts;
  final ValueChanged<String> onDismiss;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: alerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final a = alerts[i];
        final color = a.priority == AiInsightPriority.high
            ? DashboardColors.risk
            : DashboardColors.molting;
        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(a.area, style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 12)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => onDismiss(a.id),
                    child: Text(
                      'Bỏ qua',
                      style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(a.message, style: GoogleFonts.notoSans(fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DashboardColors.darkNavy.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DashboardColors.cardBorder),
                ),
                child: Text(
                  '→ ${a.suggestedAction}',
                  style: GoogleFonts.notoSans(color: DashboardColors.cyan, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
