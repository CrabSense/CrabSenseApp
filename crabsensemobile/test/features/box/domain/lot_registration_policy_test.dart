import 'package:crabsensemobile/features/box/domain/lot_registration_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final lot = <String, dynamic>{
    'farmingAreaIds': ['a'], 'status': 'Pending', 'quantity': 5,
    'placedCount': 3, 'deadOnArrival': 1,
  };
  test('only linked open lots with remaining capacity are selectable', () {
    expect(canRegisterInLot(lot, 'a'), isTrue);
    expect(canRegisterInLot(lot, 'b'), isFalse);
    expect(canRegisterInLot({...lot, 'placedCount': 4}, 'a'), isFalse);
    expect(canRegisterInLot({...lot, 'status': 'Cancelled'}, 'a'), isFalse);
    expect(canRegisterInLot({...lot, 'closedAt': '2026-11-25'}, 'a'), isFalse);
  });
  test('partial scope does not infer global remaining capacity from masked counts', () {
    expect(canRegisterInLot({...lot, 'isPartialScope': true, 'quantity': 3}, 'a'), isTrue);
    expect(canRegisterInLot({...lot, 'isPartialScope': true}, 'b'), isFalse);
  });
}
