import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Date Picker Field Component
/// Reusable date picker input field
/// Requirements: 20.1-20.10, 21.6
class DatePickerField extends StatelessWidget {
  /// Creates a date picker field
  const DatePickerField({
    required this.onDateSelected,
    super.key,
    this.selectedDate,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.dateFormat,
  });

  /// Called when date is selected
  final ValueChanged<DateTime> onDateSelected;

  /// Currently selected date
  final DateTime? selectedDate;

  /// Label text displayed above field
  final String? labelText;

  /// Hint text when no date selected
  final String? hintText;

  /// Helper text below field
  final String? helperText;

  /// Error text below field
  final String? errorText;

  /// Leading icon
  final Widget? prefixIcon;

  /// Earliest selectable date
  final DateTime? firstDate;

  /// Latest selectable date
  final DateTime? lastDate;

  /// Whether field is enabled
  final bool enabled;

  /// Custom date format (defaults to yyyy-MM-dd)
  final DateFormat? dateFormat;

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = selectedDate ?? now;
    final effectiveFirstDate = firstDate ?? DateTime(1900);
    final effectiveLastDate = lastDate ?? DateTime(2100);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: effectiveFirstDate,
      lastDate: effectiveLastDate,
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  String _formatDate(DateTime date) {
    final formatter = dateFormat ?? DateFormat('yyyy-MM-dd');
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: enabled ? () => _selectDate(context) : null,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          helperText: helperText,
          errorText: errorText,
          prefixIcon: prefixIcon ?? const Icon(Icons.calendar_today),
          suffixIcon: selectedDate != null && enabled
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onDateSelected(DateTime.now()),
                  tooltip: 'Clear date',
                )
              : null,
        ),
        child: Text(
          selectedDate != null ? _formatDate(selectedDate!) : hintText ?? '',
          style: selectedDate != null
              ? theme.textTheme.bodyLarge
              : theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
        ),
      ),
    );
  }
}
