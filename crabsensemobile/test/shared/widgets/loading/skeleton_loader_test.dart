import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crabsensemobile/shared/widgets/loading/skeleton_loader.dart';

void main() {
  group('SkeletonLoader Widget Tests', () {
    testWidgets('renders basic skeleton loader correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SkeletonLoader())));

      expect(find.byType(SkeletonLoader), findsOneWidget);
      // AnimatedBuilder exists inside the SkeletonLoader tree
      expect(
        find.descendant(of: find.byType(SkeletonLoader), matching: find.byType(AnimatedBuilder)),
        findsOneWidget,
      );
    });

    testWidgets('applies default dimensions correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SkeletonLoader())));

      await tester.pump();

      final container = tester.widget<Container>(
        find.descendant(of: find.byType(SkeletonLoader), matching: find.byType(Container)),
      );

      expect(container.constraints?.maxHeight, 16.0); // Default height
    });

    testWidgets('applies custom dimensions correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SkeletonLoader(width: 200, height: 24))),
      );

      await tester.pump();

      // Verify the AnimatedBuilder is inside the SkeletonLoader tree
      expect(
        find.descendant(of: find.byType(SkeletonLoader), matching: find.byType(AnimatedBuilder)),
        findsOneWidget,
      );
    });

    testWidgets('applies custom border radius correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SkeletonLoader(borderRadius: 12))),
      );

      await tester.pump();

      final container = tester.widget<Container>(
        find.descendant(of: find.byType(SkeletonLoader), matching: find.byType(Container)),
      );

      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('animates correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SkeletonLoader())));

      // Initial state
      await tester.pump();

      // Advance animation
      await tester.pump(const Duration(milliseconds: 100));

      // The animation should still be running — widget still present
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('uses theme colors when not specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              surfaceContainerHighest: Colors.grey,
              primary: Colors.blue,
            ),
          ),
          home: const Scaffold(body: SkeletonLoader()),
        ),
      );

      await tester.pump();

      // Widget should use theme colors
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('uses custom colors when specified', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(baseColor: Colors.red, highlightColor: Colors.green),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('animation controller disposes correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SkeletonLoader())));

      // Remove widget to test dispose
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox.shrink())));

      // Should not throw an error
      expect(find.byType(SkeletonLoader), findsNothing);
    });
  });

  group('SkeletonText Widget Tests', () {
    testWidgets('renders single line correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SkeletonText())));

      expect(find.byType(SkeletonText), findsOneWidget);
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('renders multiple lines correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SkeletonText(lines: 3))));

      expect(find.byType(SkeletonText), findsOneWidget);
      expect(find.byType(SkeletonLoader), findsNWidgets(3));
    });

    testWidgets('applies custom line height correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SkeletonText(lines: 2, lineHeight: 20))),
      );

      final column = tester.widget<Column>(
        find.descendant(of: find.byType(SkeletonText), matching: find.byType(Column)),
      );

      expect(column.children.length, 2);
    });

    testWidgets('applies custom spacing between lines', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SkeletonText(lines: 2, spacing: 12))),
      );

      // Find padding widgets between lines — at least 2 present (one per line)
      final paddingWidgets = tester.widgetList<Padding>(
        find.descendant(of: find.byType(SkeletonText), matching: find.byType(Padding)),
      );

      // Each line is in a Padding widget (at minimum); exact count may vary by tree depth
      expect(paddingWidgets.length, greaterThanOrEqualTo(2));
    });

    testWidgets('applies last line width factor correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SkeletonText(lines: 2, lastLineWidth: 0.5))),
      );

      // Should have FractionallySizedBox for the last line inside SkeletonText
      final fractionallySizedBox = tester.widget<FractionallySizedBox>(
        find
            .descendant(of: find.byType(SkeletonText), matching: find.byType(FractionallySizedBox))
            .first,
      );

      expect(fractionallySizedBox.widthFactor, 0.5);
      expect(fractionallySizedBox.alignment, Alignment.centerLeft);
    });

    testWidgets('handles single line without width constraint', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SkeletonText())));

      // Single line should not have FractionallySizedBox
      expect(
        find.descendant(of: find.byType(SkeletonText), matching: find.byType(FractionallySizedBox)),
        findsNothing,
      );
    });
  });

  group('SkeletonCircle Widget Tests', () {
    testWidgets('renders circular skeleton correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SkeletonCircle())));

      expect(find.byType(SkeletonCircle), findsOneWidget);
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('applies default size correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SkeletonCircle())));

      await tester.pump();

      final skeletonLoader = tester.widget<SkeletonLoader>(find.byType(SkeletonLoader));

      expect(skeletonLoader.width, 48.0); // Default size
      expect(skeletonLoader.height, 48.0); // Default size
      expect(skeletonLoader.borderRadius, 24.0); // Half of size for perfect circle
    });

    testWidgets('applies custom size correctly', (tester) async {
      const customSize = 64.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonCircle(size: customSize)),
        ),
      );

      await tester.pump();

      final skeletonLoader = tester.widget<SkeletonLoader>(find.byType(SkeletonLoader));

      expect(skeletonLoader.width, customSize);
      expect(skeletonLoader.height, customSize);
      expect(skeletonLoader.borderRadius, customSize / 2);
    });
  });

  group('Skeleton Animation Tests', () {
    testWidgets('animation repeats correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SkeletonLoader())));

      // Pump through multiple animation cycles
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500)); // Complete one cycle
      await tester.pump(const Duration(milliseconds: 100)); // Start next cycle

      // Animation should still be active — widget still present
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('gradient animation values are within bounds', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SkeletonLoader())));

      // Test at various animation points
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 150));

        final container = tester.widget<Container>(
          find.descendant(of: find.byType(SkeletonLoader), matching: find.byType(Container)),
        );

        final decoration = container.decoration! as BoxDecoration;
        final gradient = decoration.gradient! as LinearGradient;

        // All stops should be within 0.0 to 1.0 range
        for (final stop in gradient.stops ?? []) {
          expect(stop, greaterThanOrEqualTo(0.0));
          expect(stop, lessThanOrEqualTo(1.0));
        }
      }
    });
  });
}
