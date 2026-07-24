import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// Base class for all QR scanner events.
abstract class ScannerEvent extends Equatable {
  const ScannerEvent();

  @override
  List<Object?> get props => [];
}

class ScannerStarted extends ScannerEvent {
  const ScannerStarted();
}

class QRCodeDetected extends ScannerEvent {
  const QRCodeDetected({required this.rawValue});

  final String rawValue;

  @override
  List<Object?> get props => [rawValue];
}

class CameraPermissionRequested extends ScannerEvent {
  const CameraPermissionRequested({this.context});

  final BuildContext? context;

  @override
  List<Object?> get props => [];
}

class ScannerStopped extends ScannerEvent {
  const ScannerStopped();
}

class FlashlightToggled extends ScannerEvent {
  const FlashlightToggled();
}

class CameraFacingToggled extends ScannerEvent {
  const CameraFacingToggled();
}

class ContinuousScanModeToggled extends ScannerEvent {
  const ContinuousScanModeToggled();
}

class ScannerReset extends ScannerEvent {
  const ScannerReset();
}

class FetchBoxData extends ScannerEvent {
  const FetchBoxData({required this.rawValue});

  final String rawValue;

  @override
  List<Object?> get props => [rawValue];
}

class LoadScanHistory extends ScannerEvent {
  const LoadScanHistory();
}

class DismissQuickResult extends ScannerEvent {
  const DismissQuickResult();
}

class RescanFromHistory extends ScannerEvent {
  const RescanFromHistory({required this.rawValue});

  final String rawValue;

  @override
  List<Object?> get props => [rawValue];
}

class SyncWhenOnlineRequested extends ScannerEvent {
  const SyncWhenOnlineRequested();
}
