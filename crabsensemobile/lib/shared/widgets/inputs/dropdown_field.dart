import 'package:flutter/material.dart';

/// Dropdown Field Component
/// Reusable dropdown selector with validation
/// Requirements: 20.1-20.10, 21.6
class DropdownField<T> extends StatelessWidget {
  /// Creates a dropdown field
  const DropdownField({
    required this.items,
    required this.onChanged,
    super.key,
    this.value,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
    this.itemLabelBuilder,
  });

  /// List of dropdown items
  final List<T> items;

  /// Called when selection changes
  final ValueChanged<T?> onChanged;

  /// Currently selected value
  final T? value;

  /// Label text displayed above field
  final String? labelText;

  /// Hint text when no selection
  final String? hintText;

  /// Helper text below field
  final String? helperText;

  /// Error text below field
  final String? errorText;

  /// Leading icon
  final Widget? prefixIcon;

  /// Validation function
  final String? Function(T?)? validator;

  /// Whether field is enabled
  final bool enabled;

  /// Custom label builder for items
  final String Function(T)? itemLabelBuilder;

  String _getItemLabel(T item) {
    if (itemLabelBuilder != null) {
      return itemLabelBuilder!(item);
    }
    return item.toString();
  }

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    items: items
        .map((item) => DropdownMenuItem<T>(value: item, child: Text(_getItemLabel(item))))
        .toList(),
    onChanged: enabled ? onChanged : null,
    decoration: InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefixIcon,
    ),
    validator: validator,
    isExpanded: true,
  );
}
