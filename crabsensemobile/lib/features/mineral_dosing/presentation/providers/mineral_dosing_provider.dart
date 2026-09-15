import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../data/mineral_dosing_repository.dart';
import '../../data/models/mineral_dose_models.dart';

final mineralDosingRepositoryProvider = Provider<MineralDosingRepository>(
  (ref) => MineralDosingRepositoryImpl(api: sl<ApiClient>()),
);

/// State của màn tính liều khoáng.
///
/// State form (các ô nhập) do widget giữ; provider chỉ giữ kết quả API để
/// không phải đồng bộ hai chiều giữa controller và state.
class MineralDosingState {
  const MineralDosingState({
    this.recommendation,
    this.result,
    this.isCalculating = false,
    this.isLoadingRecommendation = false,
    this.error,
  });

  /// Mục tiêu ĐỀ XUẤT theo độ mặn — hiển thị trước khi người dùng bấm tính.
  final MineralTargetRecommendation? recommendation;

  /// Kết quả tính liều gần nhất.
  final MineralDoseResult? result;

  final bool isCalculating;
  final bool isLoadingRecommendation;
  final String? error;

  MineralDosingState copyWith({
    MineralTargetRecommendation? recommendation,
    MineralDoseResult? result,
    bool? isCalculating,
    bool? isLoadingRecommendation,
    String? error,
    bool clearRecommendation = false,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return MineralDosingState(
      recommendation:
          clearRecommendation ? null : (recommendation ?? this.recommendation),
      result: clearResult ? null : (result ?? this.result),
      isCalculating: isCalculating ?? this.isCalculating,
      isLoadingRecommendation:
          isLoadingRecommendation ?? this.isLoadingRecommendation,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MineralDosingNotifier extends StateNotifier<MineralDosingState> {
  MineralDosingNotifier(this._repo) : super(const MineralDosingState());

  final MineralDosingRepository _repo;
  Timer? _debounce;

  /// Gọi đề xuất mục tiêu có debounce — dùng khi người dùng đang gõ độ mặn,
  /// tránh bắn một request cho mỗi ký tự.
  void scheduleRecommendation(double? salinityPpt) {
    _debounce?.cancel();

    if (salinityPpt == null || salinityPpt < 0) {
      state = state.copyWith(clearRecommendation: true);
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => loadRecommendation(salinityPpt),
    );
  }

  Future<void> loadRecommendation(double salinityPpt) async {
    state = state.copyWith(isLoadingRecommendation: true, clearError: true);
    try {
      final rec = await _repo.recommendTargets(salinityPpt);
      state = state.copyWith(
        recommendation: rec,
        isLoadingRecommendation: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingRecommendation: false,
        error: e.toString(),
      );
    }
  }

  Future<void> calculate(MineralDoseRequest request) async {
    state = state.copyWith(
      isCalculating: true,
      clearError: true,
      clearResult: true,
    );
    try {
      final result = await _repo.calculate(request);
      state = state.copyWith(
        result: result,
        isCalculating: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isCalculating: false,
        error: e.toString(),
      );
    }
  }

  /// Xoá kết quả cũ khi người dùng đổi cách chọn mục tiêu — kết quả cũ
  /// sẽ hiển thị badge "ĐỀ XUẤT"/"BẠN NHẬP" sai với chế độ mới.
  void clearResult() {
    state = state.copyWith(clearResult: true, clearError: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final mineralDosingProvider =
    StateNotifierProvider.autoDispose<MineralDosingNotifier, MineralDosingState>(
  (ref) => MineralDosingNotifier(ref.watch(mineralDosingRepositoryProvider)),
);
