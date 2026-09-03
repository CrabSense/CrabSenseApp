import 'package:flutter/material.dart';

import '../models/box_status.dart';
import '../models/crab_box.dart';
import '../models/farm_layout.dart';

export '../models/farm_layout.dart' show FarmLayoutSummary;

abstract final class MockFarmLayoutData {
  static const zones = ['A', 'B', 'C'];
  static const boxesPerZone = 120;
  static const columnsPerRow = 10;

  static const rasFlow = [
    RasComponent(
      name: 'Hộp nuôi cua',
      metric: '360 hộp',
      icon: Icons.grid_view,
      temperatureCelsius: 28.4,
    ),
    RasComponent(
      name: 'Drum Filter',
      metric: '1200 L/h',
      icon: Icons.filter_alt_outlined,
      powerWatts: 370,
      hasControl: true,
      isOn: true,
      temperatureCelsius: 27.8,
    ),
    RasComponent(
      name: 'Bể xả',
      metric: '200 L',
      icon: Icons.water_drop_outlined,
      temperatureCelsius: 27.5,
    ),
    RasComponent(
      name: 'Skimmer',
      metric: '88% Eff.',
      icon: Icons.air_outlined,
      powerWatts: 65,
      hasControl: true,
      isOn: true,
      temperatureCelsius: 26.9,
    ),
    RasComponent(
      name: 'Bể vi sinh',
      metric: 'pH 8.1',
      icon: Icons.biotech_outlined,
      powerWatts: 180,
      hasControl: true,
      isOn: true,
      temperatureCelsius: 27.2,
    ),
    RasComponent(
      name: 'Bể san hô',
      metric: '15.5 m³',
      icon: Icons.spa_outlined,
      temperatureCelsius: 27.6,
    ),
    RasComponent(
      name: 'Bể lắng',
      metric: '12.8 m³',
      icon: Icons.layers_outlined,
      temperatureCelsius: 27.3,
    ),
    RasComponent(
      name: 'Máy bơm chính',
      metric: '2.4 kW',
      icon: Icons.settings_input_component_outlined,
      powerWatts: 2400,
      hasControl: true,
      isOn: true,
      temperatureCelsius: 32.1,
    ),
  ];

  static List<CrabBox> generateBoxes() {
    final statuses = <BoxStatus>[
      ...List.filled(280, BoxStatus.normal),
      ...List.filled(25, BoxStatus.watch),
      ...List.filled(10, BoxStatus.molting),
      ...List.filled(4, BoxStatus.alert),
      ...List.filled(1, BoxStatus.deceased),
      ...List.filled(40, BoxStatus.empty),
    ];

  final boxes = <CrabBox>[];
    var statusIndex = 0;

    for (final zone in zones) {
      for (var i = 1; i <= boxesPerZone; i++) {
        final id = '$zone${i.toString().padLeft(2, '0')}';
        final status = statuses[statusIndex++];

        boxes.add(_boxFromStatus(id, zone, status));
      }
    }

    _assignShowcaseBoxes(boxes);
    return boxes;
  }

  static void _assignShowcaseBoxes(List<CrabBox> boxes) {
    final showcase = {
      'A01': BoxStatus.normal,
      'A02': BoxStatus.watch,
      'A03': BoxStatus.molting,
      'A04': BoxStatus.alert,
      'A05': BoxStatus.deceased,
      'A06': BoxStatus.empty,
      'A07': BoxStatus.alert,
    };

    for (var i = 0; i < boxes.length; i++) {
      final s = showcase[boxes[i].id];
      if (s != null) {
        boxes[i] = _boxFromStatus(boxes[i].id, boxes[i].zone, s);
      }
    }
  }

  static CrabBox _boxFromStatus(String id, String zone, BoxStatus status) {
    if (status == BoxStatus.empty) {
      return CrabBox(id: id, zone: zone, status: status);
    }

    final health = switch (status) {
      BoxStatus.normal => 94,
      BoxStatus.watch => 78,
      BoxStatus.molting => 85,
      BoxStatus.alert => 62,
      BoxStatus.deceased => 0,
      BoxStatus.empty => 0,
    };

    return CrabBox(
      id: id,
      zone: zone,
      status: status,
      healthScore: health,
      crabId: 'CRAB-$id-001',
      batchId: 'CFM-2026-001',
      releaseDate: DateTime(2026, 1, 1),
      weightGram: 125,
      lastMoltDate: DateTime(2026, 2, 12),
      expectedHarvest: DateTime(2026, 3, 20),
      hasAlert: status == BoxStatus.alert,
    );
  }

  static FarmLayoutSummary summarize(List<CrabBox> boxes) {
    final mapped = boxes
        .map(
          (b) => FarmMapBox(
            display: b,
            boxId: b.id,
            areaId: '',
            areaCode: b.zone,
            areaName: b.zone,
            rowCode: '—',
            rowName: '—',
            apiStatus: b.status.name,
          ),
        )
        .toList();
    return mapped.toSummary();
  }

  static List<MapEntry<String, String>> boxEnvironment() => const [
        MapEntry('Nhiệt độ', '28.4°C'),
        MapEntry('pH', '7.8'),
        MapEntry('DO', '6.5 mg/L'),
        MapEntry('Độ mặn', '15 ppt'),
        MapEntry('NH3', '0.02 mg/L'),
        MapEntry('NO2', '0.01 mg/L'),
      ];

  static List<String> boxActivityLog() => const [
        '08:00 - Cho ăn',
        '10:30 - Kiểm tra cảm biến',
        '12:00 - Cua hoạt động bình thường',
        '15:20 - Ghi nhận tăng trưởng',
      ];

  static String mascotMessage(List<CrabBox> boxes) {
    final alerts = boxes.where((b) => b.status == BoxStatus.alert).toList();
    if (alerts.isEmpty) {
      return 'Hệ thống RAS đang hoạt động ổn định.\nKhông có hộp cần xử lý khẩn cấp.';
    }
    final ids = alerts.take(2).map((b) => b.id).join(', ');
    return 'Hệ thống RAS đang hoạt động ổn định.\n'
        'Lưu ý Hộp $ids cần kiểm tra khẩn cấp vì nồng độ DO thấp!';
  }
}
