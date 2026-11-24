import 'package:flutter_test/flutter_test.dart';
import 'package:crab_farm_monitor_desktop/config/preview_policy.dart';

void main() {
  bool allowed(String url, {bool debug = false, bool local = false, bool hosted = true}) =>
      PreviewPolicy.allows(uri: Uri.parse(url), debug: debug, localEnabled: local,
        hostedEnabled: hosted, hostedOrigin: 'https://desktop-preview.example.invalid');

  test('local debug remains loopback-only and opt-in', () {
    expect(allowed('http://localhost:5500', debug: true, local: true), isTrue);
    expect(allowed('http://localhost:5500', debug: true), isFalse);
    expect(allowed('http://192.168.1.1:5500', debug: true, local: true), isFalse);
  });
  test('hosted build only starts on configured HTTPS origin', () {
    expect(allowed('https://desktop-preview.example.invalid/'), isTrue);
    expect(allowed('http://desktop-preview.example.invalid/'), isFalse);
    expect(allowed('https://other.example.invalid/'), isFalse);
    expect(allowed('https://desktop-preview.example.invalid:8443/'), isFalse);
    expect(allowed('https://desktop-preview.example.invalid/', hosted: false), isFalse);
    expect(allowed('http://localhost:5500', local: true), isFalse);
  });
  test('hosted API must be a non-loopback HTTPS origin', () {
    expect(PreviewPolicy.validHostedApi('https://api-staging.example.invalid'), isTrue);
    expect(PreviewPolicy.validHostedApi('http://localhost:5080'), isFalse);
    expect(PreviewPolicy.validHostedApi('https://user:secret@example.invalid'), isFalse);
    expect(PreviewPolicy.validHostedApi('https://example.invalid?key=secret'), isFalse);
  });
}
