import 'package:flutter/material.dart';

enum AiInsightPriority { high, medium, low }

class AiChatMessage {
  AiChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.time,
  });

  final String id;
  final bool isUser;
  final String text;
  final String time;
}

class AiRecommendation {
  const AiRecommendation({
    required this.id,
    required this.title,
    required this.detail,
    required this.module,
    required this.priority,
    required this.icon,
  });

  final String id;
  final String title;
  final String detail;
  final String module;
  final AiInsightPriority priority;
  final IconData icon;
}

class AiInsightCard {
  const AiInsightCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.trendUp,
  });

  final String title;
  final String value;
  final String trend;
  final bool trendUp;
}

class AiAlertInsight {
  const AiAlertInsight({
    required this.id,
    required this.area,
    required this.message,
    required this.suggestedAction,
    required this.priority,
  });

  final String id;
  final String area;
  final String message;
  final String suggestedAction;
  final AiInsightPriority priority;
}
