import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crabsensemobile/shared/widgets/cards/crabsense_card.dart';

void main() {
  group('CrabSenseCard Widget Tests', () {
    testWidgets('renders child widget correctly', (tester) async {
      const testChild = Text('Test Content');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CrabSenseCard(child: testChild)),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('applies default styling correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CrabSenseCard(child: Text('Test'))),
        ),
      );

      // Find the container with decoration
      final containerWidget = tester.widget<Container>(
        find.descendant(of: find.byType(CrabSenseCard), matching: find.byType(Container)).first,
      );

      final decoration = containerWidget.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(16));
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.length, 1);
    });

    testWidgets('applies custom padding and margin', (tester) async {
      const customPadding = EdgeInsets.all(24);
      const customMargin = EdgeInsets.all(16);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CrabSenseCard(padding: customPadding, margin: customMargin, child: Text('Test')),
          ),
        ),
      );

      // Find the outermost Container (first one) which carries the margin
      final containerWidget = tester.widget<Container>(
        find.descendant(of: find.byType(CrabSenseCard), matching: find.byType(Container)).first,
      );

      expect(containerWidget.margin, customMargin);

      // Find the padding widget (always only one Padding inside the card)
      final paddingWidgets = tester.widgetList<Padding>(
        find.descendant(of: find.byType(CrabSenseCard), matching: find.byType(Padding)),
      );

      final innerPadding = paddingWidgets.firstWhere(
        (p) => p.padding == customPadding,
        orElse: () => throw TestFailure('No Padding widget with customPadding found'),
      );
      expect(innerPadding.padding, customPadding);
    });

    testWidgets('applies custom border radius', (tester) async {
      const customRadius = 20.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CrabSenseCard(borderRadius: customRadius, child: Text('Test')),
          ),
        ),
      );

      // Find ClipRRect with custom radius
      final clipRRect = tester.widget<ClipRRect>(
        find.descendant(of: find.byType(CrabSenseCard), matching: find.byType(ClipRRect)),
      );

      expect(clipRRect.borderRadius, BorderRadius.circular(customRadius));
    });

    testWidgets('handles tap callback correctly', (tester) async {
      var tapped = false;
      void onTap() {
        tapped = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrabSenseCard(onTap: onTap, child: const Text('Tap me')),
          ),
        ),
      );

      // Verify InkWell is present when onTap is provided
      expect(find.byType(InkWell), findsOneWidget);

      // Tap the card
      await tester.tap(find.byType(CrabSenseCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not create InkWell when onTap is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CrabSenseCard(child: Text('No tap'))),
        ),
      );

      // Should not have InkWell when onTap is null
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('applies backdrop filter correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CrabSenseCard(blur: 15, child: Text('Blurred'))),
        ),
      );

      // Find BackdropFilter
      final backdropFilter = tester.widget<BackdropFilter>(
        find.descendant(of: find.byType(CrabSenseCard), matching: find.byType(BackdropFilter)),
      );

      expect(backdropFilter.filter, ImageFilter.blur(sigmaX: 15, sigmaY: 15));
    });

    testWidgets('applies elevation shadow correctly', (tester) async {
      const elevation = 4.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CrabSenseCard(elevation: elevation, child: Text('Elevated')),
          ),
        ),
      );

      final containerWidget = tester.widget<Container>(
        find.descendant(of: find.byType(CrabSenseCard), matching: find.byType(Container)).first,
      );

      final decoration = containerWidget.decoration! as BoxDecoration;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.first.blurRadius, elevation * 2);
      expect(decoration.boxShadow!.first.offset, const Offset(0, elevation));
    });

    testWidgets('removes shadow when elevation is 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CrabSenseCard(elevation: 0, child: Text('No shadow'))),
        ),
      );

      final containerWidget = tester.widget<Container>(
        find.descendant(of: find.byType(CrabSenseCard), matching: find.byType(Container)).first,
      );

      final decoration = containerWidget.decoration! as BoxDecoration;
      expect(decoration.boxShadow, isNull);
    });

    testWidgets('applies border correctly when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CrabSenseCard(child: Text('With border'))),
        ),
      );

      // Find all DecoratedBoxes and pick the one with a border (the inner styling one)
      final decoratedBoxes = tester.widgetList<DecoratedBox>(
        find.descendant(of: find.byType(CrabSenseCard), matching: find.byType(DecoratedBox)),
      );

      final hasBorder = decoratedBoxes.any((b) {
        final dec = b.decoration;
        return dec is BoxDecoration && dec.border != null;
      });
      expect(hasBorder, isTrue);
    });

    testWidgets('removes border when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CrabSenseCard(border: false, child: Text('No border'))),
        ),
      );

      // Find all DecoratedBoxes — none should have a border
      final decoratedBoxes = tester.widgetList<DecoratedBox>(
        find.descendant(of: find.byType(CrabSenseCard), matching: find.byType(DecoratedBox)),
      );

      final hasBorder = decoratedBoxes.any((b) {
        final dec = b.decoration;
        return dec is BoxDecoration && dec.border != null;
      });
      expect(hasBorder, isFalse);
    });

    testWidgets('applies custom colors correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: const ColorScheme.light(primary: Colors.blue)),
          home: const Scaffold(body: CrabSenseCard(opacity: 0.2, child: Text('Custom colors'))),
        ),
      );

      // Find the inner DecoratedBox that has a non-null color
      final decoratedBoxes = tester.widgetList<DecoratedBox>(
        find.descendant(of: find.byType(CrabSenseCard), matching: find.byType(DecoratedBox)),
      );

      final hasColor = decoratedBoxes.any((b) {
        final dec = b.decoration;
        return dec is BoxDecoration && dec.color != null;
      });
      expect(hasColor, isTrue);
    });
  });
}
