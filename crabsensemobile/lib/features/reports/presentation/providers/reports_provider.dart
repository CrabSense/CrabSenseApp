import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/report_models.dart';
import '../../data/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepositoryImpl(api: sl<ApiClient>()),
);

// Mobile only admits FarmStaff; all /api/reports routes are management-only.
// Keep the provider fail-closed for existing or future deep-link consumers.
// The repository parser is retained for contract tests; do not grant new roles.
final reportDetailProvider =
    FutureProvider.autoDispose.family<ReportDetailData, ReportKind>((ref, kind) async {
  throw StateError('Farm Staff không có quyền xem báo cáo quản trị.');
});
