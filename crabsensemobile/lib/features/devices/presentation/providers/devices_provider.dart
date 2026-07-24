import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/di/injection.dart';
import '../../data/devices_repository.dart';
import '../../data/models/iot_device.dart';

final devicesRepositoryProvider = Provider<DevicesRepository>(
  (ref) => DevicesRepositoryImpl(secureStorage: sl<FlutterSecureStorage>()),
);

class DevicesState {
  const DevicesState({
    required this.devices,
    this.filter = DevicesFilter.all,
    this.typeFilter = DevicesTypeFilter.all,
    this.isLoading = false,
    this.error,
  });

  final List<IotDevice> devices;
  final DevicesFilter filter;
  final DevicesTypeFilter typeFilter;
  final bool isLoading;
  final String? error;

  int get onlineCount => devices.where((d) => d.isOnline).length;
  int get offlineCount => devices.length - onlineCount;

  List<IotDevice> get filtered {
    var list = devices;
    switch (filter) {
      case DevicesFilter.online:
        list = list.where((d) => d.isOnline).toList();
      case DevicesFilter.offline:
        list = list.where((d) => !d.isOnline).toList();
      case DevicesFilter.all:
        break;
    }
    switch (typeFilter) {
      case DevicesTypeFilter.all:
        break;
      case DevicesTypeFilter.esp:
        list = list
            .where((d) {
              final t = d.deviceType.toLowerCase();
              return t.contains('esp') ||
                  t.contains('controller') ||
                  t.contains('gateway');
            })
            .toList();
      case DevicesTypeFilter.camera:
        list = list
            .where((d) => d.deviceType.toLowerCase().contains('cam'))
            .toList();
      case DevicesTypeFilter.sensor:
        list = list
            .where((d) => d.deviceType.toLowerCase().contains('sensor'))
            .toList();
      case DevicesTypeFilter.pump:
        list = list
            .where((d) {
              final t = d.deviceType.toLowerCase();
              return t.contains('pump') || t.contains('bơm');
            })
            .toList();
      case DevicesTypeFilter.valve:
        list = list
            .where((d) {
              final t = d.deviceType.toLowerCase();
              return t.contains('valve') || t.contains('van');
            })
            .toList();
    }
    return list;
  }

  DevicesState copyWith({
    List<IotDevice>? devices,
    DevicesFilter? filter,
    DevicesTypeFilter? typeFilter,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return DevicesState(
      devices: devices ?? this.devices,
      filter: filter ?? this.filter,
      typeFilter: typeFilter ?? this.typeFilter,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DevicesNotifier extends StateNotifier<DevicesState> {
  DevicesNotifier(this._repo) : super(const DevicesState(devices: [], isLoading: true)) {
    load();
  }

  final DevicesRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getDevices();
      state = state.copyWith(devices: list, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(DevicesFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setTypeFilter(DevicesTypeFilter typeFilter) {
    state = state.copyWith(typeFilter: typeFilter);
  }
}

final devicesStateProvider =
    StateNotifierProvider.autoDispose<DevicesNotifier, DevicesState>((ref) {
  return DevicesNotifier(ref.watch(devicesRepositoryProvider));
});
