// ignore_for_file: lines_longer_than_80_chars

/// Integration tests for the box module end-to-end flows.
///
/// Covers:
/// 1. QR scan → box details navigation (ScannerBloc → GoRouter)
/// 2. Box data loading and caching via BoxRepositoryImpl
/// 3. Offline mode: stale data warning banner rendered in BoxDetailsScreen
///
/// Requirements: 4.7, 4.10, 25.3
library;

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:crabsensemobile/core/errors/exceptions.dart';
import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/core/network/network_info.dart';
import 'package:crabsensemobile/features/box/data/datasources/box_local_data_source.dart';
import 'package:crabsensemobile/features/box/data/datasources/box_remote_data_source.dart';
import 'package:crabsensemobile/features/box/data/models/box_model.dart';
import 'package:crabsensemobile/features/box/data/models/crab_model.dart';
import 'package:crabsensemobile/features/box/data/repositories/box_repository_impl.dart';
import 'package:crabsensemobile/features/box/domain/entities/box.dart';
import 'package:crabsensemobile/features/box/domain/entities/box_enums.dart';
import 'package:crabsensemobile/features/box/domain/entities/crab.dart';
import 'package:crabsensemobile/features/box/domain/usecases/get_box_details_usecase.dart';
import 'package:crabsensemobile/features/box/presentation/bloc/box_bloc.dart';
import 'package:crabsensemobile/features/box/presentation/bloc/box_event.dart';
import 'package:crabsensemobile/features/box/presentation/bloc/box_state.dart';
import 'package:crabsensemobile/features/qr_scanner/presentation/bloc/scanner_state.dart';

// ---------------------------------------------------------------------------
// Network stubs
// ---------------------------------------------------------------------------

class _OnlineNetwork implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

class _OfflineNetwork implements NetworkInfo {
  @override
  Future<bool> get isConnected async => false;
}

// ---------------------------------------------------------------------------
// Remote data source stubs
// ---------------------------------------------------------------------------

class _StubRemoteSuccess implements BoxRemoteDataSource {
  _StubRemoteSuccess({BoxModel? model}) : _model = model ?? _makeBoxModel();
  final BoxModel _model;

  @override
  Future<BoxModel> getBoxDetails(String boxId) async => _model;

  @override
  Future<BoxModel> getBoxByQrCode(String qrCode) async => _model;

  @override
  Future<List<BoxModel>> getBoxesByFarm(String farmId) async => [_model];

  @override
  Future<CrabModel> addCrab(String boxId, CrabModel crab) async => crab;

  @override
  Future<void> transferCrab(String crabId, String sourceBoxId, String destinationBoxId) async {}

  @override
  Future<BoxModel> updateBox(BoxModel box) async => box;

  @override
  Future<List<CrabModel>> getCrabsByBox(String boxId) async => [];

  @override
  Future<void> deleteCrab(String crabId) async {}
}

// ---------------------------------------------------------------------------
// Local data source stub (captures writes for assertion)
// ---------------------------------------------------------------------------

/// Local source that records every [cacheBox] call so tests can assert
/// that data was persisted.
class _StubLocalCapturing implements BoxLocalDataSource {
  BoxModel? _lastCached;
  final Map<String, BoxModel> _byId = {};
  final Map<String, BoxModel> _byQr = {};

  /// The last model passed to [cacheBox].
  BoxModel? get lastCachedBox => _lastCached;

  @override
  Future<BoxModel> getCachedBox(String boxId) async {
    final found = _byId[boxId];
    if (found == null) {
      throw CacheException(message: 'No cached box: $boxId', code: 'BOX_NOT_FOUND');
    }
    return found;
  }

  @override
  Future<BoxModel> getCachedBoxByQrCode(String qrCode) async {
    final found = _byQr[qrCode];
    if (found == null) {
      throw CacheException(message: 'No cached box for QR: $qrCode', code: 'BOX_NOT_FOUND');
    }
    return found;
  }

  @override
  Future<List<BoxModel>> getCachedBoxesByFarm(String farmId) async =>
      _byId.values.where((b) => b.farmId == farmId).toList();

  @override
  Future<void> cacheBox(Box box, {bool isDirty = false}) async {
    final model = BoxModel.fromEntity(box);
    _lastCached = model;
    _byId[box.id] = model;
    _byQr[box.qrCode] = model;
  }

  @override
  Future<void> cacheBoxes(List<Box> boxes) async {
    for (final b in boxes) {
      await cacheBox(b);
    }
  }

  @override
  Future<void> cacheCrab(Crab crab, {bool isDirty = false}) async {}

  @override
  Future<List<CrabModel>> getCachedCrabsByBox(String boxId) async => [];

  @override
  Future<void> deleteCachedCrab(String crabId) async {}

