import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../authentication/data/datasources/auth_local_data_source.dart';
import '../../../authentication/domain/entities/user.dart';
import '../datasources/scoped_history_cache.dart';
import '../models/scoped_history_snapshot.dart';

/// Identity is only held in memory while making an online request.
/// The backend still validates signature, token version, role and area scope.
class HistoryIdentity {
  const HistoryIdentity(this.userId, this.accessToken);
  final String userId;
  final String accessToken;

  bool matches(HistoryIdentity other) =>
      userId == other.userId && accessToken == other.accessToken;
}

Future<HistoryIdentity> readHistoryIdentity(AuthLocalDataSource auth) async {
  final user = await auth.getCachedUser();
  final token = await auth.getAccessToken();
  final parts = token.split('.');
  if (!user.role.canUseMobile || parts.length != 3) {
    throw StateError('History session unavailable');
  }
  final claims = jsonDecode(utf8.decode(base64Url.decode(
    base64Url.normalize(parts[1]),
  )));
  // This is only a local consistency check, NOT JWT verification.
  if (claims is! Map || claims['sub'] != user.id ||
      claims['exp'] is! num ||
      (claims['exp'] as num) <= DateTime.now().millisecondsSinceEpoch / 1000) {
    throw StateError('History session unavailable');
  }
  return HistoryIdentity(user.id, token);
}

typedef HistoryPageLoader = Future<Map<String, dynamic>> Function(
  ScopedHistoryQuery query, int page, String? asOf, HistoryIdentity identity,
);

/// Use an explicit bearer for each page. A 401 must not silently retry a
/// historical request under a different user's refreshed credential.
HistoryPageLoader scopedHistoryHttpLoader(ApiClient api) =>
    (query, page, asOf, identity) async {
  final response = await api.get<Map<String, dynamic>>(
    '/areas/${query.areaId}/sensors/${query.sensorId}/history',
    queryParameters: {
      'from': query.from.toIso8601String(),
      'to': query.to.toIso8601String(),
      if (query.rowId != null) 'farmingRowId': query.rowId,
      'page': page,
      'pageSize': 250,
      if (asOf != null) 'asOf': asOf,
    },
    options: Options(
      headers: {'Authorization': 'Bearer ${identity.accessToken}'},
      extra: const {
        'skipAuthInterceptor': true,
        'skipTokenRefresh': true,
        'skipSensitiveLogging': true,
      },
    ),
  );
  final body = response.data;
  if (body == null || body['success'] != true || body['data'] is! Map) {
    throw const FormatException('Invalid history response envelope');
  }
  return Map<String, dynamic>.from(body['data'] as Map);
};

/// Online-only repository for the new history contract. Cache writes are
/// optional; no cached data is returned on denial, timeout or offline.
class ScopedHistoryService {
  ScopedHistoryService({
    required ScopedHistoryCache cache,
    required Future<HistoryIdentity> Function() identity,
    required HistoryPageLoader loadPage,
    this.persist = true,
  }) : _cache = cache, _identity = identity, _loadPage = loadPage;

  final ScopedHistoryCache _cache;
  final Future<HistoryIdentity> Function() _identity;
  final HistoryPageLoader _loadPage;
  final bool persist;
  String? _user;
  int _generation = 0;
  int? _epoch;
  bool _busy = false;
  final _invalidations = StreamController<int>.broadcast();

  int get revision => _generation;
  Stream<int> get invalidations => _invalidations.stream;

  /// Called synchronously at auth-event start and when AuthBloc publishes
  /// a new authenticated user. Credentials changing outside the bloc also
  /// invalidate the generation before their asynchronous storage writes.
  Future<void> bindUser(User? user) {
    _user = user != null && user.role.canUseMobile ? user.id : null;
    return invalidate();
  }

  Future<void> invalidate() async {
    ++_generation;
    _invalidations.add(_generation);
    _epoch = null;
    try {
      await _cache.invalidate();
    } catch (_) {
      // Fail closed: no cache reads; next beginSession must purge successfully
      // before any new write. Auth itself must not fail because SQLite failed.
    }
  }

  void _checkGeneration(int generation, HistoryIdentity id) {
    if (_generation != generation || _user != id.userId) {
      throw StateError('History session changed');
    }
  }

  Future<void> _checkIdentity(int generation, HistoryIdentity id) async {
    _checkGeneration(generation, id);
    final current = await _identity();
    _checkGeneration(generation, id);
    if (!id.matches(current)) throw StateError('History credentials changed');
  }

  Future<ScopedHistorySnapshot> fetchOnline(ScopedHistoryQuery query) async {
    if (_user == null || _busy) throw StateError('History session unavailable');
    _busy = true;
    final generation = _generation;
    try {
      final id = await _identity();
      _checkGeneration(generation, id);
      final pages = <Map<String, dynamic>>[];
      String? asOf;
      for (var page = 1; page <= 20; page++) {
        await _checkIdentity(generation, id);
        final result = await _loadPage(query, page, asOf, id);
        await _checkIdentity(generation, id);
        // Preserve the original server timestamp string (including .NET ticks).
        if (page == 1) {
          final raw = result['asOf'];
          if (raw is! String) throw const FormatException('Missing history cutoff');
          asOf = raw;
        } else if (result['asOf'] != asOf) {
          throw const FormatException('History cutoff changed');
        }
        pages.add(result);
        if (result['hasMore'] == false) break;
        if (result['hasMore'] != true) {
          throw const FormatException('Invalid history pagination');
        }
      }
      final snapshot = ScopedHistorySnapshot.fromPages(query, pages);
      if (persist) {
        try {
          final epoch = _epoch ?? await _cache.beginSession(id.userId);
          await _checkIdentity(generation, id);
          _epoch = epoch;
          await _cache.saveOnline(epoch, snapshot);
        } catch (_) {
          // Storage failure cannot authorize a read or prevent a valid
          // online response. Recheck session below before returning.
          await _checkIdentity(generation, id);
          _epoch = null;
        }
      }
      await _checkIdentity(generation, id);
      return snapshot;
    } catch (_) {
      // Do not clear the new user's cache from an obsolete request.
      if (_generation == generation) await invalidate();
      rethrow;
    } finally {
      _busy = false;
    }
  }
}
