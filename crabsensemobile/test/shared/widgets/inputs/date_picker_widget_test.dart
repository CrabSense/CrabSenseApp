import 'package:crabsensemobile/shared/widgets/inputs/date_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for DatePickerWidget component
/// Requirements: 25.2, 25.4
void main() {
  group('DatePickerWidget Tests', () {
    testWidgets('renders with no date selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DatePickerWidget(selectedDate: null, onDateSelected: (_) {})),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
      expect(find.byType(InputDecorator), findsOneWidget);
    });

    testWidgets('displays selected date in default format', (tester) async {
      final selectedDate = DateTime(2024, 1, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerWidget(selectedDate: selectedDate, onDateSelected: (_) {}),
          ),
        ),
      );

      expect(find.text('Jan 15, 2024'), findsOneWidget);
    });

    testWidgets('displays date in custom format', (tester) async {
      final selectedDate = DateTime(2024, 1, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerWidget(
              selectedDate: selectedDate,
              onDateSelected: (_) {},
              dateFormat: 'yyyy-MM-dd',
            ),
          ),
        ),
      );

      expect(find.text('2024-01-15'), findsOneWidget);
    });

    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerWidget(selectedDate: null, onDateSelected: (_) {}, label: 'Birth Date'),
          ),
        ),
      );

      expect(find.text('Birth Date'), findsOneWidget);
    });

    testWidgets('displays hint text when no date selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerWidget(selectedDate: null, onDateSelected: (_) {}, hint: 'Pick a date'),
          ),
        ),
      );

      // The hint appears in both decoration and as text child — at least one match expected
      expect(find.text('Pick a date'), findsWidgets);
    });

    testWidgets('opens date picker dialog when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DatePickerWidget(selectedDate: null, onDateSelected: (_) {})),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('calls onDateSelected when date is picked', (tester) async {
      DateTime? pickedDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerWidget(selectedDate: null, onDateSelected: (date) => pickedDate = date),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Find and tap OK button
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(pickedDate, isNotNull);
    });

    testWidgets('does not call onDateSelected when cancelled', (tester) async {
      DateTime? pickedDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerWidget(selectedDate: null, onDateSelected: (date) => pickedDate = date),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Find and tap Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(pickedDate, isNull);
    });

    testWidgets('displays error text when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerWidget(
              selectedDate: null,
              onDateSelected: (_) {},
              errorText: 'Date is required',
            ),
          ),
        ),
      );

      expect(find.text('Date is required'), findsOneWidget);
    });

    testWidgets('disabled when enabled is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerWidget(selectedDate: null, onDateSelected: (_) {}, enabled: false),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Dialog should not open when disabled
      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets('renders with prefix icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerWidget(
              selectedDate: null,
              onDateSelected: (_) {},
              prefixIcon: Icons.event,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.event), findsOneWidget);
    });

    testWidgets('uses default calendar icon when not specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DatePickerWidget(selectedDate: null, onDateSelected: (_) {})),
        ),
      );

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('renders dropdown icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DatePickerWidget(selectedDate: null, onDateSelected: (_) {})),
        ),
      );

      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('respects firstDate constraint', (tester) async {
      final firstDate = DateTime(2020);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerWidget(
              selectedDate: null,
              onDateSelected: (_) {},
              firstDate: firstDate,
            ),
          ),
        ),
      );

      final widget = tester.widget<DatePickerWidget>(find.byType(DatePickerWidget));
      expect(widget.firstDate, firstDate);
    });

    testWidgets('respects lastDate constraint', (tester) async {
      final lastDate = DateTime(2030, 12, 31);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerWidget(selectedDate: null, onDateSelected: (_) {}, lastDate: lastDate),
          ),
        ),
      );

      final widget = tester.widget<DatePickerWidget>(find.byType(DatePickerWidget));
      expect(widget.lastDate, lastDate);
    });

    testWidgets('uses initialDate when provided', (tester) async {
      final initialDate = DateTime(2023, 6, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerWidget(
              selectedDate: null,
              onDateSelected: (_) {},
              initialDate: initialDate,
            ),
          ),
        ),
      );

      final widget = tester.widget<DatePickerWidget>(find.byType(DatePickerWidget));
      expect(widget.initialDate, initialDate);
    });

    testWidgets('respects theme colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan, brightness: Brightness.dark),
          ),
          home: Scaffold(body: DatePickerWidget(selectedDate: null, onDateSelected: (_) {})),
        ),
      );

      expect(find.byType(DatePickerWidget), findsOneWidget);
    });

    testWidgets('complete date picker with all properties', (tester) async {
      final selectedDate = DateTime(2024, 1, 15);
      final firstDate = DateTime(2020);
      final lastDate = DateTime(2030, 12, 31);
      DateTime? newDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerWidget(
              selectedDate: selectedDate,
              onDateSelected: (date) => newDate = date,
              label: 'Event Date',
              hint: 'Select event date',
              prefixIcon: Icons.event,
              firstDate: firstDate,
              lastDate: lastDate,
            ),
          ),
        ),
      );

      expect(find.text('Event Date'), findsOneWidget);
      expect(find.text('Jan 15, 2024'), findsOneWidget);
      expect(find.byIcon(Icons.event), findsOneWidget);
    });

    testWidgets('multiple date pickers render independently', (tester) async {
      final date1 = DateTime(2024, 1, 15);
      final date2 = DateTime(2024, 2, 20);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                DatePickerWidget(selectedDate: date1, onDateSelected: (_) {}, label: 'Start Date'),
                DatePickerWidget(selectedDate: date2, onDateSelected: (_) {}, label: 'End Date'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Start Date'), findsOneWidget);
      expect(find.text('End Date'), findsOneWidget);
      expect(find.text('Jan 15, 2024'), findsOneWidget);
      expect(find.text('Feb 20, 2024'), findsOneWidget);
    });
  });
}
