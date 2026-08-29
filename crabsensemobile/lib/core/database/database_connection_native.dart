import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens a persistent SQLite database on native platforms (Android/iOS/desktop).
///
/// Uses [NativeDatabase.createInBackground] so schema creation does not
/// block the UI thread.
Future<QueryExecutor> openDatabaseConnection() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'crabsense.db'));
  return NativeDatabase.createInBackground(file);
}
