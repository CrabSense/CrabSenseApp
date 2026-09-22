import '../models/home_models.dart';

abstract class HomeRepository {
  /// Lấy toàn bộ dữ liệu tổng quan cho Farm Command Center.
  /// [farmingAreaId] — khi có thì scope metrics/boxes theo khu đó.
  Future<HomeStateData> getHomeSummary({
    bool forceRefresh = false,
    String? farmingAreaId,
  });

  /// Chuyển khu nuôi — refetch data theo [farmId].
  Future<HomeStateData> switchFarm(String farmId);

  /// Bỏ qua khuyến nghị AI hiện tại
  Future<void> dismissRecommendation(String recommendationId);
}
