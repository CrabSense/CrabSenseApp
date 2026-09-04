import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/report_models.dart';
import '../../data/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepositoryImpl(api: sl<ApiClient>()),
);

final reportDetailProvider =
    FutureProvider.family<ReportDetailData, ReportKind>((ref, kind) async {
  return ref.watch(reportsRepositoryProvider).getReport(kind);
});
