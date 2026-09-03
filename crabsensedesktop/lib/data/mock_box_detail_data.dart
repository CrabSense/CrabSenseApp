import '../models/area_environment_metric.dart';
import '../models/crab_individual.dart';
import '../models/crab_status.dart';

class BoxAlert {
  const BoxAlert({
    required this.severity,
    required this.message,
    required this.time,
  });

  final String severity;
  final String message;
  final String time;
}

abstract final class MockBoxDetailData {
  static CrabIndividual sampleCrab() => CrabIndividual(
        id: 'CRAB-H05-001',
        displayCode: 'CR-2048',
        boxId: 'H05',
        batchId: 'BT-2026-Q2',
        areaName: 'Khu A',
        rowName: 'Dãy 01',
        boxName: 'Hộp 05',
        developmentStage: CrabDevelopmentStage.growing,
        updatedAt: DateTime(2026, 5, 30, 14, 20),
        estimatedValueVnd: 210000,
        meatQualityScore: 85,
        alertCount: 2,
        gender: CrabGender.male,
        weightGram: 138,
        shellSizeCm: 8.6,
        releaseDate: DateTime(2026, 1, 10),
        moltCount: 3,
        lastMoltDate: DateTime(2026, 4, 18),
        healthStatus: CrabHealthStatus.healthy,
        lifeStatus: CrabLifeStatus.raising,
        healthScore: 91,
        quickNote: 'Phát triển tốt, tăng trưởng ổn định sau lần lột xác thứ 3.',
        molts: [
          CrabMoltRecord(
            number: 1,
            date: DateTime(2026, 2, 5),
            condition: MoltCondition.normal,
            note: 'Tăng 10% kích thước',
          ),
          CrabMoltRecord(
            number: 2,
            date: DateTime(2026, 3, 12),
            condition: MoltCondition.normal,
            note: 'Phát triển tốt',
          ),
          CrabMoltRecord(
            number: 3,
            date: DateTime(2026, 4, 18),
            condition: MoltCondition.needsWatch,
            note: 'Mai chưa cứng hoàn toàn — theo dõi 48h',
          ),
        ],
        diseases: [
          CrabDiseaseRecord(
            date: DateTime(2026, 3, 1),
            name: 'Đốm đen nhẹ',
            severity: DiseaseSeverity.mild,
            symptoms: 'Đốm nhỏ trên càng trái',
            treatment: 'Tăng oxy, bổ sung khoáng',
            status: DiseaseRecordStatus.resolved,
          ),
        ],
        feedings: [
          CrabFeedingRecord(
            date: DateTime(2026, 5, 28),
            foodType: 'Cá tạp',
            amountGram: 10,
            note: 'Ăn tốt',
          ),
          CrabFeedingRecord(
            date: DateTime(2026, 5, 29),
            foodType: 'Thức ăn viên',
            amountGram: 8,
            note: 'Bình thường',
          ),
          CrabFeedingRecord(
            date: DateTime(2026, 5, 30),
            foodType: 'Cá tạp',
            amountGram: 11,
            note: 'Ăn mạnh',
          ),
        ],
        weightHistory: [
          CrabWeightPoint(date: DateTime(2026, 1, 10), weightGram: 18),
          CrabWeightPoint(date: DateTime(2026, 2, 5), weightGram: 42),
          CrabWeightPoint(
              date: DateTime(2026, 3, 12), weightGram: 78, shellSizeCm: 6.4),
          CrabWeightPoint(
              date: DateTime(2026, 4, 18), weightGram: 112, shellSizeCm: 7.8),
          CrabWeightPoint(
              date: DateTime(2026, 5, 30), weightGram: 138, shellSizeCm: 8.6),
        ],
        healthLogs: [
          CrabHealthLogEntry(
            recordedAt: DateTime(2026, 4, 1),
            weightGram: 95,
            shellSizeCm: 7.2,
            shellCondition: 'Cứng',
            diseaseNote: 'Không',
          ),
          CrabHealthLogEntry(
            recordedAt: DateTime(2026, 5, 1),
            weightGram: 120,
            shellSizeCm: 8.0,
            shellCondition: 'Cứng',
            diseaseNote: 'Không',
          ),
          CrabHealthLogEntry(
            recordedAt: DateTime(2026, 5, 30),
            weightGram: 138,
            shellSizeCm: 8.6,
            shellCondition: 'Đang cứng',
            diseaseNote: 'Đốm đen đã hết',
          ),
        ],
      );

  static List<BoxEnvironmentMetric> sampleEnvironment() => const [
        BoxEnvironmentMetric(
          label: 'pH',
          value: 7.8,
          unit: '',
          icon: 'pH',
          status: 'good',
        ),
        BoxEnvironmentMetric(
          label: 'Nhiệt độ',
          value: 28.5,
          unit: '°C',
          icon: 'temp',
          status: 'good',
        ),
        BoxEnvironmentMetric(
          label: 'DO',
          value: 5.2,
          unit: 'mg/L',
          icon: 'do',
          status: 'good',
        ),
        BoxEnvironmentMetric(
          label: 'Độ mặn',
          value: 25.0,
          unit: '‰',
          icon: 'sal',
          status: 'good',
        ),
        BoxEnvironmentMetric(
          label: 'NH₃',
          value: 0.02,
          unit: 'mg/L',
          icon: 'nh3',
          status: 'warning',
        ),
        BoxEnvironmentMetric(
          label: 'NO₂',
          value: 0.15,
          unit: 'mg/L',
          icon: 'no2',
          status: 'good',
        ),
      ];

  static List<BoxAlert> sampleAlerts() => const [
        BoxAlert(
          severity: 'warning',
          message: 'NH₃ tăng nhẹ — kiểm tra bộ lọc',
          time: '30/05/2026 14:20',
        ),
        BoxAlert(
          severity: 'info',
          message: 'Cua hoàn tất lột xác lần 3',
          time: '18/04/2026 08:30',
        ),
        BoxAlert(
          severity: 'critical',
          message: 'Nhiệt độ vượt ngưỡng 32°C trong 15 phút',
          time: '15/04/2026 12:05',
        ),
        BoxAlert(
          severity: 'info',
          message: 'Camera AI phát hiện cua di chuyển chậm',
          time: '10/04/2026 22:10',
        ),
        BoxAlert(
          severity: 'warning',
          message: 'DO giảm dưới 4.5 mg/L',
          time: '05/04/2026 06:45',
        ),
      ];
}
