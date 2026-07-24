import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Date Picker Input Component
/// Requirements: 20.1-20.10, 21.6, 21.7
///
/// Reusable date picker field
/// - 14dp border radius
/// - Outlined style
/// - Tappable field that opens date picker dialog
/// - Label and hint text support
/// - Error state with error message display
/// - Date formatting support
/// - Min and max date constraints
class DatePickerWidget extends StatelessWidget {
  const DatePickerWidget({
    required this.selectedDate,
    required this.onDateSelected,
    super.key,
    this.label,
    this.hint = 'Select date',
    this.errorText,
    this.enabled = true,
    this.dateFormat = 'MMM dd, yyyy',
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.prefixIcon = Icons.calendar_today,
  });

  /// Currently selected date
  final DateTime? selectedDate;

  /// Callback when date is selected
  final ValueChanged<DateTime>? onDateSelected;

  /// Label text displayed above field
  final String? label;

  /// Hint text displayed when no date selected
  final String hint;

  /// Error message to display
  final String? errorText;

  /// Enable or disable the picker
  final bool enabled;

  /// Date format pattern (default: 'MMM dd, yyyy')
  final String dateFormat;

  /// Minimum selectable date
  final DateTime? firstDate;

  /// Maximum selectable date
  final DateTime? lastDate;

  /// Initial date to show in picker
  final DateTime? initialDate;

  /// Prefix icon
  final IconData prefixIcon;

  Future<void> _selectDate(BuildContext context) async {
    if (!enabled || onDateSelected == null) return;

    final initialPickerDate = initialDate ?? selectedDate ?? DateTime.now();

    final firstPickerDate =
        firstDate ?? DateTime.now().subtract(const Duration(days: 36500)); // ~100 years

    final lastPickerDate =
        lastDate ?? DateTime.now().add(const Duration(days: 36500)); // ~100 years

    final picked = await showDatePicker(
      context: context,
      initialDate: initialPickerDate,
      firstDate: firstPickerDate,
      lastDate: lastPickerDate,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: Colors.black,
              surface: theme.colorScheme.surface,
              onSurface: theme.colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      onDateSelected!(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat(dateFormat);
    final displayText = selectedDate != null ? formatter.format(selectedDate!) : '';

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
        InkWell(
          onTap: enabled ? () => _selectDate(context) : null,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorText,
              prefixIcon: Icon(prefixIcon),
              suffixIcon: const Icon(Icons.arrow_drop_down),
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
            child: Text(
              displayText.isEmpty ? hint : displayText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: displayText.isEmpty
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
