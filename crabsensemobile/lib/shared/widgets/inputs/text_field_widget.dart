import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Text Field Input Component
/// Requirements: 20.1-20.10, 21.6, 21.7
///
/// Reusable text input field with validation support
/// - 14dp border radius
/// - Outlined style with primary color focus
/// - Label and hint text support
/// - Error state with error message display
/// - Prefix and suffix icon support
/// - Input formatters and validators
/// - Obscure text option for passwords
class TextFieldWidget extends StatelessWidget {
  const TextFieldWidget({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.maxLines = 1,
    this.minLines = 1,
    this.maxLength,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.inputFormatters,
    this.validator,
  });

  /// Text editing controller
  final TextEditingController? controller;

  /// Label text displayed above input
  final String? label;

  /// Hint text displayed when empty
  final String? hint;

  /// Error message to display
  final String? errorText;

  /// Callback when text changes
  final ValueChanged<String>? onChanged;

  /// Callback when editing is complete
  final VoidCallback? onEditingComplete;

  /// Callback when field is submitted
  final ValueChanged<String>? onSubmitted;

  /// Keyboard type
  final TextInputType keyboardType;

  /// Text input action
  final TextInputAction textInputAction;

  /// Maximum number of lines (default: 1)
  final int maxLines;

  /// Minimum number of lines (default: 1)
  final int minLines;

  /// Maximum character length
  final int? maxLength;

  /// Obscure text for passwords
  final bool obscureText;

  /// Enable or disable the field
  final bool enabled;

  /// Read-only mode
  final bool readOnly;

  /// Autofocus on widget creation
  final bool autofocus;

  /// Prefix icon
  final IconData? prefixIcon;

  /// Suffix icon
  final IconData? suffixIcon;

  /// Suffix icon tap callback
  final VoidCallback? onSuffixIconTap;

  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Validator function
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null && label!.isNotEmpty) ...[
          Text(
            label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.87),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          onSubmitted: onSubmitted,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          maxLength: maxLength,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          inputFormatters: inputFormatters,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixIcon != null
                ? IconButton(icon: Icon(suffixIcon), onPressed: onSuffixIconTap)
                : null,
            counterText: maxLength != null ? null : '',
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }
}
