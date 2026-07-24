/// GoRouter configuration for the CrabSense mobile application.
///
/// Defines the complete route tree, authentication guards, deep-link
/// support, and a navigation observer stub.
///
/// Design ref: section 4.4 Navigation Architecture
/// Requirements: 1.3 (redirect on token expiry),
///               1.7 (offline auth error),
///               17.1 (traceability public access, ≤ 500 ms QR decode)
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection.dart';
import '../features/authentication/presentation/bloc/auth_bloc.dart';
import '../features/authentication/presentation/bloc/auth_event.dart';
import '../features/authentication/presentation/bloc/auth_state.dart';
import '../features/authentication/presentation/bloc/biometric_cubit.dart';
import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/alert/presentation/screens/alerts_screen.dart';
import '../features/box/domain/usecases/get_box_details_usecase.dart';
import '../features/box/presentation/bloc/box_bloc.dart';
import '../features/box/presentation/screens/box_details_screen.dart';
import '../features/box/presentation/screens/box_camera_screen.dart';
import '../features/box_management/presentation/screens/boxes_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/manual_inspection/domain/repositories/inspection_repository.dart';
import '../features/manual_inspection/domain/usecases/submit_feedback_use_case.dart';
import '../features/manual_inspection/domain/usecases/submit_inspection_use_case.dart';
import '../features/manual_inspection/presentation/bloc/bloc.dart';
import '../features/manual_inspection/presentation/screens/inspection_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/qr_scanner/presentation/bloc/bloc.dart';
import '../features/qr_scanner/presentation/screens/qr_scanner_screen.dart';
import '../features/video_capture/domain/usecases/get_ai_results_usecase.dart';
import '../features/video_capture/presentation/bloc/bloc.dart';
import '../features/video_capture/presentation/screens/ai_results_screen.dart';
import '../features/video_capture/presentation/screens/video_capture_screen.dart';
import '../features/harvest/presentation/screens/harvest_screen.dart';
import '../features/notifications/presentation/screens/notification_history_screen.dart';
import '../features/water_quality/presentation/screens/water_quality_screen.dart';
import '../features/sales/presentation/screens/sales_screen.dart';
import '../features/operation_logs/domain/entities/operation_log.dart';
import '../features/operation_logs/presentation/screens/operation_log_screen.dart';
import 'scaffold_with_navbar.dart';
import 'routes.dart';

// ── Placeholder helper ────────────────────────────────────────────────────────

/// Returns a minimal placeholder [Scaffold] for screens not yet implemented.
Widget _placeholder(String title) => Scaffold(
  backgroundColor: const Color(0xFF081528),
  appBar: AppBar(
    title: Text(title),
    backgroundColor: const Color(0xFF0F1F3D),
    foregroundColor: Colors.white,
  ),
  body: Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.construction_rounded,
          size: 64,
          color: Color(0xFF00C8FF),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // ignore: avoid_hardcoded_text
        const Text(
          '// implement screen',
          style: TextStyle(
            color: Color(0xFF00C8FF),
            fontSize: 14,
            fontFamily: 'monospace',
          ),
        ),
      ],
    ),
  ),
);

// ── Auth state notifier ───────────────────────────────────────────────────────

