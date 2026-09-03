import 'package:flutter/foundation.dart';

import '../data/mock_sensor_kit_data.dart';
import '../models/sensor_kit.dart';

class SensorKitService extends ChangeNotifier {
  CurrentSensorKit _current = MockSensorKitData.current;
  String? _selectedPlanId = 'pro';
  bool _upgrading = false;

  CurrentSensorKit get current => _current;
  List<SensorKitPlan> get plans => MockSensorKitData.plans();
  List<List<String>> get compareRows => MockSensorKitData.compareRows;
  String? get selectedPlanId => _selectedPlanId;
  bool get upgrading => _upgrading;

  SensorKitPlan? get selectedPlan {
    if (_selectedPlanId == null) return null;
    for (final p in plans) {
      if (p.id == _selectedPlanId) return p;
    }
    return null;
  }

  void selectPlan(String id) {
    _selectedPlanId = id;
    notifyListeners();
  }

  Future<void> upgradeToSelected() async {
    final plan = selectedPlan;
    if (plan == null || plan.id == 'basic') return;

    _upgrading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 1200));

    _current = CurrentSensorKit(
      planName: plan.name,
      activeSensors: plan.sensorCount.clamp(12, 48),
      maxSensors: plan.sensorCount,
      firmwareVersion: 'v3.0.0',
      lastSync: 'Vừa đồng bộ',
    );
    _upgrading = false;
    notifyListeners();
  }
}
