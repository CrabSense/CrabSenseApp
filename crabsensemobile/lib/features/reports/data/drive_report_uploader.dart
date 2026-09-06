import 'dart:convert';
import 'package:crabsensemobile/core/platform/io_export.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'drive_folder_config.dart';

/// Upload file báo cáo vào folder Drive cố định (CRAB).
class DriveReportUploader {
  DriveReportUploader._();

  static const _driveScope = 'https://www.googleapis.com/auth/drive.file';
  static bool _initialized = false;

  /// Tắt Sign-In: --dart-define=ENABLE_DRIVE_GOOGLE_SIGNIN=false
  static const bool enableGoogleSignIn = bool.fromEnvironment(
    'ENABLE_DRIVE_GOOGLE_SIGNIN',
    defaultValue: true,
  );

  static Future<void> _ensureGoogleSignIn() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: DriveFolderConfig.serverClientId,
    );
    _initialized = true;
  }

  /// 1) Webhook Apps Script (nếu có URL + secret)
  /// 2) Google Sign-In + Drive API → folder cố định
  /// 3) Fallback manual share
  static Future<DriveUploadResult> uploadFile(File file) async {
    final name = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'report.csv';
    final bytes = await file.readAsBytes();
    final mime = name.endsWith('.json') ? 'application/json' : 'text/csv';

    if (DriveFolderConfig.hasWebhook) {
      final webhook = await _uploadViaWebhook(
        filename: name,
        mimeType: mime,
        bytes: bytes,
      );
      if (webhook.success) return webhook;
    }

    if (enableGoogleSignIn) {
      try {
        return await _uploadViaGoogleSignIn(
          filename: name,
          mimeType: mime,
          bytes: bytes,
        );
      } on GoogleSignInException catch (e) {
        // Thử sign-out rồi đăng nhập lại 1 lần (reauth failed thường hết sau đó).
        if (e.code == GoogleSignInExceptionCode.canceled ||
            e.code == GoogleSignInExceptionCode.interrupted) {
          try {
            await GoogleSignIn.instance.signOut();
            return await _uploadViaGoogleSignIn(
              filename: name,
              mimeType: mime,
              bytes: bytes,
            );
          } catch (e2) {
            return DriveUploadResult(
              success: false,
              needsManualShare: true,
              message:
                  'Google Sign-In thất bại ($e2). '
                  'Tài khoản phải có quyền Sửa folder CRAB; '
                  'đã thêm SHA-1 thì tải lại google-services.json rồi full rebuild.',
              via: 'google_sign_in',
            );
          }
        }
        return DriveUploadResult(
          success: false,
          needsManualShare: true,
          message: 'Google Sign-In thất bại (${e.code.name}).',
          via: 'google_sign_in',
        );
      } catch (e) {
        return DriveUploadResult(
          success: false,
          needsManualShare: true,
          message: 'Upload Drive lỗi: $e',
          via: 'google_sign_in',
        );
      }
    }

    return const DriveUploadResult(
      success: false,
      needsManualShare: true,
      message: 'Chưa bật auto-upload Drive.',
      via: 'manual',
    );
  }

  static Future<DriveUploadResult> uploadFiles(List<File> files) async {
    if (files.isEmpty) {
      return const DriveUploadResult(
        success: false,
        message: 'Không có file để upload',
      );
    }

    DriveUploadResult? last;
    for (final f in files) {
      last = await uploadFile(f);
      if (!last.success && last.needsManualShare) {
        // Vẫn thử các file còn lại không — trả ngay để UI mở share.
        return last;
      }
    }
    return last!;
  }

  static Future<void> openFolder() async {
    final uri = Uri.parse(DriveFolderConfig.folderUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<DriveUploadResult> _uploadViaWebhook({
    required String filename,
    required String mimeType,
    required List<int> bytes,
  }) async {
    final res = await http.post(
      Uri.parse(DriveFolderConfig.webhookUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'secret': DriveFolderConfig.webhookSecret,
        'filename': filename,
        'mimeType': mimeType,
        'dataBase64': base64Encode(bytes),
      }),
    );

    Map<String, dynamic>? body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>?;
    } catch (_) {
      body = null;
    }

    if (res.statusCode >= 200 &&
        res.statusCode < 300 &&
        body != null &&
        body['success'] == true) {
      return DriveUploadResult(
        success: true,
        message: 'Đã lưu lên Google Drive (webhook)',
        fileUrl: body['url']?.toString(),
        via: 'webhook',
      );
    }

    return DriveUploadResult(
      success: false,
      needsManualShare: false,
      message: body?['message']?.toString() ??
          'Upload webhook thất bại (${res.statusCode})',
      via: 'webhook',
    );
  }

  static Future<DriveUploadResult> _uploadViaGoogleSignIn({
    required String filename,
    required String mimeType,
    required List<int> bytes,
  }) async {
    await _ensureGoogleSignIn();

    final account = await GoogleSignIn.instance.authenticate(
      scopeHint: const [_driveScope],
    );

    final authz = await account.authorizationClient.authorizeScopes(
      const [_driveScope],
    );
    final token = authz.accessToken;

    const boundary = 'crabsense_boundary';
    final metadata = jsonEncode({
      'name': filename,
      'parents': [DriveFolderConfig.folderId],
    });

    final body = <int>[
      ...utf8.encode(
        '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '$metadata\r\n'
        '--$boundary\r\n'
        'Content-Type: $mimeType\r\n\r\n',
      ),
      ...bytes,
      ...utf8.encode('\r\n--$boundary--\r\n'),
    ];

    final uri = Uri.parse(
      'https://www.googleapis.com/upload/drive/v3/files'
      '?uploadType=multipart&supportsAllDrives=true',
    );

    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'multipart/related; boundary=$boundary',
      },
      body: body,
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      Map<String, dynamic>? data;
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>?;
      } catch (_) {}
      final id = data?['id']?.toString();
      return DriveUploadResult(
        success: true,
        message: 'Đã lưu lên Google Drive',
        fileUrl: id != null
            ? 'https://drive.google.com/file/d/$id/view'
            : DriveFolderConfig.folderUrl,
        via: 'google_sign_in',
      );
    }

    // 403 thường = account không có quyền viết folder
    final hint = res.statusCode == 403
        ? ' Tài khoản Google không có quyền Sửa folder CRAB — share folder cho email đó (Editor).'
        : '';

    return DriveUploadResult(
      success: false,
      needsManualShare: true,
      message: 'Drive API ${res.statusCode}.$hint',
      via: 'google_sign_in',
    );
  }
}

class DriveUploadResult {
  const DriveUploadResult({
    required this.success,
    required this.message,
    this.fileUrl,
    this.via,
    this.needsManualShare = false,
  });

  final bool success;
  final String message;
  final String? fileUrl;
  final String? via;
  final bool needsManualShare;
}
