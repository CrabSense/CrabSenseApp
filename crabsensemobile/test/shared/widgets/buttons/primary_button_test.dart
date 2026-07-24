import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crabsensemobile/shared/widgets/buttons/primary_button.dart';

void main() {
  group('PrimaryButton Widget Tests', () {
    testWidgets('renders button with child text correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(onPressed: () {}, child: const Text('Primary Action')),
          ),
        ),
      );

      expect(find.text('Primary Action'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('handles onPressed callback correctly', (tester) async {
      var pressed = false;
      void onPressed() {
        pressed = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(onPressed: onPressed, child: const Text('Press Me')),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('displays loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(onPressed: () {}, isLoading: true, child: const Text('Loading')),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('disables button when isLoading is true', (tester) async {
      var pressed = false;
      void onPressed() {
        pressed = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              onPressed: onPressed,
              isLoading: true,
              child: const Text('Loading'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, isFalse);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('disables button when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PrimaryButton(onPressed: null, child: Text('Disabled'))),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('displays icon when provided and not loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              onPressed: () {},
              icon: const Icon(Icons.add),
              child: const Text('Add Item'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);
    });

    testWidgets('hides icon when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              onPressed: () {},
              icon: const Icon(Icons.add),
              isLoading: true,
              child: const Text('Add Item'),
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('applies full width correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(onPressed: () {}, fullWidth: true, child: const Text('Full Width')),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(of: find.byType(PrimaryButton), matching: find.byType(SizedBox)),
      );

      expect(sizedBox.width, double.infinity);
    });

    testWidgets('does not apply full width when false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(onPressed: () {}, child: const Text('Normal Width')),
          ),
        ),
      );

      // Should not find SizedBox with infinite width
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final infiniteWidthBox = sizedBoxes.where((box) => box.width == double.infinity);
      expect(infiniteWidthBox, isEmpty);
    });

    testWidgets('applies custom padding correctly', (tester) async {
      const customPadding = EdgeInsets.symmetric(horizontal: 32, vertical: 16);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              onPressed: () {},
              padding: customPadding,
              child: const Text('Custom Padding'),
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final style = button.style!;

      // Verify padding is set in style
      expect(style.padding, isNotNull);
    });

    testWidgets('loading indicator has correct styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: const ColorScheme.light()),
          home: Scaffold(
            body: PrimaryButton(onPressed: () {}, isLoading: true, child: const Text('Loading')),
          ),
        ),
      );

      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );

      expect(progressIndicator.strokeWidth, 2);

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(of: find.byType(PrimaryButton), matching: find.byType(SizedBox)).first,
      );

      expect(sizedBox.height, 20);
      expect(sizedBox.width, 20);
    });

    testWidgets('maintains button type consistency', (tester) async {
      // Test regular button
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(onPressed: () {}, child: const Text('Regular')),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);

      // Test icon button
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              onPressed: () {},
              icon: const Icon(Icons.star),
              child: const Text('Icon'),
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });
}
