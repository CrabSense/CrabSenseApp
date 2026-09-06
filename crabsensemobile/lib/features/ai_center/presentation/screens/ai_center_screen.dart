import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../home/presentation/widgets/crab_hologram_painter.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../data/models/ai_center_models.dart';
import '../providers/ai_center_provider.dart';

/// Hub Trung tâm AI — detections + recommendations + model info.
class AiCenterScreen extends ConsumerWidget {
  const AiCenterScreen({super.key, this.initialTab = AiCenterTab.overview});

  final AiCenterTab initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiCenterStateProvider(initialTab));
    final notifier = ref.read(aiCenterStateProvider(initialTab).notifier);
    final fmt = DateFormat('HH:mm dd/MM');

    ref.listen(aiCenterStateProvider(initialTab), (prev, next) {
      final msg = next.feedbackMessage;
      if (msg != null && msg != prev?.feedbackMessage && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    });

    return Scaffold(
      backgroundColor: kHomeBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CrabHologramPainter(
                  color: kHomeBlueLight.withValues(alpha: 0.05),
                  trayExtent: 32,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: kHomeBlueLight,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'TRUNG TÂM AI',
                          style: TextStyle(
                            color: kHomePrimaryDark,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Làm mới',
                        onPressed: notifier.load,
                        icon: const Icon(Icons.refresh_rounded, color: kHomeCyan),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    decoration: homeCardDecoration(radius: 16, glowAlpha: 0.12),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        const HomeCrabWatermark(alpha: 0.05, trayExtent: 20),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              _MiniStat(
                                label: 'Phát hiện',
                                value: '${state.detections.length}',
                                color: kHomeBlueLight,
                              ),
                              _MiniStat(
                                label: 'Gợi ý',
                                value: '${state.activeRecCount}',
                                color: kHomePurple,
                              ),
                              _MiniStat(
                                label: 'Độ tin cậy',
                                value: state.detections.isEmpty
                                    ? '—'
                                    : '${state.avgConfidence.toStringAsFixed(0)}%',
                                color: kHomeCyan,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _TabChip(
                        label: 'Tổng quan',
                        selected: state.tab == AiCenterTab.overview,
                        onTap: () => notifier.setTab(AiCenterTab.overview),
                      ),
                      _TabChip(
                        label: 'Phát hiện',
                        selected: state.tab == AiCenterTab.detections,
                        onTap: () => notifier.setTab(AiCenterTab.detections),
                      ),
                      _TabChip(
                        label: 'Khuyến nghị',
                        selected: state.tab == AiCenterTab.recommendations,
                        onTap: () =>
                            notifier.setTab(AiCenterTab.recommendations),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: state.isLoading &&
                          state.detections.isEmpty &&
                          state.recommendations.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(color: kHomeCyan),
                        )
                      : state.error != null &&
                              state.detections.isEmpty &&
                              state.recommendations.isEmpty
                          ? _ErrorBody(
                              message: state.error!,
                              onRetry: notifier.load,
                            )
                          : RefreshIndicator(
                              color: kHomeCyan,
                              backgroundColor: kHomeSurface,
                              onRefresh: notifier.load,
                              child: switch (state.tab) {
                                AiCenterTab.overview => _OverviewTab(
                                    state: state,
                                    onOpenDetections: () =>
                                        notifier.setTab(AiCenterTab.detections),
                                    onOpenRecs: () => notifier
                                        .setTab(AiCenterTab.recommendations),
                                  ),
                                AiCenterTab.detections => _DetectionsTab(
                                    items: state.detections,
                                    fmt: fmt,
                                    onFeedback: (d, ok) => notifier.sendFeedback(
                                      detectionId: d.id,
                                      isCorrect: ok,
                                    ),
                                  ),
                                AiCenterTab.recommendations =>
                                  _RecommendationsTab(
                                    items: state.recommendations,
                                  ),
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF5A7184),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        onSelected: (_) => onTap(),
        label: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        selectedColor: kHomeBlue.withValues(alpha: 0.45),
        backgroundColor: kHomeBg.withValues(alpha: 0.72),
        side: BorderSide(
          color: selected
              ? kHomeCyan.withValues(alpha: 0.8)
              : kHomeBorderBlue.withValues(alpha: 0.45),
        ),
        showCheckmark: false,
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.psychology_outlined, color: kHomeOrange, size: 40),
        const SizedBox(height: 12),
        Text(
          'Không tải được dữ liệu AI',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF5A7184),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF5A7184),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: kHomeCyan,
              foregroundColor: kHomeBg,
            ),
            child: const Text('Thử lại'),
          ),
        ),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.state,
    required this.onOpenDetections,
    required this.onOpenRecs,
  });

  final AiCenterState state;
  final VoidCallback onOpenDetections;
  final VoidCallback onOpenRecs;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          decoration: homeCardDecoration(radius: 16, glowAlpha: 0.12),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              const HomeCrabWatermark(alpha: 0.05, trayExtent: 22),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MÔ HÌNH',
                      style: TextStyle(
                        color: kHomePrimaryDark,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.modelVersion,
                      style: const TextStyle(
                        color: kHomeTextMain,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.detections.isEmpty
                          ? 'Chưa có phát hiện — mô hình sẵn sàng khi có video/kiểm tra.'
                          : 'Đang hoạt động · ${state.detections.length} phát hiện gần đây · độ tin cậy TB ${state.avgConfidence.toStringAsFixed(1)}%.',
                      style: TextStyle(
                        color: const Color(0xFF5A7184),
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _NavCard(
          icon: Icons.history_rounded,
          title: 'Lịch sử phát hiện',
          subtitle: '${state.detections.length} lượt',
          onTap: onOpenDetections,
        ),
        const SizedBox(height: 10),
        _NavCard(
          icon: Icons.auto_awesome_rounded,
          title: 'Khuyến nghị AI',
          subtitle: '${state.activeRecCount} đề xuất đang hoạt động',
          onTap: onOpenRecs,
        ),
        const SizedBox(height: 10),
        _NavCard(
          icon: Icons.feedback_outlined,
          title: 'Phản hồi AI',
          subtitle: 'Mở tab Phát hiện → chọn đúng/sai trên từng kết quả',
          onTap: onOpenDetections,
        ),
      ],
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: homeCardDecoration(radius: 16, glowAlpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: kHomeCyan),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: kHomeTextMain,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: const Color(0xFF5A7184),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF5A7184),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetectionsTab extends StatelessWidget {
  const _DetectionsTab({
    required this.items,
    required this.fmt,
    required this.onFeedback,
  });

  final List<AiDetectionItem> items;
  final DateFormat fmt;
  final void Function(AiDetectionItem, bool) onFeedback;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: 160,
            child: Center(
              child: Text(
                'Chưa có phát hiện AI',
                style: TextStyle(color: const Color(0xFF5A7184)),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final d = items[i];
        return Container(
          decoration: homeCardDecoration(radius: 16, glowAlpha: 0.1),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              const HomeCrabWatermark(alpha: 0.04, trayExtent: 20),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            d.typeLabelVi,
                            style: const TextStyle(
                              color: kHomeTextMain,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              height: 1.3,
                            ),
                          ),
                        ),
                        Text(
                          '${d.confidencePct}%',
                          style: const TextStyle(
                            color: kHomeCyan,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${d.statusLabelVi} · ${fmt.format(d.detectedAt.toLocal())}',
                      style: TextStyle(
                        color: const Color(0xFF5A7184),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    if (d.boxId != null && d.boxId!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Box: ${d.boxId}',
                        style: TextStyle(
                          color: const Color(0xFF5A7184),
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Model: ${d.modelVersion}',
                      style: TextStyle(
                        color: const Color(0xFF5A7184),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => onFeedback(d, true),
                          icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                          label: const Text('Đúng'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kHomeGreen,
                            side: BorderSide(
                              color: kHomeGreen.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => onFeedback(d, false),
                          icon: const Icon(Icons.thumb_down_alt_outlined, size: 16),
                          label: const Text('Sai'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kHomeOrange,
                            side: BorderSide(
                              color: kHomeOrange.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
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

class _RecommendationsTab extends StatelessWidget {
  const _RecommendationsTab({required this.items});

  final List<AiRecommendationItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: 160,
            child: Center(
              child: Text(
                'Chưa có khuyến nghị',
                style: TextStyle(color: const Color(0xFF5A7184)),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final r = items[i];
        final prioColor = switch (r.priority.toLowerCase()) {
          'high' => const Color(0xFFFF6B6B),
          'medium' => kHomeOrange,
          _ => kHomeGreen,
        };
        return Container(
          decoration: homeCardDecoration(
            radius: 16,
            glowAlpha: 0.1,
            accent: kHomePurple,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              const HomeCrabWatermark(alpha: 0.04, trayExtent: 20),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            r.title,
                            style: const TextStyle(
                              color: kHomeTextMain,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              height: 1.3,
                            ),
                          ),
                        ),
                        Text(
                          '${r.confidencePercentage}%',
                          style: const TextStyle(
                            color: kHomeCyan,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Tag(label: r.typeLabelVi, color: kHomePurple),
                        _Tag(label: r.priorityLabelVi, color: prioColor),
                        if (r.targetBoxOrArea.isNotEmpty)
                          _Tag(
                            label: r.targetBoxOrArea,
                            color: kHomeBlueLight,
                          ),
                      ],
                    ),
                    if (r.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        r.description,
                        style: TextStyle(
                          color: const Color(0xFF5A7184),
                          height: 1.4,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (r.reason.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Lý do: ${r.reason}',
                        style: TextStyle(
                          color: const Color(0xFF5A7184),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (r.optimalTimeframe.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Thời điểm: ${r.optimalTimeframe}',
                        style: TextStyle(
                          color: const Color(0xFF5A7184),
                          fontSize: 12,
                        ),
                      ),
                    ],
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

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
