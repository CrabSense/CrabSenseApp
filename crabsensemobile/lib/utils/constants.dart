import 'package:crabsensemobile/core/platform/io_export.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class AppConstants {
  // API Configuration — physical Android uses PC LAN IP; emulator needs dart-define
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _devHostLan = String.fromEnvironment(
    'DEV_HOST_LAN',
    defaultValue: '10.33.248.225',
  );

  static String get apiBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (!kIsWeb && Platform.isAndroid) return 'http://$_devHostLan:5080';
    return 'http://localhost:5080';
  }
  static const Duration apiTimeout = Duration(seconds: 30);

  // App Information
  static const String appName = 'CrabSense Mobile';
  static const String appVersion = '1.0.0';

  // Thresholds cho chất lượng nước
  static const double minTemperature = 20;
  static const double maxTemperature = 32;
  
  static const double minPH = 7;
  static const double maxPH = 8.5;
  
  static const double minDissolvedOxygen = 5;
  static const double maxDissolvedOxygen = 10;
  
  static const double minSalinity = 10;
  static const double maxSalinity = 25;

  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF03A9F4);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color backgroundColor = Color(0xFFF5F5F5);

  // Sizes - Optimized for mobile
  static const double defaultPadding = 16;
  static const double smallPadding = 8;
  static const double largePadding = 24;
  static const double defaultBorderRadius = 12;
  static const double cardElevation = 2;

  // Bottom Navigation
  static const double bottomNavHeight = 60;
}
