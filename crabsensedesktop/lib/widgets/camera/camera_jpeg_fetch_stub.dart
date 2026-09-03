import 'dart:typed_data';

import 'package:http/http.dart' as http;

Future<Uint8List?> fetchJpegUrl(String url) async {
  try {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    final bytes = response.bodyBytes;
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return Uint8List.fromList(bytes);
    }
    return null;
  } catch (_) {
    return null;
  }
}
