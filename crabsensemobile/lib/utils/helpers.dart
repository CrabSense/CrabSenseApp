import 'package:intl/intl.dart';

class Helpers {
  // Format datetime
  static String formatDateTime(DateTime dateTime) => DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);

  static String formatDate(DateTime dateTime) => DateFormat('dd/MM/yyyy').format(dateTime);

  static String formatTime(DateTime dateTime) => DateFormat('HH:mm:ss').format(dateTime);

  static String formatTimeShort(DateTime dateTime) => DateFormat('HH:mm').format(dateTime);

  // Format số thập phân
  static String formatDecimal(double value, {int decimals = 2}) => value.toStringAsFixed(decimals);

  // Kiểm tra giá trị trong ngưỡng
  static bool isInRange(double value, double min, double max) => value >= min && value <= max;

  // Xác định trạng thái dựa trên ngưỡng
  static String getStatusText(double value, double min, double max) {
    if (value < min) return 'Thấp';
    if (value > max) return 'Cao';
    return 'Bình thường';
  }

  // Chuyển đổi timestamp
  static DateTime parseTimestamp(String timestamp) => DateTime.parse(timestamp);

  // Format relative time (e.g., "5 phút trước")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
