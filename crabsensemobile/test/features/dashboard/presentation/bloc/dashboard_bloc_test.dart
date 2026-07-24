import 'package:bloc_test/bloc_test.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:crabsensemobile/features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import 'package:crabsensemobile/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:crabsensemobile/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:crabsensemobile/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Manual mock for GetDashboardSummaryUseCase
// ---------------------------------------------------------------------------

class MockGetDashboardSummaryUseCase implements GetDashboardSummaryUseCase {
  MockGetDashboardSummaryUseCase({this.result});
  Either<Failure, DashboardSummary>? result;
  bool calledWithForceRefresh = false;

  @override
  Future<Either<Failure, DashboardSummary>> call({bool forceRefresh = false}) async {
    calledWithForceRefresh = forceRefresh;
    return result ?? Right(_fakeSummary());
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DashboardSummary _fakeSummary({bool isFromCache = false}) => DashboardSummary(
  alertSummary: const AlertSummary(totalActive: 0, criticalCount: 0, warningCount: 0, infoCount: 0),
  todayVideoTasks: const [],
  farmWaterQualityStatuses: const [],
  weeklyHarvestSummary: WeeklyHarvestSummary(
    weekStartDate: DateTime(2024),
    weekEndDate: DateTime(2024, 1, 7),
    totalWeightKg: 0,
    totalCrabCount: 0,
    harvestCount: 0,
    boxesHarvested: 0,
  ),
  quickMetrics: const QuickMetrics(
    activeBoxCount: 5,
    videosDueToday: 3,
    videosCompletedToday: 1,
    activeFarmCount: 2,
  ),
  fetchedAt: DateTime(2024),
  isFromCache: isFromCache,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DashboardBloc', () {
    late MockGetDashboardSummaryUseCase mockUseCase;
    late DashboardBloc bloc;

    setUp(() {
      mockUseCase = MockGetDashboardSummaryUseCase();
      bloc = DashboardBloc(getDashboardSummary: mockUseCase);
    });

    tearDown(() => bloc.close());

    test('initial state is DashboardInitial', () {
      expect(bloc.state, const DashboardInitial());
    });

    // ── DashboardLoadRequested ─────────────────────────────────────────

    blocTest<DashboardBloc, DashboardState>(
      'DashboardLoadRequested emits [DashboardLoading, DashboardLoaded] '
      'on success',
      build: () {
        mockUseCase.result = Right(_fakeSummary());
        return DashboardBloc(getDashboardSummary: mockUseCase);
      },
      act: (b) => b.add(const DashboardLoadRequested()),
      expect: () => [
        const DashboardLoading(),
        isA<DashboardLoaded>().having(
          (s) => s.summary.quickMetrics.activeBoxCount,
          'activeBoxCount',
          5,
        ),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'DashboardLoadRequested emits [DashboardLoading, DashboardError] '
      'on server failure',
      build: () {
        mockUseCase.result = const Left(ServerFailure('Server error'));
        return DashboardBloc(getDashboardSummary: mockUseCase);
      },
      act: (b) => b.add(const DashboardLoadRequested()),
      expect: () => [
        const DashboardLoading(),
        isA<DashboardError>().having((s) => s.isOffline, 'isOffline', false),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'DashboardLoadRequested emits DashboardError with isOffline=true '
      'on NetworkFailure — Requirement 2.6',
      build: () {
        mockUseCase.result = const Left(NetworkFailure());
        return DashboardBloc(getDashboardSummary: mockUseCase);
      },
      act: (b) => b.add(const DashboardLoadRequested()),
      expect: () => [
        const DashboardLoading(),
        isA<DashboardError>().having((s) => s.isOffline, 'isOffline', true),
      ],
    );

    // ── DashboardRefreshRequested ──────────────────────────────────────

    blocTest<DashboardBloc, DashboardState>(
      'DashboardRefreshRequested marks loaded state as refreshing then '
      'emits fresh DashboardLoaded — Requirement 2.7',
      build: () {
        mockUseCase.result = Right(_fakeSummary());
        return DashboardBloc(getDashboardSummary: mockUseCase);
      },
      seed: () => DashboardLoaded(summary: _fakeSummary()),
      act: (b) => b.add(const DashboardRefreshRequested()),
      expect: () => [
        isA<DashboardLoaded>().having((s) => s.isRefreshing, 'isRefreshing', true),
        isA<DashboardLoaded>().having((s) => s.isRefreshing, 'isRefreshing', false),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'DashboardRefreshRequested emits DashboardError on failure',
      build: () {
        mockUseCase.result = const Left(ServerFailure('refresh failed'));
        return DashboardBloc(getDashboardSummary: mockUseCase);
      },
      seed: () => DashboardLoaded(summary: _fakeSummary()),
      act: (b) => b.add(const DashboardRefreshRequested()),
      expect: () => [
        isA<DashboardLoaded>().having((s) => s.isRefreshing, 'isRefreshing', true),
        isA<DashboardError>(),
      ],
    );

    // ── Offline cached data ────────────────────────────────────────────

    blocTest<DashboardBloc, DashboardState>(
      'DashboardLoaded with isFromCache=true indicates offline mode '
      '— Requirement 2.6',
      build: () {
        mockUseCase.result = Right(_fakeSummary(isFromCache: true));
        return DashboardBloc(getDashboardSummary: mockUseCase);
      },
      act: (b) => b.add(const DashboardLoadRequested()),
      expect: () => [
        const DashboardLoading(),
        isA<DashboardLoaded>().having((s) => s.summary.isFromCache, 'isFromCache', true),
      ],
    );

    // ── Skeleton loading ───────────────────────────────────────────────

    blocTest<DashboardBloc, DashboardState>(
      'emits DashboardLoading as first state so UI can show skeleton '
      '— Requirement 2.10',
      build: () {
        mockUseCase.result = Right(_fakeSummary());
        return DashboardBloc(getDashboardSummary: mockUseCase);
      },
      act: (b) => b.add(const DashboardLoadRequested()),
      expect: () => [isA<DashboardLoading>(), isA<DashboardLoaded>()],
    );
  });
}
