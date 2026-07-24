// ignore_for_file: lines_longer_than_80_chars, unawaited_futures

import 'dart:async';

import 'package:crabsensemobile/core/errors/failures.dart';
import 'package:crabsensemobile/features/alert/domain/entities/alert.dart';
import 'package:crabsensemobile/features/alert/domain/entities/alert_enums.dart';
import 'package:crabsensemobile/features/alert/domain/repositories/alert_repository.dart';
import 'package:crabsensemobile/features/alert/domain/usecases/acknowledge_alert_usecase.dart';
import 'package:crabsensemobile/features/alert/domain/usecases/dismiss_alert_usecase.dart';
import 'package:crabsensemobile/features/alert/domain/usecases/get_alerts_usecase.dart';
import 'package:crabsensemobile/features/alert/presentation/bloc/alert_bloc.dart';
import 'package:crabsensemobile/features/alert/presentation/bloc/alert_event.dart';
import 'package:crabsensemobile/features/alert/presentation/bloc/alert_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Alert _makeAlert({String id = 'alert-001', AlertStatus status = AlertStatus.unread}) => Alert(
  id: id,
  type: AlertType.waterQuality,
  severity: AlertSeverity.warning,
  title: 'pH out of range',
  message: 'pH level is above threshold',
  recommendedActions: const ['Check pH sensor', 'Add buffer solution'],
  createdAt: DateTime(2024, 1, 15, 10, 0),
  status: status,
);

// ---------------------------------------------------------------------------
// Stubs
// ---------------------------------------------------------------------------

/// Stub for [GetAlertsUseCase].
class _StubGetAlerts implements GetAlertsUseCase {
  _StubGetAlerts(this._result);
  final Either<Failure, List<Alert>> _result;

  @override
  Future<Either<Failure, List<Alert>>> call(GetAlertsParams params) async => _result;
}

/// Stub for [AcknowledgeAlertUseCase].
class _StubAcknowledge implements AcknowledgeAlertUseCase {
  _StubAcknowledge(this._result);
  final Either<Failure, Alert> _result;

  @override
  Future<Either<Failure, Alert>> call(AcknowledgeAlertParams params) async => _result;
}

/// Stub for [DismissAlertUseCase].
class _StubDismiss implements DismissAlertUseCase {
  _StubDismiss(this._result);
  final Either<Failure, Alert> _result;

  @override
  Future<Either<Failure, Alert>> call(DismissAlertParams params) async => _result;
}

/// Minimal stub for [AlertRepository] used by [AlertBloc] for
/// [getUnreadCount] and [watchUnreadCount].
class _StubAlertRepository implements AlertRepository {
  _StubAlertRepository({int unreadCount = 0}) : _unreadCount = unreadCount;

  final int _unreadCount;
  final StreamController<int> _controller = StreamController<int>.broadcast();

  @override
  Future<Either<Failure, int>> getUnreadCount() async => Right(_unreadCount);

  @override
  Stream<int> watchUnreadCount() => _controller.stream;

  // Unused methods — satisfy the interface.

  @override
  Future<Either<Failure, List<Alert>>> getAlerts({AlertFilters? filters}) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Alert>> getAlertById(String alertId) => throw UnimplementedError();

