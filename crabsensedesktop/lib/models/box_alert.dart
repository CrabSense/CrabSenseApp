class BoxAlert {
  const BoxAlert({
    required this.severity,
    required this.message,
    required this.time,
    this.status = 'open',
    this.occurredAt,
  });

  final String severity;
  final String message;
  final String time;
  final String status;
  final DateTime? occurredAt;

  String get statusLabel => switch (status.toLowerCase()) {
        'acknowledged' || 'ack' => 'Đã xác nhận',
        'resolved' => 'Đã xử lý',
        'recovered' => 'Đã khôi phục',
        'closed' => 'Đã xử lý',
        'open' || 'active' => 'Đang mở',
        _ => status.isEmpty ? 'Đang mở' : status,
      };
}
