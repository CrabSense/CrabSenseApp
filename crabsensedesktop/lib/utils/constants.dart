import 'package:flutter/material.dart';

class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:5000';
  static const Duration apiTimeout = Duration(seconds: 30);

  // App Information
  static const String appName = 'CrabSense Desktop';
  static const String appVersion = '1.0.0';

  // Thresholds cho chất lượng nước
  static const double minTemperature = 20.0;
  static const double maxTemperature = 32.0;
  
  static const double minPH = 7.0;
  static const double maxPH = 8.5;
  
  static const double minDissolvedOxygen = 5.0;
  static const double maxDissolvedOxygen = 10.0;
  
  static const double minSalinity = 10.0;
  static const double maxSalinity = 25.0;

  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF03A9F4);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);

  // Sizes
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
}