/// Bridges [AuthBloc] state changes → [GoRouter.refreshListenable].
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(AuthBloc authBloc) {
    _subscription = authBloc.stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ── Router factory ────────────────────────────────────────────────────────────

/// Builds and returns the application [GoRouter].
GoRouter createRouter(AuthBloc authBloc) {
  final notifier = _AuthStateNotifier(authBloc);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: notifier,
    observers: [CrabSenseNavigationObserver()],
    redirect: (context, state) {
      final authState = authBloc.state;
      final path = state.fullPath ?? state.uri.path;

      final isAuthenticated = authState is Authenticated;
      final isInitializing = authState is AuthInitial;

      if (isInitializing) {
        return path == RoutePaths.splash ? null : RoutePaths.splash;
      }

      if (!isAuthenticated) {
        final isAllowedUnauthenticatedPath =
            path == RoutePaths.login || path.startsWith('/traceability');
        return isAllowedUnauthenticatedPath ? null : RoutePaths.login;
      }

      if (isAuthenticated &&
          (path == RoutePaths.login || path == RoutePaths.splash)) {
        return RoutePaths.dashboard;
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF081528),
      appBar: AppBar(
        title: const Text('Page Not Found'),
        backgroundColor: const Color(0xFF0F1F3D),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Color(0xFFEF5350),
            ),
            const SizedBox(height: 16),
            const Text(
              '404 — Page Not Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.dashboard),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C8FF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      // ── / — Splash / Loading ─────────────────────────────────────────
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => _SplashScreen(authBloc: authBloc),
      ),

      // ── /login ───────────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<BiometricCubit>(create: (_) => sl<BiometricCubit>()),
          ],
          child: const LoginScreen(),
        ),
      ),

      // ── ShellRoute for persistent Bottom Navigation Bar ─────────────
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          // ── /dashboard ───────────────────────────────────────────────────
          GoRoute(
            path: RoutePaths.dashboard,
            name: RouteNames.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),

          // ── /boxes ───────────────────────────────────────────────────────
          GoRoute(
            path: RoutePaths.boxes,
            name: RouteNames.boxes,
            builder: (context, state) => const BoxesScreen(),
          ),

          // ── /scanner ─────────────────────────────────────────────────────
          GoRoute(
            path: RoutePaths.scanner,
            name: RouteNames.scanner,
            builder: (context, state) => BlocProvider<ScannerBloc>(
              create: (_) => sl<ScannerBloc>(),
              child: const QRScannerScreen(),
            ),
          ),

          // ── /water-quality ───────────────────────────────────────────────
          GoRoute(
            path: RoutePaths.waterQuality,
            name: RouteNames.waterQuality,
            builder: (context, state) {
              final farmId =
                  state.uri.queryParameters['farmingAreaId'] ??
                  state.uri.queryParameters['farmId'];
              return WaterQualityScreen(farmId: farmId);
            },
          ),

          // ── /alerts ──────────────────────────────────────────────────────
          GoRoute(
            path: RoutePaths.alerts,
            name: RouteNames.alerts,
            builder: (context, state) => const AlertsScreen(),
          ),

          // ── /sales ───────────────────────────────────────────────────────
          GoRoute(
            path: RoutePaths.sales,
            name: RouteNames.sales,
            builder: (context, state) {
              final farmId = state.uri.queryParameters['farmingAreaId'] ??
                  state.uri.queryParameters['farmId'];
              // boxId reserved for future sales-by-box filter; farm context used today.
              return SalesScreen(initialFarmId: farmId);
            },
          ),

          // ── /profile ─────────────────────────────────────────────────────
          GoRoute(
            path: RoutePaths.profile,
            name: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ── /box/:id ─────────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.boxDetailsTemplate,
        name: RouteNames.boxDetails,
        builder: (context, state) {
          final id = state.pathParameters[RouteParams.boxId] ?? '';
          return BlocProvider<BoxBloc>(
            create: (_) => BoxBloc(getBoxDetails: sl<GetBoxDetailsUseCase>()),
            child: BoxDetailsScreen(boxId: id),
          );
        },
        routes: [
          GoRoute(
            path: 'video',
            name: RouteNames.boxVideo,
            builder: (context, state) {
              final id = state.pathParameters[RouteParams.boxId] ?? '';
              return BlocProvider<VideoCaptureBloc>(
                create: (_) => sl<VideoCaptureBloc>(),
                child: VideoCaptureScreen(boxId: id),
              );
            },
          ),
          GoRoute(
            path: 'inspect',
            name: RouteNames.boxInspect,
            builder: (context, state) {
              final id = state.pathParameters[RouteParams.boxId] ?? '';
              final extra = state.extra;
              final operatorId = extra is Map<String, dynamic>
                  ? (extra['operatorId'] as String? ?? '')
                  : '';
              final operatorName = extra is Map<String, dynamic>
                  ? (extra['operatorName'] as String? ?? '')
                  : '';
              final videoId = extra is Map<String, dynamic>
                  ? extra['videoId'] as String?
                  : null;
              return BlocProvider<InspectionBloc>(
                create: (_) => InspectionBloc(
                  submitInspection: sl<SubmitInspectionUseCase>(),
                  submitFeedback: sl<SubmitFeedbackUseCase>(),
                  repository: sl<InspectionRepository>(),
                  getAiResults: sl<GetAIResultsUseCase>(),
                  logger: sl(),
                ),
                child: InspectionScreen(
                  boxId: id,
                  operatorId: operatorId,
                  operatorName: operatorName,
                  videoId: videoId,
                ),
              );
            },
          ),
          GoRoute(
            path: 'camera',
            name: RouteNames.boxCamera,
            builder: (context, state) {
              final id = state.pathParameters[RouteParams.boxId] ?? '';
              return BoxCameraScreen(boxId: id);
            },
          ),
        ],
      ),

      // ── /operations ──────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.operations,
        name: RouteNames.operations,
        builder: (context, state) {
          final authState = authBloc.state;
          final user = authState is Authenticated ? authState.user : null;
          final existingLog = state.extra is OperationLog
              ? state.extra as OperationLog
              : null;
          final initialBoxId = state.uri.queryParameters['boxId'];
          return OperationLogScreen(
            operatorId: user?.id ?? '',
            operatorName: user?.name ?? 'Unknown Operator',
            userRole: user?.role,
            existingLog: existingLog,
            initialBoxId: initialBoxId,
          );
        },
      ),

      // ── /harvest ─────────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.harvest,
        name: RouteNames.harvest,
        builder: (context, state) {
          final authState = authBloc.state;
          final user = authState is Authenticated ? authState.user : null;
          final extra = state.extra;
          String? initialBoxId = state.uri.queryParameters['boxId'];
          String? initialFarmId = state.uri.queryParameters['farmId'] ??
              state.uri.queryParameters['farmingAreaId'];
          if (extra is Map<String, dynamic>) {
            initialBoxId ??= extra['boxId'] as String?;
            initialFarmId ??= extra['farmId'] as String?;
          } else if (extra is String) {
            initialBoxId ??= extra;
          }
          return HarvestScreen(
            initialBoxId: initialBoxId,
            initialFarmId: initialFarmId,
            operatorId: user?.id,
            operatorName: user?.fullName,
            userRole: user?.role,
          );
        },
      ),

      // ── /notifications ───────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.notificationHistory,
        name: RouteNames.notificationHistory,
        builder: (context, state) => const NotificationHistoryScreen(),
      ),

      // ── /ai-results/:videoId ─────────────────────────────────────────
      GoRoute(
        path: RoutePaths.aiResultsTemplate,
        name: RouteNames.aiResults,
        builder: (context, state) {
          final vid = state.pathParameters[RouteParams.videoId] ?? '';
          final extra = state.extra;
          final boxId = extra is Map<String, dynamic>
              ? (extra['boxId'] as String? ?? '')
              : '';
          return AiResultsScreen(videoId: vid, boxId: boxId);
        },
      ),

      // ── /traceability/:productId — PUBLIC ─────────────────────────────
      GoRoute(
        path: RoutePaths.traceabilityTemplate,
        name: RouteNames.traceability,
        builder: (context, state) {
          final productId = state.pathParameters[RouteParams.productId] ?? '';
          return _placeholder('Traceability — $productId');
        },
      ),
    ],
  );
}

// ── Splash screen ─────────────────────────────────────────────────────────────

class _SplashScreen extends StatefulWidget {
  const _SplashScreen({required this.authBloc});

  final AuthBloc authBloc;

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.authBloc.add(const AuthenticationStatusRequested());
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && widget.authBloc.state is AuthInitial) {
        widget.authBloc.add(const LogoutRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF081528),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.waves_rounded, size: 80, color: Color(0xFF00C8FF)),
          SizedBox(height: 24),
          Text(
            'CrabSense',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C8FF)),
            ),
          ),
        ],
      ),
    ),
  );
}

class CrabSenseNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
