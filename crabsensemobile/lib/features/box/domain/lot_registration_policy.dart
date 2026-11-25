/// BE retains authority over available capacity, especially for partial-scope lots.
bool canRegisterInLot(Map<dynamic, dynamic> lot, String areaId) {
  final areas = lot['farmingAreaIds'];
  if (areas is! List || !areas.any((id) => id.toString() == areaId)) return false;
  final status = (lot['status'] ?? '').toString().toLowerCase();
  if (lot['closedAt'] != null || status == 'closed' || status == 'cancelled') return false;
  if (lot['isPartialScope'] == true) return true;
  final quantity = num.tryParse('${lot['quantity'] ?? ''}');
  final placed = num.tryParse('${lot['placedCount'] ?? ''}');
  final dead = num.tryParse('${lot['deadOnArrival'] ?? 0}');
  return quantity != null && placed != null && dead != null && quantity - placed - dead > 0;
}
