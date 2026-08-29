import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// On web, centers the app in an iPhone-like frame so layout stays phone-sized
/// on a desktop browser (avoids full-bleed desktop redesign later).
class PhoneWebShell extends StatelessWidget {
  const PhoneWebShell({super.key, required this.child});

  final Widget child;

  /// Logical phone viewport (iPhone 14-ish).
  static const double phoneWidth = 390;
  static const double phoneHeight = 844;

  @override
  Widget build(BuildContext context) {
    // Phone frame on web + desktop previews so layout stays mobile-sized.
    final usePhoneFrame = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (!usePhoneFrame) return child;

    final screen = MediaQuery.sizeOf(context);
    final maxH = math.max(480.0, screen.height - 32);
    final frameH = math.min(phoneHeight, maxH);
    final frameW = math.min(phoneWidth, screen.width - 24);

    return ColoredBox(
      color: const Color(0xFF0B1220),
      child: Center(
        child: Container(
          width: frameW,
          height: frameH,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF334155), width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: Size(frameW, frameH),
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              viewPadding: const EdgeInsets.only(top: 12, bottom: 12),
              devicePixelRatio: 2,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
