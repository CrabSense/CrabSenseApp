import 'dart:async';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import 'sync_conflict.dart';
import 'sync_queue_item.dart';

/// Service interface for handling conflict resolution logic.
///
/// Implements Last-Write-Wins (LWW) with timestamp comparison,
/// prompt triggers for simultaneous edits, and preservation of both versions
/// with a conflict flag for review.
///
/// Requirements: 13.9
abstract class ConflictResolverService {
  /// Evaluates timestamps to determine the resolution winner.
  ///
  /// Rules:
  /// - Server timestamp > local timestamp (difference > threshold) -> [ConflictWinner.server]
  /// - Local timestamp > server timestamp (difference > threshold) -> [ConflictWinner.local]
  /// - Difference within threshold or identical -> [ConflictWinner.manualPrompt]
  ConflictWinner evaluateTimestamps({
    required DateTime localTimestamp,
    required DateTime serverTimestamp,
    Duration simultaneousThreshold = const Duration(seconds: 1),
  });

  /// Processes an incoming entity change against local data.
  ///
  /// Returns a tuple/result containing the winning version or registers a conflict
  /// preserving both versions if manual resolution is needed.
  Future<SyncConflict?> processIncomingEntityChange({
    required SyncEntityType entityType,
    required String entityId,
    required Map<String, dynamic> localVersion,
    required DateTime localTimestamp,
    required Map<String, dynamic> serverVersion,
    required DateTime serverTimestamp,
  });

  /// Registers and preserves a conflict with both versions for user review.
  Future<SyncConflict> registerConflict({
    required SyncEntityType entityType,
    required String entityId,
    required Map<String, dynamic> localVersion,
    required DateTime localTimestamp,
    required Map<String, dynamic> serverVersion,
    required DateTime serverTimestamp,
  });

  /// Resolves an active conflict using user's choice.
  Future<SyncConflict> resolveConflict(
    String conflictId,
    ConflictResolutionChoice choice, {
    Map<String, dynamic>? customPayload,
  });

  /// Returns active pending conflicts awaiting resolution.
  Future<List<SyncConflict>> getPendingConflicts();

  /// Stream of active pending conflicts.
  Stream<List<SyncConflict>> watchPendingConflicts();

  /// Gets a specific conflict by ID.
  Future<SyncConflict?> getConflict(String id);

  /// Disposes stream controllers.
  void dispose();
}

/// Implementation of [ConflictResolverService].
class ConflictResolverServiceImpl implements ConflictResolverService {
  ConflictResolverServiceImpl({
    required this.logger,
  });

  final Logger logger;
  static const _uuid = Uuid();

  final Map<String, SyncConflict> _conflicts = {};
  final StreamController<List<SyncConflict>> _conflictStreamController =
      StreamController<List<SyncConflict>>.broadcast();

  @override
  ConflictWinner evaluateTimestamps({
    required DateTime localTimestamp,
    required DateTime serverTimestamp,
    Duration simultaneousThreshold = const Duration(seconds: 1),
  }) {
    final difference = serverTimestamp.difference(localTimestamp).abs();

    if (difference <= simultaneousThreshold) {
      // Simultaneous edit -> user prompt needed
      return ConflictWinner.manualPrompt;
    }

    if (serverTimestamp.isAfter(localTimestamp)) {
      // Server timestamp > local timestamp -> server wins
      return ConflictWinner.server;
    } else {
      // Local timestamp > server timestamp -> local wins
      return ConflictWinner.local;
    }
  }

