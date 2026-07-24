import 'package:flutter/material.dart';

/// User Role Enum in CrabSense System
enum UserRole {
  operator,
  manager,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.operator:
        return 'Operator';
      case UserRole.manager:
        return 'Quản lý Trang trại';
      case UserRole.admin:
        return 'Quản trị hệ thống';
    }
  }

  Color get badgeColor {
    switch (this) {
      case UserRole.operator:
        return const Color(0xFF00C8FF);
      case UserRole.manager:
        return const Color(0xFF27AE60);
      case UserRole.admin:
        return const Color(0xFFF2C94C);
    }
  }
}

/// 1. Profile Summary Data Model
class ProfileSummary {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String employeeId;
  final UserRole role;
  final String currentFarm;
  final bool isOnline;
  final DateTime joinedDate;
  final String status;
  final String? avatarUrl;

  const ProfileSummary({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.employeeId,
    required this.role,
    required this.currentFarm,
    required this.isOnline,
    required this.joinedDate,
    required this.status,
    this.avatarUrl,
  });

  static ProfileSummary get sample => ProfileSummary(
        userId: 'USR-08821',
        fullName: 'Trương Minh Khánh',
        email: 'khanh.truong@crabsense.io',
        phone: '+84 901 234 567',
        employeeId: 'EMP-2026-088',
        role: UserRole.operator,
        currentFarm: 'Farm A',
        isOnline: true,
        joinedDate: DateTime(2024, 1, 15),
        status: 'Đang hoạt động',
        avatarUrl: null,
      );
}

/// 2. Farm Management Summary Model
class FarmSummaryItem {
  final String id;
  final String name;
  final String areaCount;
  final String boxCount;
  final bool isCurrent;

  const FarmSummaryItem({
    required this.id,
    required this.name,
    required this.areaCount,
    required this.boxCount,
    this.isCurrent = false,
  });
}

class FarmManagementSummary {
  final List<FarmSummaryItem> availableFarms;
  final String currentFarmName;
  final int totalAreas;
  final int totalBoxes;
  final int activeBatches;

  const FarmManagementSummary({
    required this.availableFarms,
    required this.currentFarmName,
    required this.totalAreas,
    required this.totalBoxes,
    required this.activeBatches,
  });

  static FarmManagementSummary get sample => const FarmManagementSummary(
        availableFarms: [
          FarmSummaryItem(id: 'F1', name: 'Farm A - Vùng Ven Biển', areaCount: '4 Khu', boxCount: '120 Box', isCurrent: true),
          FarmSummaryItem(id: 'F2', name: 'Farm B - Khu Công Nghệ Cao', areaCount: '6 Khu', boxCount: '240 Box'),
          FarmSummaryItem(id: 'F3', name: 'Farm C - Khu Thử Nghiệm', areaCount: '2 Khu', boxCount: '60 Box'),
        ],
        currentFarmName: 'Farm A',
        totalAreas: 4,
        totalBoxes: 120,
        activeBatches: 8,
      );
}

/// 3. Device & IoT Item Model
class DeviceTypeItem {
  final String id;
  final String name;
  final IconData icon;
  final int onlineCount;
  final int offlineCount;
  final DateTime lastUpdated;
  final String statusBadge;

  const DeviceTypeItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.onlineCount,
    required this.offlineCount,
    required this.lastUpdated,
    required this.statusBadge,
  });
}

class DeviceSummary {
  final List<DeviceTypeItem> devices;
  final int totalOnline;
  final int totalOffline;

  const DeviceSummary({
    required this.devices,
    required this.totalOnline,
    required this.totalOffline,
  });

