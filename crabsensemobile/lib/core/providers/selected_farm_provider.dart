import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../di/injection.dart';

/// Trại / khu nuôi đang điều hành — dùng chung Home, Boxes, Alerts, …
class SelectedFarm {
  const SelectedFarm({this.id, this.name = ''});

  final String? id;
  final String name;

  bool get hasSelection => id != null && id!.isNotEmpty;

  SelectedFarm copyWith({String? id, String? name}) => SelectedFarm(
        id: id ?? this.id,
        name: name ?? this.name,
      );
}

class SelectedFarmNotifier extends StateNotifier<SelectedFarm> {
  SelectedFarmNotifier(this._storage) : super(const SelectedFarm()) {
    _restore();
  }

  static const _kId = 'selected_farming_area_id';
  static const _kName = 'selected_farming_area_name';

  final FlutterSecureStorage _storage;
  final Completer<void> _ready = Completer<void>();

  /// Hoàn tất đọc trại đã lưu (gọi trước loadData các tab).
  Future<void> get ready => _ready.future;

  Future<void> _restore() async {
    try {
      final id = await _storage.read(key: _kId);
      final name = await _storage.read(key: _kName);
      if (id != null && id.isNotEmpty) {
        state = SelectedFarm(id: id, name: name ?? '');
      }
    } catch (_) {
      // ignore restore errors
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  /// Cập nhật trại đang chọn (no-op nếu cùng id).
  Future<void> select(String? id, {String? name}) async {
    if (id == null || id.isEmpty) return;
    if (state.id == id) {
      if (name != null &&
          name.isNotEmpty &&
          name != state.name) {
        state = SelectedFarm(id: id, name: name);
        await _persist();
      }
      return;
    }
    state = SelectedFarm(id: id, name: name ?? state.name);
    await _persist();
  }

  /// Đồng bộ từ dữ liệu đã load (không ghi đè nếu đã có selection khác).
  Future<void> syncFromLoaded({
    required String? id,
    String? name,
    bool force = false,
  }) async {
    if (id == null || id.isEmpty) return;
    if (!force && state.hasSelection && state.id != id) {
      // Giữ selection global; tab sẽ refetch theo id đó.
      return;
    }
    await select(id, name: name);
  }

  Future<void> _persist() async {
    try {
      final id = state.id;
      if (id == null || id.isEmpty) {
        await _storage.delete(key: _kId);
        await _storage.delete(key: _kName);
        return;
      }
      await _storage.write(key: _kId, value: id);
      await _storage.write(key: _kName, value: state.name);
    } catch (_) {}
  }
}

final selectedFarmProvider =
    StateNotifierProvider<SelectedFarmNotifier, SelectedFarm>((ref) {
  return SelectedFarmNotifier(sl<FlutterSecureStorage>());
});
