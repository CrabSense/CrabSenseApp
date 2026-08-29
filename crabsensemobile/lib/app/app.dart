/// Root widget for the CrabSense mobile application.
///
/// Wires together the GoRouter, BLoC providers, theme, and localization
/// delegates into a single [MaterialApp.router] entry point.
///
/// Design ref: section 4.4 Navigation Architecture
/// Requirements: 1.1-1.10 (auth-aware routing),
///               14.4, 14.5, 14.8 (notification display + navigation),
///               18.5 (English + Vietnamese locale support),
///               20.1-20.3 (Material 3, dark theme as default),
///               22.1 (app launches quickly)
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../core/di/injection.dart';
import '../features/authentication/presentation/bloc/auth_bloc.dart';
import '../shared/bloc/sync/sync_bloc.dart';
import '../shared/bloc/sync/sync_event.dart';
import '../shared/services/notification_navigation_service.dart';

import '../shared/services/notification_service.dart';
import '../shared/widgets/notifications/notification_listener_widget.dart';
import 'router.dart';
import 'theme.dart';

/// Root widget of the CrabSense application.
///
/// Retrieves [AuthBloc] from the DI service locator and exposes it to the
/// entire widget tree via [BlocProvider]. The GoRouter instance is created
/// once and held for the lifetime of the widget.
///
/// Requirements: 1.1-1.10, 18.5, 20.1-20.3, 22.1
class CrabSenseApp extends StatefulWidget {
  const CrabSenseApp({super.key});

  @override
  State<CrabSenseApp> createState() => _CrabSenseAppState();
}

class _CrabSenseAppState extends State<CrabSenseApp> {
  // Resolved once from DI; the same instance is passed to createRouter so
  // the auth guard and the BlocProvider share the same bloc stream.
  late final AuthBloc _authBloc;
  late final SyncBloc _syncBloc;

  // GoRouter is created once and reused; recreating it on every build would
  // reset navigation state and cause flicker.
  late final GoRouter _router;

  // Notification services — created after the router so that
  // NotificationNavigationService can hold a reference to the router.
  // Requirements: 14.4, 14.5, 14.8
  late final NotificationNavigationService _notificationNavService;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>();
    _syncBloc = sl<SyncBloc>()..add(const SyncStarted());
    _router = createRouter(_authBloc);
    _notificationNavService = NotificationNavigationService(router: _router, logger: sl<Logger>());
  }

  @override
  void dispose() {
    _authBloc.close();
    _syncBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: _authBloc),
      BlocProvider<SyncBloc>.value(value: _syncBloc),
    ],
    child: MaterialApp.router(
      // ── Identity ───────────────────────────────────────────────────
      title: 'CrabSense',
      debugShowCheckedModeBanner: false,

      // ── Theme (Req 20.1-20.3) ──────────────────────────────────────
      // Light theme is the default (friendly aquaculture design).
      theme: CrabSenseTheme.lightTheme,
      themeMode: ThemeMode.light,

      // ── Router ────────────────────────────────────────────────────
      routerConfig: _router,

      // ── Localisation (Req 18.5) ────────────────────────────────────
      // Supports English (en) and Vietnamese (vi).
      locale: const Locale('en'),
      supportedLocales: const [
        Locale('en'), // English
        Locale('vi'), // Vietnamese
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Notification banner overlay ────────────────────────────────
      //
      // builder wraps every route's widget tree with
      // [NotificationListenerWidget] so that:
      //   - Foreground messages trigger the in-app banner overlay
      //     (Req 14.4, 14.8).
      //   - Notification taps navigate to the relevant screen
      //     (Req 14.5).
      //   - The initial message (terminated-state tap) is checked
      //     on startup.
      builder: (context, child) => NotificationListenerWidget(
        notificationService: sl<NotificationService>(),
        navigationService: _notificationNavService,
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}
