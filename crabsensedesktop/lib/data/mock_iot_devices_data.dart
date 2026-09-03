import '../models/iot_device.dart';

abstract final class MockIotDevicesData {
  static const kpi = IotDeviceKpi(
    online: 8,
    offline: 1,
    running: 5,
    error: 1,
  );

  static const overview = IotDeviceOverview(
    total: 8,
    online: 7,
    offline: 1,
    running: 5,
    stopped: 2,
    error: 1,
    energyTodayKwh: 42.8,
  );

  static const categoryFilters = [
    'Tất cả',
    'Máy bơm',
    'Drum Filter',
    'Skimmer',
    'Oxy',
    'UV',
    'Fan',
    'Feeder',
    'Valve',
  ];

  static String aiInsight =
      'Pump-01 hoạt động ổn định. DO hiện tại đạt 6.4 mg/L. '
      'Không phát hiện lỗi nghiêm trọng trên thiết bị đang online.';

  static const aiRecommendation = 'Tiếp tục vận hành chế độ AUTO.';

  static const coreCpuPercent = 24;
  static const zigbeeSignalPercent = 92;

  static IotDeviceDetailMeta _meta(String code) => IotDeviceDetailMeta(
        deviceCode: code,
        firmware: '1.2.5',
        ip: '192.168.1.${100 + code.hashCode % 50}',
        mqttStatus: 'Connected',
        lastSeen: '3 giây trước',
      );

  static List<IotDevice> devices() => [
        IotDevice(
          id: 'pump-01',
          name: 'Pump-01',
          type: IotDeviceType.pump,
          typeLabel: 'Máy bơm nước',
          location: 'Khu A - RAS-01',
          connection: IotConnectionStatus.online,
          runStatus: IotRunStatus.running,
          mode: IotControlMode.auto,
          isOn: true,
          powerWatts: 450,
          runCount: 1240,
          scheduleInfo: '06:00 - 22:00',
          lastRunTime: '10:05',
          flowRate: '1500 L/h',
          meta: _meta('DEV-PUMP-001'),
        ),
        IotDevice(
          id: 'drum-01',
          name: 'Drum Filter-01',
          type: IotDeviceType.drumFilter,
          typeLabel: 'Drum Filter',
          location: 'Khu A - Lọc',
          connection: IotConnectionStatus.online,
          runStatus: IotRunStatus.running,
          mode: IotControlMode.auto,
          isOn: true,
          powerWatts: 250,
          runCount: 125,
          scheduleInfo: 'Chu kỳ rửa 30 phút',
          lastWashTime: '09:30',
          cycleMinutes: 30,
          totalWashes: 125,
          showFixNow: true,
          hasNoError: true,
          meta: _meta('DEV-DRUM-001'),
        ),
        IotDevice(
          id: 'skimmer-01',
          name: 'Skimmer-01',
          type: IotDeviceType.skimmer,
          typeLabel: 'Protein Skimmer',
          location: 'Khu A',
          connection: IotConnectionStatus.online,
          runStatus: IotRunStatus.running,
          mode: IotControlMode.auto,
          isOn: true,
          powerWatts: 120,
          runCount: 890,
          scheduleInfo: '24/7 — AUTO',
          skimmerEfficiency: 87,
          flowRate: '600 L/h',
          meta: _meta('DEV-SKIM-001'),
        ),
        IotDevice(
          id: 'oxy-01',
          name: 'AirPump-01',
          type: IotDeviceType.airPump,
          typeLabel: 'Sủi oxy',
          location: 'Khu A',
          connection: IotConnectionStatus.online,
          runStatus: IotRunStatus.running,
          mode: IotControlMode.auto,
          isOn: true,
          powerWatts: 75,
          runCount: 2100,
          scheduleInfo: 'Theo cảm biến DO',
          doCurrent: 6.4,
          doTarget: 6.0,
          meta: _meta('DEV-OXY-001'),
        ),
        IotDevice(
          id: 'uv-01',
          name: 'UV-01',
          type: IotDeviceType.uv,
          typeLabel: 'Đèn UV',
          location: 'Khu A',
          connection: IotConnectionStatus.online,
          runStatus: IotRunStatus.error,
          mode: IotControlMode.auto,
          isOn: false,
          powerWatts: 40,
          runCount: 520,
          scheduleInfo: '20:00 ON — 06:00 OFF',
          errorMessage: 'Bóng đèn hỏng',
          hasNoError: false,
          uvHoursPerDay: 8,
          uvLifespanHours: 4200,
          meta: _meta('DEV-UV-001'),
        ),
        IotDevice(
          id: 'fan-01',
          name: 'Fan-01',
          type: IotDeviceType.fan,
          typeLabel: 'Quạt thông gió',
          location: 'Khu A',
          connection: IotConnectionStatus.online,
          runStatus: IotRunStatus.running,
          mode: IotControlMode.auto,
          isOn: true,
          powerWatts: 80,
          runCount: 680,
          scheduleInfo: 'T > 30°C → Bật quạt',
          fanSpeedPercent: 65,
          envTemp: 29,
          fanThreshold: 30,
          meta: _meta('DEV-FAN-001'),
        ),
        IotDevice(
          id: 'feeder-01',
          name: 'Feeder-01',
          type: IotDeviceType.feeder,
          typeLabel: 'Máy cho ăn',
          location: 'Khu A',
          connection: IotConnectionStatus.online,
          runStatus: IotRunStatus.stopped,
          mode: IotControlMode.auto,
          isOn: false,
          powerWatts: 25,
          runCount: 156,
          scheduleInfo: '08:00 · 13:00 · 18:00',
          feedPortionG: 120,
          feedsToday: 3,
          feedSchedule: ['08:00', '13:00', '18:00'],
          showTestButton: true,
          meta: _meta('DEV-FEED-001'),
        ),
        IotDevice(
          id: 'valve-08',
          name: 'Valve-08',
          type: IotDeviceType.valve,
          typeLabel: 'Van điện từ',
          location: 'Khu B - Cấp nước',
          connection: IotConnectionStatus.offline,
          runStatus: IotRunStatus.error,
          mode: IotControlMode.auto,
          isOn: false,
          powerWatts: 0,
          runCount: 560,
          scheduleInfo: 'Mực nước thấp → Mở van',
          errorMessage: 'ERR — Không phản hồi',
          hasNoError: false,
          valveOpenPercent: 0,
          valveCycleCount: 560,
          meta: IotDeviceDetailMeta(
            deviceCode: 'DEV-VALVE-008',
            firmware: '1.1.0',
            ip: '192.168.1.108',
            mqttStatus: 'Disconnected',
            lastSeen: '5 phút trước',
          ),
        ),
      ];

