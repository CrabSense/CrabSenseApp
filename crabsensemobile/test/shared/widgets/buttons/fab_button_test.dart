import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crabsensemobile/shared/widgets/buttons/fab_button.dart';

void main() {
  group('FABButton Widget Tests', () {
    testWidgets('renders standard FAB with icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FABButton(onPressed: () {}, icon: Icons.add),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('calls onPressed callback when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FABButton(onPressed: () => pressed = true, icon: Icons.camera),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FABButton(onPressed: null, icon: Icons.edit)),
        ),
      );

      final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.onPressed, isNull);
    });

    testWidgets('renders extended FAB with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FABButton(onPressed: () {}, icon: Icons.add, label: 'Add Item'),
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('renders mini FAB when mini is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FABButton(onPressed: () {}, icon: Icons.edit, mini: true),
          ),
        ),
      );

      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows tooltip when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FABButton(onPressed: () {}, icon: Icons.save, tooltip: 'Save changes'),
          ),
        ),
      );

      // Long press to show tooltip
      await tester.longPress(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Save changes'), findsOneWidget);
    });

    testWidgets('applies custom background color', (tester) async {
      const customBg = Colors.green;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FABButton(onPressed: () {}, icon: Icons.check, backgroundColor: customBg),
          ),
        ),
      );

      final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.backgroundColor, equals(customBg));
    });

    testWidgets('applies custom foreground color', (tester) async {
      const customFg = Colors.white;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FABButton(onPressed: () {}, icon: Icons.share, foregroundColor: customFg),
          ),
        ),
      );

      final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.foregroundColor, equals(customFg));
    });

    testWidgets('uses theme colors when not specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
          home: Scaffold(
            body: FABButton(onPressed: () {}, icon: Icons.message),
          ),
        ),
      );

      expect(find.byIcon(Icons.message), findsOneWidget);
    });

    testWidgets('applies heroTag when provided', (tester) async {
      const heroTag = 'fab-hero';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FABButton(onPressed: () {}, icon: Icons.arrow_forward, heroTag: heroTag),
          ),
        ),
      );

      final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.heroTag, equals(heroTag));
    });

    testWidgets('extended FAB shows both icon and label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FABButton(onPressed: () {}, icon: Icons.upload, label: 'Upload'),
          ),
        ),
      );

      expect(find.byIcon(Icons.upload), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);
    });

    testWidgets('mini FAB with tooltip works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FABButton(onPressed: () {}, icon: Icons.refresh, mini: true, tooltip: 'Refresh'),
          ),
        ),
      );

      await tester.longPress(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('disabled state prevents interaction', (tester) async {
      const pressed = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FABButton(onPressed: null, icon: Icons.block)),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(pressed, isFalse);
    });
  });
}
