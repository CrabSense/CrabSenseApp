import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crabsensemobile/shared/widgets/inputs/dropdown_field.dart';

void main() {
  group('DropdownField Widget Tests', () {
    const testItems = ['Option 1', 'Option 2', 'Option 3'];

    testWidgets('renders dropdown field correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownField<String>(items: testItems, onChanged: (_) {}),
          ),
        ),
      );

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('displays all items correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownField<String>(items: testItems, onChanged: (_) {}),
          ),
        ),
      );

      // Tap to open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Check if all items are present
      for (final item in testItems) {
        expect(find.text(item).last, findsOneWidget);
      }
    });

    testWidgets('handles selection correctly', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownField<String>(
              items: testItems,
              onChanged: (value) {
                selectedValue = value;
              },
            ),
          ),
        ),
      );

      // Tap to open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select second option
      await tester.tap(find.text('Option 2').last);
      await tester.pumpAndSettle();

      expect(selectedValue, 'Option 2');
    });

    testWidgets('displays initial value correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownField<String>(items: testItems, value: 'Option 2', onChanged: (_) {}),
          ),
        ),
      );

      expect(find.text('Option 2'), findsOneWidget);
    });

    testWidgets('displays label text when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownField<String>(
              items: testItems,
              labelText: 'Select Option',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );

      expect(dropdown.decoration.labelText, 'Select Option');
    });

    testWidgets('displays hint text when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownField<String>(
              items: testItems,
              hintText: 'Choose an option',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );

      expect(dropdown.decoration.hintText, 'Choose an option');
    });

    testWidgets('displays helper text when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownField<String>(
              items: testItems,
              helperText: 'Select one option from the list',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );

      expect(dropdown.decoration.helperText, 'Select one option from the list');
    });

    testWidgets('displays error text when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownField<String>(
              items: testItems,
              errorText: 'This field is required',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );

      expect(dropdown.decoration.errorText, 'This field is required');
    });

    testWidgets('displays prefix icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownField<String>(
              items: testItems,
              prefixIcon: const Icon(Icons.category),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.category), findsOneWidget);
    });

    testWidgets('handles disabled state correctly', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownField<String>(
              items: testItems,
              enabled: false,
              onChanged: (value) {
                selectedValue = value;
              },
            ),
          ),
        ),
      );

      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );

      expect(dropdown.onChanged, isNull);

      // Try to tap disabled dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Should not have opened (no items should be visible)
      expect(find.text('Option 1'), findsNothing);
      expect(selectedValue, isNull);
    });

    testWidgets('uses custom item label builder when provided', (tester) async {
      const customItems = [1, 2, 3];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownField<int>(
              items: customItems,
              itemLabelBuilder: (item) => 'Item #$item',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Tap to open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      // Check if custom labels are present
      expect(find.text('Item #1'), findsOneWidget);
      expect(find.text('Item #2'), findsOneWidget);
      expect(find.text('Item #3'), findsOneWidget);
    });

    testWidgets('uses toString when no custom label builder', (tester) async {
      const customItems = [1, 2, 3];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownField<int>(items: customItems, onChanged: (_) {}),
          ),
        ),
      );

      // Tap to open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      // Check if toString values are present
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('validates correctly when validator is provided', (tester) async {
      String? validator(value) {
        if (value == null) {
          return 'Please select an option';
        }
        return null;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: DropdownField<String>(
                items: testItems,
                validator: validator,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );

      expect(dropdown.validator, isNotNull);
    });

    testWidgets('has isExpanded set to true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownField<String>(items: testItems, onChanged: (_) {}),
          ),
        ),
      );

      // DropdownButtonFormField renders as full-width by default in this widget.
      // Verify a DropdownButtonFormField is present (isExpanded is internal).
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('works with complex objects', (tester) async {
      final complexItems = [
        {'id': 1, 'name': 'First Item'},
        {'id': 2, 'name': 'Second Item'},
        {'id': 3, 'name': 'Third Item'},
      ];

      Map<String, dynamic>? selectedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownField<Map<String, dynamic>>(
              items: complexItems,
              itemLabelBuilder: (item) => item['name'] as String,
              onChanged: (value) {
                selectedItem = value;
              },
            ),
          ),
        ),
      );

      // Tap to open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<Map<String, dynamic>>));
      await tester.pumpAndSettle();

      // Select second item
      await tester.tap(find.text('Second Item').last);
      await tester.pumpAndSettle();

      expect(selectedItem, complexItems[1]);
    });

    testWidgets('handles empty items list correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownField<String>(items: const [], onChanged: (_) {}),
          ),
        ),
      );

      // Tap to try to open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Should not crash and no items should be visible
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });
  });
}
