import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../../../core/di/injection.dart';
import '../../../../app/routes.dart';
import '../../domain/entities/ai_detection.dart';
import '../../domain/usecases/get_ai_results_usecase.dart';
import '../../../box/domain/entities/box_enums.dart';
import '../bloc/ai_results_bloc.dart';
import '../bloc/ai_results_event.dart';
import '../bloc/ai_results_state.dart';

/// Screen displaying AI detection results for a captured video.
///
/// Shows molting status classification, health indicators, confidence
/// score, detected crab overlays, and actionable recommendations.
/// Allows the operator to submit correct/incorrect feedback on the
/// result, and prompts for manual inspection when confidence < 70%.
///
/// Requirements: 6.1-6.10
class AiResultsScreen extends StatelessWidget {
  const AiResultsScreen({required this.videoId, required this.boxId, super.key});

  /// The video whose AI analysis is displayed.
  final String videoId;

  /// The box this video was captured for (used for navigation).
  final String boxId;

  @override
  Widget build(BuildContext context) => BlocProvider<AiResultsBloc>(
    create: (_) => AiResultsBloc(
      getAIResultsUseCase: sl<GetAIResultsUseCase>(),
      videoRepository: sl(),
      logger: sl(),
    )..add(LoadAIResults(videoId: videoId)),
    child: _AiResultsView(boxId: boxId, videoId: videoId),
  );
}

// ---------------------------------------------------------------------------
// Main view widget
// ---------------------------------------------------------------------------

class _AiResultsView extends StatelessWidget {
  const _AiResultsView({required this.boxId, required this.videoId});

  final String boxId;
  final String videoId;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kHomeNavyDeep,
    appBar: AppBar(
      title: const Text(
        'K?T QU? AI',
        style: TextStyle(
          color: kHomeBlueLight,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
      backgroundColor: kHomeNavy,
      foregroundColor: kHomeBlueLight,
      elevation: 0,
      actions: [
        BlocBuilder<AiResultsBloc, AiResultsState>(
          builder: (context, state) {
            final isLoading = state is AiResultsLoading || state is AiResultsPolling;
            if (isLoading) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'T?i l?i',
              onPressed: () =>
                  context.read<AiResultsBloc>().add(RefreshAIResults(videoId: videoId)),
            );
          },
        ),
      ],
    ),
    body: BlocConsumer<AiResultsBloc, AiResultsState>(
      listener: _onStateChange,
      builder: _buildBody,
    ),
  );

