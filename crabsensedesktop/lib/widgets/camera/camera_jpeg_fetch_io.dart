import 'dart:io';
import 'dart:typed_data';

/// GET một ảnh JPEG — mỗi lần một [HttpClient] (tránh giữ socket khi ESP32 chỉ 1 client).
Future<Uint8List?> fetchJpegUrl(String url) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 8);
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close().timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;

    final chunks = <List<int>>[];
    var total = 0;
    await for (final chunk in response) {
      chunks.add(chunk);
      total += chunk.length;
      if (total > 4 * 1024 * 1024) return null;
    }
    final bytes = Uint8List(total);
    var offset = 0;
    for (final chunk in chunks) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return bytes;
    }
    return null;
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
