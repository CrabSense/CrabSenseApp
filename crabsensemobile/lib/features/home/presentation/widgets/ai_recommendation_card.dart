import 'package:flutter/material.dart';
import '../../domain/models/home_models.dart';
class AiRecommendationCard extends StatelessWidget {
  const AiRecommendationCard({super.key, required this.recommendation,
    required this.onExecutePressed, required this.onDetailPressed,
    required this.onDismissPressed, required this.onRemindLaterPressed,
    required this.onHistoryPressed});
  final AiRecommendation recommendation;
  final VoidCallback onExecutePressed, onDetailPressed, onDismissPressed,
      onRemindLaterPressed, onHistoryPressed;
  @override
  Widget build(BuildContext context) => const Card(child: ListTile(
    leading: Icon(Icons.info_outline),
    title: Text('Chưa có đánh giá AI xác minh'),
    subtitle: Text('Chưa có đề xuất có nguồn gốc xác minh.'),
  ));
}
