import 'package:flutter/material.dart';

import '../../../theme/dashboard_theme.dart';

String boxOperationalLabel(String status) {
  final s = status.trim().toLowerCase();
  return switch (s) {
    'active' || 'occupied' || 'farming' => 'Đang hoạt động',
    'empty' => 'Trống',
    'maintenance' || 'locked' => 'Đã khóa',
    'quarantine' => 'Cách ly',
    'molting' => 'Lột xác',
    'watch' => 'Theo dõi',
    'harvested' => 'Đã thu hoạch',
    'suspended' || 'closed' => 'Ngưng hoạt động',
    _ => status.isEmpty ? 'Đang hoạt động' : status,
  };
}

Color boxOperationalColor(String status) {
  final s = status.trim().toLowerCase();
  return switch (s) {
    'active' || 'occupied' || 'farming' => DashboardColors.brand,
    'empty' => DashboardColors.textMuted,
    'maintenance' || 'locked' => const Color(0xFFF5B700),
    'quarantine' || 'watch' => const Color(0xFFF5B700),
    'harvested' => DashboardColors.blue,
    _ => DashboardColors.brand,
  };
}

bool isBoxLocked(String status) {
  final s = status.trim().toLowerCase();
  return s == 'maintenance' || s == 'locked';
}

String crabLifecycleLabel(String? raw, {required bool hasCrab}) {
  if (!hasCrab) return 'Trống';
  final s = (raw ?? '').trim().toLowerCase();
  return switch (s) {
    'growing' || 'alive' || 'normal' || 'active' => 'Đang nuôi',
    'molting' => 'Đang lột xác',
    'dead' => 'Đã chết',
    'harvested' || 'sold' => 'Đã thu hoạch',
    'quarantined' => 'Cách ly',
    _ => 'Đang nuôi',
  };
}

String deviceStatusLabel(String raw) {
  final s = raw.trim().toLowerCase();
  return switch (s) {
    'online' => 'Online',
    'offline' => 'Mất kết nối',
    'degraded' => 'Không ổn định',
    _ => raw.isEmpty ? 'Mất kết nối' : raw,
  };
}

Color deviceStatusColor(String raw) {
  final s = raw.trim().toLowerCase();
  return switch (s) {
    'online' => DashboardColors.brand,
    'degraded' => const Color(0xFFF5B700),
    _ => const Color(0xFFEF4444),
  };
}

String sensorSemanticLabel(String raw) {
  final s = raw.trim().toLowerCase();
  return switch (s) {
    'good' || 'ok' || 'normal' => 'Tốt',
    'monitoring' || 'watch' => 'Theo dõi',
    'warning' || 'warn' || 'alert' => 'Cảnh báo',
    'danger' || 'critical' => 'Cảnh báo',
    'no_data' || 'nodata' || 'missing' => 'Mất dữ liệu',
    _ => 'Tốt',
  };
}

Color sensorSemanticColor(String raw) {
  final s = raw.trim().toLowerCase();
  return switch (s) {
    'good' || 'ok' || 'normal' => DashboardColors.brand,
    'monitoring' || 'watch' => const Color(0xFFF5B700),
    'warning' || 'warn' || 'alert' || 'danger' || 'critical' => const Color(0xFFEF4444),
    _ => const Color(0xFF94A3B8),
  };
}

Color sensorSemanticFill(String raw) {
  final s = raw.trim().toLowerCase();
  return switch (s) {
    'good' || 'ok' || 'normal' => const Color(0xFFF3FBF8),
    'monitoring' || 'watch' => const Color(0xFFFFF8E1),
    'warning' || 'warn' || 'alert' || 'danger' || 'critical' => const Color(0xFFFEF2F2),
    _ => const Color(0xFFF8FAFC),
  };
}

double? sanitizePh(double? raw) {
  if (raw == null) return null;
  if (raw == 0) return null;
  if (raw > 0 && raw < 2) return raw * 10;
  return raw;
}

String fmtPh(double v) => v.toStringAsFixed(2);
String fmtTemp(double v) => v.toStringAsFixed(1);
String fmtSalinity(double v) => v.toStringAsFixed(1);
String fmtDo(double v) => v.toStringAsFixed(1);
String fmtTds(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

String relativeAgo(DateTime? at) {
  if (at == null) return '';
  final local = at.isUtc ? at.toLocal() : at;
  final diff = DateTime.now().difference(local);
  if (diff.inSeconds < 45) return 'Cập nhật vừa xong';
  if (diff.inMinutes < 1) return 'Cập nhật ${diff.inSeconds} giây trước';
  if (diff.inMinutes < 60) return 'Cập nhật ${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return 'Cập nhật ${diff.inHours} giờ trước';
  return 'Cập nhật ${diff.inDays} ngày trước';
}

({String label, Color color, String title, String body, bool watch}) boxCrabHealth(String? raw) {
  final s = (raw ?? '').trim().toLowerCase().replaceAll('_', '-').replaceAll(' ', '');
  if (s.contains('alert') || s.contains('crit') || s.contains('danger')) {
    return (
      label: 'Cảnh báo',
      color: const Color(0xFFEF4444),
      title: 'Cảnh báo',
      body: 'Cần kiểm tra ngay tình trạng cua trong hộp.',
      watch: true,
    );
  }
  if (s.contains('weak') ||
      s.contains('disease') ||
      s.contains('stress') ||
      s.contains('problem') ||
      s.contains('atrisk') ||
      s.contains('at-risk')) {
    return (
      label: 'Bệnh / Yếu',
      color: const Color(0xFFEF4444),
      title: 'Bệnh / Yếu',
      body: 'Phát hiện dấu hiệu sức khỏe kém. Cần theo dõi sát.',
      watch: true,
    );
  }
  if (s.contains('monitor') || s.contains('watch')) {
    return (
      label: 'Theo dõi',
      color: const Color(0xFFF5B700),
      title: 'Cần theo dõi',
      body: 'Phát hiện một số dấu hiệu cần kiểm tra.',
      watch: true,
    );
  }
  return (
    label: 'Khỏe mạnh',
    color: DashboardColors.brand,
    title: 'Khỏe mạnh',
    body: 'Không có dấu hiệu bất thường.\nTiếp tục theo dõi định kỳ.',
    watch: false,
  );
}

String boxOccupancyEventLabel(String event) {
  return switch (event.toUpperCase()) {
    'ASSIGNED' || 'CRAB_ASSIGNED_TO_BOX' => 'Đưa vào hộp',
    'TRANSFERRED_IN' || 'CRAB_TRANSFERRED_IN' => 'Chuyển vào hộp',
    'REMOVED' || 'CRAB_REMOVED_FROM_BOX' || 'TRANSFERRED_OUT' || 'CRAB_TRANSFERRED_OUT' =>
      'Chuyển khỏi hộp',
    'RELEASED' || 'CRAB_RELEASED' => 'Giải phóng hộp',
    'HARVESTED' || 'CRAB_HARVESTED' => 'Thu hoạch khỏi hộp',
    'DEAD_REMOVED' || 'CRAB_DEAD_REMOVED' => 'Đưa cua chết ra khỏi hộp',
    _ => 'Sự kiện hộp',
  };
}

int? daysInBox(DateTime? entered) {
  if (entered == null) return null;
  final local = entered.isUtc ? entered.toLocal() : entered;
  final days = DateTime.now().difference(local).inDays;
  return days < 0 ? 0 : days;
}

bool isSensorStale(DateTime? at, {Duration max = const Duration(minutes: 5)}) {
  if (at == null) return false;
  final local = at.isUtc ? at.toLocal() : at;
  return DateTime.now().difference(local) > max;
}
