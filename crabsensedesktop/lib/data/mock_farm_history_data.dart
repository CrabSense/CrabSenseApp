import '../models/farm_history_event.dart';

class HistoryEventSummary {
  const HistoryEventSummary({
    required this.label,
    required this.count,
    required this.maxCount,
  });

  final String label;
  final int count;
  final int maxCount;

  double get fraction => maxCount == 0 ? 0 : count / maxCount;
}

abstract final class MockFarmHistoryData {
  static const pondId = 'Bể Nuôi A-04';

  static List<FarmHistoryEvent> events() => const [
        FarmHistoryEvent(
          id: 'h1',
          title: 'Cảnh báo Nồng độ Oxy thấp',
          time: '14:45',
          dateGroup: 'HÔM NAY — 24 THÁNG 5',
          location: 'Khu vực: Bể A-04 — Cảm biến S-21',
          description:
              'Nồng độ oxy giảm xuống dưới 4.5 mg/L. Hệ thống sục khí khẩn cấp đã được kích hoạt tự động.',
          type: HistoryEventType.warning,
          priority: HistoryPriority.urgent,
          tags: ['KHẨN CẤP', 'ĐÃ XỬ LÝ'],
        ),
        FarmHistoryEvent(
          id: 'h2',
          title: 'Hoàn tất Chu kỳ Cho ăn',
          time: '12:30',
          dateGroup: 'HÔM NAY — 24 THÁNG 5',
          location: 'Máy cấp liệu tự động F-02',
          description:
              'Đã cấp 15kg thức ăn, đạt 85% hạn mức cho ăn trong ngày.',
          type: HistoryEventType.info,
        ),
        FarmHistoryEvent(
          id: 'h3',
          title: 'Bảo trì Định kỳ Hệ thống Lọc',
          time: '09:15',
          dateGroup: 'HÔM NAY — 24 THÁNG 5',
          location: 'Filter Cluster A',
          description: 'Thay lõi lọc và kiểm tra áp suất máy bơm.',
          type: HistoryEventType.maintenance,
          performer: 'Kỹ thuật viên Nguyễn Văn A',
        ),
        FarmHistoryEvent(
          id: 'h4',
          title: 'Biến động Nhiệt độ Nước',
          time: '22:00',
          dateGroup: 'HÔM QUA — 23 THÁNG 5',
          location: 'Bể A-04 — Cảm biến T-12',
          description:
              'Nhiệt độ tăng từ 27.8°C lên 28.6°C trong 2 giờ. Đã ổn định lại.',
          type: HistoryEventType.environment,
          priority: HistoryPriority.urgent,
          tags: ['THEO DÕI'],
        ),
        FarmHistoryEvent(
          id: 'h5',
          title: 'Đồng bộ dữ liệu cảm biến',
          time: '18:20',
          dateGroup: 'HÔM QUA — 23 THÁNG 5',
          location: 'Toàn khu A',
          description: 'Đồng bộ 124/128 thiết bị thành công.',
          type: HistoryEventType.info,
        ),
      ];

  static List<HistoryEventSummary> eventSummaries() {
    const max = 120;
    return [
      const HistoryEventSummary(label: 'Cảnh báo', count: 12, maxCount: max),
      const HistoryEventSummary(label: 'Bảo trì', count: 45, maxCount: max),
      const HistoryEventSummary(label: 'Cho ăn', count: 120, maxCount: max),
    ];
  }

  static String aiInsight() =>
      'Tần suất cảnh báo Oxy tăng 15% so với tuần trước trong khung 14h–16h. '
      'Nên kiểm tra hệ thống sục khí dự phòng.';

  /// 7 columns x 5 rows heatmap values 0.0 - 1.0
  static List<List<double>> activityHeatmap() => [
        [0.2, 0.4, 0.6, 0.8, 0.5, 0.3, 0.7],
        [0.3, 0.5, 0.9, 1.0, 0.6, 0.4, 0.5],
        [0.1, 0.3, 0.5, 0.7, 0.8, 0.6, 0.4],
        [0.4, 0.6, 0.7, 0.5, 0.3, 0.2, 0.6],
        [0.5, 0.7, 0.4, 0.3, 0.6, 0.8, 0.9],
      ];
}
