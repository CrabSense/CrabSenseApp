import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/services/camera_permission_service.dart';
import '../../domain/entities/scan_quick_result.dart';
import '../../domain/repositories/scanner_repository.dart';
import '../../domain/usecases/scan_qr_quick_result_usecase.dart';
import '../../domain/usecases/validate_qr_code_usecase.dart';
import 'scanner_event.dart';
import 'scanner_state.dart';

/// BLoC for Scan QR tab — camera, permission, quick-result sheet, history.
class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  ScannerBloc({
    required ScanQRQuickResultUseCase scanQRQuickResultUseCase,
    required ScannerRepository scannerRepository,
  })  : _scanQuick = scanQRQuickResultUseCase,
        _repository = scannerRepository,
        super(const ScannerInitial()) {
    on<CameraPermissionRequested>(_onCameraPermissionRequested);
    on<ScannerStarted>(_onScannerStarted);
    on<QRCodeDetected>(_onQRCodeDetected);
    on<FetchBoxData>(_onFetchBoxData);
    on<ScannerStopped>(_onScannerStopped);
    on<FlashlightToggled>(_onFlashlightToggled);
    on<CameraFacingToggled>(_onCameraFacingToggled);
    on<ContinuousScanModeToggled>(_onContinuousScanModeToggled);
    on<ScannerReset>(_onScannerReset);
    on<LoadScanHistory>(_onLoadScanHistory);
    on<DismissQuickResult>(_onDismissQuickResult);
    on<RescanFromHistory>(_onRescanFromHistory);
    on<SyncWhenOnlineRequested>(_onSyncWhenOnlineRequested);
  }

  final ScanQRQuickResultUseCase _scanQuick;
  final ScannerRepository _repository;
  static const _validator = ValidateQRCodeUseCase();

  String? _lastAcceptedRaw;
  DateTime? _lastAcceptedAt;

  ScannerSessionFlags get _flags => state.flags;

  Future<void> _onCameraPermissionRequested(
    CameraPermissionRequested event,
    Emitter<ScannerState> emit,
  ) async {
    emit(ScannerPermissionChecking(flags: _flags));

    final context = event.context;
    if (context == null || !context.mounted) {
      emit(ScannerPermissionDenied(flags: _flags));
      return;
    }

    final result = await CameraPermissionService.request(context);

    switch (result) {
      case PermissionResult.granted:
      case PermissionResult.restricted:
        emit(ScannerPermissionGranted(flags: _flags));
      case PermissionResult.permanentlyDenied:
        emit(ScannerPermissionPermanentlyDenied(flags: _flags));
      case PermissionResult.denied:
        emit(ScannerPermissionDenied(flags: _flags));
    }

    add(const LoadScanHistory());
  }

  Future<void> _onScannerStarted(
    ScannerStarted event,
    Emitter<ScannerState> emit,
  ) async {
    emit(ScannerActive(flags: _flags));
  }

  Future<void> _onQRCodeDetected(
    QRCodeDetected event,
    Emitter<ScannerState> emit,
  ) async {
    final current = state;
    // Throttle while loading / processing.
    if (current is ScannerProcessing || current is BoxFetchInProgress) {
      return;
    }
    // Single-scan: ignore while sheet is open.
    if (current is QuickResultReady && !current.continuousScan) {
      return;
    }
    // Continuous: ignore same code within 2.5s.
    if (current is QuickResultReady && current.continuousScan) {
      final now = DateTime.now();
      if (_lastAcceptedRaw == event.rawValue &&
          _lastAcceptedAt != null &&
          now.difference(_lastAcceptedAt!) < const Duration(milliseconds: 2500)) {
        return;
      }
    }

    emit(ScannerProcessing(rawValue: event.rawValue, flags: _flags));

    final validationResult = _validator(rawValue: event.rawValue);
    validationResult.fold(
      (failure) {
        emit(
          ScannerError(
            message: failure.message.isNotEmpty
                ? failure.message
                : 'QR không thuộc hệ thống CrabSense.',
            code: failure.code,
            flags: _flags,
          ),
        );
      },
      (_) => add(FetchBoxData(rawValue: event.rawValue)),
    );
  }

  Future<void> _onFetchBoxData(
    FetchBoxData event,
    Emitter<ScannerState> emit,
  ) async {
    emit(BoxFetchInProgress(rawValue: event.rawValue, flags: _flags));

    final result = await _scanQuick(rawValue: event.rawValue);

    await result.fold(
      (failure) async {
        final history = await _loadHistorySafe();
        final flags = _flags.copyWith(history: history);

        if (failure is NetworkFailure ||
            failure.message.toLowerCase().contains('network') ||
            failure.message.toLowerCase().contains('internet')) {
          emit(
            ScanQueuedOffline(
              qrCode: event.rawValue,
              flags: flags,
            ),
          );
          return;
        }

        emit(
          BoxFetchFailure(
            message: failure.message.isNotEmpty
                ? failure.message
                : 'QR không thuộc hệ thống CrabSense.',
            rawValue: event.rawValue,
            code: failure.code,
            flags: flags,
          ),
        );
      },
      (quick) async {
        _lastAcceptedRaw = event.rawValue;
        _lastAcceptedAt = DateTime.now();
        final history = await _loadHistorySafe();
        final flags = _flags.copyWith(
          history: history,
          farmLabel: quick.farmName.isNotEmpty ? quick.farmName : _flags.farmLabel,
        );
        emit(QuickResultReady(result: quick, flags: flags));
      },
    );
  }

  Future<void> _onScannerStopped(
    ScannerStopped event,
    Emitter<ScannerState> emit,
  ) async {
    emit(ScannerInactive(flags: _flags));
  }

  Future<void> _onFlashlightToggled(
    FlashlightToggled event,
    Emitter<ScannerState> emit,
  ) async {
    emit(_copyWithFlags(_flags.copyWith(isFlashlightOn: !_flags.isFlashlightOn)));
  }

  Future<void> _onCameraFacingToggled(
    CameraFacingToggled event,
    Emitter<ScannerState> emit,
  ) async {
    emit(_copyWithFlags(_flags.copyWith(useFrontCamera: !_flags.useFrontCamera)));
  }

  Future<void> _onContinuousScanModeToggled(
    ContinuousScanModeToggled event,
    Emitter<ScannerState> emit,
  ) async {
    emit(_copyWithFlags(_flags.copyWith(continuousScan: !_flags.continuousScan)));
  }

  Future<void> _onScannerReset(
    ScannerReset event,
    Emitter<ScannerState> emit,
  ) async {
    emit(ScannerActive(flags: _flags));
  }

  Future<void> _onDismissQuickResult(
    DismissQuickResult event,
    Emitter<ScannerState> emit,
  ) async {
    emit(ScannerActive(flags: _flags));
  }

  Future<void> _onRescanFromHistory(
    RescanFromHistory event,
    Emitter<ScannerState> emit,
  ) async {
    add(FetchBoxData(rawValue: event.rawValue));
  }

  Future<void> _onLoadScanHistory(
    LoadScanHistory event,
    Emitter<ScannerState> emit,
  ) async {
    final history = await _loadHistorySafe();
    emit(_copyWithFlags(_flags.copyWith(history: history)));
  }

  Future<void> _onSyncWhenOnlineRequested(
    SyncWhenOnlineRequested event,
    Emitter<ScannerState> emit,
  ) async {
    // Re-fetch last offline QR when connectivity returns.
    final current = state;
    if (current is ScanQueuedOffline) {
      add(FetchBoxData(rawValue: current.qrCode));
    } else if (current is QuickResultReady && current.result.isOffline) {
      add(FetchBoxData(rawValue: current.result.rawValue));
    }
  }

  Future<List<ScanHistoryEntry>> _loadHistorySafe() async {
    final result = await _repository.getScanHistory();
    return result.fold((_) => _flags.history, (h) => h);
  }

  ScannerState _copyWithFlags(ScannerSessionFlags flags) {
    final s = state;
    if (s is ScannerActive) return ScannerActive(flags: flags);
    if (s is ScannerProcessing) {
      return ScannerProcessing(rawValue: s.rawValue, flags: flags);
    }
    if (s is BoxFetchInProgress) {
      return BoxFetchInProgress(rawValue: s.rawValue, flags: flags);
    }
    if (s is QuickResultReady) {
      return QuickResultReady(result: s.result, flags: flags);
    }
    if (s is BoxFetchSuccess) {
      return BoxFetchSuccess(boxId: s.boxId, flags: flags);
    }
    if (s is BoxFetchFailure) {
      return BoxFetchFailure(
        message: s.message,
        rawValue: s.rawValue,
        code: s.code,
        flags: flags,
      );
    }
    if (s is ScanQueuedOffline) {
      return ScanQueuedOffline(
        qrCode: s.qrCode,
        cachedResult: s.cachedResult,
        flags: flags,
      );
    }
    if (s is ScannerSuccess) {
      return ScannerSuccess(scanResult: s.scanResult, flags: flags);
    }
    if (s is ScannerError) {
      return ScannerError(message: s.message, code: s.code, flags: flags);
    }
    if (s is ScannerPermissionGranted) {
      return ScannerPermissionGranted(flags: flags);
    }
    if (s is ScannerPermissionDenied) {
      return ScannerPermissionDenied(flags: flags);
    }
    if (s is ScannerPermissionPermanentlyDenied) {
      return ScannerPermissionPermanentlyDenied(flags: flags);
    }
    if (s is ScannerPermissionChecking) {
      return ScannerPermissionChecking(flags: flags);
    }
    if (s is ScannerInactive) return ScannerInactive(flags: flags);
    return ScannerActive(flags: flags);
  }
}
