import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

class FirebaseHubRepository {
  Future<FirebaseHubSnapshot> load() async {
    try {
      final coreReady = Firebase.apps.isNotEmpty;
      final projectId = coreReady
          ? Firebase.app().options.projectId
          : FirebaseSetupGuides.projectId;

      String? fcmToken;
      if (coreReady) {
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
        } catch (_) {}
      }

      final statuses = <FirebaseServiceStatus>[
        _authStatus(coreReady),
        _storageStatus(coreReady),
        _crashlyticsStatus(coreReady),
        _messagingStatus(coreReady, fcmToken),
      ];

      return FirebaseHubSnapshot(
        coreReady: coreReady,
        projectId: projectId,
        statuses: statuses,
        fcmToken: fcmToken,
      );
    } catch (e) {
      return FirebaseHubSnapshot(
        coreReady: false,
        projectId: FirebaseSetupGuides.projectId,
        statuses: [
          for (final k in FirebaseServiceKind.values)
            FirebaseServiceStatus(
              kind: k,
              ready: false,
              statusLabel: 'Lỗi',
              detail: '$e',
            ),
        ],
        error: '$e',
      );
    }
  }

  FirebaseServiceStatus _authStatus(bool coreReady) {
    if (!coreReady) {
      return const FirebaseServiceStatus(
        kind: FirebaseServiceKind.authentication,
        ready: false,
        statusLabel: 'Chưa init',
        detail: 'Firebase.initializeApp() chưa chạy',
      );
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      return FirebaseServiceStatus(
        kind: FirebaseServiceKind.authentication,
        ready: true,
        statusLabel: user == null ? 'Sẵn sàng (chưa login FB)' : 'Đã login FB',
        detail: user == null
            ? 'Package firebase_auth OK — bật provider trên Console'
            : 'UID: ${user.uid}',
      );
    } catch (e) {
      return FirebaseServiceStatus(
        kind: FirebaseServiceKind.authentication,
        ready: false,
        statusLabel: 'Lỗi',
        detail: '$e',
      );
    }
  }

  FirebaseServiceStatus _storageStatus(bool coreReady) {
    if (!coreReady) {
      return const FirebaseServiceStatus(
        kind: FirebaseServiceKind.storage,
        ready: false,
        statusLabel: 'Chưa init',
      );
    }
    try {
      final bucket = FirebaseStorage.instance.bucket;
      return FirebaseServiceStatus(
        kind: FirebaseServiceKind.storage,
        ready: true,
        statusLabel: 'Sẵn sàng',
        detail: 'Bucket: $bucket',
      );
    } catch (e) {
      return FirebaseServiceStatus(
        kind: FirebaseServiceKind.storage,
        ready: false,
        statusLabel: 'Lỗi',
        detail: '$e',
      );
    }
  }

  FirebaseServiceStatus _crashlyticsStatus(bool coreReady) {
    if (!coreReady) {
      return const FirebaseServiceStatus(
        kind: FirebaseServiceKind.crashlytics,
        ready: false,
        statusLabel: 'Chưa init',
      );
    }
    try {
      // Access instance to verify plugin linked.
      final _ = FirebaseCrashlytics.instance;
      return FirebaseServiceStatus(
        kind: FirebaseServiceKind.crashlytics,
        ready: true,
        statusLabel: kDebugMode ? 'Sẵn sàng (debug)' : 'Sẵn sàng',
        detail: 'Gửi non-fatal từ màn hướng dẫn để kiểm tra Console',
      );
    } catch (e) {
      return FirebaseServiceStatus(
        kind: FirebaseServiceKind.crashlytics,
        ready: false,
        statusLabel: 'Lỗi',
        detail: '$e',
      );
    }
  }

  FirebaseServiceStatus _messagingStatus(bool coreReady, String? token) {
    if (!coreReady) {
      return const FirebaseServiceStatus(
        kind: FirebaseServiceKind.cloudMessaging,
        ready: false,
        statusLabel: 'Chưa init',
      );
    }
    final short = token == null
        ? null
        : (token.length <= 28 ? token : '${token.substring(0, 14)}…${token.substring(token.length - 10)}');
    return FirebaseServiceStatus(
      kind: FirebaseServiceKind.cloudMessaging,
      ready: token != null && token.isNotEmpty,
      statusLabel: token == null ? 'Chưa có token' : 'Có FCM token',
      detail: short,
    );
  }

  Future<void> sendTestCrashlyticsLog() async {
    await FirebaseCrashlytics.instance.log('CrabSense test log from Firebase hub');
    await FirebaseCrashlytics.instance.recordError(
      Exception('CrabSense test non-fatal'),
      StackTrace.current,
      reason: 'Manual test from Tài khoản → Firebase → Crashlytics',
      fatal: false,
    );
  }
}
