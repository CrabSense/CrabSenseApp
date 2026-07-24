import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crabsensemobile/shared/widgets/errors/error_state_widget.dart';

void main() {
  group('ErrorStateWidget Widget Tests', () {
    testWidgets('renders error message correctly', (tester) async {
      const errorMessage = 'Something went wrong';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorStateWidget(message: errorMessage)),
        ),
      );

      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('displays default error icon when no custom icon provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorStateWidget(message: 'Error message')),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays custom icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(message: 'Custom error', icon: Icons.warning),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('displays title when provided', (tester) async {
      const title = 'Error Title';
      const message = 'Error details';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(title: title, message: message),
          ),
        ),
      );

      expect(find.text(title), findsOneWidget);
      expect(find.text(message), findsOneWidget);
    });

    testWidgets('does not display title when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorStateWidget(message: 'Just a message')),
        ),
      );

      // Should only have the message text
      expect(find.text('Just a message'), findsOneWidget);
    });

    testWidgets('displays retry button when onRetry provided', (tester) async {
      var retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Retry error',
              onRetry: () {
                retryPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      expect(retryPressed, isTrue);
    });

    testWidgets('does not display retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorStateWidget(message: 'No retry')),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('displays custom retry button text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Custom retry',
              retryButtonText: 'Try Again',
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('displays additional actions when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Error with actions',
              additionalActions: [
                TextButton(onPressed: () {}, child: const Text('Action 1')),
                TextButton(onPressed: () {}, child: const Text('Action 2')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Action 1'), findsOneWidget);
      expect(find.text('Action 2'), findsOneWidget);
      expect(find.byType(TextButton), findsNWidgets(2));
    });

    testWidgets('uses theme colors correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: const ColorScheme.light(error: Colors.red)),
          home: const Scaffold(
            body: ErrorStateWidget(title: 'Error Title', message: 'Error message'),
          ),
        ),
      );

      // Icon should use error color from theme
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(iconWidget.color, Colors.red);
    });

    testWidgets('centers content correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorStateWidget(message: 'Centered error')),
        ),
      );

      // Verify at least one Center widget is present in the ErrorStateWidget tree
      expect(
        find.descendant(of: find.byType(ErrorStateWidget), matching: find.byType(Center)),
        findsWidgets,
      );

      final column = tester.widget<Column>(
        find.descendant(of: find.byType(ErrorStateWidget), matching: find.byType(Column)).first,
      );

      expect(column.mainAxisAlignment, MainAxisAlignment.center);
    });
  });

  group('EmptyStateWidget Widget Tests', () {
    testWidgets('renders empty message correctly', (tester) async {
      const emptyMessage = 'No data available';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EmptyStateWidget(message: emptyMessage)),
        ),
      );

      expect(find.text(emptyMessage), findsOneWidget);
    });

    testWidgets('displays default empty icon when no custom icon provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EmptyStateWidget(message: 'Empty message')),
        ),
      );

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('displays custom icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(message: 'Custom empty', icon: Icons.folder_open),
          ),
        ),
      );

      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsNothing);
    });

    testWidgets('displays title when provided', (tester) async {
      const title = 'No Items';
      const message = 'Add some items to get started';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(title: title, message: message),
          ),
        ),
      );

      expect(find.text(title), findsOneWidget);
      expect(find.text(message), findsOneWidget);
    });

    testWidgets('displays action button when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              message: 'Empty with action',
              actionButton: ElevatedButton(onPressed: () {}, child: const Text('Add Item')),
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('does not display action button when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EmptyStateWidget(message: 'No action')),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('uses theme colors for icon correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: const ColorScheme.light(primary: Colors.blue)),
          home: const Scaffold(body: EmptyStateWidget(message: 'Themed empty')),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.inbox_outlined));
      expect(iconWidget.color, Colors.blue.withValues(alpha: 0.5));
    });
  });

  group('NetworkErrorWidget Widget Tests', () {
    testWidgets('renders network error correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: NetworkErrorWidget())));

      expect(find.text('Connection Error'), findsOneWidget);
      expect(
        find.text(
          'Unable to connect to the server. Please check your internet connection and try again.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('handles retry callback correctly', (tester) async {
      var retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkErrorWidget(
              onRetry: () {
                retryPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      expect(retryPressed, isTrue);
    });

    testWidgets('does not show retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: NetworkErrorWidget())));

      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('TimeoutErrorWidget Widget Tests', () {
    testWidgets('renders timeout error correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TimeoutErrorWidget())));

      expect(find.text('Request Timeout'), findsOneWidget);
      expect(find.text('The request took too long to complete. Please try again.'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('handles retry callback correctly', (tester) async {
      var retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeoutErrorWidget(
              onRetry: () {
                retryPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      expect(retryPressed, isTrue);
    });

    testWidgets('does not show retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TimeoutErrorWidget())));

      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('Error Widget Spacing and Layout Tests', () {
    testWidgets('error widgets have correct spacing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              title: 'Error Title',
              message: 'Error message',
              onRetry: () {},
              additionalActions: [TextButton(onPressed: () {}, child: const Text('Action'))],
            ),
          ),
        ),
      );

      // Check that spacing widgets (SizedBox) are present
      final sizedBoxes = tester.widgetList<SizedBox>(
        find.descendant(of: find.byType(ErrorStateWidget), matching: find.byType(SizedBox)),
      );

      expect(sizedBoxes.length, greaterThan(0));
    });

    testWidgets('empty widget has correct spacing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'Empty Title',
              message: 'Empty message',
              actionButton: ElevatedButton(onPressed: () {}, child: const Text('Action')),
            ),
          ),
        ),
      );

      // Check that spacing widgets (SizedBox) are present
      final sizedBoxes = tester.widgetList<SizedBox>(
        find.descendant(of: find.byType(EmptyStateWidget), matching: find.byType(SizedBox)),
      );

      expect(sizedBoxes.length, greaterThan(0));
    });
  });
}
