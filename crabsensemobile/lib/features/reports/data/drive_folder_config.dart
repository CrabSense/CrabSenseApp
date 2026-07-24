/// Folder Google Drive cố định để lưu báo cáo xuất từ app.
///
/// Link: https://drive.google.com/drive/folders/1ChLUTQOsr_h4LuNEO5QqyEeoybWVfKan?usp=drive_link
class DriveFolderConfig {
  DriveFolderConfig._();

  static const String folderId = '1ChLUTQOsr_h4LuNEO5QqyEeoybWVfKan';

  static const String folderUrl =
      'https://drive.google.com/drive/folders/$folderId?usp=drive_link';

  /// Web App URL từ Apps Script (tuỳ chọn). Nếu có → upload im lặng, không cần đăng nhập Google trên máy.
  /// Deploy: tools/google_drive_report_upload.gs → Deploy as Web App → dán URL:
  ///   flutter run --dart-define=DRIVE_UPLOAD_WEBHOOK=https://script.google.com/...
  static const String webhookUrl = String.fromEnvironment(
    'DRIVE_UPLOAD_WEBHOOK',
    defaultValue: '',
  );

  /// Shared secret với Apps Script UPLOAD_SECRET.
  static const String webhookSecret = String.fromEnvironment(
    'DRIVE_UPLOAD_SECRET',
    defaultValue: '',
  );

  static bool get hasWebhook =>
      webhookUrl.trim().isNotEmpty && webhookSecret.trim().isNotEmpty;

  /// OAuth Web client từ google-services.json (Firebase project crabssense).
  static const String serverClientId =
      '558115783722-gn2101sanmnmht9p59715ru2eghqdu2o.apps.googleusercontent.com';
}
