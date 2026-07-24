import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/harvest.dart';

/// Exporter for converting list of [Harvest] items into CSV files.
///
/// Requirements: 11.9, 11.10
class HarvestCsvExporter {
  /// Converts [harvests] to CSV string.
  static String generateCsvString(List<Harvest> harvests) {
    final buffer = StringBuffer();
    // Header
    buffer.writeln(
      'ID,Harvest Date,Farm ID,Box ID,Total Weight (kg),Crab Count,Quality Grade,Operator ID,Operator Name,Notes',
    );

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    for (final harvest in harvests) {
      final id = _escapeCsvField(harvest.id);
      final date = _escapeCsvField(dateFormat.format(harvest.harvestDate));
      final farmId = _escapeCsvField(harvest.farmId);
      final boxId = _escapeCsvField(harvest.boxId);
      final weight = harvest.totalWeight.toStringAsFixed(2);
      final count = harvest.crabCount.toString();
      final grade = _escapeCsvField(harvest.qualityGrade.displayName);
      final operatorId = _escapeCsvField(harvest.operatorId);
      final operatorName = _escapeCsvField(harvest.operatorName);
      final notes = _escapeCsvField(harvest.notes ?? '');

      buffer.writeln('$id,$date,$farmId,$boxId,$weight,$count,$grade,$operatorId,$operatorName,$notes');
    }

    return buffer.toString();
  }

  /// Escapes CSV field if it contains special characters.
  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
      final escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }
    return field;
  }

  /// Writes CSV string to a file in the app documents/temporary directory.
  static Future<File> exportToCsvFile(List<Harvest> harvests, {String? customFilename}) async {
    final csvData = generateCsvString(harvests);
    final directory = await getApplicationDocumentsDirectory();
    final filename = customFilename ??
        'harvest_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${directory.path}/$filename');
    return file.writeAsString(csvData);
  }
}