  @override
  Stream<Box> watchBox(String boxId) => const Stream.empty();
}

/// Local source that always throws on reads (simulates empty cache).
class _StubLocalEmpty implements BoxLocalDataSource {
  @override
  Future<BoxModel> getCachedBox(String boxId) async =>
      throw CacheException(message: 'No cached box: $boxId', code: 'BOX_NOT_FOUND');

  @override
  Future<BoxModel> getCachedBoxByQrCode(String qrCode) async =>
      throw CacheException(message: 'No cached QR: $qrCode', code: 'BOX_NOT_FOUND');

  @override
  Future<List<BoxModel>> getCachedBoxesByFarm(String farmId) async => [];

  @override
  Future<void> cacheBox(Box box, {bool isDirty = false}) async {}

  @override
  Future<void> cacheBoxes(List<Box> boxes) async {}

  @override
  Future<void> cacheCrab(Crab crab, {bool isDirty = false}) async {}

  @override
  Future<List<CrabModel>> getCachedCrabsByBox(String boxId) async => [];

  @override
  Future<void> deleteCachedCrab(String crabId) async {}

  @override
  Stream<Box> watchBox(String boxId) => const Stream.empty();
}

// ---------------------------------------------------------------------------
// Use-case stub (drives BoxBloc without a real repository)
// ---------------------------------------------------------------------------

class _StubGetBoxDetails implements GetBoxDetailsUseCase {
  _StubGetBoxDetails(this._result);
  final Either<Failure, Box> _result;

  @override
  Future<Either<Failure, Box>> call(GetBoxDetailsParams params) async => _result;
}

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

BoxModel _makeBoxModel({
  String id = 'box-001',
  String qrCode = 'CRABSENSE:BOX:box-001',
  DateTime? createdAt,
}) => BoxModel(
  id: id,
  qrCode: qrCode,
  farmId: 'farm-001',
  location: const Location(latitude: 10, longitude: 20, label: 'Pond A'),
  currentCrabCount: 5,
  capacity: 20,
  species: CrabSpecies.mudCrab,
  averageWeight: 150,
  status: BoxStatus.active,
  createdAt: createdAt ?? DateTime.now(),
);

Box _makeBox({String id = 'box-001', BoxStatus status = BoxStatus.active, DateTime? createdAt}) =>
    Box(
      id: id,
      qrCode: 'CRABSENSE:BOX:$id',
      farmId: 'farm-001',
      location: const Location(latitude: 10, longitude: 20, label: 'Pond A'),
      currentCrabCount: 5,
      capacity: 20,
      species: CrabSpecies.mudCrab,
      averageWeight: 150,
      status: status,
      createdAt: createdAt ?? DateTime.now(),
    );

BoxRepositoryImpl _buildRepo({
  BoxRemoteDataSource? remote,
  BoxLocalDataSource? local,
  NetworkInfo? network,
}) => BoxRepositoryImpl(
  remoteDataSource: remote ?? _StubRemoteSuccess(),
  localDataSource: local ?? _StubLocalCapturing(),
  networkInfo: network ?? _OnlineNetwork(),
);

// ---------------------------------------------------------------------------
// Minimal test widget for BoxDetailsScreen (no DI, no GoRouter dependency)
// ---------------------------------------------------------------------------