  @override
  Future<Either<Failure, Alert>> acknowledgeAlert({
    required String alertId,
    required String acknowledgedBy,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, Alert>> dismissAlert(String alertId) => throw UnimplementedError();

  void dispose() => _controller.close();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AlertBloc', () {
    // ── Initial state ───────────────────────────────────────────────────────

    group('initial state', () {
      test('is AlertInitial before any event', () {
        final repo = _StubAlertRepository();
        final bloc = AlertBloc(
          getAlerts: _StubGetAlerts(const Right([])),
          acknowledgeAlert: _StubAcknowledge(Right(_makeAlert())),
          dismissAlert: _StubDismiss(Right(_makeAlert())),
          repository: repo,
        );

        expect(bloc.state, isA<AlertInitial>());
        bloc.close();
        repo.dispose();
      });
    });

    // ── Acknowledge success (online) ────────────────────────────────────────

    group('AlertAcknowledgeRequested — success (online)', () {
      test('emits [AlertActionInProgress, AlertLoaded] with updated list', () async {
        final original = _makeAlert(status: AlertStatus.unread);
        final updated = _makeAlert(status: AlertStatus.acknowledged);
        final repo = _StubAlertRepository();

        // After the action, getAlerts returns the updated list.
        final bloc = AlertBloc(
          getAlerts: _StubGetAlerts(Right([updated])),
          acknowledgeAlert: _StubAcknowledge(Right(updated)),
          dismissAlert: _StubDismiss(Right(_makeAlert(status: AlertStatus.dismissed))),
          repository: repo,
        );

        // Drive to AlertLoaded first.
        bloc.add(const AlertLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(bloc.state, isA<AlertLoaded>());

        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AlertActionInProgress>().having(
              (s) => s.processingAlertId,
              'processingAlertId',
              original.id,
            ),
            isA<AlertLoaded>().having(
              (s) => s.alerts.first.status,
              'status',
              AlertStatus.acknowledged,
            ),
          ]),
        );

        bloc.add(AlertAcknowledgeRequested(alertId: original.id, acknowledgedBy: 'user-001'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await bloc.close();
        repo.dispose();
      });
    });

    // ── Dismiss success (online) ────────────────────────────────────────────

    group('AlertDismissRequested — success (online)', () {
      test('emits [AlertActionInProgress, AlertLoaded] with updated list', () async {
        final original = _makeAlert(status: AlertStatus.unread);
        final dismissed = _makeAlert(status: AlertStatus.dismissed);
        final repo = _StubAlertRepository();

        final bloc = AlertBloc(
          getAlerts: _StubGetAlerts(Right([dismissed])),
          acknowledgeAlert: _StubAcknowledge(Right(_makeAlert(status: AlertStatus.acknowledged))),
          dismissAlert: _StubDismiss(Right(dismissed)),
          repository: repo,
        );

        // Drive to AlertLoaded.
        bloc.add(const AlertLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(bloc.state, isA<AlertLoaded>());

        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AlertActionInProgress>().having(
              (s) => s.processingAlertId,
              'processingAlertId',
              original.id,
            ),
            isA<AlertLoaded>().having(
              (s) => s.alerts.first.status,
              'status',
              AlertStatus.dismissed,
            ),
          ]),
        );

        bloc.add(AlertDismissRequested(alertId: original.id));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await bloc.close();
        repo.dispose();
      });
    });

    // ── Acknowledge offline (queued) ────────────────────────────────────────

