const kAllFilter = 'Tất cả';

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String formatClock(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Ví dụ: `3 ngày 7 giờ`, `45 phút`, `Vừa xong`.
String formatDurationVi(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final days = d.inDays;
  final hours = d.inHours.remainder(24);
  final minutes = d.inMinutes.remainder(60);
  if (days > 0) {
    if (hours > 0) return '$days ngày $hours giờ';
    return '$days ngày';
  }
  if (d.inHours > 0) {
    if (minutes > 0) return '${d.inHours} giờ $minutes phút';
    return '${d.inHours} giờ';
  }
  if (minutes > 0) return '$minutes phút';
  return 'Vừa xong';
}

/// `Cập nhật 2 phút trước` hoặc `Cập nhật 15:58` nếu > 1 ngày.
String formatAiUpdatedLabel(DateTime? at, {DateTime? now}) {
  if (at == null) return 'Chưa có cập nhật';
  final n = now ?? DateTime.now();
  final local = at.isUtc ? at.toLocal() : at;
  final diff = n.difference(local);
  if (diff.inDays >= 1) return 'Cập nhật ${formatClock(local)}';
  if (diff.inMinutes < 1) return 'Cập nhật vừa xong';
  if (diff.inHours < 1) return 'Cập nhật ${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return 'Cập nhật ${diff.inHours} giờ trước';
  return 'Cập nhật ${formatClock(local)}';
}

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
