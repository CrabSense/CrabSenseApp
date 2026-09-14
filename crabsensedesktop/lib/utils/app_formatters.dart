const kAllFilter = 'Tất cả';

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String formatInt(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

String formatVnd(int vnd) => '${formatInt(vnd)}đ';

String formatVndShort(int vnd) {
  if (vnd >= 1000000000) {
    return '${(vnd / 1000000000).toStringAsFixed(1)}B';
  }
  if (vnd >= 1000000) {
    return '${(vnd / 1000000).toStringAsFixed(vnd % 1000000 == 0 ? 0 : 1)}M';
  }
  if (vnd >= 1000) {
    return '${(vnd / 1000).round()}K';
  }
  return '$vnd';
}

String formatVndFull(int vnd) => formatVnd(vnd);
