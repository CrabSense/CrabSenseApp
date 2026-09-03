/// Gợi ý URL MJPEG / snapshot cho ESP32-CAM khi DB chỉ lưu IP hoặc URL gốc.
abstract final class CameraStreamUrlHelper {
  static List<String> streamCandidates({
    String? streamUrl,
    String? ipAddress,
  }) {
    final seen = <String>{};
    final out = <String>[];
    void add(String u) {
      final t = u.trim();
      if (t.isEmpty || seen.contains(t)) return;
      seen.add(t);
      out.add(t);
    }

    final host = _resolveHost(streamUrl: streamUrl, ipAddress: ipAddress);
    if (host.isEmpty) {
      final raw = streamUrl?.trim();
      if (raw != null && raw.isNotEmpty) add(raw);
      return out;
    }

    final raw = streamUrl?.trim() ?? '';
    if (raw.isNotEmpty && _isBareHostUrl(raw, host)) {
      // ESP32-CAM mặc định port 80 — /stream (đã xác nhận trên browser).
      add('http://$host/stream');
      add('http://$host:81/stream');
      add(raw);
    } else if (raw.isNotEmpty && !_looksLikeMjpegEndpoint(raw)) {
      add('http://$host/stream');
      add('http://$host:81/stream');
      add(raw);
    } else if (raw.isNotEmpty) {
      add(raw);
      if (!raw.toLowerCase().contains('/stream')) {
        add('http://$host/stream');
      }
      if (!raw.contains(':81/stream')) {
        add('http://$host:81/stream');
      }
    } else {
      add('http://$host/stream');
      add('http://$host:81/stream');
    }

    return out;
  }

  static String? snapshotFallback({
    String? streamUrl,
    String? ipAddress,
  }) {
    final host = _resolveHost(streamUrl: streamUrl, ipAddress: ipAddress);
    if (host.isEmpty) return null;

    final raw = streamUrl?.trim() ?? '';
    if (raw.contains(':81')) {
      return 'http://$host:81/capture';
    }
    return 'http://$host/capture';
  }

  /// Host lấy từ [streamUrl] trước — tránh lệch với [ipAddress] trong DB.
  static String? streamHost({String? streamUrl, String? ipAddress}) {
    final h = _resolveHost(streamUrl: streamUrl, ipAddress: ipAddress);
    return h.isEmpty ? null : h;
  }

  static bool ipMismatch(String? streamUrl, String? ipAddress) {
    final fromStream = streamUrl == null ? '' : _extractHost(streamUrl);
    final fromIp = ipAddress?.trim() ?? '';
    if (fromStream.isEmpty || fromIp.isEmpty) return false;
    return fromStream != fromIp;
  }

  static String _resolveHost({String? streamUrl, String? ipAddress}) {
    if (streamUrl != null && streamUrl.trim().isNotEmpty) {
      final h = _extractHost(streamUrl);
      if (h.isNotEmpty) return h;
    }
    if (ipAddress != null && ipAddress.trim().isNotEmpty) {
      return _extractHost(ipAddress);
    }
    return '';
  }

  static String _extractHost(String value) {
    var s = value.trim();
    if (s.startsWith('http://')) s = s.substring(7);
    if (s.startsWith('https://')) s = s.substring(8);
    if (s.startsWith('rtsp://')) s = s.substring(7);

    final at = s.indexOf('@');
    if (at >= 0) s = s.substring(at + 1);

    final slash = s.indexOf('/');
    if (slash >= 0) s = s.substring(0, slash);

    final colon = s.indexOf(':');
    if (colon >= 0) s = s.substring(0, colon);

    return s.trim();
  }

  static bool _isBareHostUrl(String url, String host) {
    final lower = url.toLowerCase();
    return lower == 'http://$host' ||
        lower == 'http://$host/' ||
        lower == 'https://$host' ||
        lower == 'https://$host/';
  }

  static bool hasMjpegEndpoint(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    return _looksLikeMjpegEndpoint(url);
  }

  static bool _looksLikeMjpegEndpoint(String url) {
    final lower = url.toLowerCase();
    return lower.contains('/stream') ||
        lower.contains(':81/') ||
        lower.startsWith('rtsp://');
  }
}
