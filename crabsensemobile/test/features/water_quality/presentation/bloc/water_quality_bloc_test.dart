import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:crabsensemobile/features/water_quality/data/datasources/water_quality_remote_data_source.dart';
import 'package:crabsensemobile/features/water_quality/data/models/water_quality_model.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/features/water_quality/domain/entities/water_quality.dart';
import 'package:crabsensemobile/features/water_quality/domain/repositories/water_quality_repository.dart';
import 'package:crabsensemobile/features/water_quality/domain/usecases/get_current_readings_usecase.dart';
import 'package:crabsensemobile/features/water_quality/domain/usecases/get_historical_data_usecase.dart';
import 'package:crabsensemobile/features/water_quality/presentation/bloc/water_quality_bloc.dart';
import 'package:crabsensemobile/features/water_quality/presentation/bloc/water_quality_event.dart';
import 'package:crabsensemobile/features/water_quality/presentation/bloc/water_quality_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class MockWaterQualityRepository implements WaterQualityRepository {
  Either<Failure, List<WaterQuality>>? readingsResult;
  Either<Failure, List<WaterQuality>>? historicalResult;
  Either<Failure, bool>? deviceStatusResult;
  Future<Either<Failure,List<WaterQuality>>> Function(String,String?)? onRead;
  final calls=<String>[];

  @override
  Future<Either<Failure, List<WaterQuality>>> getCurrentReadings({
    required String farmId,
    String? pondId,
  }) async {
    calls.add(farmId);
    if(onRead!=null) return onRead!(farmId,pondId);
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
  Future<Either<Failure, List<WaterQuality>>> getHistoricalData({
    required String farmId,
    required HistoricalPeriod period,
    String? pondId,
  }) async {
    return historicalResult ?? const Right([]);
  }

  @override
  Future<Either<Failure, bool>> checkDeviceStatus({required String sensorId}) async {
    return deviceStatusResult ?? const Right(true);
  }

  @override
  Stream<List<WaterQuality>> watchCurrentReadings({
    required String farmId,
    String? pondId,
  }) =>
      const Stream.empty();
}

void main() {
  late MockWaterQualityRepository mockRepo;
  late GetCurrentReadingsUseCase getCurrentReadings;
  late GetHistoricalDataUseCase getHistoricalData;

  setUp(() {
    mockRepo = MockWaterQualityRepository();
    getCurrentReadings = GetCurrentReadingsUseCase(mockRepo);
    getHistoricalData = GetHistoricalDataUseCase(mockRepo);
  });

  WaterQualityBloc buildBloc() => WaterQualityBloc(
        getCurrentReadings: getCurrentReadings,
        getHistoricalData: getHistoricalData,
        repository: mockRepo,
      );

  group('WaterQualityBloc', () {
    test('initial state is WaterQualityInitial', () {
      expect(buildBloc().state, isA<WaterQualityInitial>());
    });

    blocTest<WaterQualityBloc, WaterQualityState>(
      'emits [WaterQualityLoading, WaterQualityLoaded] with mock sensor data on WaterQualityLoadRequested',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const WaterQualityLoadRequested(farmId: 'farm-1', pondId: 'pond-1')),
      expect: () => [
        isA<WaterQualityLoading>(),
        isA<WaterQualityLoaded>()
            .having((s) => s.readings.first.ph, 'ph', 8.0)
            .having((s) => s.isDeviceOffline, 'isDeviceOffline', false),
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
      act: (bloc) =>
          bloc.add(const WaterQualityFarmChanged(farmId: 'farm-2', pondId: 'pond-2')),
      expect: () => [
        isA<WaterQualityLoading>(),
        isA<WaterQualityLoaded>()
            .having((s) => s.farmId, 'farmId', 'farm-2')
            .having((s) => s.pondId, 'pondId', 'pond-2'),
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

  test('missing is null, true zero retained, invalid or wrong-scope data rejected', (){
    final row={'sensorId':'sensor','farmingAreaId':'farm','farmingRowId':'row','sensorType':'Salinity',
      'unit':'ppt','latestValue':0,'latestMeasuredAt':'2026-11-01T00:00:00Z','isActive':true,'dataQuality':'Realtime'};
    final r=decodeLiveWaterReading(row,farmId:'farm',pondId:'row')!;
    expect(r.salinity,0); expect(r.ph,isNull); expect(r.ammonia,isNull);
    for(final change in [{'latestValue':null},{'latestValue':'bad'},{'latestMeasuredAt':null},
      {'farmingAreaId':'other'},{'farmingRowId':'other'},{'unit':'ppm'},{'dataQuality':'Unknown'}]){
      expect(decodeLiveWaterReading({...row,...change},farmId:'farm',pondId:'row'),isNull);
    }
    expect(WaterQualityModel.fromJson({'timestamp':'2026-11-01T00:00:00Z','ph':'invalid','salinity':0}).ph,isNull);
    expect(()=>WaterQualityModel.fromJson({'ph':8}),throwsFormatException);
  });

  test('latest farm wins, refresh during load ignored, failure retry retains selected scope',()async{
    final old=Completer<Either<Failure,List<WaterQuality>>>();
    final fresh=Completer<Either<Failure,List<WaterQuality>>>();
    mockRepo.onRead=(farm,pond)=>farm=='farm-old'?old.future:fresh.future;
    final bloc=buildBloc();
    addTearDown(bloc.close);
    bloc.add(const WaterQualityLoadRequested(farmId:'farm-old'));
    await Future<void>.delayed(Duration.zero);
    bloc.add(const WaterQualityFarmChanged(farmId:'farm-new',pondId:'row-new'));
    await Future<void>.delayed(Duration.zero);
    bloc.add(const WaterQualityRefreshRequested());
    await Future<void>.delayed(Duration.zero);
    expect(mockRepo.calls,['farm-old','farm-new']);
    final ready=bloc.stream.firstWhere((s)=>s is WaterQualityLoaded);
    fresh.complete(const Right([])); await ready;
    old.complete(const Left(NetworkFailure('old request')));
    await Future<void>.delayed(Duration.zero);
    expect((bloc.state as WaterQualityLoaded).farmId,'farm-new');
    expect((bloc.state as WaterQualityLoaded).deviceStatusKnown,false);
    mockRepo.onRead=(farm,pond)async=>const Left(NetworkFailure('new request'));
    final failed=bloc.stream.firstWhere((s)=>s is WaterQualityError);
    bloc.add(const WaterQualityRefreshRequested()); await failed;
    await Future<void>.delayed(Duration.zero);
    mockRepo.onRead=(farm,pond)async=>const Right([]);
    final retried=bloc.stream.firstWhere((s)=>s is WaterQualityLoaded);
    bloc.add(const WaterQualityRefreshRequested()); await retried;
    expect(mockRepo.calls,['farm-old','farm-new','farm-new','farm-new']);
    expect((bloc.state as WaterQualityLoaded).pondId,'row-new');
  });
}
