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
import '../core/theme/app_colors.dart';
import '../features/home/presentation/widgets/home_palette.dart';
import '../features/authentication/presentation/bloc/auth_bloc.dart';
import '../features/authentication/presentation/bloc/auth_event.dart';
import '../features/authentication/presentation/bloc/auth_state.dart';
import '../features/authentication/presentation/bloc/biometric_cubit.dart';
import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/authentication/presentation/screens/crab_splash_screen.dart';
import '../features/alert/presentation/screens/alerts_screen.dart';
import '../features/box/domain/usecases/get_box_details_usecase.dart';
import '../features/box/presentation/bloc/box_bloc.dart';
import '../features/box/presentation/screens/box_details_screen.dart';
import '../features/box/presentation/screens/box_camera_screen.dart';
import '../features/box/presentation/screens/crab_list_screen.dart';
import '../features/box/presentation/screens/crab_detail_screen.dart';
import '../features/box/data/models/crab_model.dart';
import '../features/box_management/presentation/screens/boxes_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/manual_inspection/domain/repositories/inspection_repository.dart';
import '../features/manual_inspection/domain/usecases/submit_feedback_use_case.dart';
import '../features/manual_inspection/domain/usecases/submit_inspection_use_case.dart';
import '../features/manual_inspection/presentation/bloc/bloc.dart';
import '../features/manual_inspection/presentation/screens/inspection_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/change_password_screen.dart';
import '../features/profile/presentation/screens/notification_settings_screen.dart';
import '../features/devices/presentation/screens/devices_screen.dart';
import '../features/ai_center/presentation/screens/ai_center_screen.dart';
import '../features/ai_center/data/models/ai_center_models.dart';
import '../features/mineral_dosing/presentation/screens/mineral_dosing_screen.dart';
import '../features/reports/data/models/report_models.dart';
import '../features/reports/presentation/screens/reports_hub_screen.dart';
import '../features/profile/presentation/screens/offline_sync_screen.dart';
import '../features/profile/presentation/screens/app_settings_screen.dart';
import '../features/profile/presentation/screens/security_privacy_screen.dart';
import '../features/profile/presentation/screens/help_support_screen.dart';
import '../features/profile/presentation/screens/legal_document_screen.dart';
import '../features/firebase_hub/presentation/screens/firebase_hub_screen.dart';
import '../features/firebase_hub/data/firebase_hub_models.dart';
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
import '../features/stock_management/presentation/screens/add_crab_screen.dart';
import '../features/stock_management/presentation/screens/crab_tracking_screen.dart';
import '../features/crab_management/presentation/screens/crab_management_screen.dart';
import '../features/operation_logs/domain/entities/operation_log.dart';
import '../features/operation_logs/presentation/screens/operation_history_screen.dart';
import '../features/operation_logs/presentation/screens/operation_log_screen.dart';
import '../features/scheduled_tasks/presentation/scheduled_tasks_screen.dart';
import 'scaffold_with_navbar.dart';
import 'routes.dart';
import '../widgets/branded_loading_screen.dart';

// ── Placeholder helper ────────────────────────────────────────────────────────