  void _onStateChange(BuildContext context, AiResultsState state) {
    if (state is FeedbackSubmitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('?? g?i ph?n h?i ? c?m ?n b?n!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    if (state is FeedbackError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildBody(BuildContext context, AiResultsState state) {
    if (state is AiResultsLoading) {
      return const _LoadingView();
    }
    if (state is AiResultsPolling) {
      return _PollingView(attemptCount: state.attemptCount);
    }
    if (state is AiResultsError) {
      return _ErrorView(
        message: state.message,
        onRetry: () => context.read<AiResultsBloc>().add(LoadAIResults(videoId: videoId)),
      );
    }

    final detection = _extractDetection(state);
    if (detection == null) {
      return const _LoadingView();
    }

    final requiresManualInspection = state is AiResultsLoaded && state.requiresManualInspection;

    return _DetectionResultView(
      detection: detection,
      boxId: boxId,
      requiresManualInspection: requiresManualInspection,
      isFeedbackLoading: state is FeedbackSubmitting,
    );
  }

  AIDetection? _extractDetection(AiResultsState state) {
    if (state is AiResultsLoaded) return state.detection;
    if (state is FeedbackSubmitting) return state.detection;
    if (state is FeedbackSubmitted) return state.detection;
    if (state is FeedbackError) return state.detection;
    return null;
  }
}

// ---------------------------------------------------------------------------
// Detection result view
// ---------------------------------------------------------------------------

class _DetectionResultView extends StatelessWidget {
  const _DetectionResultView({
    required this.detection,
    required this.boxId,
    required this.requiresManualInspection,
    required this.isFeedbackLoading,
  });

  final AIDetection detection;
  final String boxId;
  final bool requiresManualInspection;
  final bool isFeedbackLoading;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Low-confidence banner ? Requirement 6.7
        if (requiresManualInspection) _LowConfidenceBanner(boxId: boxId),
        if (requiresManualInspection) const SizedBox(height: 16),

        // Confidence score card ? Requirement 6.3
        _ConfidenceScoreCard(detection: detection),
        const SizedBox(height: 12),

        // Molting status card ? Requirement 6.2
        _MoltingStatusCard(moltingStatus: detection.moltingStatus),
        const SizedBox(height: 12),

        // Health indicators card ? Requirement 6.4
        _HealthIndicatorCard(healthStatus: detection.healthStatus),
        const SizedBox(height: 12),

        // Detected crabs overlay ? Requirement 6.6
        if (detection.detectedCrabs.isNotEmpty) ...[
          _DetectedCrabsCard(detectedCrabs: detection.detectedCrabs),
          const SizedBox(height: 12),
        ],

        // Recommendations ? Requirement 6.5
        _RecommendationsCard(recommendations: detection.recommendations),
        const SizedBox(height: 16),

        // Feedback buttons ? Requirement 6.9
        _FeedbackSection(detection: detection, isLoading: isFeedbackLoading),
        const SizedBox(height: 8),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Low-confidence banner ? Requirement 6.7
// ---------------------------------------------------------------------------

class _LowConfidenceBanner extends StatelessWidget {
  const _LowConfidenceBanner({required this.boxId});

  final String boxId;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kHomeOrange.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kHomeOrange.withValues(alpha: 0.5)),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: kHomeOrange, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '?? tin c?y th?p ? C?n ki?m tra th? công',
                style: TextStyle(
                  color: kHomeOrange,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '?? tin c?y AI d??i 70%. Vui lòng xác minh '
                'b?ng ki?m tra th? công.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.go(RoutePaths.boxInspect(boxId)),
                icon: const Icon(Icons.search_rounded, size: 16),
                label: const Text('B?t ??u ki?m tra th? công'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kHomeOrange,
                  side: const BorderSide(color: kHomeOrange),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Confidence score card ? Requirement 6.3
// ---------------------------------------------------------------------------

class _ConfidenceScoreCard extends StatelessWidget {
  const _ConfidenceScoreCard({required this.detection});

  final AIDetection detection;

  Color get _confidenceColor {
    final pct = detection.confidencePercent;
    if (pct >= 85) return kHomeGreen;
    if (pct >= 70) return kHomeOrange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) => _GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Circular progress indicator
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: detection.confidenceScore,
                  backgroundColor: kHomeBorderBlue.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(_confidenceColor),
                  strokeWidth: 6,
                ),
                Text(
                  '${detection.confidencePercent}%',
                  style: TextStyle(
                    color: _confidenceColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '?i?m tin c?y AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_confidenceLabel, style: TextStyle(color: _confidenceColor, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  'Phân tích ${_formatTime(detection.analyzedAt)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  String get _confidenceLabel {
    final pct = detection.confidencePercent;
    if (pct >= 85) return 'Tin c?y cao';
    if (pct >= 70) return 'Tin c?y trung bình';
    return 'Tin c?y th?p ? c?n xác minh th? công';
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'v?a xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút tr??c';
    return '${diff.inHours} gi? tr??c';
  }
}

// ---------------------------------------------------------------------------
// Molting status card ? Requirement 6.2
// ---------------------------------------------------------------------------

class _MoltingStatusCard extends StatelessWidget {
  const _MoltingStatusCard({required this.moltingStatus});

  final MoltingStatus moltingStatus;

  Color get _statusColor {
    switch (moltingStatus) {
      case MoltingStatus.preMolt:
        return const Color(0xFFFFD54F); // amber/yellow
      case MoltingStatus.molting:
        return kHomeOrange; // orange
      case MoltingStatus.postMolt:
        return kHomeGreen; // green
      case MoltingStatus.hardShell:
        return kHomeCyan; // cyan/blue
    }
  }

  IconData get _statusIcon {
    switch (moltingStatus) {
      case MoltingStatus.preMolt:
        return Icons.timer_rounded;
      case MoltingStatus.molting:
        return Icons.autorenew_rounded;
      case MoltingStatus.postMolt:
        return Icons.check_circle_outline_rounded;
      case MoltingStatus.hardShell:
        return Icons.shield_rounded;
    }
  }

  @override
  Widget build(BuildContext context) => _GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_statusIcon, color: _statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tr?ng thái l?t xác',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  moltingStatus.displayName,
                  style: TextStyle(color: _statusColor, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (moltingStatus.isVulnerable)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Cua ?ang ? giai ?o?n d? t?n th??ng',
                      style: TextStyle(color: kHomeOrange, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          // Status badge chip
          Chip(
            label: Text(moltingStatus.displayName),
            backgroundColor: _statusColor.withValues(alpha: 0.15),
            side: BorderSide(color: _statusColor.withValues(alpha: 0.4)),
            labelStyle: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w600),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Health indicator card ? Requirement 6.4
// ---------------------------------------------------------------------------

class _HealthIndicatorCard extends StatelessWidget {
  const _HealthIndicatorCard({required this.healthStatus});

  final HealthStatus healthStatus;

  Color get _healthColor {
    switch (healthStatus) {
      case HealthStatus.normal:
        return kHomeGreen;
      case HealthStatus.disease:
        return Colors.redAccent;
      case HealthStatus.stress:
        return kHomeOrange;
      case HealthStatus.unknown:
        return Colors.white70;
    }
  }

  IconData get _healthIcon {
    switch (healthStatus) {
      case HealthStatus.normal:
        return Icons.check_circle_rounded;
      case HealthStatus.disease:
        return Icons.warning_rounded;
      case HealthStatus.stress:
        return Icons.error_outline_rounded;
      case HealthStatus.unknown:
        return Icons.help_outline_rounded;
    }
  }

  String get _healthLabel {
    switch (healthStatus) {
      case HealthStatus.normal:
        return 'Các ch? s? bình th??ng';
      case HealthStatus.disease:
        return 'Phát hi?n d?u hi?u b?nh ? x? lý s?m';
      case HealthStatus.stress:
        return 'Có d?u hi?u stress ? ki?m tra ?i?u ki?n';
      case HealthStatus.unknown:
        return 'Không xác ??nh ???c tình tr?ng s?c kh?e';
    }
  }

  @override
  Widget build(BuildContext context) => _GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _healthColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_healthIcon, color: _healthColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tình tr?ng s?c kh?e',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  healthStatus.displayName,
                  style: TextStyle(color: _healthColor, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  _healthLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Detected crabs overlay card ? Requirement 6.6
// ---------------------------------------------------------------------------

class _DetectedCrabsCard extends StatelessWidget {
  const _DetectedCrabsCard({required this.detectedCrabs});

  final List<DetectionBox> detectedCrabs;

  @override
  Widget build(BuildContext context) => _GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.camera_enhance_rounded, color: kHomeCyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'Cua phát hi?n (${detectedCrabs.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Frame placeholder with bounding box overlays
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: kHomeNavyLift,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kHomeBorderBlue),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Background placeholder (replaced by actual frame image)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_rounded,
                          size: 40,
                          color: Colors.white70.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Xem tr??c khung hình',
                          style: TextStyle(
                            color: Colors.white70.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bounding box overlays using normalised coordinates
                  ...detectedCrabs.map((box) => _BoundingBoxOverlay(detectionBox: box)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Per-detection confidence list
          ...detectedCrabs.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: kHomeCyan,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Crab ${entry.key + 1}: ${entry.value.label}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    '${(entry.value.confidence * 100).round()}%',
                    style: const TextStyle(
                      color: kHomeCyan,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Renders a semi-transparent bounding box overlay using normalised
/// coordinates [0.0, 1.0] relative to the container dimensions.
///
/// Requirement 6.6
class _BoundingBoxOverlay extends StatelessWidget {
  const _BoundingBoxOverlay({required this.detectionBox});

  final DetectionBox detectionBox;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return Positioned(
        left: detectionBox.x * w,
        top: detectionBox.y * h,
        width: detectionBox.width * w,
        height: detectionBox.height * h,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: kHomeCyan, width: 2),
            color: kHomeCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              color: kHomeCyan,
              child: Text(
                detectionBox.label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Recommendations card ? Requirement 6.5
// ---------------------------------------------------------------------------

class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({required this.recommendations});

  final List<AIRecommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: kHomeCyan, size: 20),
                SizedBox(width: 8),
                Text(
                  'Khuy?n ngh?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RecommendationTile(recommendation: rec),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({required this.recommendation});

  final AIRecommendation recommendation;

  Color get _tileColor {
    switch (recommendation) {
      case AIRecommendation.continueMonitoring:
        return kHomeBlueLight;
      case AIRecommendation.harvestReady:
        return kHomeGreen;
      case AIRecommendation.treatDisease:
        return Colors.redAccent;
      case AIRecommendation.manualInspectionRequired:
        return kHomeOrange;
    }
  }

  IconData get _tileIcon {
    switch (recommendation) {
      case AIRecommendation.continueMonitoring:
        return Icons.monitor_heart_outlined;
      case AIRecommendation.harvestReady:
        return Icons.agriculture_rounded;
      case AIRecommendation.treatDisease:
        return Icons.healing_rounded;
      case AIRecommendation.manualInspectionRequired:
        return Icons.search_rounded;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: _tileColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _tileColor.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Icon(_tileIcon, color: _tileColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            recommendation.displayName,
            style: TextStyle(color: _tileColor, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Icon(Icons.arrow_forward_ios_rounded, color: _tileColor.withValues(alpha: 0.6), size: 14),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Feedback section ? Requirement 6.9
// ---------------------------------------------------------------------------

class _FeedbackSection extends StatelessWidget {
  const _FeedbackSection({required this.detection, required this.isLoading});

  final AIDetection detection;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    // If feedback was already given, show the submitted state
    if (detection.hasFeedback) {
      final isCorrect = detection.feedbackStatus == DetectionFeedbackStatus.correct;
      return _GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCorrect ? kHomeGreen : Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect
                    ? 'B?n ?ánh d?u k?t qu? là ?úng'
                    : 'B?n ?ánh d?u k?t qu? là Sai',
                style: TextStyle(
                  color: isCorrect ? kHomeGreen : Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'K?t qu? này có chính xác không?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ph?n h?i c?a b?n giúp c?i thi?n ?? chính xác AI',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FeedbackButton(
                    label: '?úng',
                    icon: Icons.thumb_up_alt_rounded,
                    color: kHomeGreen,
                    isLoading: isLoading,
                    onTap: () => context.read<AiResultsBloc>().add(
                      SubmitFeedback(detectionId: detection.id, isCorrect: true),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FeedbackButton(
                    label: 'Sai',
                    icon: Icons.thumb_down_alt_rounded,
                    color: Colors.redAccent,
                    isLoading: isLoading,
                    onTap: () => context.read<AiResultsBloc>().add(
                      SubmitFeedback(detectionId: detection.id, isCorrect: false),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: isLoading ? null : onTap,
    icon: isLoading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        : Icon(icon, size: 18),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      padding: const EdgeInsets.symmetric(vertical: 12),
    ),
  );
}

// ---------------------------------------------------------------------------
// Loading / Polling / Error views
// ---------------------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: kHomeCyan),
        SizedBox(height: 16),
        Text('?ang t?i k?t qu? AI?', style: TextStyle(color: Colors.white70)),
      ],
    ),
  );
}

class _PollingView extends StatelessWidget {
  const _PollingView({required this.attemptCount});

  final int attemptCount;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: kHomeCyan),
          const SizedBox(height: 24),
          const Text(
            '?ang phân tích AI?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Có th? m?t t?i 60 giây.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '?ang ki?m tra? (l?n $attemptCount)',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 56),
          const SizedBox(height: 16),
          const Text(
            'Không t?i ???c k?t qu? AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Th? l?i'),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Shared glassmorphism card ? matches CrabSense design system
// ---------------------------------------------------------------------------

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: homeCardDecoration(radius: 16, glowAlpha: 0.12),
    child: child,
  );
}