  static List<IotActivityLog> activityLogs() => const [
        IotActivityLog(
          time: '08:00:12',
          deviceName: 'Máy cho ăn',
          action: 'Cho ăn 50g',
          success: true,
        ),
        IotActivityLog(
          time: '07:45:00',
          deviceName: 'Sủi oxy',
          action: 'Auto-off (DO cao)',
          success: true,
        ),
        IotActivityLog(
          time: '07:30:22',
          deviceName: 'Drum Filter-01',
          action: 'Xả rửa định kỳ',
          success: true,
        ),
        IotActivityLog(
          time: '07:15:00',
          deviceName: 'Pump-01',
          action: 'Kích hoạt ON',
          success: true,
        ),
        IotActivityLog(
          time: '06:50:11',
          deviceName: 'Valve-08',
          action: 'Mất kết nối MQTT',
          success: false,
        ),
      ];

  static List<IotAutomationRule> automationRules() => [
        IotAutomationRule(
          id: 'oxy-guard',
          title: 'Bảo vệ oxy',
          description: 'DO < 5 mg/L → Bật sủi oxy',
          enabled: true,
        ),
        IotAutomationRule(
          id: 'temp-monitor',
          title: 'Kiểm soát nhiệt độ',
          description: 'Nhiệt độ > 30°C → Bật quạt',
          enabled: true,
        ),
        IotAutomationRule(
          id: 'feeding-time',
          title: 'Lịch cho ăn',
          description: 'Đến giờ ăn → Kích hoạt máy cho ăn',
          enabled: true,
        ),
        IotAutomationRule(
          id: 'nh3-pump',
          title: 'NH3 Guard',
          description: 'NH3 > 0.1 ppm → Tăng lưu lượng bơm',
          enabled: true,
        ),
        IotAutomationRule(
          id: 'water-level',
          title: 'Mực nước thấp',
          description: 'Mực nước thấp → Mở van cấp nước',
          enabled: false,
        ),
      ];

  static const deviceStats = IotDeviceStats(
    totalRuntimeHours: 356,
    totalEnergyKwh: 128,
    powerOnCount: 285,
    errorCount: 2,
    efficiencyPercent: 96,
  );

  static List<IotScheduleEntry> defaultSchedule() => const [
        IotScheduleEntry(time: '08:00', action: 'ON'),
        IotScheduleEntry(time: '09:00', action: 'OFF'),
        IotScheduleEntry(time: '10:00', action: 'ON'),
        IotScheduleEntry(time: '11:30', action: 'OFF'),
        IotScheduleEntry(time: '12:00', action: 'ON'),
      ];

  static List<IotCalendarBlock> calendarBlocks() => const [
        IotCalendarBlock(range: '06:00 - 08:00', label: 'Pump ON'),
        IotCalendarBlock(range: '12:00 - 14:00', label: 'Pump ON'),
        IotCalendarBlock(range: '18:00 - 22:00', label: 'Pump ON'),
      ];

  static List<IotDeviceAlert> systemAlerts() => const [
        IotDeviceAlert(
          deviceName: 'Pump-01',
          message: 'Pump-01 Offline',
          severity: IotRunStatus.error,
        ),
        IotDeviceAlert(
          deviceName: 'Drum Filter',
          message: 'Drum Filter bị kẹt',
          severity: IotRunStatus.warning,
        ),
        IotDeviceAlert(
          deviceName: 'UV-01',
          message: 'UV sắp hết tuổi thọ',
          severity: IotRunStatus.warning,
        ),
        IotDeviceAlert(
          deviceName: 'Feeder-01',
          message: 'Máy cho ăn không phản hồi',
          severity: IotRunStatus.error,
        ),
        IotDeviceAlert(
          deviceName: 'Valve-08',
          message: 'Van điện từ mở bất thường',
          severity: IotRunStatus.warning,
        ),
      ];
}