/// Returns a minimal placeholder [Scaffold] for screens not yet implemented.
Widget _placeholder(String title) => Scaffold(
  backgroundColor: const Color(0xFFF5F7FA),
  appBar: AppBar(
    title: Text(title),
    backgroundColor: const Color(0xFFFFFFFF),
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
            color: kHomeTextMain,
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Page Not Found'),
        backgroundColor: const Color(0xFFFFFFFF),
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
                color: kHomeTextMain,
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
                backgroundColor: const Color(0xFF2ECC71),
                foregroundColor: Colors.white,
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
        builder: (context, state) => CrabSplashScreen(authBloc: authBloc),
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
              final farmId =
                  state.uri.queryParameters['farmingAreaId'] ??
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
          GoRoute(
            path: 'crabs',
            name: RouteNames.boxCrabs,
            builder: (context, state) {
              final id = state.pathParameters[RouteParams.boxId] ?? '';
              final boxCode =
                  state.uri.queryParameters['boxCode'] ??
                  (state.extra is String ? state.extra as String? : null);
              return CrabListScreen(boxId: id, boxCode: boxCode);
            },
          ),
        ],
      ),

      // ── /crab/:crabId ────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.crabDetailsTemplate,
        name: RouteNames.crabDetails,
        builder: (context, state) {
          final crabId = state.pathParameters[RouteParams.crabId] ?? '';
          final boxId = state.uri.queryParameters['boxId'];
          final boxCode = state.uri.queryParameters['boxCode'];
          final extra = state.extra;
          final initial = extra is CrabModel ? extra : null;
          return CrabDetailScreen(
            crabId: crabId,
            boxId: boxId,
            boxCode: boxCode,
            initial: initial,
          );
        },
      ),

      // ── /profile/edit|change-password|notifications + /devices ──────
      GoRoute(
        path: RoutePaths.devices,
        name: RouteNames.devices,
        builder: (context, state) {
          final type = state.uri.queryParameters['type'];
          return DevicesScreen(initialType: type);
        },
      ),
      GoRoute(
        path: RoutePaths.aiCenter,
        name: RouteNames.aiCenter,
        builder: (context, state) {
          final tab = switch (state.uri.queryParameters['tab']) {
            'detections' => AiCenterTab.detections,
            'recommendations' => AiCenterTab.recommendations,
            _ => AiCenterTab.overview,
          };
          return AiCenterScreen(initialTab: tab);
        },
      ),
      GoRoute(
        path: RoutePaths.mineralDosing,
        name: RouteNames.mineralDosing,
        builder: (context, state) => const MineralDosingScreen(),
      ),
      GoRoute(
        path: RoutePaths.reports,
        name: RouteNames.reports,
        builder: (context, state) {
          final kind = ReportKindX.fromQuery(state.uri.queryParameters['type']);
          return ReportsHubScreen(initialKind: kind);
        },
      ),
      GoRoute(
        path: RoutePaths.offlineSync,
        name: RouteNames.offlineSync,
        builder: (context, state) => const OfflineSyncScreen(),
      ),
      GoRoute(
        path: RoutePaths.appSettings,
        name: RouteNames.appSettings,
        builder: (context, state) => const AppSettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.securityPrivacy,
        name: RouteNames.securityPrivacy,
        builder: (context, state) => const SecurityPrivacyScreen(),
      ),
      GoRoute(
        path: RoutePaths.helpSupport,
        name: RouteNames.helpSupport,
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: RoutePaths.appInfo,
        name: RouteNames.appInfo,
        builder: (context, state) => const AppInfoScreen(),
      ),
      GoRoute(
        path: RoutePaths.legalDocument,
        name: RouteNames.legalDocument,
        builder: (context, state) {
          final extra = state.extra;
          final args = extra is LegalDocumentArgs
              ? extra
              : LegalDocumentArgs.terms;
          return LegalDocumentScreen(args: args);
        },
      ),
      GoRoute(
        path: RoutePaths.firebaseHub,
        name: RouteNames.firebaseHub,
        builder: (context, state) {
          final kind = FirebaseServiceKindX.fromQuery(
            state.uri.queryParameters['service'],
          );
          return FirebaseHubScreen(initialKind: kind);
        },
      ),
      GoRoute(
        path: RoutePaths.editProfile,
        name: RouteNames.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.changePassword,
        name: RouteNames.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.notificationSettings,
        name: RouteNames.notificationSettings,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),

      // ── /operations/history ──────────────────────────────────────────
      GoRoute(
        path: RoutePaths.operationHistory,
        name: RouteNames.operationHistory,
        builder: (context, state) => const OperationHistoryScreen(),
      ),
      GoRoute(
        path: RoutePaths.scheduledTasks,
        name: 'scheduledTasks',
        builder: (context, state) => const ScheduledTasksScreen(),
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
          String? initialFarmId =
              state.uri.queryParameters['farmId'] ??
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

      // ── /add-crab ─────────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.addCrab,
        name: RouteNames.addCrab,
        builder: (context, state) => const AddCrabScreen(),
      ),

      // ── /crab-tracking ────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.crabTracking,
        name: RouteNames.crabTracking,
        builder: (context, state) => const CrabTrackingScreen(),
      ),

      // ── /crab-management ──────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.crabManagement,
        name: RouteNames.crabManagement,
        builder: (context, state) => const CrabManagementScreen(),
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
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/login_splash.png', fit: BoxFit.fill),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 28,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF1298EA),
              ),
            ),
          ),
        ),
      ],
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
