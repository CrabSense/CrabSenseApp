import 'dart:io';

/// Mở stream ngắn — đọc vài KB rồi đóng (ESP32 chỉ 1 client).
Future<({bool ok, String detail, int ms})> probeMjpegStreamUrl(String url) async {
  final sw = Stopwatch()..start();
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 8);
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set('Accept', '*/*');
    final response = await request.close().timeout(const Duration(seconds: 8));
    final status = response.statusCode;
    final type =
        response.headers.value('content-type')?.toLowerCase() ?? '';

    if (status != 200) {
      return (
        ok: false,
        detail: 'HTTP $status',
        ms: sw.elapsedMilliseconds,
      );
    }

    var received = 0;
    await for (final chunk in response.timeout(const Duration(seconds: 6))) {
      received += chunk.length;
      if (received >= 1024) break;
    }

    if (received == 0) {
      return (
        ok: false,
        detail: 'Không nhận byte từ stream',
        ms: sw.elapsedMilliseconds,
      );
    }

    final hint = type.contains('multipart')
        ? 'multipart OK'
        : type.contains('jpeg')
            ? 'image/jpeg'
            : 'đã nhận $received byte';
    return (ok: true, detail: hint, ms: sw.elapsedMilliseconds);
  } catch (e) {
    return (ok: false, detail: '$e', ms: sw.elapsedMilliseconds);
  } finally {
    client.close(force: true);
  }
}
