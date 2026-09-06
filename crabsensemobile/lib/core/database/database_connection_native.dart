import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Persistent SQLite via drift_flutter (not compiled for web).
QueryExecutor openAppConnection() => driftDatabase(name: 'crabsense');
