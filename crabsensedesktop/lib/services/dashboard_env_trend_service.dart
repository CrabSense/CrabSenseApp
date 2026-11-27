import 'package:flutter/foundation.dart';
import '../models/water_quality.dart';

/// Compatibility facade: the former combined trend cannot carry per-sensor
/// scope/receipt. No bootstrap, smoothing, noise, or inferred historical points.
class DashboardEnvTrendService extends ChangeNotifier {
  static const rangeMinutes=30;
  static const liveWindowMinutes=30;
  static const pollInterval=Duration(seconds:3);
  List<WaterTrendPoint> get points=>const [];
  List<WaterTrendPoint> get rawBuffer=>const [];
  int get rangeMinutesValue=>rangeMinutes;
  bool get isLiveApi=>false;
  void startLiveFromHistory(List<WaterTrendPoint> history) { notifyListeners(); }
  void startLiveFromAnchor({required double ph,required double temp,double? dissolvedOxygen}) { notifyListeners(); }
  void seedFromApi(List<WaterTrendPoint> points,{bool enableLive=false}) { notifyListeners(); }
  void appendLiveSample(WaterTrendPoint raw) {}
  void start() {}
  void stop() {}
  void tick() {}
}
