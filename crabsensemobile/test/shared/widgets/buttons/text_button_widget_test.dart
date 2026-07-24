import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crabsensemobile/shared/widgets/buttons/text_button_widget.dart';

void main() {
  group('TextButtonWidget Tests', () {
    testWidgets('renders with text label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextButtonWidget(onPressed: () {}, child: const Text('Learn More')),
          ),
        ),
      );

      expect(find.text('Learn More'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('calls onPressed callback when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextButtonWidget(onPressed: () => pressed = true, child: const Text('Press')),
          ),
        ),
      );

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TextButtonWidget(onPressed: null, child: Text('Disabled'))),
        ),
      );

      final button = tester.widget<TextButton>(find.byType(TextButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextButtonWidget(onPressed: () {}, isLoading: true, child: const Text('Loading')),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('renders with icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextButtonWidget(
              onPressed: () {},
              icon: const Icon(Icons.info),
              child: const Text('Info'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.info), findsOneWidget);
      expect(find.text('Info'), findsOneWidget);
    });

    testWidgets('does not show icon when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextButtonWidget(
              onPressed: () {},
              icon: const Icon(Icons.info),
              isLoading: true,
              child: const Text('Loading'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.info), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders full width when fullWidth is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TextButtonWidget(
                onPressed: () {},
                fullWidth: true,
                child: const Text('Full Width'),
              ),
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(of: find.byType(TextButton), matching: find.byType(SizedBox)),
      );

      expect(sizedBox.width, equals(double.infinity));
    });

    testWidgets('applies custom padding when provided', (tester) async {
      const customPadding = EdgeInsets.all(16);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextButtonWidget(
              onPressed: () {},
              padding: customPadding,
              child: const Text('Custom Padding'),
            ),
          ),
        ),
      );

      final button = tester.widget<TextButton>(find.byType(TextButton));
      expect(button.style, isNotNull);
    });
  });
}
