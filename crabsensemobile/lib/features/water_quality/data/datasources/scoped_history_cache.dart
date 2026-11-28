import 'dart:async';

import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';
import '../models/scoped_history_snapshot.dart';

/// Session-bound SQLite cache foundation. One instance per app database.
/// The caller must bind begin/invalidate to authenticated session changes
/// and call invalidate on a denied/revoked scope before enabling UI reads.
/// A cached response is historical evidence, never current authorization.
/// Offline use is limited to five minutes after a verified online response.
class ScopedHistoryCache {
  ScopedHistoryCache(this._db, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;
  Future<void> _tail = Future<void>.value();
  String? _user;
  int _epoch = 0;

  static const maxAge = Duration(minutes: 5);
  static const retention = Duration(days: 7);
  static const maxSnapshots = 32;

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  /// An epoch is a local capability, not an access token.
  Future<int> beginSession(String userId) {
    if (userId.trim().isEmpty) throw ArgumentError('Missing user');
    final epoch = ++_epoch;
    _user = null;
    return _serial(() async {
      await _db.customStatement('DELETE FROM scoped_sensor_history_cache');
      if (_epoch != epoch) throw StateError('Superseded session');
      _user = userId;
      return epoch;
    });
  }

  Future<void> invalidate() {
    ++_epoch;
    _user = null;
    return _serial(() async {
      await _db.customStatement('DELETE FROM scoped_sensor_history_cache');
    });
  }

  /// Conservative: purge all session history when any scope is denied.
  Future<void> revokeScope() => invalidate();

  bool _active(int epoch) => _user != null && epoch == _epoch;

  /// Accept only a complete response from a successful online request
  /// associated with the same epoch. A 30-day chart is not cached offline.
  Future<bool> saveOnline(int epoch, ScopedHistorySnapshot snapshot) =>
      _serial(() async {
    if (!_active(epoch)) return false;
    final now = _clock().toUtc();
    if (snapshot.query.from.isBefore(now.subtract(retention)) ||
        snapshot.asOf.isAfter(now.add(const Duration(seconds: 1))) ||
        snapshot.asOf.isBefore(now.subtract(maxAge))) {
      return false;
    }
    final user = _user!;
    await _db.transaction(() async {
      await _db.customStatement(
        'DELETE FROM scoped_sensor_history_cache WHERE saved_at_ms < ?',
        [now.subtract(maxAge).millisecondsSinceEpoch],
      );
      await _db.customStatement(
        'INSERT OR REPLACE INTO scoped_sensor_history_cache '
        '(user_id,query_key,area_id,saved_at_ms,payload) VALUES (?,?,?,?,?)',
        [user, snapshot.query.key, snapshot.query.areaId,
          now.millisecondsSinceEpoch, snapshot.encodedPages],
      );
      await _db.customStatement(
        'DELETE FROM scoped_sensor_history_cache WHERE rowid IN '
        '(SELECT rowid FROM scoped_sensor_history_cache '
        'ORDER BY saved_at_ms DESC, rowid DESC LIMIT -1 OFFSET ?)',
        [maxSnapshots],
      );
    });
    return _active(epoch);
  });

  Future<ScopedHistorySnapshot?> read(
    int epoch, ScopedHistoryQuery query,
  ) => _serial(() async {
    if (!_active(epoch)) return null;
    final now = _clock().toUtc();
    final rows = await _db.customSelect(
      'SELECT saved_at_ms,payload FROM scoped_sensor_history_cache '
      'WHERE user_id=? AND query_key=? AND area_id=?',
      variables: [
        Variable.withString(_user!),
        Variable.withString(query.key),
        Variable.withString(query.areaId),
      ],
    ).get();
    if (!_active(epoch) || rows.length != 1) return null;
    final row = rows.single;
    final saved = DateTime.fromMillisecondsSinceEpoch(
      row.read<int>('saved_at_ms'), isUtc: true,
    );
    if (saved.isAfter(now) || now.difference(saved) > maxAge ||
        query.from.isBefore(now.subtract(retention))) return null;
    try {
      final snapshot = ScopedHistorySnapshot.decode(
        query, row.read<String>('payload'),
      );
      if (snapshot.asOf.isAfter(now.add(const Duration(seconds: 1))) ||
          now.difference(snapshot.asOf) > maxAge) return null;
      return _active(epoch) ? snapshot : null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  });
}
