import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Displays the elapsed / remaining recording time during active recording.
///
/// Rendered near the top of the camera view. Shows:
/// - A pulsing red recording dot
/// - Elapsed/total time label formatted as "0:05 / 0:10"
/// - A linear progress bar that fills from left to right, transitioning
///   in colour from red to orange as the recording approaches its limit.
///
/// Requirements: 5.2, 5.3
class RecordingTimerDisplay extends StatefulWidget {
  const RecordingTimerDisplay({required this.elapsedSeconds, required this.maxSeconds, super.key});

  /// Elapsed recording time in whole seconds.
  final int elapsedSeconds;

  /// Maximum allowed recording duration in seconds.
  final int maxSeconds;

  @override
  State<RecordingTimerDisplay> createState() => _RecordingTimerDisplayState();
}

class _RecordingTimerDisplayState extends State<RecordingTimerDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Interpolates bar colour between red (start) and orange (full).
  Color _progressColor(double progress) =>
      Color.lerp(CrabSenseColors.error, CrabSenseColors.warning, progress)!;

  @override
  Widget build(BuildContext context) {
    final progress = widget.maxSeconds > 0
        ? (widget.elapsedSeconds / widget.maxSeconds).clamp(0.0, 1.0)
        : 0.0;

    final barColor = _progressColor(progress);

    return Positioned(
      top: 72,
      left: 16,
      right: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing red recording dot
                  FadeTransition(
                    opacity: _pulseAnimation,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: CrabSenseColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatTime(widget.elapsedSeconds)} '
                    '/ ${_formatTime(widget.maxSeconds)}',
                    style: const TextStyle(
                      color: CrabSenseColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
