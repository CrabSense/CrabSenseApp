import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/sale.dart';

/// Exporter for converting list of [Sale] items into CSV files.
///
/// Requirements: 12.10
class SalesCsvExporter {
  /// Converts [sales] to CSV string.
  static String generateCsvString(List<Sale> sales) {
    final buffer = StringBuffer();
    // Header
    buffer.writeln(
      'Transaction ID,Sale Date,Farm ID,Buyer Name,Buyer Contact,Quantity (kg),Unit Price (\$),Total Amount (\$),Payment Method,Payment Status,Operator ID,Operator Name,Notes',
    );

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    for (final sale in sales) {
      final id = _escapeCsvField(sale.id);
      final date = _escapeCsvField(dateFormat.format(sale.saleDate));
      final farmId = _escapeCsvField(sale.farmId ?? '');
      final buyerName = _escapeCsvField(sale.buyerName);
      final buyerContact = _escapeCsvField(sale.buyerContact ?? '');
      final quantity = sale.quantity.toStringAsFixed(2);
      final unitPrice = sale.unitPrice.toStringAsFixed(2);
      final totalAmount = sale.totalAmount.toStringAsFixed(2);
      final paymentMethod = _escapeCsvField(sale.paymentMethod.displayName);
      final paymentStatus = _escapeCsvField(sale.paymentStatus.displayName);
      final operatorId = _escapeCsvField(sale.operatorId);
      final operatorName = _escapeCsvField(sale.operatorName);
      final notes = _escapeCsvField(sale.notes ?? '');

      buffer.writeln(
        '$id,$date,$farmId,$buyerName,$buyerContact,$quantity,$unitPrice,$totalAmount,$paymentMethod,$paymentStatus,$operatorId,$operatorName,$notes',
      );
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
  static Future<File> exportToCsvFile(List<Sale> sales, {String? customFilename}) async {
    final csvData = generateCsvString(sales);
    final directory = await getApplicationDocumentsDirectory();
    final filename = customFilename ??
        'sales_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${directory.path}/$filename');
    return file.writeAsString(csvData);
  }
}
