import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Text Input Field Component
/// Reusable text field with validation and styling
/// Requirements: 20.1-20.10, 21.6
class TextInputField extends StatelessWidget {
  /// Creates a text input field
  const TextInputField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autofocus = false,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
  });

  /// Text editing controller
  final TextEditingController? controller;

  /// Label text displayed above field
  final String? labelText;

  /// Hint text when field is empty
  final String? hintText;

  /// Helper text below field
  final String? helperText;

  /// Error text below field (overrides helperText)
  final String? errorText;

  /// Leading icon
  final Widget? prefixIcon;

  /// Trailing icon
  final Widget? suffixIcon;

  /// Whether to hide text (for passwords)
  final bool obscureText;

  /// Whether field is enabled
  final bool enabled;

  /// Whether field is read-only
  final bool readOnly;

  /// Maximum number of lines
  final int maxLines;

  /// Minimum number of lines
  final int? minLines;

  /// Maximum character length
  final int? maxLength;

  /// Keyboard type
  final TextInputType? keyboardType;

  /// Text input action
  final TextInputAction? textInputAction;

  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Validation function
  final String? Function(String?)? validator;

  /// Called when text changes
  final ValueChanged<String>? onChanged;

  /// Called when user submits
  final ValueChanged<String>? onSubmitted;

  /// Called when field is tapped
  final VoidCallback? onTap;

  /// Whether field should autofocus
  final bool autofocus;

  /// Whether to enable autocorrect
  final bool autocorrect;

  /// Text capitalization strategy
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      counterText: maxLength != null ? null : '',
    ),
    obscureText: obscureText,
    enabled: enabled,
    readOnly: readOnly,
    maxLines: obscureText ? 1 : maxLines,
    minLines: minLines,
    maxLength: maxLength,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    inputFormatters: inputFormatters,
    validator: validator,
    onChanged: onChanged,
    onFieldSubmitted: onSubmitted,
    onTap: onTap,
    autofocus: autofocus,
    autocorrect: autocorrect,
    textCapitalization: textCapitalization,
  );
}
