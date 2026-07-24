import 'package:flutter/material.dart';

/// Dropdown Input Component
/// Requirements: 20.1-20.10, 21.6, 21.7
///
/// Reusable dropdown select field
/// - 14dp border radius
/// - Outlined style
/// - Label and hint text support
/// - Error state with error message display
/// - Generic type support for any value type
class DropdownWidget<T> extends StatelessWidget {
  const DropdownWidget({
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
    this.label,
    this.hint = 'Select an option',
    this.errorText,
    this.enabled = true,
    this.prefixIcon,
  });

  /// Current selected value
  final T? value;

  /// List of dropdown items
  final List<DropdownMenuItem<T>> items;

  /// Callback when value changes
  final ValueChanged<T?>? onChanged;

  /// Label text displayed above dropdown
  final String? label;

  /// Hint text displayed when no value selected
  final String hint;

  /// Error message to display
  final String? errorText;

  /// Enable or disable the dropdown
  final bool enabled;

  /// Prefix icon
  final IconData? prefixIcon;

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
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
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
          dropdownColor: theme.colorScheme.surface,
          icon: Icon(
            Icons.arrow_drop_down,
            color: enabled
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.38),
          ),
          style: theme.textTheme.bodyLarge,
          isExpanded: true,
        ),
      ],
    );
  }
}
