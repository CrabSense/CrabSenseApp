import 'package:crabsensemobile/app/routes.dart';
import 'package:crabsensemobile/shared/services/notification_navigation_service.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

class MockGoRouter extends Fake implements GoRouter {
  String? lastNavigatedPath;

  @override
  void go(String location, {Object? extra}) {
    lastNavigatedPath = location;
  }
}

void main() {
  late MockGoRouter mockRouter;
  late Logger mockLogger;
  late NotificationNavigationService navigationService;

  setUp(() {
    mockRouter = MockGoRouter();
    mockLogger = Logger(printer: SimplePrinter());
    navigationService = NotificationNavigationService(
      router: mockRouter,
      logger: mockLogger,
    );
  });

  group('NotificationNavigationService', () {
    test('navigates using explicit deepLink field if provided', () {
      const message = RemoteMessage(
        data: {'deepLink': '/water-quality'},
      );

      navigationService.navigate(message);

      expect(mockRouter.lastNavigatedPath, '/water-quality');
    });

    test('navigates to box details when screen is box_details and resourceId provided', () {
      const message = RemoteMessage(
        data: {
          'screen': 'box_details',
          'resourceId': 'BOX-999',
        },
      );

      navigationService.navigate(message);

      expect(mockRouter.lastNavigatedPath, RoutePaths.boxDetails('BOX-999'));
    });

    test('navigates to alerts screen for CRITICAL_ALERT category fallback', () {
      const message = RemoteMessage(
        data: {'category': 'CRITICAL_ALERT'},
      );

      navigationService.navigate(message);

      expect(mockRouter.lastNavigatedPath, RoutePaths.alerts);
    });

    test('navigates to profile screen for SYSTEM_UPDATE category', () {
      const message = RemoteMessage(
        data: {'category': 'SYSTEM_UPDATE'},
      );

      navigationService.navigate(message);

      expect(mockRouter.lastNavigatedPath, RoutePaths.profile);
    });

    test('falls back to alerts screen for unknown payload data', () {
      const message = RemoteMessage(
        data: {},
      );

      navigationService.navigate(message);

      expect(mockRouter.lastNavigatedPath, RoutePaths.alerts);
    });
  });
}
