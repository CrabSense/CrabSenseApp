import 'package:flutter/material.dart';

import '../models/ai_assistant.dart';
import '../models/auth_models.dart';
import 'cloud_api_client.dart';

class AiAssistantService extends ChangeNotifier {
  AiAssistantService({required AuthSession session, CloudApiClient? api})
      : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  final List<AiChatMessage> _messages = [];
  List<AiRecommendation> _recommendations = [];
  String _search = '';
  bool loading = false;
  String? error;

  List<AiChatMessage> get messages => List.unmodifiable(_messages);
  String get overviewSummary => _recommendations.isEmpty
      ? 'Chưa có khuyến nghị AI từ CrabSenseBE cho khu này.'
      : 'Có ${_recommendations.length} khuyến nghị từ /api/ai/recommendations.';
  List<AiInsightCard> get overviewKpi => [
        AiInsightCard(
          title: 'Khuyến nghị',
          value: '${_recommendations.length}',
          trend: '',
          trendUp: _recommendations.isNotEmpty,
        ),
      ];
  List<String> get quickPrompts => const [
        'Tình trạng khu nuôi hôm nay?',
        'Cảnh báo nào đang mở?',
        'Nên thu hoạch hộp nào?',
      ];
  List<AiRecommendation> get recommendations =>
      List.unmodifiable(_recommendations);
  List<AiAlertInsight> get aiAlerts => const [];

  List<AiRecommendation> get filteredRecommendations {
    if (_search.trim().isEmpty) return recommendations;
    final q = _search.toLowerCase();
    return recommendations
        .where(
          (r) =>
              r.title.toLowerCase().contains(q) ||
              r.module.toLowerCase().contains(q),
        )
        .toList();
  }

  void updateSession(AuthSession session) {
    _session = session;
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final raw = await _api.fetchAiRecommendations(
        _session.token,
        farmingAreaId: _session.selectedFarm.id,
      );
      _recommendations = raw.map(_fromApi).toList();
      error = null;
    } on CloudApiException catch (e) {
      error = e.message;
      _recommendations = [];
    } catch (e) {
      error = '$e';
      _recommendations = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  void sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _messages.add(
      AiChatMessage(
        id: 'u-${now.millisecondsSinceEpoch}',
        isUser: true,
        text: trimmed,
        time: time,
      ),
    );
    final match = _recommendations.where(
      (r) =>
          r.title.toLowerCase().contains(trimmed.toLowerCase()) ||
          r.detail.toLowerCase().contains(trimmed.toLowerCase()),
    );
    _messages.add(
      AiChatMessage(
        id: 'a-${now.millisecondsSinceEpoch}',
        isUser: false,
        text: match.isNotEmpty
            ? match.first.detail
            : 'CrabSenseBE không có chat AI. Xem khuyến nghị từ /api/ai/recommendations.',
        time: time,
      ),
    );
    notifyListeners();
  }

  void applyRecommendation(String id) {
    notifyListeners();
  }

  void dismissAlert(String id) {
    notifyListeners();
  }

  AiRecommendation _fromApi(Map<String, dynamic> json) {
    final priority = (json['priority'] ?? json['Priority'] ?? '').toString();
    return AiRecommendation(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      detail: (json['description'] ??
              json['Description'] ??
              json['reason'] ??
              json['Reason'] ??
              '')
          .toString(),
      module: (json['type'] ?? json['Type'] ?? 'AI').toString(),
      priority: switch (priority.toLowerCase()) {
        'high' || 'urgent' || 'critical' => AiInsightPriority.high,
        'low' => AiInsightPriority.low,
        _ => AiInsightPriority.medium,
      },
      icon: Icons.auto_awesome_outlined,
    );
  }
}
