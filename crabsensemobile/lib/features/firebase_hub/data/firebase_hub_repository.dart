import 'package:flutter/foundation.dart';

import 'firebase_hub_models.dart';

class FirebaseServiceStatus {
  const FirebaseServiceStatus({
    required this.kind,
    required this.ready,
    required this.statusLabel,
    this.detail,
  });

  final FirebaseServiceKind kind;
  final bool ready;
  final String statusLabel;
  final String? detail;
}

class FirebaseHubSnapshot {
  const FirebaseHubSnapshot({
    required this.coreReady,
    required this.projectId,
    required this.statuses,
    this.fcmToken,
    this.error,
  });

  final bool coreReady;
  final String projectId;
  final List<FirebaseServiceStatus> statuses;
  final String? fcmToken;
  final String? error;
}

/// Hub Firebase trên Profile — dùng mock data demo (không gọi SDK thật).
class FirebaseHubRepository {
  /// Bật mock để Profile → Firebase luôn hiện trạng thái demo ổn định.
  static const bool useMockData = true;

  Future<FirebaseHubSnapshot> load() async {
    if (useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 280));
      return _mockSnapshot();
    }
    return _liveSnapshot();
  }

  FirebaseHubSnapshot _mockSnapshot() {
    const token =
        'dK8fR2mQpLwN7xYvB3cT9aHsUeZ1oJiG5nVbC4xWmPqL8rTy';
    return FirebaseHubSnapshot(
      coreReady: true,
      projectId: FirebaseSetupGuides.projectId,
      fcmToken: token,
      statuses: const [
        FirebaseServiceStatus(
          kind: FirebaseServiceKind.authentication,
          ready: true,
          statusLabel: 'Đã kết nối',
          detail: 'Email/Google Auth đã cấu hình — UID: a8f3c1e2b9d04761',
        ),
        FirebaseServiceStatus(
          kind: FirebaseServiceKind.storage,
          ready: true,
          statusLabel: 'Sẵn sàng',
          detail: 'Bucket: crabssense.firebasestorage.app',
        ),
        FirebaseServiceStatus(
          kind: FirebaseServiceKind.crashlytics,
          ready: true,
          statusLabel: kDebugMode ? 'Sẵn sàng (debug)' : 'Sẵn sàng',
          detail: 'Theo dõi crash & non-fatal trên Console',
        ),
        FirebaseServiceStatus(
          kind: FirebaseServiceKind.cloudMessaging,
          ready: true,
          statusLabel: 'Có FCM token',
          detail: 'dK8fR2mQpLwN…8rTy',
        ),
      ],
    );
  }

  Future<FirebaseHubSnapshot> _liveSnapshot() async {
    // Giữ stub tối giản — mặc định app dùng mock.
    return _mockSnapshot();
  }

  Future<void> sendTestCrashlyticsLog() async {
    if (useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      return;
    }
  }
}
