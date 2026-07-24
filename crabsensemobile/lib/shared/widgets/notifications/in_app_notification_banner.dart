/// In-app notification banner overlay for foreground notifications.
///
/// Displays a slide-in banner from the top of the screen when a push
/// notification is received while the app is in the foreground.
///
/// The banner:
///   - Slides in from the top with an animation.
///   - Auto-dismisses after [autoDismissDuration] (default 4 seconds).
///   - Can be dismissed manually by swiping up or tapping the × button.
///   - Navigates to the relevant screen when tapped.
///   - Uses category-specific accent colours.
///
/// Requirements: 14.4, 14.8
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../services/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Banner entry point – overlay helper
// ─────────────────────────────────────────────────────────────────────────────

/// Displays an [InAppNotificationBanner] in the [Overlay] of the
/// nearest [Navigator].
///
/// [message]   – the incoming [RemoteMessage].
/// [onTap]     – called when the user taps the banner; receives the
///               [RemoteMessage] so the caller can navigate.
///
/// Requirements: 14.4, 14.8
void showInAppNotificationBanner({
  required BuildContext context,
  required RemoteMessage message,
  required void Function(RemoteMessage message) onTap,
  Duration autoDismissDuration = const Duration(seconds: 4),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => InAppNotificationBanner(
      message: message,
      onTap: () {
        entry.remove();
        onTap(message);
      },
      onDismiss: entry.remove,
      autoDismissDuration: autoDismissDuration,
    ),
  );

  overlay.insert(entry);
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner widget
// ─────────────────────────────────────────────────────────────────────────────

/// Animated slide-in banner that appears at the top of the screen.
///
/// Intended to be inserted into the [Overlay] via
/// [showInAppNotificationBanner]; it should not be placed directly in a
/// widget tree.
///
/// Requirements: 14.4, 14.8
class InAppNotificationBanner extends StatefulWidget {
  const InAppNotificationBanner({
    required this.message,
    required this.onTap,
    required this.onDismiss,
    super.key,
    this.autoDismissDuration = const Duration(seconds: 4),
  });

  /// The incoming push notification.
  final RemoteMessage message;

  /// Called when the user taps the banner body.
  final VoidCallback onTap;

  /// Called when the banner is dismissed (by swipe, timeout, or ×).
  final VoidCallback onDismiss;

  /// How long to wait before auto-dismissing.
  final Duration autoDismissDuration;

  @override
  State<InAppNotificationBanner> createState() => _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  Timer? _dismissTimer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Slide in.
    _controller.forward();

    // Schedule auto-dismiss.
    _dismissTimer = Timer(widget.autoDismissDuration, _animateDismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _animateDismiss() async {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    _dismissTimer?.cancel();
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  // ── Category styling ──────────────────────────────────────────────────────

  Color _accentColor(String category) {
    switch (category) {
      case NotificationCategory.criticalAlert:
        return const Color(0xFFEF5350); // Red
      case NotificationCategory.warning:
        return const Color(0xFFFFB300); // Amber
      case NotificationCategory.taskReminder:
        return const Color(0xFF00C8FF); // CrabSense primary
      case NotificationCategory.systemUpdate:
        return const Color(0xFF66BB6A); // Green
      default:
        return const Color(0xFF00C8FF);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case NotificationCategory.criticalAlert:
        return Icons.warning_amber_rounded;
      case NotificationCategory.warning:
        return Icons.info_outline_rounded;
      case NotificationCategory.taskReminder:
        return Icons.task_alt_rounded;
      case NotificationCategory.systemUpdate:
        return Icons.system_update_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _categoryLabel(String category) {
    switch (category) {
      case NotificationCategory.criticalAlert:
        return 'Critical Alert';
      case NotificationCategory.warning:
        return 'Warning';
      case NotificationCategory.taskReminder:
        return 'Task Reminder';
      case NotificationCategory.systemUpdate:
        return 'System Update';
      default:
        return 'Notification';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final notification = widget.message.notification;
    final category = widget.message.data['category'] as String? ?? '';
    final title = notification?.title ?? '';
    final body = notification?.body ?? '';
    final accent = _accentColor(category);
    final icon = _categoryIcon(category);
    final label = _categoryLabel(category);

    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Dismissible(
            key: ValueKey(widget.message.messageId ?? label),
            direction: DismissDirection.up,
            onDismissed: (_) => _animateDismiss(),
            child: GestureDetector(
              onTap: () {
                _dismissTimer?.cancel();
                widget.onTap();
              },
              child: Container(
                margin: EdgeInsets.only(top: topPadding + 8, left: 12, right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1F3D).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: accent.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Category accent bar ─────────────────────────
                      Container(height: 3, color: accent),
                      // ── Content ─────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: accent, size: 20),
                            ),
                            const SizedBox(width: 10),
                            // Text content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category label
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // Title
                                  if (title.isNotEmpty)
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  // Body
                                  if (body.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        body,
                                        style: const TextStyle(
                                          color: Color(0xFFB0BEC5),
                                          fontSize: 12.5,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Dismiss button
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFF78909C),
                              ),
                              onPressed: _animateDismiss,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
