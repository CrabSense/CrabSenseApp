import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Dart extensions for CrabSense Mobile Application

// ===========================================================================
// String Extensions
// ===========================================================================

extension StringExtensions on String {
  /// Checks if string is empty or null
  bool get isNullOrEmpty => trim().isEmpty;

  /// Checks if string is not empty
  bool get isNotNullOrEmpty => trim().isNotEmpty;

  /// Capitalizes first letter of string
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Capitalizes first letter of each word
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Truncates string to specified length with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  /// Removes all whitespace from string
  String removeWhitespace() => replaceAll(RegExp(r'\s+'), '');

  /// Checks if string is a valid email
  bool get isValidEmail => RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(this);

  /// Checks if string is numeric
  bool get isNumeric => double.tryParse(this) != null;

  /// Converts string to snake_case
  String toSnakeCase() => replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)?.toLowerCase()}',
    ).replaceFirst(RegExp(r'^_'), '');

  /// Converts string to camelCase
  String toCamelCase() {
    final words = split(RegExp(r'[_\s-]+'));
    if (words.isEmpty) return this;
    return words.first.toLowerCase() + words.skip(1).map((word) => word.capitalize()).join();
  }

  /// Masks email address (e.g., j***@example.com)
  String maskEmail() {
    if (!isValidEmail) return this;
    final parts = split('@');
    if (parts.length != 2) return this;
    final username = parts[0];
    if (username.length <= 2) return this;
    return '${username[0]}${'*' * (username.length - 1)}@${parts[1]}';
  }

  /// Masks phone number (e.g., +84 *** *** 123)
  String maskPhone() {
    if (length < 4) return this;
    return '${substring(0, length - 3).replaceAll(RegExp('[0-9]'), '*')}${substring(length - 3)}';
  }
}

// ===========================================================================
// DateTime Extensions
// ===========================================================================

extension DateTimeExtensions on DateTime {
  /// Formats date as display format (e.g., Jan 15, 2024)
  String toDisplayDate() => DateFormat(AppConstants.displayDateFormat).format(this);

  /// Formats time as display format (e.g., 02:30 PM)
  String toDisplayTime() => DateFormat(AppConstants.displayTimeFormat).format(this);

  /// Formats datetime as display format (e.g., Jan 15, 2024 02:30 PM)
  String toDisplayDateTime() => DateFormat(AppConstants.displayDateTimeFormat).format(this);

  /// Formats date as API format (e.g., 2024-01-15)
  String toApiDate() => DateFormat(AppConstants.dateFormat).format(this);

  /// Formats datetime as API format (e.g., 2024-01-15 14:30:00)
  String toApiDateTime() => DateFormat(AppConstants.dateTimeFormat).format(this);

  /// Returns relative time string (e.g., "2 hours ago", "just now")
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Checks if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Checks if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Checks if date is within the last 7 days
  bool get isThisWeek {
    final now = DateTime.now();
    final difference = now.difference(this);
    return difference.inDays < 7 && difference.inDays >= 0;
  }

  /// Checks if date is within the current month
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Checks if date is in the future
  bool get isFuture => isAfter(DateTime.now());

  /// Checks if date is in the past
  bool get isPast => isBefore(DateTime.now());

  /// Returns start of day (00:00:00)
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns end of day (23:59:59)
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Returns start of week (Monday)
  DateTime get startOfWeek {
    final daysToSubtract = weekday - 1;
    return subtract(Duration(days: daysToSubtract)).startOfDay;
  }

  /// Returns end of week (Sunday)
  DateTime get endOfWeek {
    final daysToAdd = 7 - weekday;
    return add(Duration(days: daysToAdd)).endOfDay;
  }

  /// Checks if data is stale based on threshold
  bool isStale(Duration threshold) {
    final now = DateTime.now();
    return now.difference(this) > threshold;
  }

  /// Checks if data is fresh based on threshold
  bool isFresh(Duration threshold) {
    final now = DateTime.now();
    return now.difference(this) <= threshold;
  }
}

// ===========================================================================
// Number Extensions
// ===========================================================================

extension IntExtensions on int {
  /// Formats integer with thousands separator (e.g., 1,234,567)
  String toFormattedString() => NumberFormat('#,###').format(this);

