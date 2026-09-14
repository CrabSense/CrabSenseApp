import 'package:flutter/foundation.dart';

import '../models/sensor_kit.dart';

class SensorKitService extends ChangeNotifier {
  CurrentSensorKit _current = const CurrentSensorKit(
    planName: 'Chưa đăng ký',
    activeSensors: 0,
    maxSensors: 0,
    firmwareVersion: '—',
    lastSync: '—',
  );
  String? _selectedPlanId;
  bool _upgrading = false;

  CurrentSensorKit get current => _current;
  List<SensorKitPlan> get plans => const [];
  List<List<String>> get compareRows => const [];
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
    if (plan == null) return;

    _upgrading = true;
    notifyListeners();

    _current = CurrentSensorKit(
      planName: plan.name,
      activeSensors: 0,
      maxSensors: plan.sensorCount,
      firmwareVersion: _current.firmwareVersion,
      lastSync: _current.lastSync,
    );
    _upgrading = false;
    notifyListeners();
  }
}
