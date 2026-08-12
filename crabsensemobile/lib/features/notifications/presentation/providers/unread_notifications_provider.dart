import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../alert/data/datasources/alert_remote_data_source.dart';

/// Số thông báo / cảnh báo chưa đọc từ `GET /api/alerts/unread/count`.
///
/// Dùng chung cho badge chuông trên header Home và Boxes.
final unreadNotificationsCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  try {
    final count = await sl<AlertRemoteDataSource>().getUnreadCount();
    return count < 0 ? 0 : count;
  } catch (_) {
    return 0;
  }
});
