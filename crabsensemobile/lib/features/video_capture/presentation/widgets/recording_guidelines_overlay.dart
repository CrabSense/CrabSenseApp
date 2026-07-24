import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../bloc/bloc.dart' show VideoCaptureReady;
import '../bloc/video_capture_state.dart' show VideoCaptureReady;

/// Semi-transparent overlay that displays recording guidelines to the
/// operator before they start recording.
///
/// Shown only when the camera is in [VideoCaptureReady] state (i.e. not
/// during active recording). Displays three tips with icons:
///
/// - Distance (ruler) — "Hold 20-30 cm from crabs"
/// - Lighting (lightbulb) — "Ensure adequate lighting"
/// - Stability (pause) — "Keep device steady"
///
/// The overlay anchors to the bottom of the camera preview with a
/// semi-transparent dark background, white text, and rounded top
/// corners to match the CrabSense design language.
///
/// Requirements: 5.8
class RecordingGuidelinesOverlay extends StatelessWidget {
  const RecordingGuidelinesOverlay({super.key});

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    bottom: 120,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recording Tips',
                style: TextStyle(
                  color: CrabSenseColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 10),
              _GuidelineRow(icon: Icons.straighten_outlined, text: 'Hold 20-30 cm from crabs'),
              SizedBox(height: 8),
              _GuidelineRow(icon: Icons.lightbulb_outline, text: 'Ensure adequate lighting'),
              SizedBox(height: 8),
              _GuidelineRow(icon: Icons.pan_tool_outlined, text: 'Keep device steady'),
            ],
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Private helper
// ---------------------------------------------------------------------------

/// A single guideline row with an icon and descriptive text.
class _GuidelineRow extends StatelessWidget {
  const _GuidelineRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: CrabSenseColors.primary, size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text, style: const TextStyle(color: CrabSenseColors.textPrimary, fontSize: 13)),
      ),
    ],
  );
}
