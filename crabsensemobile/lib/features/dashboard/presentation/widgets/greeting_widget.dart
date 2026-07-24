import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Displays a time-of-day greeting with the user's name and an optional
/// farm name beneath it.
///
/// Example output:
/// ```
/// Good morning, John!
/// Farm: Green Bay Farm
/// ```
///
/// Requirements: 2.1
class GreetingWidget extends StatelessWidget {
  const GreetingWidget({required this.userName, super.key, this.farmName});

  /// The display name of the currently logged-in user.
  final String userName;

  /// Optional farm name to show below the greeting.
  final String? farmName;

  // Returns the time-of-day portion ("morning", "afternoon", "evening").
  String _timeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'morning';
    }
    if (hour < 17) {
      return 'afternoon';
    }
    return 'evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good ${_timeOfDay()}, $userName!',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: CrabSenseColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (farmName != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: CrabSenseColors.primary),
              const SizedBox(width: 4),
              Text(
                farmName!,
                style: theme.textTheme.bodyMedium?.copyWith(color: CrabSenseColors.primary),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
