import 'package:drift/drift.dart';

/// In-memory no-op executor so Flutter web does not pull sqlite3 FFI.
QueryExecutor openAppConnection() => NullExecutor();

class NullExecutor extends QueryExecutor {
  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async => true;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) async =>
      [];

  @override
  Future<int> runInsert(String statement, List<Object?> args) async => 0;

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async => 0;

  @override
  Future<int> runDelete(String statement, List<Object?> args) async => 0;

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) async {}

  @override
  Future<int> runBatched(BatchedStatements statements) async => 0;

  @override
  Future<void> close() async {}

  @override
  SqlDialect get dialect => SqlDialect.sqlite;

  @override
  TransactionExecutor beginTransaction() => _NullTransaction();

  @override
  QueryExecutor beginExclusive() => _NullTransaction();
}

class _NullTransaction extends TransactionExecutor {
  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async => true;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) async =>
      [];

  @override
  Future<int> runInsert(String statement, List<Object?> args) async => 0;

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async => 0;

  @override
  Future<int> runDelete(String statement, List<Object?> args) async => 0;

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) async {}

  @override
  Future<int> runBatched(BatchedStatements statements) async => 0;

  @override
  Future<void> close() async {}

  @override
  SqlDialect get dialect => SqlDialect.sqlite;

  @override
  TransactionExecutor beginTransaction() => _NullTransaction();

  @override
  Future<void> send() async {}

  @override
  Future<void> rollback() async {}

  @override
  bool get supportsNestedTransactions => false;

  @override
  QueryExecutor beginExclusive() => _NullTransaction();
}
