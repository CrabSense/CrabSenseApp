enum FirebaseServiceKind {
  authentication,
  storage,
  crashlytics,
  cloudMessaging,
}

extension FirebaseServiceKindX on FirebaseServiceKind {
  String get titleVi => switch (this) {
        FirebaseServiceKind.authentication => 'Authentication',
        FirebaseServiceKind.storage => 'Storage',
        FirebaseServiceKind.crashlytics => 'Crashlytics',
        FirebaseServiceKind.cloudMessaging => 'Cloud Messaging',
      };

  String get subtitleVi => switch (this) {
        FirebaseServiceKind.authentication =>
          'Đăng nhập Google / Email trên Firebase Auth',
        FirebaseServiceKind.storage =>
          'Lưu ảnh, video, file báo cáo trên Cloud Storage',
        FirebaseServiceKind.crashlytics =>
          'Theo dõi crash & lỗi native trên Console',
        FirebaseServiceKind.cloudMessaging =>
          'Push notification FCM tới thiết bị',
      };

  String get queryValue => name;

  static FirebaseServiceKind? fromQuery(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return FirebaseServiceKind.values
        .where((e) => e.name == raw)
        .firstOrNull;
  }
}

class FirebaseGuideStep {
  const FirebaseGuideStep({
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;
}

/// Nội dung hướng dẫn setup từng dịch vụ Firebase (Console + app).
class FirebaseSetupGuides {
  FirebaseSetupGuides._();

  static const projectId = 'crabssense';
  static const packageName = 'com.example.crabsensemobile';
  static const consoleUrl = 'https://console.firebase.google.com/project/crabssense';

  static List<FirebaseGuideStep> stepsFor(FirebaseServiceKind kind) {
    return switch (kind) {
      FirebaseServiceKind.authentication => const [
          FirebaseGuideStep(
            title: '1. Mở Firebase Console',
            detail:
                'Vào console.firebase.google.com → chọn project crabssense '
                '(hoặc tạo project mới rồi thêm Android app package '
                'com.example.crabsensemobile).',
          ),
          FirebaseGuideStep(
            title: '2. Bật Authentication',
            detail:
                'Build → Authentication → Get started → Sign-in method.\n'
                'Bật Email/Password và/hoặc Google.\n'
                'Với Google: thêm SHA-1 debug '
                '(chạy: cd android && ./gradlew signingReport) vào '
                'Project settings → Your apps → Android.',
          ),
          FirebaseGuideStep(
            title: '3. Tải google-services.json',
            detail:
                'Project settings → Your apps → Download google-services.json '
                '→ đặt vào android/app/ (file hiện đã có).',
          ),
          FirebaseGuideStep(
            title: '4. Package Flutter',
            detail:
                'Đã thêm firebase_auth. Trong code dùng FirebaseAuth.instance '
                'sau Firebase.initializeApp(). App CrabSense vẫn dùng JWT BE '
                'cho tài khoản chính; Firebase Auth dùng cho Google / thử nghiệm.',
          ),
          FirebaseGuideStep(
            title: '5. Kiểm tra',
            detail:
                'Full rebuild app → vào Tài khoản → Firebase → Authentication. '
                'Trạng thái phải hiện “Core OK”. Thử đăng nhập Google nếu đã bật.',
          ),
        ],
      FirebaseServiceKind.storage => const [
          FirebaseGuideStep(
            title: '1. Bật Storage',
            detail:
                'Console → Build → Storage → Get started → chọn chế độ '
                'Test mode (dev) hoặc Production rules.',
          ),
          FirebaseGuideStep(
            title: '2. Bucket',
            detail:
                'Bucket mặc định: crabssense.firebasestorage.app '
                '(đã có trong google-services.json).',
          ),
          FirebaseGuideStep(
            title: '3. Rules (dev)',
            detail:
                'Tạm thời (chỉ dev):\n'
                'rules_version = \'2\';\n'
                'service firebase.storage {\n'
                '  match /b/{bucket}/o {\n'
                '    match /{allPaths=**} {\n'
                '      allow read, write: if request.auth != null;\n'
                '    }\n'
                '  }\n'
                '}',
          ),
          FirebaseGuideStep(
            title: '4. Package Flutter',
            detail:
                'Đã thêm firebase_storage. Upload ví dụ:\n'
                'FirebaseStorage.instance.ref(\'reports/x.csv\').putFile(file);',
          ),
          FirebaseGuideStep(
            title: '5. Kiểm tra',
            detail:
                'Upload thử 1 file từ app/debug → Console Storage thấy file.',
          ),
        ],
      FirebaseServiceKind.crashlytics => const [
          FirebaseGuideStep(
            title: '1. Bật Crashlytics',
            detail:
                'Console → Build → Crashlytics → Get started / Enable.',
          ),
          FirebaseGuideStep(
            title: '2. Gradle plugin',
            detail:
                'settings.gradle.kts thêm:\n'
                'id("com.google.firebase.crashlytics") version "3.0.3" apply false\n'
                'app/build.gradle.kts thêm:\n'
                'id("com.google.firebase.crashlytics")',
          ),
          FirebaseGuideStep(
            title: '3. Package Flutter',
            detail:
                'Đã thêm firebase_crashlytics. main.dart gọi '
                'FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError '
                'sau Firebase.initializeApp().',
          ),
          FirebaseGuideStep(
            title: '4. Test crash',
            detail:
                'Trong màn Crashlytics bấm “Gửi lỗi thử nghiệm” '
                '(non-fatal). Hoặc release build + Force crash → '
                'vài phút sau Console hiện report.',
          ),
          FirebaseGuideStep(
            title: '5. Lưu ý',
            detail:
                'Crashlytics đầy đủ nhất trên build release / không bị '
                'debugger attach. Debug vẫn gửi được non-fatal log.',
          ),
        ],
      FirebaseServiceKind.cloudMessaging => const [
          FirebaseGuideStep(
            title: '1. Cloud Messaging đã dùng sẵn',
            detail:
                'App đã có firebase_messaging + NotificationService. '
                'Project crabssense đã init FCM trong main.dart.',
          ),
          FirebaseGuideStep(
            title: '2. Console → Messaging',
            detail:
                'Engage → Messaging → Create your first campaign '
                '(hoặc Cloud Messaging cũ) → gửi notification test '
                'tới FCM token của máy.',
          ),
          FirebaseGuideStep(
            title: '3. Lấy FCM token',
            detail:
                'Màn Cloud Messaging trong app hiện token (copy được). '
                'Hoặc log: FirebaseMessaging.instance.getToken().',
          ),
          FirebaseGuideStep(
            title: '4. Android notification',
            detail:
                'Đã dùng flutter_local_notifications. Trên Android 13+ '
                'cần quyền POST_NOTIFICATIONS (permission_handler).',
          ),
          FirebaseGuideStep(
            title: '5. Backend (tuỳ chọn)',
            detail:
                'BE có thể gửi FCM bằng server key / HTTP v1 '
                '(service account). Console → Project settings → '
                'Cloud Messaging / Service accounts.',
          ),
        ],
    };
  }
}
