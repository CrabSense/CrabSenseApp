import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../models/crab_lifecycle_event.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';

enum CrabHistoryExportFormat { csv, excel, pdf }

class CrabHistoryExportMenu extends StatelessWidget {
  const CrabHistoryExportMenu({super.key, required this.onExport});

  final Future<void> Function(CrabHistoryExportFormat format) onExport;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CrabHistoryExportFormat>(
      tooltip: 'Xuất lịch sử',
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      onSelected: (f) => onExport(f),
      itemBuilder: (_) => [
        _item(CrabHistoryExportFormat.csv, Icons.table_chart_outlined, 'CSV'),
        _item(CrabHistoryExportFormat.excel, Icons.grid_on_outlined, 'Excel'),
        _item(CrabHistoryExportFormat.pdf, Icons.picture_as_pdf_outlined, 'PDF'),
      ],
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DashboardColors.brand.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_rounded, size: 17, color: DashboardColors.brand),
            const SizedBox(width: 6),
            Text(
              'Xuất lịch sử',
              style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.brand),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<CrabHistoryExportFormat> _item(
    CrabHistoryExportFormat f,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      value: f,
      height: 38,
      child: Row(
        children: [
          Icon(icon, size: 16, color: DashboardColors.brand),
          const SizedBox(width: 8),
          Text(label, style: bvText(fontSize: 13, color: DashboardColors.textPrimary)),
        ],
      ),
    );
  }
}

Future<void> exportCrabHistory({
  required BuildContext context,
  required String crabCode,
  required List<CrabLifecycleEvent> events,
  required CrabHistoryExportFormat format,
}) async {
  final now = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  final stamp = '${now.year}${two(now.month)}${two(now.day)}';
  final base = 'crabsense_nhatky_${crabCode}_$stamp';

  late final String name;
  late final String ext;
  late final String body;
  switch (format) {
    case CrabHistoryExportFormat.csv:
      name = '$base.csv';
      ext = 'csv';
      body = '\uFEFF${_csv(events)}';
    case CrabHistoryExportFormat.excel:
      name = '$base.xls';
      ext = 'xls';
      body = _xls(events, crabCode);
    case CrabHistoryExportFormat.pdf:
      name = '$base.pdf';
      ext = 'pdf';
      body = _pdf(events, crabCode);
  }

  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Xuất lịch sử',
    fileName: name,
    type: FileType.custom,
    allowedExtensions: [ext],
  );
  if (path == null) return;
  if (format == CrabHistoryExportFormat.pdf) {
    await File(path).writeAsBytes(_pdfBytes(events, crabCode));
  } else {
    await File(path).writeAsString(body);
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Đã xuất ${events.length} sự kiện của $crabCode.')),
  );
}

String _csvCell(String v) =>
    v.contains(',') || v.contains('"') || v.contains('\n') ? '"${v.replaceAll('"', '""')}"' : v;

String _csv(List<CrabLifecycleEvent> events) {
  final sb = StringBuffer()
    ..writeln('Thoi gian,Loai,Tieu de,Tom tat,Vi tri,Nguoi thuc hien,Nguon,Camera,Ghi chu');
  for (final e in events) {
    sb.writeln([
      _csvCell(fmtDateTimeVn(e.occurredAt)),
      _csvCell(e.eventType.label),
      _csvCell(e.title),
      _csvCell(e.summary),
      _csvCell([e.location?.farmAreaCode, e.location?.rowCode, e.location?.boxCode].whereType<String>().join(' > ')),
      _csvCell(e.actor.name),
      _csvCell(e.sourceLabel()),
      _csvCell(e.cameraId ?? ''),
      _csvCell(e.note ?? ''),
    ].join(','));
  }
  return sb.toString();
}

String _xls(List<CrabLifecycleEvent> events, String crabCode) {
  String esc(String v) => v
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
  final rows = StringBuffer();
  void cell(String v) => rows.write('<Cell><Data ss:Type="String">${esc(v)}</Data></Cell>');
  void row(List<String> cols) {
    rows.write('<Row>');
    for (final c in cols) {
      cell(c);
    }
    rows.writeln('</Row>');
  }

  row(['Cua', crabCode]);
  row(['Thời gian', 'Loại', 'Tiêu đề', 'Tóm tắt', 'Vị trí', 'Người thực hiện', 'Nguồn', 'Camera', 'Ghi chú']);
  for (final e in events) {
    row([
      fmtDateTimeVn(e.occurredAt),
      e.eventType.label,
      e.title,
      e.summary,
      [e.location?.farmAreaCode, e.location?.rowCode, e.location?.boxCode].whereType<String>().join(' > '),
      e.actor.name,
      e.sourceLabel(),
      e.cameraId ?? '',
      e.note ?? '',
    ]);
  }
  return '''<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
<Worksheet ss:Name="Nhat ky"><Table>
$rows
</Table></Worksheet></Workbook>''';
}

String _ascii(String s) {
  const map = {
    'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
    'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
    'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
    'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
    'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
    'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
    'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
    'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
    'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
    'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
    'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
    'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    'đ': 'd',
    'À': 'A', 'Á': 'A', 'Ả': 'A', 'Ã': 'A', 'Ạ': 'A',
    'Ă': 'A', 'Ằ': 'A', 'Ắ': 'A', 'Ẳ': 'A', 'Ẵ': 'A',
    'Â': 'A', 'Đ': 'D',
  };
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    buf.write(map[ch] ?? ch);
  }
  return buf.toString();
}

String _pdf(List<CrabLifecycleEvent> events, String crabCode) =>
    String.fromCharCodes(_pdfBytes(events, crabCode));

List<int> _pdfBytes(List<CrabLifecycleEvent> events, String crabCode) {
  final lines = <String>[
    'CrabSense - Lich su ${_ascii(crabCode)}',
    'Tong su kien: ${events.length}',
    '',
    for (final e in events)
      '${fmtDateTimeVn(e.occurredAt)} | ${_ascii(e.eventType.label)} | ${_ascii(e.title)} | ${_ascii(e.summary)} | ${_ascii(e.actor.name)}',
  ];
  final content = StringBuffer('BT /F1 9 Tf 40 800 Td\n');
  for (var i = 0; i < lines.length; i++) {
    final yShift = i == 0 ? '' : '0 -13 Td\n';
    final safe = lines[i].replaceAll('(', '\\(').replaceAll(')', '\\)').replaceAll('\\', '\\\\');
    content.write('$yShift($safe) Tj\n');
  }
  content.write('ET');
  final stream = content.toString();
  final objs = <String>[
    '1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n',
    '2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n',
    '3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >> endobj\n',
    '4 0 obj << /Length ${stream.length} >> stream\n$stream\nendstream endobj\n',
    '5 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n',
  ];
  final buf = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[];
  for (final o in objs) {
    offsets.add(buf.length);
    buf.write(o);
  }
  final xref = buf.length;
  buf.write('xref\n0 6\n0000000000 65535 f \n');
  for (final off in offsets) {
    buf.write('${off.toString().padLeft(10, '0')} 00000 n \n');
  }
  buf.write('trailer << /Size 6 /Root 1 0 R >>\nstartxref\n$xref\n%%EOF');
  return buf.toString().codeUnits;
}
