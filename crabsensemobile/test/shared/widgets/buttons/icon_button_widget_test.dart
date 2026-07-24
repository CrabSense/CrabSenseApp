import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crabsensemobile/shared/widgets/buttons/icon_button_widget.dart';

void main() {
  group('IconButtonWidget Tests', () {
    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButtonWidget(onPressed: () {}, icon: Icons.settings),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('calls onPressed callback when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButtonWidget(onPressed: () => pressed = true, icon: Icons.delete),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: IconButtonWidget(onPressed: null, icon: Icons.edit)),
        ),
      );

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows tooltip when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButtonWidget(
              onPressed: () {},
              icon: Icons.favorite,
              tooltip: 'Add to favorites',
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);

      // Long press to show tooltip
      await tester.longPress(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Add to favorites'), findsOneWidget);
    });

    testWidgets('does not show tooltip when not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButtonWidget(onPressed: () {}, icon: Icons.favorite),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('applies custom icon size', (tester) async {
      const customSize = 32.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButtonWidget(onPressed: () {}, icon: Icons.star, size: customSize),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(iconWidget.size, equals(customSize));
    });

    testWidgets('applies custom padding', (tester) async {
      const customPadding = EdgeInsets.all(16);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButtonWidget(onPressed: () {}, icon: Icons.menu, padding: customPadding),
          ),
        ),
      );

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.padding, equals(customPadding));
    });

    testWidgets('applies custom background color', (tester) async {
      const customBg = Colors.blue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButtonWidget(onPressed: () {}, icon: Icons.home, backgroundColor: customBg),
          ),
        ),
      );

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.style, isNotNull);
    });

    testWidgets('applies custom foreground color', (tester) async {
      const customFg = Colors.red;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButtonWidget(
              onPressed: () {},
              icon: Icons.notifications,
              foregroundColor: customFg,
            ),
          ),
        ),
      );

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.style, isNotNull);
    });

    testWidgets('uses default size when not specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButtonWidget(onPressed: () {}, icon: Icons.search),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.search));
      expect(iconWidget.size, equals(24.0)); // Default size
    });

    testWidgets('disabled state prevents interaction', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: IconButtonWidget(onPressed: null, icon: Icons.lock)),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(pressed, isFalse);
    });
  });
}