    group('AlertAcknowledgeRequested — offline queued (Req 9.10)', () {
      /// When offline the repository returns Right(Alert) with the locally-
      /// optimistic update (queued to SyncQueue). The BLoC should behave
      /// identically to the online success path from the UI perspective.
      test(
        'emits [AlertActionInProgress, AlertLoaded] when repository returns Right offline',
        () async {
          final updatedOffline = _makeAlert(status: AlertStatus.acknowledged);
          final repo = _StubAlertRepository();

          final bloc = AlertBloc(
            getAlerts: _StubGetAlerts(Right([updatedOffline])),
            // Simulate offline: repository still returns Right(Alert)
            acknowledgeAlert: _StubAcknowledge(Right(updatedOffline)),
            dismissAlert: _StubDismiss(Right(_makeAlert(status: AlertStatus.dismissed))),
            repository: repo,
          );

          // Drive to AlertLoaded.
          bloc.add(const AlertLoadRequested());
          await Future<void>.delayed(const Duration(milliseconds: 50));
          expect(bloc.state, isA<AlertLoaded>());

          // Offline-queued success emits the same sequence as online success.
          expectLater(
            bloc.stream,
            emitsInOrder([isA<AlertActionInProgress>(), isA<AlertLoaded>()]),
          );

          bloc.add(
            const AlertAcknowledgeRequested(alertId: 'alert-001', acknowledgedBy: 'user-001'),
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await bloc.close();
          repo.dispose();
        },
      );
    });

    // ── Acknowledge failure — server error ──────────────────────────────────

    group('AlertAcknowledgeRequested — server failure', () {
      test('emits [AlertActionInProgress, AlertError] with isOffline=false', () async {
        final alert = _makeAlert(status: AlertStatus.unread);
        final repo = _StubAlertRepository();

        final bloc = AlertBloc(
          getAlerts: _StubGetAlerts(Right([alert])),
          acknowledgeAlert: _StubAcknowledge(
            const Left(ServerFailure('Internal server error', statusCode: 500)),
          ),
          dismissAlert: _StubDismiss(Right(_makeAlert(status: AlertStatus.dismissed))),
          repository: repo,
        );

        // Drive to AlertLoaded.
        bloc.add(const AlertLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(bloc.state, isA<AlertLoaded>());

        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AlertActionInProgress>().having(
              (s) => s.processingAlertId,
              'processingAlertId',
              alert.id,
            ),
            isA<AlertError>()
                .having((s) => s.isOffline, 'isOffline', isFalse)
                .having((s) => s.message, 'message', 'Internal server error'),
          ]),
        );

        bloc.add(AlertAcknowledgeRequested(alertId: alert.id, acknowledgedBy: 'user-001'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await bloc.close();
        repo.dispose();
      });

      test('emits AlertError with isOffline=true on NetworkFailure', () async {
        final alert = _makeAlert(status: AlertStatus.unread);
        final repo = _StubAlertRepository();

        final bloc = AlertBloc(
          getAlerts: _StubGetAlerts(Right([alert])),
          acknowledgeAlert: _StubAcknowledge(const Left(NetworkFailure('No internet connection'))),
          dismissAlert: _StubDismiss(Right(_makeAlert(status: AlertStatus.dismissed))),
          repository: repo,
        );

        // Drive to AlertLoaded.
        bloc.add(const AlertLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(bloc.state, isA<AlertLoaded>());

        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AlertActionInProgress>(),
            isA<AlertError>().having((s) => s.isOffline, 'isOffline', isTrue),
          ]),
        );

        bloc.add(AlertAcknowledgeRequested(alertId: alert.id, acknowledgedBy: 'user-001'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await bloc.close();
        repo.dispose();
      });
    });

    // ── AlertActionInProgress carries the current list and processingAlertId ─

    group('AlertActionInProgress state', () {
      test('carries the current alert list and correct processingAlertId', () async {
        final alert = _makeAlert(status: AlertStatus.unread);
        final repo = _StubAlertRepository(unreadCount: 1);

        final bloc = AlertBloc(
          getAlerts: _StubGetAlerts(Right([alert])),
          acknowledgeAlert: _StubAcknowledge(Right(_makeAlert(status: AlertStatus.acknowledged))),
          dismissAlert: _StubDismiss(Right(_makeAlert(status: AlertStatus.dismissed))),
          repository: repo,
        );

        bloc.add(const AlertLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final loadedState = bloc.state as AlertLoaded;
        expect(loadedState.alerts, hasLength(1));

        // Capture the first AlertActionInProgress state.
        AlertActionInProgress? inProgressState;
        final subscription = bloc.stream.listen((state) {
          if (state is AlertActionInProgress) {
            inProgressState = state;
          }
        });

        bloc.add(AlertAcknowledgeRequested(alertId: alert.id, acknowledgedBy: 'user-001'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        expect(inProgressState, isNotNull);
        expect(inProgressState!.processingAlertId, equals(alert.id));
        expect(inProgressState!.alerts, equals(loadedState.alerts));

        await bloc.close();
        repo.dispose();
      });
    });
  });
}
