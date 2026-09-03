import 'package:http/http.dart' as http;

Future<({bool ok, String detail, int ms})> probeMjpegStreamUrl(String url) async {
  final sw = Stopwatch()..start();
  try {
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    request.headers['Accept'] = '*/*';
    final response = await client.send(request).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      client.close();
      return (
        ok: false,
        detail: 'HTTP ${response.statusCode}',
        ms: sw.elapsedMilliseconds,
      );
    }
    var received = 0;
    await for (final chunk in response.stream.timeout(const Duration(seconds: 6))) {
      received += chunk.length;
      if (received >= 1024) break;
    }
    client.close();
    if (received == 0) {
      return (
        ok: false,
        detail: 'Không nhận byte từ stream',
        ms: sw.elapsedMilliseconds,
      );
    }
    return (ok: true, detail: 'đã nhận $received byte', ms: sw.elapsedMilliseconds);
  } catch (e) {
    return (ok: false, detail: '$e', ms: sw.elapsedMilliseconds);
  }
}
