import '../models/sensor_kit.dart';

abstract final class MockSensorKitData {
  static const current = CurrentSensorKit(
    planName: 'Starter Kit',
    activeSensors: 12,
    maxSensors: 16,
    firmwareVersion: 'v2.4.1',
    lastSync: '24/05/2026 08:15',
  );

  static List<SensorKitPlan> plans() => const [
        SensorKitPlan(
          id: 'basic',
          name: 'Gói Cơ bản',
          priceLabel: 'Miễn phí (đã kích hoạt)',
          description: 'Phù hợp trại nhỏ, giám sát thủ công + cảnh báo cơ bản.',
          sensorCount: 16,
          includesAi: false,
          recommended: false,
          features: [
            'pH, Nhiệt độ, DO (tối đa 16 điểm)',
            'Cảnh báo email',
            'Lưu lịch sử 7 ngày',
            'Dashboard tổng quan',
          ],
        ),
        SensorKitPlan(
          id: 'pro',
          name: 'Gói Pro',
          priceLabel: '4.500.000đ / năm',
          description: 'Tự động hóa IoT + AI Insight cho trại vừa.',
          sensorCount: 48,
          includesAi: true,
          recommended: true,
          features: [
            '48 cảm biến: pH, DO, ORP, NH3, nhiệt độ, độ mặn',
            'Crab Assistant — AI Insight realtime',
            'Điều khiển máy sủi, bơm, cho ăn',
            'Lưu lịch sử 365 ngày + xuất báo cáo',
            'Camera AI (2 luồng)',
          ],
        ),
        SensorKitPlan(
          id: 'enterprise',
          name: 'Gói Enterprise',
          priceLabel: 'Liên hệ',
          description: 'Giải pháp toàn trại, đa chi nhánh, SLA 24/7.',
          sensorCount: 200,
          includesAi: true,
          recommended: false,
          features: [
            'Không giới hạn cảm biến (theo hợp đồng)',
            'AI dự báo bệnh & tăng trưởng',
            'Tích hợp ERP / bán hàng',
            'Kỹ thuật viên onsite',
            'API mở & backup cloud',
          ],
        ),
      ];

  static const compareRows = [
    ['Số cảm biến', '16', '48', '200+'],
    ['AI Assistant', '—', '✓', '✓'],
    ['Camera AI', '—', '2 cam', 'Không giới hạn'],
    ['IoT điều khiển', 'Cơ bản', 'Đầy đủ', 'Đầy đủ + tùy biến'],
    ['Lịch sử dữ liệu', '7 ngày', '365 ngày', 'Không giới hạn'],
  ];
}
