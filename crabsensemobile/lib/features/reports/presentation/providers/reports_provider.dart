import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/selected_farm_provider.dart';
import '../../../water_quality/data/repositories/scoped_history_service.dart';
import '../../data/models/report_models.dart';
import '../../data/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepositoryImpl(api: sl<ApiClient>()),
);

final _reportSessionRevision = StreamProvider.autoDispose<int>((ref) async* {
  final session = sl<ScopedHistoryService>();
  yield session.revision;
  yield* session.invalidations;
});

final reportDetailProvider =
    FutureProvider.autoDispose.family<ReportDetailData, ReportKind>((ref, kind) async {
  final repository = ref.watch(reportsRepositoryProvider);
  if (kind != ReportKind.efficiency) return repository.getReport(kind);
  final areaId = ref.watch(selectedFarmProvider).id;
  final revision = ref.watch(_reportSessionRevision);
  final expected = revision.asData?.value;
  final session = sl<ScopedHistoryService>();
  if (expected == null || session.revision != expected) {
    throw StateError('Phiên báo cáo chưa xác minh.');
  }
  final result = await repository.getReport(kind, areaId: areaId);
  if (session.revision != expected) throw StateError('Phiên báo cáo đã thay đổi.');
  return result;
});
