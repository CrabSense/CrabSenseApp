import 'package:http/http.dart' as http;

/// Kết quả mở stream HTTP (web / fallback).
class MjpegStreamHandle {
  MjpegStreamHandle({
    required this.statusCode,
    required this.contentType,
    required this.byteStream,
    required this.close,
  });

  final int statusCode;
  final String contentType;
  final Stream<List<int>> byteStream;
  final void Function() close;
}

Future<MjpegStreamHandle> openMjpegStream(String url) async {
  final client = http.Client();
  final request = http.Request('GET', Uri.parse(url));
  request.headers['Accept'] = '*/*';
  request.headers['Connection'] = 'keep-alive';

  final response = await client.send(request).timeout(const Duration(seconds: 10));
  return MjpegStreamHandle(
    statusCode: response.statusCode,
    contentType: (response.headers['content-type'] ?? '').toLowerCase(),
    byteStream: response.stream,
    close: client.close,
  );
}
