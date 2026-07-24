import 'package:bloc_test/bloc_test.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/features/water_quality/domain/entities/water_quality.dart';
import 'package:crabsensemobile/features/water_quality/domain/entities/water_quality_thresholds.dart';
import 'package:crabsensemobile/features/water_quality/domain/repositories/water_quality_repository.dart';
import 'package:crabsensemobile/features/water_quality/domain/usecases/get_current_readings_usecase.dart';
import 'package:crabsensemobile/features/water_quality/presentation/bloc/water_quality_bloc.dart';
import 'package:crabsensemobile/features/water_quality/presentation/bloc/water_quality_event.dart';
import 'package:crabsensemobile/features/water_quality/presentation/bloc/water_quality_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class MockWaterQualityRepository implements WaterQualityRepository {
  Either<Failure, List<WaterQuality>>? readingsResult;
  Either<Failure, bool>? deviceStatusResult;

  @override
  Future<Either<Failure, List<WaterQuality>>> getCurrentReadings({
    required String farmId,
    String? pondId,
  }) async {
    return readingsResult ??
        Right([
          WaterQuality(
            id: 'wq-1',
            sensorId: 'sensor-1',
            farmId: farmId,
            pondId: pondId ?? 'pond-1',
            temperature: 28.5,
            ph: 8.0,
            dissolvedOxygen: 6.2,
            salinity: 20.0,
            timestamp: DateTime.now(),
            isAlertTriggered: false,
          ),
        ]);
  }

  @override
  Future<Either<Failure, bool>> checkDeviceStatus({required String sensorId}) async {
    return deviceStatusResult ?? const Right(true);
  }

  @override
  Future<Either<Failure, List<WaterQuality>>> getHistoricalReadings({
    required String farmId,
    required DateTime startDate,
    required DateTime endDate,
    String? pondId,
  }) async =>
      const Right([]);

  @override
  Stream<WaterQuality> watchWaterQuality({required String farmId, String? pondId}) =>
      const Stream.empty();
}

void main() {
  late MockWaterQualityRepository mockRepo;
  late GetCurrentReadingsUseCase getCurrentReadings;

  setUp(() {
    mockRepo = MockWaterQualityRepository();
    getCurrentReadings = GetCurrentReadingsUseCase(mockRepo);
  });

  WaterQualityBloc buildBloc() => WaterQualityBloc(
        getCurrentReadings: getCurrentReadings,
        repository: mockRepo,
      );

  group('WaterQualityBloc', () {
    test('initial state is WaterQualityInitial', () {
      expect(buildBloc().state, isA<WaterQualityInitial>());
    });

    blocTest<WaterQualityBloc, WaterQualityState>(
      'emits [WaterQualityLoading, WaterQualityLoaded] with mock sensor data on WaterQualityLoadRequested',
      build: buildBloc,
      act: (bloc) => bloc.add(const WaterQualityLoadRequested(farmId: 'farm-1', pondId: 'pond-1')),
      expect: () => [
        isA<WaterQualityLoading>(),
        isA<WaterQualityLoaded>().having(
          (s) => s.readings.first.ph,
          'ph',
          8.0,
        ).having(
          (s) => s.isDeviceOffline,
          'isDeviceOffline',
          false,
        ),
      ],
    );

    blocTest<WaterQualityBloc, WaterQualityState>(
      'detects offline sensor status when deviceStatus check returns false',
      build: buildBloc,
      setUp: () {
        mockRepo.deviceStatusResult = const Right(false);
      },
      act: (bloc) => bloc.add(const WaterQualityLoadRequested(farmId: 'farm-1')),
      expect: () => [
        isA<WaterQualityLoading>(),
        isA<WaterQualityLoaded>().having(
          (s) => s.isDeviceOffline,
          'isDeviceOffline',
          true,
        ),
      ],
    );

    blocTest<WaterQualityBloc, WaterQualityState>(
      'handles WaterQualityFarmChanged event',
      build: buildBloc,
      act: (bloc) => bloc.add(const WaterQualityFarmChanged(farmId: 'farm-2', pondId: 'pond-2')),
      expect: () => [
        isA<WaterQualityLoading>(),
        isA<WaterQualityLoaded>().having(
          (s) => s.farmId,
          'farmId',
          'farm-2',
        ).having(
          (s) => s.pondId,
          'pondId',
          'pond-2',
        ),
      ],
    );

    blocTest<WaterQualityBloc, WaterQualityState>(
      'emits WaterQualityError when loading fails with NetworkFailure',
      build: buildBloc,
      setUp: () {
        mockRepo.readingsResult = const Left(NetworkFailure('No connection'));
      },
      act: (bloc) => bloc.add(const WaterQualityLoadRequested(farmId: 'farm-1')),
      expect: () => [
        isA<WaterQualityLoading>(),
        isA<WaterQualityError>()
            .having((e) => e.isOffline, 'isOffline', true)
            .having((e) => e.message, 'message', contains('No connection')),
      ],
    );
  });
}
