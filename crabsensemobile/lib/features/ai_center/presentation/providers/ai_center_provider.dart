import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../data/ai_center_repository.dart';
import '../../data/models/ai_center_models.dart';

final aiCenterRepositoryProvider = Provider<AiCenterRepository>(
  (ref) => AiCenterRepositoryImpl(api: sl<ApiClient>()),
);

class AiCenterState {
  const AiCenterState({
    this.detections = const [],
    this.recommendations = const [],
    this.tab = AiCenterTab.overview,
    this.isLoading = false,
    this.error,
    this.feedbackMessage,
  });

  final List<AiDetectionItem> detections;
  final List<AiRecommendationItem> recommendations;
  final AiCenterTab tab;
  final bool isLoading;
  final String? error;
  final String? feedbackMessage;

  String get modelVersion {
    if (detections.isNotEmpty && detections.first.modelVersion.isNotEmpty) {
      return detections.first.modelVersion;
    }
    return 'crabsense-ai-v1';
  }

  double get avgConfidence {
    if (detections.isEmpty) return 0;
    final sum = detections.fold<double>(0, (a, d) => a + d.confidencePct);
    return sum / detections.length;
  }

  int get activeRecCount =>
      recommendations.where((r) => r.hasActiveRecommendation).length;

  AiCenterState copyWith({
    List<AiDetectionItem>? detections,
    List<AiRecommendationItem>? recommendations,
    AiCenterTab? tab,
    bool? isLoading,
    String? error,
    String? feedbackMessage,
    bool clearError = false,
    bool clearFeedback = false,
  }) {
    return AiCenterState(
      detections: detections ?? this.detections,
      recommendations: recommendations ?? this.recommendations,
      tab: tab ?? this.tab,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
    );
  }
}

class AiCenterNotifier extends StateNotifier<AiCenterState> {
  AiCenterNotifier(this._repo, {AiCenterTab initialTab = AiCenterTab.overview})
      : super(AiCenterState(tab: initialTab, isLoading: true)) {
    load();
  }

  final AiCenterRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repo.getDetections(),
        _repo.getRecommendations(),
      ]);
      state = state.copyWith(
        detections: results[0] as List<AiDetectionItem>,
        recommendations: results[1] as List<AiRecommendationItem>,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setTab(AiCenterTab tab) {
    state = state.copyWith(tab: tab);
  }

  Future<void> sendFeedback({
    required String detectionId,
    required bool isCorrect,
    String? comment,
  }) async {
    try {
      await _repo.submitFeedback(
        detectionId: detectionId,
        isCorrect: isCorrect,
        comment: comment,
      );
      state = state.copyWith(
        feedbackMessage: isCorrect
            ? 'Đã gửi phản hồi: đúng'
            : 'Đã gửi phản hồi: cần chỉnh',
      );
    } catch (e) {
      state = state.copyWith(feedbackMessage: 'Lỗi gửi phản hồi: $e');
    }
  }
}

final aiCenterStateProvider = StateNotifierProvider.autoDispose
    .family<AiCenterNotifier, AiCenterState, AiCenterTab>((ref, initialTab) {
  return AiCenterNotifier(
    ref.watch(aiCenterRepositoryProvider),
    initialTab: initialTab,
  );
});