  static DeviceSummary get sample => DeviceSummary(
        devices: [
          DeviceTypeItem(
            id: 'gateway',
            name: 'Gateway Trung Tâm',
            icon: Icons.router_rounded,
            onlineCount: 4,
            offlineCount: 0,
            lastUpdated: DateTime.now().subtract(const Duration(minutes: 1)),
            statusBadge: 'Hoạt động tốt',
          ),
          DeviceTypeItem(
            id: 'esp32',
            name: 'Bộ Điều Khiển ESP32',
            icon: Icons.memory_rounded,
            onlineCount: 28,
            offlineCount: 2,
            lastUpdated: DateTime.now().subtract(const Duration(minutes: 2)),
            statusBadge: '2 Cần kiểm tra',
          ),
          DeviceTypeItem(
            id: 'camera',
            name: 'Camera AI Giám Sát',
            icon: Icons.videocam_rounded,
            onlineCount: 12,
            offlineCount: 1,
            lastUpdated: DateTime.now().subtract(const Duration(minutes: 3)),
            statusBadge: '11/12 Trực tiếp',
          ),
          DeviceTypeItem(
            id: 'sensor',
            name: 'Cảm Biến Môi Trường',
            icon: Icons.sensors_rounded,
            onlineCount: 64,
            offlineCount: 0,
            lastUpdated: DateTime.now().subtract(const Duration(seconds: 45)),
            statusBadge: 'Chính xác 99%',
          ),
          DeviceTypeItem(
            id: 'pump',
            name: 'Máy Bơm Nước',
            icon: Icons.water_drop_rounded,
            onlineCount: 8,
            offlineCount: 0,
            lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
            statusBadge: 'Sẵn sàng',
          ),
          DeviceTypeItem(
            id: 'valve',
            name: 'Van Tự Động',
            icon: Icons.tune_rounded,
            onlineCount: 16,
            offlineCount: 0,
            lastUpdated: DateTime.now().subtract(const Duration(minutes: 4)),
            statusBadge: 'Tự động',
          ),
          DeviceTypeItem(
            id: 'lighting',
            name: 'Hệ Thống Chiếu Sáng',
            icon: Icons.lightbulb_rounded,
            onlineCount: 24,
            offlineCount: 0,
            lastUpdated: DateTime.now().subtract(const Duration(minutes: 10)),
            statusBadge: 'Chế độ đêm',
          ),
        ],
        totalOnline: 156,
        totalOffline: 3,
      );
}

/// 4. AI Center Model
class AISummary {
  final int detectionHistoryCount;
  final int recommendationHistoryCount;
  final String modelVersion;
  final String modelStatus;
  final int feedbackCount;
  final String trainingInfo;
  final double avgConfidencePercentage;

  const AISummary({
    required this.detectionHistoryCount,
    required this.recommendationHistoryCount,
    required this.modelVersion,
    required this.modelStatus,
    required this.feedbackCount,
    required this.trainingInfo,
    required this.avgConfidencePercentage,
  });

  static AISummary get sample => const AISummary(
        detectionHistoryCount: 1420,
        recommendationHistoryCount: 318,
        modelVersion: 'CrabSense-AI v2.4.1',
        modelStatus: 'Đang hoạt động (Operational)',
        feedbackCount: 84,
        trainingInfo: 'Cập nhật lần cuối: 20/07/2026 (Dataset 50K images)',
        avgConfidencePercentage: 96.8,
      );
}

/// 5. Reports Summary Model
class ReportSummary {
  final int totalReportsAvailable;
  final DateTime lastGeneratedReport;

  const ReportSummary({
    required this.totalReportsAvailable,
    required this.lastGeneratedReport,
  });

  static ReportSummary get sample => ReportSummary(
        totalReportsAvailable: 7,
        lastGeneratedReport: DateTime.now().subtract(const Duration(hours: 3)),
      );
}

/// 6. Offline & Sync Model
class SyncSummary {
  final String syncStatus;
  final int offlineQueueCount;
  final int pendingUploadCount;
  final DateTime lastSyncedAt;
  final int conflictCount;

  const SyncSummary({
    required this.syncStatus,
    required this.offlineQueueCount,
    required this.pendingUploadCount,
    required this.lastSyncedAt,
    required this.conflictCount,
  });

  static SyncSummary get sample => SyncSummary(
        syncStatus: 'Đã đồng bộ',
        offlineQueueCount: 0,
        pendingUploadCount: 0,
        lastSyncedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        conflictCount: 0,
      );
}

/// 7. App Settings Model
class SettingsSummary {
  final bool isDarkMode;
  final String language;
  final bool notificationsEnabled;
  final String measurementUnit;
  final String cameraResolution;
  final String cacheSize;
  final bool autoSync;
  final int refreshRateSeconds;

  const SettingsSummary({
    required this.isDarkMode,
    required this.language,
    required this.notificationsEnabled,
    required this.measurementUnit,
    required this.cameraResolution,
    required this.cacheSize,
    required this.autoSync,
    required this.refreshRateSeconds,
  });

