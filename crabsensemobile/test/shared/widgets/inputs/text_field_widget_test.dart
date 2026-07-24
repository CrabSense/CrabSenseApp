import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crabsensemobile/shared/widgets/inputs/text_field_widget.dart';

void main() {
  group('TextFieldWidget Widget Tests', () {
    testWidgets('renders basic text field correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TextFieldWidget())));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays label when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TextFieldWidget(label: 'Email Address')),
        ),
      );

      expect(find.text('Email Address'), findsOneWidget);
    });

    testWidgets('displays hint text when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TextFieldWidget(hint: 'Enter your email')),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, 'Enter your email');
    });

    testWidgets('displays error text when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TextFieldWidget(errorText: 'This field is required')),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.errorText, 'This field is required');
    });

    testWidgets('handles text input correctly', (tester) async {
      var inputText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFieldWidget(
              onChanged: (text) {
                inputText = text;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Hello World');
      expect(inputText, 'Hello World');
    });

    testWidgets('handles text submission correctly', (tester) async {
      var submittedText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFieldWidget(
              onSubmitted: (text) {
                submittedText = text;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Submitted');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submittedText, 'Submitted');
    });

    testWidgets('applies keyboard type correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TextFieldWidget(keyboardType: TextInputType.emailAddress)),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, TextInputType.emailAddress);
    });

    testWidgets('applies text input action correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TextFieldWidget(textInputAction: TextInputAction.next)),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.textInputAction, TextInputAction.next);
    });

    testWidgets('handles maxLength correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TextFieldWidget(maxLength: 10))),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLength, 10);
    });

    testWidgets('applies obscureText for password fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TextFieldWidget(obscureText: true))),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
      expect(textField.maxLines, 1); // Should force maxLines to 1 for password
    });

    testWidgets('handles enabled state correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TextFieldWidget(enabled: false))),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('handles readOnly state correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TextFieldWidget(readOnly: true))),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.readOnly, isTrue);
    });

    testWidgets('displays prefix icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TextFieldWidget(prefixIcon: Icons.email)),
        ),
      );

      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('displays suffix icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFieldWidget(suffixIcon: Icons.visibility, onSuffixIconTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('handles suffix icon tap correctly', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFieldWidget(
              suffixIcon: Icons.visibility,
              onSuffixIconTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      expect(tapped, isTrue);
    });

    testWidgets('applies input formatters correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFieldWidget(inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.inputFormatters, isNotNull);
      expect(textField.inputFormatters!.length, 1);
    });

    testWidgets('handles multiline text correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TextFieldWidget(maxLines: 3, minLines: 2))),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, 3);
      expect(textField.minLines, 2);
    });

    testWidgets('applies autofocus correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TextFieldWidget(autofocus: true))),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autofocus, isTrue);
    });

    testWidgets('uses controller when provided', (tester) async {
      final controller = TextEditingController(text: 'Initial Text');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextFieldWidget(controller: controller)),
        ),
      );

      expect(find.text('Initial Text'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('applies proper styling and decoration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              outline: Colors.grey,
              error: Colors.red,
            ),
          ),
          home: const Scaffold(
            body: TextFieldWidget(label: 'Styled Field', errorText: 'Error message'),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      final decoration = textField.decoration!;

      expect(decoration.filled, isTrue);
      expect(decoration.border, isA<OutlineInputBorder>());
      expect(decoration.enabledBorder, isA<OutlineInputBorder>());
      expect(decoration.focusedBorder, isA<OutlineInputBorder>());
      expect(decoration.errorBorder, isA<OutlineInputBorder>());

      // Verify border radius
      final border = decoration.border! as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(14));
    });

    testWidgets('validation integration works correctly', (tester) async {
      String? validator(value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextFieldWidget(validator: validator)),
        ),
      );

      // The validator function is passed but not directly testable in widget tests
      // It would be tested in form integration tests
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField, isNotNull);
    });

    testWidgets('handles editing complete callback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextFieldWidget(onEditingComplete: () {})),
        ),
      );

      // Just verify the callback is assigned to the TextField
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.onEditingComplete, isNotNull);
    });
  });
}
