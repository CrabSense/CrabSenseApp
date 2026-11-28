import 'package:flutter/material.dart';
import '../../domain/models/home_models.dart';
class FarmHealthScoreCard extends StatelessWidget {
  const FarmHealthScoreCard({required this.healthScore, required this.onAnalysisPressed, super.key});
  final FarmHealthScore healthScore;
  final VoidCallback onAnalysisPressed;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    leading: const Icon(Icons.info_outline),
    title: const Text('Đánh giá sức khỏe'),
    subtitle: const Text('Chưa có đánh giá xác minh. Xem riêng phép đo nước và cảnh báo.'),
    trailing: TextButton(onPressed: onAnalysisPressed, child: const Text('Chi tiết')),
  ));
}
