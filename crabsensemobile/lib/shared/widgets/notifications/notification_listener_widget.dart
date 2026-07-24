/// Widget that subscribes to [NotificationService] streams and handles
/// foreground in-app banners and notification tap navigation.
///
/// Insert this widget near the root of the authenticated widget tree so it
/// has access to the [Overlay] needed for banner display and shares the
/// [GoRouter] instance used for navigation.
///
/// Responsibilities:
///   - Listens to [NotificationService.foregroundMessages] and shows
///     [InAppNotificationBanner] overlay entries (Req 14.8).
///   - Listens to [NotificationService.notificationTaps] and calls
///     [NotificationNavigationService.navigate] (Req 14.5).
///   - On first build, checks [FirebaseMessaging.getInitialMessage] for
///     taps that launched the app from terminated state (Req 14.5).
///
/// Requirements: 14.4, 14.5, 14.8
library;

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../services/notification_navigation_service.dart';
import '../../services/notification_service.dart';
import 'in_app_notification_banner.dart';

/// Wraps [child] with notification stream subscriptions.
///
/// Must be placed below the [MaterialApp] / [OverlayPortal] so that
/// [Overlay.of(context)] resolves correctly.
///
/// Requirements: 14.4, 14.5, 14.8
class NotificationListenerWidget extends StatefulWidget {
  const NotificationListenerWidget({
    required this.child,
    required this.notificationService,
    required this.navigationService,
    super.key,
  });

  final Widget child;
  final NotificationService notificationService;
  final NotificationNavigationService navigationService;

  @override
  State<NotificationListenerWidget> createState() => _NotificationListenerWidgetState();
}

class _NotificationListenerWidgetState extends State<NotificationListenerWidget> {
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _tapSub;

  @override
  void initState() {
    super.initState();
    _subscribeToStreams();
    _handleInitialMessage();
  }

  @override
  void dispose() {
    _foregroundSub?.cancel();
    _tapSub?.cancel();
    super.dispose();
  }

  // ── Stream subscriptions ──────────────────────────────────────────────────

  /// Subscribe to foreground message and tap streams.
  void _subscribeToStreams() {
    // Foreground messages → show in-app banner.
    _foregroundSub = widget.notificationService.foregroundMessages.listen(_onForegroundMessage);

    // Notification taps (background / terminated) → navigate.
    _tapSub = widget.notificationService.notificationTaps.listen(_onNotificationTap);
  }

  // ── Message handlers ──────────────────────────────────────────────────────

  /// Shows an [InAppNotificationBanner] for a foreground message.
  ///
  /// Requirements: 14.4, 14.8
  void _onForegroundMessage(RemoteMessage message) {
    // Only show banner if there is actual notification content.
    if (message.notification == null && (message.data['category'] == null)) {
      return;
    }

    if (!mounted) return;

    showInAppNotificationBanner(
      context: context,
      message: message,
      onTap: (msg) => widget.navigationService.navigate(msg),
    );
  }

  /// Navigates to the relevant screen when a notification is tapped
  /// while the app is in the background (or the tap comes from a local
  /// notification shown in the foreground).
  ///
  /// Requirements: 14.5
  void _onNotificationTap(RemoteMessage message) {
    if (!mounted) return;
    widget.navigationService.navigate(message);
  }

  /// Checks for a notification that launched the app from terminated state.
  ///
  /// [FirebaseMessaging.getInitialMessage] returns the [RemoteMessage] that
  /// caused the app to open from a completely terminated state.  This must be
  /// checked on startup so the app navigates to the correct screen.
  ///
  /// Requirements: 14.5
  Future<void> _handleInitialMessage() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null && mounted) {
        // Add a small delay so the router has finished its initial
        // redirect (auth check) before we push an additional route.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          widget.navigationService.navigate(initialMessage);
        }
      }
    } catch (_) {
      // Non-fatal: if initial message check fails or Firebase is disabled,
      // the app still opens normally.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
