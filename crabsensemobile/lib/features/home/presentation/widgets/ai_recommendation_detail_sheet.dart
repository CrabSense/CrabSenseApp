import 'package:flutter/material.dart';
import '../../domain/models/home_models.dart';
void showAiRecommendationDetailSheet(BuildContext context, {
  required AiRecommendation recommendation, required VoidCallback onExecutePressed,
  VoidCallback? onRemindLaterPressed, VoidCallback? onDismissPressed,
}) {
  showModalBottomSheet<void>(context: context, builder: (ctx) => const SafeArea(
    child: Padding(padding: EdgeInsets.all(24),
      child: Text('Chưa có đề xuất AI xác minh.')),
  ));
}
