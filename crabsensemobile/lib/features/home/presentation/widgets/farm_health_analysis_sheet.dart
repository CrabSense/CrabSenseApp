import 'package:flutter/material.dart';
import '../../domain/models/home_models.dart';
void showFarmHealthAnalysisSheet(BuildContext context, {
  required FarmHealthScore healthScore, String? farmName,
}) {
  showModalBottomSheet<void>(context: context, builder: (ctx) => const SafeArea(
    child: Padding(padding: EdgeInsets.all(24), child: Text(
      'Chưa có hồ sơ đánh giá sức khỏe xác minh. Không thể kết luận chất lượng nước hoặc tình trạng cua từ điểm legacy.')),
  ));
}
