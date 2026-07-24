import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/di/injection.dart';
import '../../data/models/report_models.dart';
import '../../data/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepositoryImpl(secureStorage: sl<FlutterSecureStorage>()),
);

final reportDetailProvider =
    FutureProvider.family<ReportDetailData, ReportKind>((ref, kind) async {
  return ref.watch(reportsRepositoryProvider).getReport(kind);
});
