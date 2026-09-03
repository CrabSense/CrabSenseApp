import 'package:flutter/material.dart';

import '../models/ai_assistant.dart';

abstract final class MockAiAssistantData {
  static const overviewSummary =
      'Trang trại vận hành ổn định. 3 khu nuôi trong ngưỡng an toàn. '
      'Có 2 khuyến nghị cần xử lý trong 24h.';

  static List<AiInsightCard> overviewKpi() => const [
        AiInsightCard(
          title: 'Health Score TB',
          value: '88/100',
          trend: '+2 điểm',
          trendUp: true,
        ),
        AiInsightCard(
          title: 'Cảnh báo AI',
          value: '4',
          trend: '-1 so với hôm qua',
          trendUp: true,
        ),
        AiInsightCard(
          title: 'FCR trung bình',
          value: '1.85',
          trend: 'Mục tiêu < 2.0',
          trendUp: true,
        ),
        AiInsightCard(
          title: 'Hiệu suất thiết bị',
          value: '94%',
          trend: 'Uptime cao',
          trendUp: true,
        ),
      ];

  static List<AiChatMessage> initialChat() => [
        AiChatMessage(
          id: 'm0',
          isUser: false,
          text:
              'Xin chào! Tôi là Crab Assistant. Hỏi tôi về sức khỏe cua, '
              'môi trường nước, thức ăn hoặc thiết bị IoT.',
          time: '08:00',
        ),
      ];

  static const quickPrompts = [
    'Tình trạng Khu B hôm nay?',
    'Lứa nào cần giảm khẩu phần?',
    'Dự báo thu hoạch tuần này',
    'Thiết bị nào tiêu thụ điện nhiều?',
  ];

  static String replyFor(String prompt) {
    final q = prompt.toLowerCase();
    if (q.contains('khu b')) {
      return 'Khu B: DO 5.2 mg/L (ổn), pH 7.8. Health Score TB 86. '
          'Khuyến nghị kiểm tra cảm biến DO lúc 14h — dao động nhẹ 3 ngày qua.';
    }
    if (q.contains('khẩu phần') || q.contains('thức ăn')) {
      return 'CFM-2026-002: FCR 1.98, thức ăn thừa tăng. '
          'Nên giảm khẩu phần buổi trưa ~5% trong 3 ngày.';
    }
    if (q.contains('thu hoạch')) {
      return 'CFM-2026-001 đạt 95% sống, XL chiếm 58%. '
          'Thu hoạch tối ưu trong 5 ngày tới để đạt giá XXL cao nhất.';
    }
    if (q.contains('điện') || q.contains('thiết bị')) {
      return 'Máy sủi oxy Khu B tiêu thụ +15% (22h–04h). '
          'Cân nhắc tối ưu lịch chạy sau khi kiểm tra DO.';
    }
    return 'Tôi đã ghi nhận câu hỏi. Dữ liệu demo: tỷ lệ sống 96.8%, '
        '2 cảnh báo môi trường chưa xử lý. Bạn muốn xem chi tiết module nào?';
  }

  static List<AiRecommendation> recommendations() => const [
        AiRecommendation(
          id: 'r1',
          title: 'Kiểm tra cảm biến DO khu B',
          detail: 'DO dao động 4.8–5.4 mg/L trong 72h. Calibrate hoặc thay pin.',
          module: 'Môi trường',
          priority: AiInsightPriority.high,
          icon: Icons.water_outlined,
        ),
        AiRecommendation(
          id: 'r2',
          title: 'Giảm khẩu phần CFM-2026-002',
          detail: 'FCR 1.98, thức ăn thừa +12% so với TB. Giảm 5% buổi trưa.',
          module: 'Thức ăn',
          priority: AiInsightPriority.high,
          icon: Icons.restaurant_outlined,
        ),
        AiRecommendation(
          id: 'r3',
          title: 'Tối ưu lịch sủi oxy 22h–04h',
          detail: 'Tiết kiệm ~8% điện năng mà vẫn giữ DO > 5 mg/L.',
          module: 'Thiết bị',
          priority: AiInsightPriority.medium,
          icon: Icons.air_outlined,
        ),
        AiRecommendation(
          id: 'r4',
          title: 'Lên lịch thu hoạch CFM-2026-001',
          detail: 'Tỷ lệ XL/XXL cao, giá thị trường XXL +2%.',
          module: 'Thu hoạch',
          priority: AiInsightPriority.medium,
          icon: Icons.shopping_bag_outlined,
        ),
      ];

  static List<AiAlertInsight> aiAlerts() => const [
        AiAlertInsight(
          id: 'a1',
          area: 'Khu B',
          message: 'DO giảm nhẹ ngoài giờ cao điểm',
          suggestedAction: 'Kiểm tra sủi oxy & cảm biến DO-02',
          priority: AiInsightPriority.high,
        ),
        AiAlertInsight(
          id: 'a2',
          area: 'Khu A',
          message: 'FCR lứa CFM-2026-002 vượt ngưỡng theo dõi',
          suggestedAction: 'Giảm khẩu phần 5%',
          priority: AiInsightPriority.medium,
        ),
        AiAlertInsight(
          id: 'a3',
          area: 'Toàn trại',
          message: 'Điện tiêu thụ +15% so với TB tuần',
          suggestedAction: 'Xem báo cáo thiết bị IoT',
          priority: AiInsightPriority.medium,
        ),
      ];
}