  @override
  Future<SyncConflict?> processIncomingEntityChange({
    required SyncEntityType entityType,
    required String entityId,
    required Map<String, dynamic> localVersion,
    required DateTime localTimestamp,
    required Map<String, dynamic> serverVersion,
    required DateTime serverTimestamp,
  }) async {
    final winner = evaluateTimestamps(
      localTimestamp: localTimestamp,
      serverTimestamp: serverTimestamp,
    );

    switch (winner) {
      case ConflictWinner.server:
        logger.i(
          'ConflictResolver: Server version wins for ${entityType.code} ($entityId). Server TS > Local TS.',
        );
        return null; // Server wins automatically, no manual conflict registered

      case ConflictWinner.local:
        logger.i(
          'ConflictResolver: Local version wins for ${entityType.code} ($entityId). Local TS > Server TS.',
        );
        return null; // Local wins automatically, no manual conflict registered

      case ConflictWinner.manualPrompt:
        logger.w(
          'ConflictResolver: Simultaneous edit detected for ${entityType.code} ($entityId). Prompting user.',
        );
        final conflict = await registerConflict(
          entityType: entityType,
          entityId: entityId,
          localVersion: localVersion,
          localTimestamp: localTimestamp,
          serverVersion: serverVersion,
          serverTimestamp: serverTimestamp,
        );
        return conflict;
    }
  }

  @override
  Future<SyncConflict> registerConflict({
    required SyncEntityType entityType,
    required String entityId,
    required Map<String, dynamic> localVersion,
    required DateTime localTimestamp,
    required Map<String, dynamic> serverVersion,
    required DateTime serverTimestamp,
  }) async {
    final conflict = SyncConflict(
      id: _uuid.v4(),
      entityType: entityType,
      entityId: entityId,
      localVersion: localVersion,
      localTimestamp: localTimestamp,
      serverVersion: serverVersion,
      serverTimestamp: serverTimestamp,
      status: ConflictStatus.pending,
      hasConflict: true,
      createdAt: DateTime.now(),
    );

    _conflicts[conflict.id] = conflict;
    _emitPendingConflicts();

    logger.w(
      'ConflictResolver: Registered conflict ${conflict.id} for ${entityType.code}/$entityId with hasConflict=true',
    );
    return conflict;
  }

  @override
  Future<SyncConflict> resolveConflict(
    String conflictId,
    ConflictResolutionChoice choice, {
    Map<String, dynamic>? customPayload,
  }) async {
    final existing = _conflicts[conflictId];
    if (existing == null) {
      throw StateError('Conflict with ID $conflictId not found.');
    }

    ConflictStatus newStatus;
    Map<String, dynamic> finalPayload;

    switch (choice) {
      case ConflictResolutionChoice.useServer:
        newStatus = ConflictStatus.resolvedServer;
        finalPayload = existing.serverVersion;
        break;
      case ConflictResolutionChoice.useLocal:
        newStatus = ConflictStatus.resolvedLocal;
        finalPayload = existing.localVersion;
        break;
      case ConflictResolutionChoice.customMerge:
        newStatus = ConflictStatus.resolvedMerged;
        finalPayload = customPayload ?? existing.serverVersion;
        break;
    }

    final resolvedConflict = existing.copyWith(
      status: newStatus,
      hasConflict: false,
      resolvedAt: DateTime.now(),
      resolvedVersion: finalPayload,
    );

    _conflicts[conflictId] = resolvedConflict;
    _emitPendingConflicts();

    logger.i(
      'ConflictResolver: Resolved conflict $conflictId with status ${newStatus.name}',
    );
    return resolvedConflict;
  }

  @override
  Future<List<SyncConflict>> getPendingConflicts() async {
    return _conflicts.values.where((c) => c.hasConflict).toList();
  }

  @override
  Stream<List<SyncConflict>> watchPendingConflicts() {
    return _conflictStreamController.stream;
  }

  @override
  Future<SyncConflict?> getConflict(String id) async {
    return _conflicts[id];
  }

  void _emitPendingConflicts() {
    final pending = _conflicts.values.where((c) => c.hasConflict).toList();
    if (!_conflictStreamController.isClosed) {
      _conflictStreamController.add(pending);
    }
  }

  @override
  void dispose() {
    _conflictStreamController.close();
  }
}