  SettingsSummary copyWith({
    bool? isDarkMode,
    String? language,
    bool? notificationsEnabled,
    String? measurementUnit,
    String? cameraResolution,
    String? cacheSize,
    bool? autoSync,
    int? refreshRateSeconds,
  }) {
    return SettingsSummary(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      cameraResolution: cameraResolution ?? this.cameraResolution,
      cacheSize: cacheSize ?? this.cacheSize,
      autoSync: autoSync ?? this.autoSync,
      refreshRateSeconds: refreshRateSeconds ?? this.refreshRateSeconds,
    );
  }

  static SettingsSummary get sample => const SettingsSummary(
        isDarkMode: true,
        language: 'Tiếng Việt',
        notificationsEnabled: true,
        measurementUnit: '°C, mg/L, ppt',
        cameraResolution: 'HD 1080p',
        cacheSize: '124 MB',
        autoSync: true,
        refreshRateSeconds: 30,
      );
}

/// 8. Security Summary Model
class SecuritySummary {
  final DateTime passwordLastChanged;
  final bool biometricEnabled;
  final bool twoFactorEnabled;
  final int activeDevicesCount;
  final int loginHistoryCount;

  const SecuritySummary({
    required this.passwordLastChanged,
    required this.biometricEnabled,
    required this.twoFactorEnabled,
    required this.activeDevicesCount,
    required this.loginHistoryCount,
  });

  SecuritySummary copyWith({
    DateTime? passwordLastChanged,
    bool? biometricEnabled,
    bool? twoFactorEnabled,
    int? activeDevicesCount,
    int? loginHistoryCount,
  }) {
    return SecuritySummary(
      passwordLastChanged: passwordLastChanged ?? this.passwordLastChanged,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      activeDevicesCount: activeDevicesCount ?? this.activeDevicesCount,
      loginHistoryCount: loginHistoryCount ?? this.loginHistoryCount,
    );
  }

  static SecuritySummary get sample => SecuritySummary(
        passwordLastChanged: DateTime(2026, 6, 1),
        biometricEnabled: true,
        twoFactorEnabled: true,
        activeDevicesCount: 2,
        loginHistoryCount: 18,
      );
}

/// Master Profile State Data aggregating all sections
class ProfileStateData {
  final ProfileSummary profile;
  final FarmManagementSummary farmManagement;
  final DeviceSummary devices;
  final AISummary aiSummary;
  final ReportSummary reports;
  final SyncSummary syncSummary;
  final SettingsSummary settings;
  final SecuritySummary security;
  final bool isOnline;
  final bool isOfflineCached;
  final DateTime lastSyncedAt;
  final String? sectionError;

  const ProfileStateData({
    required this.profile,
    required this.farmManagement,
    required this.devices,
    required this.aiSummary,
    required this.reports,
    required this.syncSummary,
    required this.settings,
    required this.security,
    required this.isOnline,
    required this.isOfflineCached,
    required this.lastSyncedAt,
    this.sectionError,
  });

  ProfileStateData copyWith({
    ProfileSummary? profile,
    FarmManagementSummary? farmManagement,
    DeviceSummary? devices,
    AISummary? aiSummary,
    ReportSummary? reports,
    SyncSummary? syncSummary,
    SettingsSummary? settings,
    SecuritySummary? security,
    bool? isOnline,
    bool? isOfflineCached,
    DateTime? lastSyncedAt,
    String? sectionError,
  }) {
    return ProfileStateData(
      profile: profile ?? this.profile,
      farmManagement: farmManagement ?? this.farmManagement,
      devices: devices ?? this.devices,
      aiSummary: aiSummary ?? this.aiSummary,
      reports: reports ?? this.reports,
      syncSummary: syncSummary ?? this.syncSummary,
      settings: settings ?? this.settings,
      security: security ?? this.security,
      isOnline: isOnline ?? this.isOnline,
      isOfflineCached: isOfflineCached ?? this.isOfflineCached,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      sectionError: sectionError,
    );
  }

  static ProfileStateData get sample => ProfileStateData(
        profile: ProfileSummary.sample,
        farmManagement: FarmManagementSummary.sample,
        devices: DeviceSummary.sample,
        aiSummary: AISummary.sample,
        reports: ReportSummary.sample,
        syncSummary: SyncSummary.sample,
        settings: SettingsSummary.sample,
        security: SecuritySummary.sample,
        isOnline: true,
        isOfflineCached: false,
        lastSyncedAt: DateTime.now(),
      );
}
