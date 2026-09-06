import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Network connection type detected by [NetworkInfo].
enum NetworkType {
  wifi,
  mobile,
  ethernet,
  vpn,
  bluetooth,
  other,
  none,
}

/// Abstract interface for checking network connectivity and monitoring changes.
abstract class NetworkInfo {
  /// Returns true if device has an active network connection (WiFi, mobile, ethernet, VPN).
  Future<bool> get isConnected;

  /// Returns current list of active network connection types.
  Future<List<NetworkType>> get currentNetworkTypes =>
      isConnected.then((connected) => connected ? [NetworkType.other] : [NetworkType.none]);

  /// Primary network type or [NetworkType.none] if disconnected.
  Future<NetworkType> get primaryNetworkType =>
      currentNetworkTypes.then((types) => types.firstOrNull ?? NetworkType.none);

  /// Stream emitting boolean status updates when connectivity changes (true = online, false = offline).
  Stream<bool> get onConnectivityChanged => const Stream.empty();

  /// Stream emitting list of active network connection types when connectivity changes.
  Stream<List<NetworkType>> get onNetworkTypesChanged => const Stream.empty();
}

/// Implementation of [NetworkInfo] using the connectivity_plus package.
class NetworkInfoImpl implements NetworkInfo {
  const NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    // Browser connectivity_plus often reports "none" even when online.
    if (kIsWeb) return true;
    final results = await _getResults();
    return _isConnectedFromResults(results);
  }

  @override
  Future<List<NetworkType>> get currentNetworkTypes async {
    final results = await _getResults();
    return _mapResultsToNetworkTypes(results);
  }

  @override
  Future<NetworkType> get primaryNetworkType async {
    final types = await currentNetworkTypes;
    return _determinePrimaryType(types);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((dynamic event) {
      final results = _parseResults(event);
      return _isConnectedFromResults(results);
    }).distinct();
  }

  @override
  Stream<List<NetworkType>> get onNetworkTypesChanged {
    return _connectivity.onConnectivityChanged.map((dynamic event) {
      final results = _parseResults(event);
      return _mapResultsToNetworkTypes(results);
    });
  }

  Future<List<ConnectivityResult>> _getResults() async {
    final dynamic raw = await _connectivity.checkConnectivity();
    return _parseResults(raw);
  }

  List<ConnectivityResult> _parseResults(dynamic raw) {
    if (raw is List<ConnectivityResult>) {
      return raw;
    } else if (raw is List) {
      return raw.whereType<ConnectivityResult>().toList();
    } else if (raw is ConnectivityResult) {
      return [raw];
    }
    return [];
  }

  bool _isConnectedFromResults(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn ||
          r == ConnectivityResult.other,
    );
  }

  List<NetworkType> _mapResultsToNetworkTypes(List<ConnectivityResult> results) {
    final types = <NetworkType>[];
    for (final r in results) {
      switch (r) {
        case ConnectivityResult.wifi:
          types.add(NetworkType.wifi);
          break;
        case ConnectivityResult.mobile:
          types.add(NetworkType.mobile);
          break;
        case ConnectivityResult.ethernet:
          types.add(NetworkType.ethernet);
          break;
        case ConnectivityResult.vpn:
          types.add(NetworkType.vpn);
          break;
        case ConnectivityResult.bluetooth:
          types.add(NetworkType.bluetooth);
          break;
        case ConnectivityResult.other:
          types.add(NetworkType.other);
          break;
        case ConnectivityResult.none:
          types.add(NetworkType.none);
          break;
      }
    }
    if (types.isEmpty) {
      return [NetworkType.none];
    }
    return types;
  }

  NetworkType _determinePrimaryType(List<NetworkType> types) {
    if (types.contains(NetworkType.wifi)) return NetworkType.wifi;
    if (types.contains(NetworkType.ethernet)) return NetworkType.ethernet;
    if (types.contains(NetworkType.mobile)) return NetworkType.mobile;
    if (types.contains(NetworkType.vpn)) return NetworkType.vpn;
    if (types.contains(NetworkType.bluetooth)) return NetworkType.bluetooth;
    if (types.contains(NetworkType.other)) return NetworkType.other;
    return NetworkType.none;
  }
}
