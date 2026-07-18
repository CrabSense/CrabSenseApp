import 'package:intl/intl.dart';

class Helpers {
  // Format datetime
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  // Format số thập phân
  static String formatDecimal(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }

  // Kiểm tra giá trị trong ngưỡng
  static bool isInRange(double value, double min, double max) {
    return value >= min && value <= max;
  }

  // Xác định trạng thái dựa trên ngưỡng
  static String getStatusText(double value, double min, double max) {
    if (value < min) return 'Thấp';
    if (value > max) return 'Cao';
    return 'Bình thường';
  }

  // Chuyển đổi timestamp
  static DateTime parseTimestamp(String timestamp) {
    return DateTime.parse(timestamp);
  }
}
