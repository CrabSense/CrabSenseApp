import 'package:crab_farm_monitor_desktop/widgets/camera/camera_jpeg_fetch.dart';
import 'camera_stream_probe.dart';
import 'camera_stream_url_helper.dart';

class CameraEndpointTest {
  const CameraEndpointTest({
    required this.label,
    required this.url,
    required this.ok,
    required this.detail,
    required this.ms,
  });

  final String label;
  final String url;
  final bool ok;
  final String detail;
  final int ms;
}

class CameraConnectTestResult {
  const CameraConnectTestResult({
    required this.tests,
    this.error,
  });

  final List<CameraEndpointTest> tests;
  final String? error;

  bool get success => tests.any((t) => t.ok);
}

/// Kiểm tra ESP32: `/capture` trước, chờ, rồi thử `/stream` (từng URL ứng viên).
Future<CameraConnectTestResult> runCameraConnectTest({
  String? streamUrl,
  String? ipAddress,
}) async {
  final tests = <CameraEndpointTest>[];

  final captureBase = CameraStreamUrlHelper.snapshotFallback(
    streamUrl: streamUrl,
    ipAddress: ipAddress,
  );
  if (captureBase == null || captureBase.isEmpty) {
    return const CameraConnectTestResult(
      tests: [],
      error: 'Thiếu IP hoặc Stream URL để kiểm tra',
    );
  }

  final captureUri = Uri.parse(captureBase).replace(
    queryParameters: {
      ...Uri.parse(captureBase).queryParameters,
      '_': '${DateTime.now().millisecondsSinceEpoch}',
    },
  );
  final capSw = Stopwatch()..start();
  final jpeg = await fetchJpegUrl(captureUri.toString());
  capSw.stop();
  tests.add(
    CameraEndpointTest(
      label: 'Capture',
      url: captureBase,
      ok: jpeg != null,
      detail: jpeg != null
          ? 'JPEG ${jpeg.length} byte'
          : 'Không lấy được ảnh — đóng tab /stream trên browser trước',
      ms: capSw.elapsedMilliseconds,
    ),
  );

  await Future<void>.delayed(const Duration(milliseconds: 700));

  final streamUrls = CameraStreamUrlHelper.streamCandidates(
    streamUrl: streamUrl,
    ipAddress: ipAddress,
  );
  if (streamUrls.isEmpty) {
    return CameraConnectTestResult(tests: tests);
  }

  for (var i = 0; i < streamUrls.length; i++) {
    final url = streamUrls[i];
    final probe = await probeMjpegStreamUrl(url);
    tests.add(
      CameraEndpointTest(
        label: streamUrls.length > 1 ? 'Stream ${i + 1}' : 'Stream',
        url: url,
        ok: probe.ok,
        detail: probe.detail,
        ms: probe.ms,
      ),
    );
    if (probe.ok) break;
    if (i < streamUrls.length - 1) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  return CameraConnectTestResult(tests: tests);
}
