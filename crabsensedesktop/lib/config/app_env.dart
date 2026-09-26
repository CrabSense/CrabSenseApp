import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Biến môi trường từ `.env` (Cloud only).
abstract final class AppEnv {
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    await dotenv.load(fileName: '.env');
    _loaded = true;
  }

  static String get cloudApiUrl {
    final raw = dotenv.env['CLOUD_API_URL']?.trim();
    if (raw == null || raw.isEmpty) {
      throw StateError('Thiếu CLOUD_API_URL trong .env');
    }
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static String? get defaultFarmId {
    final v = dotenv.env['DEFAULT_FARM_ID']?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  static String? get defaultDeviceMac {
    final v = dotenv.env['DEFAULT_DEVICE_MAC']?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  static String get kioskUrl {
    final value = dotenv.env['KIOSK_URL']?.trim();
    return value == null || value.isEmpty ? 'http://192.168.1.50:8090' : value;
  }

  static String get defaultGatewayId {
    final v = dotenv.env['DEFAULT_GATEWAY_ID']?.trim();
    return v == null || v.isEmpty ? '11111111-1111-1111-1111-111111111111' : v;
  }

  /// IP camera 1 (hiển thị trên UI).
  static String get camera1Ip =>
      dotenv.env['CAMERA_1_IP']?.trim().isNotEmpty == true
          ? dotenv.env['CAMERA_1_IP']!.trim()
          : '10.122.95.47';

  /// URL stream Camera 1 — HTTP MJPEG hoặc RTSP.
  /// Ví dụ: http://10.122.95.47/stream hoặc rtsp://10.122.95.47:554/...
  static String get camera1StreamUrl {
    final explicit = dotenv.env['CAMERA_1_STREAM_URL']?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final ip = camera1Ip;
    if (ip.startsWith('http://') ||
        ip.startsWith('https://') ||
        ip.startsWith('rtsp://')) {
      return ip;
    }
    return 'http://$ip/stream';
  }

  /// Ảnh chụp định kỳ khi MJPEG stream lỗi (ESP32: /capture).
  static String get camera1SnapshotFallbackUrl {
    final explicit = dotenv.env['CAMERA_1_SNAPSHOT_URL']?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final ip = camera1Ip;
    if (ip.startsWith('http://') || ip.startsWith('https://')) {
      return '$ip/capture';
    }
    return 'http://$ip/capture';
  }

  /// IP / host Camera 2.
  static String get camera2Ip =>
      dotenv.env['CAMERA_2_IP']?.trim().isNotEmpty == true
          ? dotenv.env['CAMERA_2_IP']!.trim()
          : '10.122.95.227';

  /// URL stream Camera 2 — HTTP MJPEG giống Camera 1.
  /// Ví dụ: http://10.122.95.227/stream
  static String get camera2StreamUrl {
    final explicit = dotenv.env['CAMERA_2_STREAM_URL']?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final ip = camera2Ip;
    if (ip.startsWith('http://') ||
        ip.startsWith('https://') ||
        ip.startsWith('rtsp://')) {
      return ip;
    }
    return 'http://$ip/stream';
  }

  /// Ảnh chụp định kỳ khi MJPEG stream lỗi (ESP32: /capture).
  static String get camera2SnapshotFallbackUrl {
    final explicit = dotenv.env['CAMERA_2_SNAPSHOT_URL']?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final ip = camera2Ip;
    if (ip.startsWith('http://') || ip.startsWith('https://')) {
      return '$ip/capture';
    }
    return 'http://$ip/capture';
  }

  /// Chỉ chụp /capture (không mở MJPEG) — mượt hơn nếu stream không ổn.
  static bool get camera2SnapshotOnly =>
      dotenv.env['CAMERA_2_SNAPSHOT_ONLY']?.trim().toLowerCase() == 'true';

  /// Trang ESP32 DHCP Test: HTML + ảnh tĩnh (không MJPEG /stream).
  static bool get camera2HtmlPage {
    final raw = dotenv.env['CAMERA_2_HTML_PAGE']?.trim().toLowerCase();
    if (raw == 'false') return false;
    if (raw == 'true') return true;
    return false; // Mặc định dùng MJPEG stream
  }

  static String _cameraHost(String ipOrUrl) {
    var s = ipOrUrl.trim();
    if (s.startsWith('http://')) s = s.substring(7);
    if (s.startsWith('https://')) s = s.substring(8);
    final slash = s.indexOf('/');
    if (slash >= 0) s = s.substring(0, slash);
    return s;
  }
}