  /// Converts bytes to human-readable format (e.g., 1.5 MB)
  String toBytesString() {
    if (this < 1024) {
      return '$this B';
    } else if (this < 1024 * 1024) {
      return '${(this / 1024).toStringAsFixed(1)} KB';
    } else if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Converts duration in seconds to human-readable format
  String toReadableDuration() {
    final duration = Duration(seconds: this);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

extension DoubleExtensions on double {
  /// Formats double with specified decimal places
  String toFixed(int decimalPlaces) => toStringAsFixed(decimalPlaces);

  /// Formats double with thousands separator and decimals
  String toFormattedString({int decimalPlaces = 2}) => NumberFormat('#,##0.${'0' * decimalPlaces}').format(this);

  /// Formats as percentage (e.g., 0.75 → "75%")
  String toPercentage({int decimalPlaces = 0}) => '${(this * 100).toStringAsFixed(decimalPlaces)}%';

  /// Formats as currency (e.g., 1234.56 → "$1,234.56")
  String toCurrency({String symbol = r'$', int decimalPlaces = 2}) => '$symbol${toFormattedString(decimalPlaces: decimalPlaces)}';

  /// Formats as Vietnamese currency (e.g., 1234567 → "1.234.567 ₫")
  String toVNDCurrency() {
    final formatted = NumberFormat('#,###', 'vi_VN').format(this);
    return '$formatted ₫';
  }

  /// Converts kilograms to formatted string (e.g., 12.5 kg)
  String toKgString({int decimalPlaces = 2}) => '${toStringAsFixed(decimalPlaces)} kg';

  /// Checks if number is within range
  bool isInRange(double min, double max) => this >= min && this <= max;

  /// Clamps value between min and max
  double clamp(double min, double max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}

// ===========================================================================
// Duration Extensions
// ===========================================================================

extension DurationExtensions on Duration {
  /// Formats duration as readable string (e.g., "2h 30m")
  String toReadableString() {
    if (inHours > 0) {
      return '${inHours}h ${inMinutes.remainder(60)}m';
    } else if (inMinutes > 0) {
      return '${inMinutes}m ${inSeconds.remainder(60)}s';
    } else {
      return '${inSeconds}s';
    }
  }

  /// Formats duration as detailed string (e.g., "2 hours 30 minutes")
  String toDetailedString() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    final parts = <String>[];
    if (hours > 0) {
      parts.add('$hours ${hours == 1 ? 'hour' : 'hours'}');
    }
    if (minutes > 0) {
      parts.add('$minutes ${minutes == 1 ? 'minute' : 'minutes'}');
    }
    if (seconds > 0 && hours == 0) {
      parts.add('$seconds ${seconds == 1 ? 'second' : 'seconds'}');
    }

    return parts.join(' ');
  }
}

// ===========================================================================
// List Extensions
// ===========================================================================

extension ListExtensions<T> on List<T> {
  /// Returns list with duplicates removed
  List<T> get distinct => toSet().toList();

  /// Safely gets element at index, returns null if out of bounds
  T? elementAtOrNull(int index) {
    if (index >= 0 && index < length) {
      return this[index];
    }
    return null;
  }

  /// Chunks list into smaller lists of specified size
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, (i + size > length) ? length : i + size));
    }
    return chunks;
  }

  /// Returns first element or null if list is empty
  T? get firstOrNull => isEmpty ? null : first;

  /// Returns last element or null if list is empty
  T? get lastOrNull => isEmpty ? null : last;
}

// ===========================================================================
// Map Extensions
// ===========================================================================

extension MapExtensions<K, V> on Map<K, V> {
  /// Safely gets value by key, returns null if key doesn't exist
  V? getOrNull(K key) => containsKey(key) ? this[key] : null;

  /// Gets value by key or returns default value
  V getOrDefault(K key, V defaultValue) => containsKey(key) ? this[key] as V : defaultValue;
}

// ===========================================================================
// Enum Extensions
// ===========================================================================

extension EnumExtensions on Enum {
  /// Gets enum name without type prefix
  String get name => toString().split('.').last;

  /// Capitalizes enum name for display
  String get displayName => name.capitalizeWords();
}
