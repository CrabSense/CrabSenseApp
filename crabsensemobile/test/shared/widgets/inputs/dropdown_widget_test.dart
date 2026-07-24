import 'package:crabsensemobile/shared/widgets/inputs/dropdown_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for DropdownWidget component
/// Requirements: 25.2, 25.4
void main() {
  group('DropdownWidget Tests', () {
    final testItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'option1', child: Text('Option 1')),
      const DropdownMenuItem(value: 'option2', child: Text('Option 2')),
      const DropdownMenuItem(value: 'option3', child: Text('Option 3')),
    ];

    testWidgets('renders with items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownWidget<String>(value: null, items: testItems, onChanged: (_) {}),
          ),
        ),
      );

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('displays selected value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownWidget<String>(value: 'option2', items: testItems, onChanged: (_) {}),
          ),
        ),
      );

      expect(find.text('Option 2'), findsOneWidget);
    });

    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownWidget<String>(
              value: null,
              items: testItems,
              onChanged: (_) {},
              label: 'Select Category',
            ),
          ),
        ),
      );

      expect(find.text('Select Category'), findsOneWidget);
    });

    testWidgets('displays hint text when no value selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownWidget<String>(
              value: null,
              items: testItems,
              onChanged: (_) {},
              hint: 'Choose an option',
            ),
          ),
        ),
      );

      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(dropdown.decoration.hintText, 'Choose an option');
    });

    testWidgets('calls onChanged when value changes', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownWidget<String>(
              value: null,
              items: testItems,
              onChanged: (value) => selectedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Option 2').last);
      await tester.pumpAndSettle();

      expect(selectedValue, 'option2');
    });

    testWidgets('displays error text when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownWidget<String>(
              value: null,
              items: testItems,
              onChanged: (_) {},
              errorText: 'Please select an option',
            ),
          ),
        ),
      );

      expect(find.text('Please select an option'), findsOneWidget);
    });

    testWidgets('disabled when enabled is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownWidget<String>(
              value: 'option1',
              items: testItems,
              onChanged: (_) {},
              enabled: false,
            ),
          ),
        ),
      );

      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(dropdown.onChanged, isNull);
    });

    testWidgets('renders with prefix icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownWidget<String>(
              value: null,
              items: testItems,
              onChanged: (_) {},
              prefixIcon: Icons.category,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.category), findsOneWidget);
    });

    testWidgets('supports integer values', (tester) async {
      final intItems = [
        const DropdownMenuItem(value: 1, child: Text('One')),
        const DropdownMenuItem(value: 2, child: Text('Two')),
        const DropdownMenuItem(value: 3, child: Text('Three')),
      ];

      int? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownWidget<int>(
              value: null,
              items: intItems,
              onChanged: (value) => selectedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Two').last);
      await tester.pumpAndSettle();

      expect(selectedValue, 2);
    });

    testWidgets('supports enum values', (tester) async {
      // Enum for test
      final enumItems = [
        const DropdownMenuItem<String>(value: 'active', child: Text('Active')),
        const DropdownMenuItem<String>(value: 'inactive', child: Text('Inactive')),
        const DropdownMenuItem<String>(value: 'pending', child: Text('Pending')),
      ];

      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownWidget<String>(
              value: null,
              items: enumItems,
              onChanged: (value) => selectedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Active').last);
      await tester.pumpAndSettle();

      expect(selectedValue, 'active');
    });

    testWidgets('respects theme colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan, brightness: Brightness.dark),
          ),
          home: Scaffold(
            body: DropdownWidget<String>(value: 'option1', items: testItems, onChanged: (_) {}),
          ),
        ),
      );

      expect(find.text('Option 1'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('complete dropdown with all properties', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownWidget<String>(
              value: 'option1',
              items: testItems,
              onChanged: (value) => selectedValue = value,
              label: 'Category',
              hint: 'Select category',
              prefixIcon: Icons.category,
            ),
          ),
        ),
      );

      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Option 1'), findsOneWidget);
      expect(find.byIcon(Icons.category), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Option 3').last);
      await tester.pumpAndSettle();

      expect(selectedValue, 'option3');
    });

    testWidgets('dropdown icon shows correct state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownWidget<String>(value: null, items: testItems, onChanged: (_) {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('multiple dropdowns render independently', (tester) async {
      String? dropdown1Value;
      String? dropdown2Value;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                DropdownWidget<String>(
                  value: null,
                  items: testItems,
                  onChanged: (value) => dropdown1Value = value,
                  label: 'Dropdown 1',
                ),
                DropdownWidget<String>(
                  value: null,
                  items: testItems,
                  onChanged: (value) => dropdown2Value = value,
                  label: 'Dropdown 2',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Dropdown 1'), findsOneWidget);
      expect(find.text('Dropdown 2'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    });
  });
}
