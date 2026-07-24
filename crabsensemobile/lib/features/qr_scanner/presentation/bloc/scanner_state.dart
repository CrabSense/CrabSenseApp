import 'package:equatable/equatable.dart';

import '../../domain/entities/scan_quick_result.dart';
import '../../domain/entities/scan_result.dart';

/// Shared camera / mode flags carried across scanner states.
class ScannerSessionFlags extends Equatable {
  const ScannerSessionFlags({
    this.isFlashlightOn = false,
    this.continuousScan = false,
    this.useFrontCamera = false,
    this.history = const [],
    this.farmLabel = 'Farm hiện tại',
  });

  final bool isFlashlightOn;
  final bool continuousScan;
  final bool useFrontCamera;
  final List<ScanHistoryEntry> history;
  final String farmLabel;

  ScannerSessionFlags copyWith({
    bool? isFlashlightOn,
    bool? continuousScan,
    bool? useFrontCamera,
    List<ScanHistoryEntry>? history,
    String? farmLabel,
  }) =>
      ScannerSessionFlags(
        isFlashlightOn: isFlashlightOn ?? this.isFlashlightOn,
        continuousScan: continuousScan ?? this.continuousScan,
        useFrontCamera: useFrontCamera ?? this.useFrontCamera,
        history: history ?? this.history,
        farmLabel: farmLabel ?? this.farmLabel,
      );

  @override
  List<Object?> get props =>
      [isFlashlightOn, continuousScan, useFrontCamera, history, farmLabel];
}

abstract class ScannerState extends Equatable {
  const ScannerState({this.flags = const ScannerSessionFlags()});

  final ScannerSessionFlags flags;

  bool get isFlashlightOn => flags.isFlashlightOn;
  bool get continuousScan => flags.continuousScan;
  bool get useFrontCamera => flags.useFrontCamera;
  List<ScanHistoryEntry> get history => flags.history;

  @override
  List<Object?> get props => [flags];
}

class ScannerInitial extends ScannerState {
  const ScannerInitial({super.flags});
}

class ScannerActive extends ScannerState {
  const ScannerActive({super.flags});

  ScannerActive copyWith({ScannerSessionFlags? flags}) =>
      ScannerActive(flags: flags ?? this.flags);
}

class ScannerProcessing extends ScannerState {
  const ScannerProcessing({
    required this.rawValue,
    super.flags,
  });

  final String rawValue;

  @override
  List<Object?> get props => [rawValue, flags];
}

class ScannerSuccess extends ScannerState {
  const ScannerSuccess({required this.scanResult, super.flags});

  final ScanResult scanResult;

  @override
  List<Object?> get props => [scanResult, flags];
}

class ScannerError extends ScannerState {
  const ScannerError({
    required this.message,
    this.code,
    super.flags,
  });

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code, flags];
}

class ScannerInactive extends ScannerState {
  const ScannerInactive({super.flags});
}

/// Skeleton loading while enriching box quick-result.
class BoxFetchInProgress extends ScannerState {
  const BoxFetchInProgress({required this.rawValue, super.flags});

  final String rawValue;

  @override
  List<Object?> get props => [rawValue, flags];
}

/// Quick result ready — UI shows bottom sheet (no auto-navigation).
class QuickResultReady extends ScannerState {
  const QuickResultReady({required this.result, super.flags});

  final ScanQuickResult result;

  @override
  List<Object?> get props => [result, flags];
}

/// Legacy alias kept for older listeners — prefer [QuickResultReady].
class BoxFetchSuccess extends ScannerState {
  const BoxFetchSuccess({required this.boxId, super.flags});

  final String boxId;

  @override
  List<Object?> get props => [boxId, flags];
}

class BoxFetchFailure extends ScannerState {
  const BoxFetchFailure({
    required this.message,
    this.rawValue,
    this.code,
    super.flags,
  });

  final String message;
  final String? rawValue;
  final String? code;

  @override
  List<Object?> get props => [message, rawValue, code, flags];
}

class ScanQueuedOffline extends ScannerState {
  const ScanQueuedOffline({
    required this.qrCode,
    this.cachedResult,
    super.flags,
  });

  final String qrCode;
  final ScanQuickResult? cachedResult;

  @override
  List<Object?> get props => [qrCode, cachedResult, flags];
}

class ScannerPermissionChecking extends ScannerState {
  const ScannerPermissionChecking({super.flags});
}

class ScannerPermissionGranted extends ScannerState {
  const ScannerPermissionGranted({super.flags});
}

class ScannerPermissionDenied extends ScannerState {
  const ScannerPermissionDenied({super.flags});
}

class ScannerPermissionPermanentlyDenied extends ScannerState {
  const ScannerPermissionPermanentlyDenied({super.flags});
}
