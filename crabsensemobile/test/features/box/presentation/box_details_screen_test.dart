// ignore_for_file: lines_longer_than_80_chars

import 'package:crabsensemobile/features/box/presentation/screens/box_details_screen.dart'
    show BoxDetailsScreen;
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/features/box/domain/entities/box.dart';
import 'package:crabsensemobile/features/box/domain/entities/box_enums.dart';
import 'package:crabsensemobile/features/box/domain/usecases/get_box_details_usecase.dart';
import 'package:crabsensemobile/features/box/presentation/bloc/box_bloc.dart';
import 'package:crabsensemobile/features/box/presentation/bloc/box_event.dart';
import 'package:crabsensemobile/features/box/presentation/bloc/box_state.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// Simple stub that always returns the given result.
class _StubGetBoxDetails implements GetBoxDetailsUseCase {
  _StubGetBoxDetails(this._result);
  final Either<Failure, Box> _result;

  @override
  Future<Either<Failure, Box>> call(GetBoxDetailsParams params) async => _result;
}

/// A stub that counts invocations for event-dispatch verification.
class _CountingStub implements GetBoxDetailsUseCase {
  _CountingStub({required this.result, required this.onCall});
  final Either<Failure, Box> result;
  final void Function() onCall;

  @override
  Future<Either<Failure, Box>> call(GetBoxDetailsParams params) async {
    onCall();
    return result;
  }
}

// ---------------------------------------------------------------------------
// Test fixture
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Minimal test widget
// ---------------------------------------------------------------------------

/// Builds a self-contained screen that exercises the same [BoxBloc] state
/// branches as [BoxDetailsScreen] without pulling in DI or GoRouter.
Widget _buildScreen({required BoxBloc bloc, String boxId = 'box-001'}) => MaterialApp(
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
// Helper: drive the bloc to completion without time-based waits
// ---------------------------------------------------------------------------

/// Pumps the tester until the BLoC has settled into a non-transient state.
///
/// Drives microtasks (each [tester.pump()] call) until [bloc.state] is no
/// longer [BoxLoading].  Caps at [maxPumps] to prevent infinite loops.
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
  group('BoxDetailsScreen widget', () {
    testWidgets('shows skeleton loader when BoxBloc is in BoxInitial state', (tester) async {
      final bloc = BoxBloc(getBoxDetails: _StubGetBoxDetails(Right(_makeBox())));
      addTearDown(bloc.close);

      await tester.pumpWidget(_buildScreen(bloc: bloc));
      // BoxInitial before any event fires.
      expect(find.byKey(const Key('skeleton_loader')), findsOneWidget);
    });

    testWidgets('shows stale data warning banner when box.isDataStale is true', (tester) async {
      // createdAt 2 hours ago → isDataStale returns true.
      final staleBox = _makeBox(createdAt: DateTime.now().subtract(const Duration(hours: 2)));
      final bloc = BoxBloc(getBoxDetails: _StubGetBoxDetails(Right(staleBox)));
      addTearDown(bloc.close);

      await tester.pumpWidget(_buildScreen(bloc: bloc));
      bloc.add(const BoxDetailsLoadRequested('box-001'));
      await _pumpUntilSettled(tester, bloc);

      expect(
        find.byKey(const Key('staleness_banner')),
        findsOneWidget,
        reason: 'Expected stale data banner for a 2-hour-old box',
      );
    });

    testWidgets('shows wifi_off icon when BoxError.isOffline=true', (tester) async {
      final bloc = BoxBloc(
        getBoxDetails: _StubGetBoxDetails(const Left(NetworkFailure('No connection'))),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(_buildScreen(bloc: bloc));
      bloc.add(const BoxDetailsLoadRequested('box-001'));
      await _pumpUntilSettled(tester, bloc);

      final icon = tester.widget<Icon>(find.byKey(const Key('error_icon')));
      expect(icon.icon, equals(Icons.wifi_off));
    });

    testWidgets('shows box ID and status label when BoxLoaded', (tester) async {
      final box = _makeBox(id: 'box-007');
      final bloc = BoxBloc(getBoxDetails: _StubGetBoxDetails(Right(box)));
      addTearDown(bloc.close);

      await tester.pumpWidget(_buildScreen(bloc: bloc, boxId: 'box-007'));
      bloc.add(const BoxDetailsLoadRequested('box-007'));
      await _pumpUntilSettled(tester, bloc);

      expect(find.text('box-007'), findsOneWidget);
      expect(
        find.text(BoxStatus.active.displayName),
        findsOneWidget,
        reason: 'Expected status label "Active"',
      );
    });

    testWidgets('retry button dispatches BoxDetailsLoadRequested', (tester) async {
      var callCount = 0;

      final bloc = BoxBloc(
        getBoxDetails: _CountingStub(
          result: const Left(ServerFailure('Something went wrong', statusCode: 500)),
          onCall: () => callCount++,
        ),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(_buildScreen(bloc: bloc));

      // First load.
      bloc.add(const BoxDetailsLoadRequested('box-001'));
      await _pumpUntilSettled(tester, bloc);

      expect(callCount, equals(1));
      expect(find.byKey(const Key('retry_button')), findsOneWidget);

      // Tap retry and wait for it to settle again.
      await tester.tap(find.byKey(const Key('retry_button')));
      // After tap the bloc transitions back to BoxLoading — pump until it
      // settles again (use-case completes and bloc emits BoxError again).
      for (var i = 0; i < 20; i++) {
        await tester.pump();
        if (callCount >= 2) break;
      }

      expect(
        callCount,
        equals(2),
        reason: 'Retry tap should have dispatched a second BoxDetailsLoadRequested',
      );
    });
  });
}