Widget _buildBoxDetailsWidget({required BoxBloc bloc, String boxId = 'box-001'}) => MaterialApp(
  home: BlocProvider<BoxBloc>.value(
    value: bloc,
    child: Builder(
      builder: (ctx) => Scaffold(
        body: BlocBuilder<BoxBloc, BoxState>(
          builder: (context, state) {
            if (state is BoxLoading) {
              return const Center(key: Key('skeleton_loader'), child: CircularProgressIndicator());
            }

            if (state is BoxError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      state.isOffline ? Icons.wifi_off : Icons.error_outline,
                      key: const Key('error_icon'),
                    ),
                    Text(state.message),
                    ElevatedButton(
                      key: const Key('retry_button'),
                      onPressed: () => context.read<BoxBloc>().add(BoxDetailsLoadRequested(boxId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is BoxLoaded) {
              return ListView(
                children: [
                  if (state.box.isDataStale)
                    Container(
                      key: const Key('staleness_banner'),
                      child: const Row(
                        children: [Icon(Icons.warning_amber), Text('Data may be outdated')],
                      ),
                    ),
                  Text(state.box.id, key: const Key('box_id')),
                  Text(state.box.status.displayName, key: const Key('box_status')),
                ],
              );
            }

            // BoxInitial
            return const Center(key: Key('skeleton_loader'), child: CircularProgressIndicator());
          },
        ),
      ),
    ),
  ),
);

// ---------------------------------------------------------------------------
// Helper: pump until BoxBloc settles (exits BoxLoading)
// ---------------------------------------------------------------------------

Future<void> _pumpUntilSettled(WidgetTester tester, BoxBloc bloc, {int maxPumps = 20}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump();
    if (bloc.state is! BoxLoading) break;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── Flow 1: QR scan → box details navigation ───────────────────────────────

  group('Flow 1 – QR scan → navigation to /box/:id', () {
    testWidgets('navigates to /box/box-001 when ScannerBloc emits BoxFetchSuccess', (tester) async {
      // Track which path GoRouter actually navigated to.
      String? lastNavigatedPath;

      // Build a minimal GoRouter with /scanner and /box/:id routes.
      // The scanner route hosts a widget that listens to ScannerBloc and
      // calls context.go('/box/$boxId') on BoxFetchSuccess — exactly as
      // the real QRScannerScreen does.
      final scannerBloc = _FakeScannerBloc();
      addTearDown(scannerBloc.close);

      final router = GoRouter(
        initialLocation: '/scanner',
        routes: [
          GoRoute(
            path: '/scanner',
            builder: (context, state) => BlocProvider<_FakeScannerBloc>.value(
              value: scannerBloc,
              child: _ScannerListenerWidget(onNavigate: (path) => lastNavigatedPath = path),
            ),
          ),
          GoRoute(
            path: '/box/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return Scaffold(body: Text('Box Details $id'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Emit BoxFetchSuccess from the scanner bloc — triggers navigation.
      scannerBloc.emitState(const BoxFetchSuccess(boxId: 'box-001'));
      await tester.pumpAndSettle();

      // Verify we landed on the box details route.
      expect(lastNavigatedPath, equals('/box/box-001'));
      expect(find.text('Box Details box-001'), findsOneWidget);
    });
  });

  // ── Flow 2: Box data loading and caching ───────────────────────────────────

  group('Flow 2 – Box data loading and caching (Requirement 4.7)', () {
    test('online fetch: data is fetched from remote and stored in cache', () async {
      final local = _StubLocalCapturing();
      final model = _makeBoxModel();
      final repo = _buildRepo(
        remote: _StubRemoteSuccess(model: model),
        local: local,
        network: _OnlineNetwork(),
      );
      final useCase = GetBoxDetailsUseCase(repo);

      final result = await useCase(const GetBoxDetailsParams(boxId: 'box-001'));

      expect(result.isRight(), isTrue, reason: 'Expected Right(Box) when online');
      result.fold((_) => fail('Expected Right'), (box) {
        expect(box.id, equals('box-001'));
        expect(box.farmId, equals('farm-001'));
      });
      // Data must have been written to cache.
      expect(local.lastCachedBox, isNotNull, reason: 'Remote result should be cached locally');
      expect(local.lastCachedBox!.id, equals('box-001'));
    });

    test('online then offline: second fetch serves from cache', () async {
      final local = _StubLocalCapturing();
      final model = _makeBoxModel();
      final onlineRepo = _buildRepo(
        remote: _StubRemoteSuccess(model: model),
        local: local,
        network: _OnlineNetwork(),
      );

      // First call — online: populates cache.
      final first = await onlineRepo.getBoxDetails('box-001');
      expect(first.isRight(), isTrue, reason: 'Online fetch should succeed');
      expect(
        local.lastCachedBox,
        isNotNull,
        reason: 'Cache should be populated after online fetch',
      );

      // Second call — offline: must serve from the cache populated above.
      final offlineRepo = _buildRepo(
        remote: _StubRemoteSuccess(model: model),
        local: local,
        network: _OfflineNetwork(),
      );

      final second = await offlineRepo.getBoxDetails('box-001');
      expect(second.isRight(), isTrue, reason: 'Offline fetch should serve from cache');
      second.fold(
        (_) => fail('Expected Right (cached box)'),
        (box) => expect(box.id, equals('box-001')),
      );
    });

    test('offline with empty cache returns Left(CacheFailure)', () async {
      final repo = _buildRepo(local: _StubLocalEmpty(), network: _OfflineNetwork());
      final useCase = GetBoxDetailsUseCase(repo);

      final result = await useCase(const GetBoxDetailsParams(boxId: 'box-001'));

      expect(result.isLeft(), isTrue, reason: 'Expected failure when offline with no cache');
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('Expected Left(CacheFailure)'),
      );
    });
  });

  // ── Flow 3: Offline mode – stale data warning ──────────────────────────────

  group('Flow 3 – Offline mode displays stale data warning (Requirements 4.7, 4.10)', () {
    testWidgets('staleness_banner shown when box.createdAt is older than 30 minutes', (
      tester,
    ) async {
      // Create a box with createdAt 2 hours ago → isDataStale == true.
      final staleBox = _makeBox(createdAt: DateTime.now().subtract(const Duration(hours: 2)));

      final bloc = BoxBloc(getBoxDetails: _StubGetBoxDetails(Right(staleBox)));
      addTearDown(bloc.close);

      await tester.pumpWidget(_buildBoxDetailsWidget(bloc: bloc));
      bloc.add(const BoxDetailsLoadRequested('box-001'));
      await _pumpUntilSettled(tester, bloc);

      expect(
        find.byKey(const Key('staleness_banner')),
        findsOneWidget,
        reason: 'Expected stale data banner for a box created 2 hours ago',
      );
      expect(find.text('Data may be outdated'), findsOneWidget);
    });

    testWidgets('staleness_banner is absent when box data is fresh (within 30 minutes)', (
      tester,
    ) async {
      // Fresh box — created just now.
      final freshBox = _makeBox(createdAt: DateTime.now());

      final bloc = BoxBloc(getBoxDetails: _StubGetBoxDetails(Right(freshBox)));
      addTearDown(bloc.close);

      await tester.pumpWidget(_buildBoxDetailsWidget(bloc: bloc));
      bloc.add(const BoxDetailsLoadRequested('box-001'));
      await _pumpUntilSettled(tester, bloc);

      expect(
        find.byKey(const Key('staleness_banner')),
        findsNothing,
        reason: 'Fresh box should not show stale banner',
      );
    });

    testWidgets(
      'wifi_off icon shown in BoxError when isOffline is true (offline cached data failure)',
      (tester) async {
        final bloc = BoxBloc(
          getBoxDetails: _StubGetBoxDetails(const Left(NetworkFailure('No connection'))),
        );
        addTearDown(bloc.close);

        await tester.pumpWidget(_buildBoxDetailsWidget(bloc: bloc));
        bloc.add(const BoxDetailsLoadRequested('box-001'));
        await _pumpUntilSettled(tester, bloc);

        final icon = tester.widget<Icon>(find.byKey(const Key('error_icon')));
        expect(icon.icon, equals(Icons.wifi_off));
      },
    );

    testWidgets(
      'BoxBloc driven to BoxLoaded with stale box shows staleness_banner via direct state drive',
      (tester) async {
        // Drive the bloc directly to BoxLoaded without going through the use case.
        final staleBox = _makeBox(createdAt: DateTime.now().subtract(const Duration(minutes: 45)));

        final bloc = BoxBloc(getBoxDetails: _StubGetBoxDetails(Right(staleBox)));
        addTearDown(bloc.close);

        await tester.pumpWidget(_buildBoxDetailsWidget(bloc: bloc));

        // Dispatch load event so bloc transitions to BoxLoaded(staleBox).
        bloc.add(const BoxDetailsLoadRequested('box-001'));
        await _pumpUntilSettled(tester, bloc);

        // Final state check.
        expect(bloc.state, isA<BoxLoaded>());
        final loaded = bloc.state as BoxLoaded;
        expect(loaded.box.isDataStale, isTrue, reason: 'Box 45 min old should be stale');

        expect(find.byKey(const Key('staleness_banner')), findsOneWidget);
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Test doubles for navigation flow
// ---------------------------------------------------------------------------

/// A fake ScannerBloc that lets tests emit arbitrary states.
///
/// Extends [Bloc] with [BoxFetchSuccess] as a reachable state by accepting
/// any [_FakeScannerEvent] and re-emitting the state captured in that event.
class _FakeScannerBloc extends Bloc<_FakeScannerEvent, ScannerState> {
  _FakeScannerBloc() : super(const ScannerInitial()) {
    on<_FakeScannerEvent>((event, emit) => emit(event.state));
  }

  /// Convenience method to emit an arbitrary [ScannerState].
  void emitState(ScannerState state) => add(_FakeScannerEvent(state));
}

class _FakeScannerEvent {
  const _FakeScannerEvent(this.state);
  final ScannerState state;
}

/// Minimal widget that mimics [QRScannerScreen]'s navigation logic.
///
/// Listens to [_FakeScannerBloc] and calls [context.go] on [BoxFetchSuccess],
/// then invokes [onNavigate] with the target path so tests can assert it.
class _ScannerListenerWidget extends StatelessWidget {
  const _ScannerListenerWidget({required this.onNavigate});

  final void Function(String path) onNavigate;

  @override
  Widget build(BuildContext context) => BlocListener<_FakeScannerBloc, ScannerState>(
    listener: (ctx, state) {
      if (state is BoxFetchSuccess) {
        final path = '/box/${state.boxId}';
        onNavigate(path);
        ctx.go(path);
      }
    },
    child: const Scaffold(body: Center(child: Text('Scanner'))),
  );
}
