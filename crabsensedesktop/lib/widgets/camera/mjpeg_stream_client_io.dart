import 'dart:async';
import 'dart:io';

import 'mjpeg_stream_client_stub.dart' show MjpegStreamHandle;

/// Windows/desktop: [HttpClient] ổn định hơn với MJPEG dài của ESP32.
Future<MjpegStreamHandle> openMjpegStream(String url) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 10);

  final request = await client.getUrl(Uri.parse(url));
  request.headers.set('Accept', '*/*');
  request.headers.set('Connection', 'keep-alive');

  final response = await request.close();
  final contentType =
      (response.headers.contentType?.mimeType ?? '').toLowerCase();
  final fullType = response.headers.value('content-type')?.toLowerCase() ??
      contentType;

  return MjpegStreamHandle(
    statusCode: response.statusCode,
    contentType: fullType,
    byteStream: response.map((chunk) => chunk),
    close: () => client.close(force: true),
  );
}
