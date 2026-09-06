import 'dart:convert';
import 'package:crabsensemobile/core/platform/io_export.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/drive_folder_config.dart';
import '../../data/drive_report_uploader.dart';
import '../../data/models/report_models.dart';

/// Xuất báo cáo → file local → upload / chia sẻ vào folder Drive CRAB.
class ReportFileExporter {
  ReportFileExporter._();

  static String generateCsv(ReportDetailData data) {
    final buf = StringBuffer();
    buf.write('\uFEFF');
    buf.writeln('Loại báo cáo,${_esc(data.kind.titleVi)}');
    buf.writeln(
      'Xuất lúc,${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
    );
    buf.writeln();
    buf.writeln('Mục,Giá trị,Ghi chú');
    for (final m in data.metrics) {
      buf.writeln('${_esc(m.label)},${_esc(m.value)},${_esc(m.hint ?? '')}');
    }
    for (final section in data.sections) {
      buf.writeln();
      buf.writeln('=== ${_esc(section.title)} ===');
      buf.writeln('Mục,Giá trị,Ghi chú');
      for (final row in section.rows) {
        buf.writeln(
          '${_esc(row.label)},${_esc(row.value)},${_esc(row.hint ?? '')}',
        );
      }
    }
    return buf.toString();
  }

  static String generateJson(ReportDetailData data) {
    final payload = <String, dynamic>{
      'kind': data.kind.name,
      'title': data.kind.titleVi,
      'exportedAt': DateTime.now().toIso8601String(),
      'metrics': [
        for (final m in data.metrics)
          {
            'label': m.label,
            'value': m.value,
            if (m.hint != null) 'hint': m.hint,
          },
      ],
      'sections': [
        for (final s in data.sections)
          {
            'title': s.title,
            'rows': [
              for (final r in s.rows)
                {
                  'label': r.label,
                  'value': r.value,
                  if (r.hint != null) 'hint': r.hint,
                },
            ],
          },
      ],
      if (data.raw != null) 'metricsCount': data.metrics.length,
      // Không export toàn bộ raw API (tránh lộ field nội bộ).
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Ghi CSV+JSON → thử upload Drive → fallback share + mở folder CRAB.
  static Future<ReportExportResult> exportAndShare(
    ReportDetailData data, {
    bool includeJson = true,
    bool openFolderOnSuccess = true,
  }) async {
    if (kIsWeb) {
      // On web: file system is not accessible. Return CSV string only.
      return const ReportExportResult(
        csvPath: '',
        shared: false,
        driveUploaded: false,
        driveMessage: 'File export not supported on web. Copy CSV data manually.',
      );
    }

    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final base = 'crabsense_${data.kind.name}_$stamp';
    final dir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${dir.path}/reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    final csvFile = File('${reportsDir.path}/$base.csv');
    await csvFile.writeAsString(generateCsv(data), encoding: utf8);

    File? jsonFile;
    if (includeJson) {
      jsonFile = File('${reportsDir.path}/$base.json');
      await jsonFile.writeAsString(generateJson(data), encoding: utf8);
    }

    final toUpload = <File>[csvFile, if (jsonFile != null) jsonFile];

    DriveUploadResult? drive;
    try {
      drive = await DriveReportUploader.uploadFiles(toUpload);
    } catch (e) {
      drive = DriveUploadResult(
        success: false,
        needsManualShare: true,
        message: 'Upload Drive lỗi: $e',
      );
    }

    var shared = false;
    if (drive.success == true) {
      if (openFolderOnSuccess) {
        try {
          await DriveReportUploader.openFolder();
        } catch (_) {}
      }
    } else {
      // Mở folder CRAB trước, rồi share sheet để lưu vào đó.
      try {
        await DriveReportUploader.openFolder();
      } catch (_) {}
      try {
        final files = <XFile>[
          XFile(csvFile.path, mimeType: 'text/csv', name: '$base.csv'),
          if (jsonFile != null)
            XFile(
              jsonFile.path,
              mimeType: 'application/json',
              name: '$base.json',
            ),
        ];
        await SharePlus.instance.share(
          ShareParams(
            files: files,
            subject: data.kind.titleVi,
            text:
                '${data.kind.titleVi}\nLưu vào folder CRAB:\n${DriveFolderConfig.folderUrl}',
          ),
        );
        shared = true;
      } on MissingPluginException {
        shared = false;
      } catch (_) {
        shared = false;
      }
    }

    return ReportExportResult(
      csvPath: csvFile.path,
      jsonPath: jsonFile?.path,
      shared: shared,
      driveUploaded: drive.success,
      driveMessage: drive.message,
      driveFileUrl: drive.fileUrl,
      folderUrl: DriveFolderConfig.folderUrl,
    );
  }

  static String _esc(String field) {
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}

class ReportExportResult {
  const ReportExportResult({
    required this.csvPath,
    this.jsonPath,
    this.shared = false,
    this.driveUploaded = false,
    this.driveMessage,
    this.driveFileUrl,
    this.folderUrl,
  });

  final String csvPath;
  final String? jsonPath;
  final bool shared;
  final bool driveUploaded;
  final String? driveMessage;
  final String? driveFileUrl;
  final String? folderUrl;
}
