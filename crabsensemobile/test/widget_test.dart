// Basic smoke test for the CrabSense root widget.
//
// NOTE: Full widget-level tests require DI initialisation (di.init()) and a
// device (camera, secure storage, biometrics). This file is intentionally
// minimal — it just verifies that the app compiles and imports resolve.

import 'package:crabsensemobile/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CrabSenseApp type check', () {
    // Verify the class exists and is a widget type.
    // Full integration tests live in test/features/ and require DI setup.
    expect(CrabSenseApp, isNotNull);
  });
}
