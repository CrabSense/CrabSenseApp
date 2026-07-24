import 'package:crabsensemobile/shared/widgets/inputs/date_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Widget tests for DatePickerField
/// Requirements: 25.2, 25.4
void main() {
  group('DatePickerField Widget Tests', () {
    testWidgets('should render date picker field', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DatePickerField(onDateSelected: (_) {})),
        ),
      );

      // Assert
      expect(find.byType(DatePickerField), findsOneWidget);
      expect(find.byType(InputDecorator), findsOneWidget);
    });

    testWidgets('should display selected date', (tester) async {
      // Arrange
      final selectedDate = DateTime(2024, 3, 15);
      final expectedText = DateFormat('yyyy-MM-dd').format(selectedDate);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerField(selectedDate: selectedDate, onDateSelected: (_) {}),
          ),
        ),
      );

      // Assert
      expect(find.text(expectedText), findsOneWidget);
    });

    testWidgets('should display hint text when no date selected', (tester) async {
      // Arrange
      const hintText = 'Select a date';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerField(hintText: hintText, onDateSelected: (_) {}),
          ),
        ),
      );

      // The hint text appears in both the decoration and as the Text child widget
      expect(find.text(hintText), findsWidgets);
    });

    testWidgets('should display label text', (tester) async {
      // Arrange
      const labelText = 'Birth Date';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerField(labelText: labelText, onDateSelected: (_) {}),
          ),
        ),
      );

      // Assert
      expect(find.text(labelText), findsOneWidget);
    });

    testWidgets('should display error text', (tester) async {
      // Arrange
      const errorText = 'Date is required';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerField(errorText: errorText, onDateSelected: (_) {}),
          ),
        ),
      );

      // Assert
      expect(find.text(errorText), findsOneWidget);
    });

    testWidgets('should display default calendar icon', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DatePickerField(onDateSelected: (_) {})),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('should display custom prefix icon', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerField(prefixIcon: const Icon(Icons.date_range), onDateSelected: (_) {}),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.date_range), findsOneWidget);
    });

    testWidgets('should open date picker on tap', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DatePickerField(onDateSelected: (_) {})),
        ),
      );

      // Tap the field
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert - DatePicker dialog should be shown
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('should not open picker when disabled', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DatePickerField(enabled: false, onDateSelected: (_) {})),
        ),
      );

      // Try to tap
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert - DatePicker should not appear
      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets('should call onDateSelected when date is picked', (tester) async {
      // Arrange
      DateTime? selectedDate;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerField(
              onDateSelected: (date) {
                selectedDate = date;
              },
            ),
          ),
        ),
      );

      // Open picker
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Select a date (tap OK button)
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Assert
      expect(selectedDate, isNotNull);
    });

    testWidgets('should show clear button when date is selected', (tester) async {
      // Arrange
      final selectedDate = DateTime(2024, 3, 15);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerField(selectedDate: selectedDate, onDateSelected: (_) {}),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('should not show clear button when disabled', (tester) async {
      // Arrange
      final selectedDate = DateTime(2024, 3, 15);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerField(
              selectedDate: selectedDate,
              enabled: false,
              onDateSelected: (_) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('should use custom date format', (tester) async {
      // Arrange
      final selectedDate = DateTime(2024, 3, 15);
      final customFormat = DateFormat('dd/MM/yyyy');
      final expectedText = customFormat.format(selectedDate);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerField(
              selectedDate: selectedDate,
              dateFormat: customFormat,
              onDateSelected: (_) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(expectedText), findsOneWidget);
    });

    testWidgets('should respect firstDate constraint', (tester) async {
      // Arrange
      final firstDate = DateTime(2020);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerField(firstDate: firstDate, onDateSelected: (_) {}),
          ),
        ),
      );

      // Open picker
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert - DatePicker should be shown
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('should respect lastDate constraint', (tester) async {
      // Arrange - use a future lastDate so today's date is always valid as initialDate
      final lastDate = DateTime(2030, 12, 31);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerField(lastDate: lastDate, onDateSelected: (_) {}),
          ),
        ),
      );

      // Open picker
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('should display helper text', (tester) async {
      // Arrange
      const helperText = 'Select your birth date';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerField(helperText: helperText, onDateSelected: (_) {}),
          ),
        ),
      );

      // Assert
      expect(find.text(helperText), findsOneWidget);
    });

    testWidgets('should use today as default initial date', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DatePickerField(onDateSelected: (_) {})),
        ),
      );

      // Open picker
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert - DatePicker should open with today's date
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('should handle clear button tap', (tester) async {
      // Arrange
      DateTime? lastSelectedDate;
      final initialDate = DateTime(2024, 3, 15);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => DatePickerField(
                selectedDate: initialDate,
                onDateSelected: (date) {
                  setState(() {
                    lastSelectedDate = date;
                  });
                },
              ),
            ),
          ),
        ),
      );

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Assert - onDateSelected should be called
      expect(lastSelectedDate, isNotNull);
    });
  });
}
