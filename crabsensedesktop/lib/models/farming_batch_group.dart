import 'batch_list_item.dart';

/// Một đợt nuôi logic (có thể gồm nhiều hộp, mỗi hộp một bản ghi API).
class FarmingBatchGroup {
  const FarmingBatchGroup({
    required this.key,
    required this.members,
  });

  final String key;
  final List<BatchListItem> members;

  BatchListItem get primary => members.first;

  String get batchCode => primary.batch.batchCode;
  String get areaId => primary.areaId;
  String get areaCode => primary.areaCode;
  String get rowId => primary.rowId;
  String get rowCode => primary.rowCode;
  DateTime get startDate => primary.batch.startDate;
  DateTime? get expectedHarvestDate => primary.batch.expectedHarvestDate;
  String get status => primary.batch.status;

  int get boxCount => members.length;

  int get totalInitial =>
      members.fold(0, (s, m) => s + m.batch.initialQuantity);

  int get totalCurrent =>
      members.fold(0, (s, m) => s + m.batch.currentQuantity);

  double get survivalPercent {
    if (totalInitial <= 0) return 0;
    return (totalCurrent / totalInitial * 100).clamp(0, 100);
  }

  List<String> get boxCodes =>
      members.map((m) => m.boxCode).toList()..sort();

  String get boxSummary {
    if (members.isEmpty) return '—';
    if (members.length == 1) return members.first.boxCode;
    final codes = boxCodes;
    if (codes.length <= 3) return codes.join(', ');
    return '${codes.first} … ${codes.last} (${codes.length} hộp)';
  }

  static String buildKey(BatchListItem item) {
    final b = item.batch;
    final exp = b.expectedHarvestDate != null
        ? b.expectedHarvestDate!.toIso8601String().substring(0, 10)
        : '';
    return '${item.rowId}|${b.batchCode.trim().toLowerCase()}|'
        '${b.startDate.toIso8601String().substring(0, 10)}|$exp|${b.status}';
  }

  static List<FarmingBatchGroup> fromItems(List<BatchListItem> items) {
    final map = <String, List<BatchListItem>>{};
    for (final item in items) {
      final k = buildKey(item);
      map.putIfAbsent(k, () => []).add(item);
    }
    final groups = map.entries
        .map((e) => FarmingBatchGroup(key: e.key, members: e.value))
        .toList();
    groups.sort((a, b) {
      final d = b.startDate.compareTo(a.startDate);
      if (d != 0) return d;
      return a.batchCode.compareTo(b.batchCode);
    });
    return groups;
  }
}
