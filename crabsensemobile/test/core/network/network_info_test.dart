import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crabsensemobile/core/network/network_info.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeConnectivity implements Connectivity {
  dynamic checkConnectivityResult = <ConnectivityResult>[ConnectivityResult.none];
  final _controller = StreamController<dynamic>.broadcast();

  void emit(dynamic result) {
    _controller.add(result);
  }

  @override
  Future<dynamic> checkConnectivity() async {
    return checkConnectivityResult;
  }

  @override
  Stream<dynamic> get onConnectivityChanged => _controller.stream;

  void dispose() {
    _controller.close();
  }
}

void main() {
  late FakeConnectivity fakeConnectivity;
  late NetworkInfoImpl networkInfo;

  setUp(() {
    fakeConnectivity = FakeConnectivity();
    networkInfo = NetworkInfoImpl(fakeConnectivity);
  });

  tearDown(() {
    fakeConnectivity.dispose();
  });

  group('isConnected', () {
    test('returns true when ConnectivityResult.wifi is present', () async {
      fakeConnectivity.checkConnectivityResult = [ConnectivityResult.wifi];

      final result = await networkInfo.isConnected;

      expect(result, isTrue);
    });

    test('returns true when ConnectivityResult.mobile is present', () async {
      fakeConnectivity.checkConnectivityResult = [ConnectivityResult.mobile];

      final result = await networkInfo.isConnected;

      expect(result, isTrue);
    });

    test('returns true when ConnectivityResult.ethernet is present', () async {
      fakeConnectivity.checkConnectivityResult = [ConnectivityResult.ethernet];

      final result = await networkInfo.isConnected;

      expect(result, isTrue);
    });

    test('returns false when ConnectivityResult.none is returned', () async {
      fakeConnectivity.checkConnectivityResult = [ConnectivityResult.none];

      final result = await networkInfo.isConnected;

      expect(result, isFalse);
    });

    test('handles single ConnectivityResult object seamlessly', () async {
      fakeConnectivity.checkConnectivityResult = ConnectivityResult.wifi;

      final result = await networkInfo.isConnected;

      expect(result, isTrue);
    });
  });

  group('currentNetworkTypes & primaryNetworkType', () {
    test('detects wifi, mobile, and ethernet connection types', () async {
      fakeConnectivity.checkConnectivityResult = [
        ConnectivityResult.wifi,
        ConnectivityResult.mobile,
      ];

      final types = await networkInfo.currentNetworkTypes;
      final primary = await networkInfo.primaryNetworkType;

      expect(types, containsAll([NetworkType.wifi, NetworkType.mobile]));
      expect(primary, equals(NetworkType.wifi));
    });

    test('returns none when disconnected', () async {
      fakeConnectivity.checkConnectivityResult = [ConnectivityResult.none];

      final types = await networkInfo.currentNetworkTypes;
      final primary = await networkInfo.primaryNetworkType;

      expect(types, equals([NetworkType.none]));
      expect(primary, equals(NetworkType.none));
    });
  });

  group('stream-based connectivity updates', () {
    test('onConnectivityChanged emits online/offline status updates', () async {
      expectLater(
        networkInfo.onConnectivityChanged,
        emitsInOrder([true, false, true]),
      );

      fakeConnectivity.emit([ConnectivityResult.wifi]);
      fakeConnectivity.emit([ConnectivityResult.none]);
      fakeConnectivity.emit([ConnectivityResult.mobile]);
    });

    test('onNetworkTypesChanged emits updated network types', () async {
      expectLater(
        networkInfo.onNetworkTypesChanged,
        emitsInOrder([
          [NetworkType.wifi],
          [NetworkType.none],
          [NetworkType.ethernet],
        ]),
      );

      fakeConnectivity.emit([ConnectivityResult.wifi]);
      fakeConnectivity.emit([ConnectivityResult.none]);
      fakeConnectivity.emit([ConnectivityResult.ethernet]);
    });
  });
}
