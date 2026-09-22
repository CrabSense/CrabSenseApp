import 'package:flutter_test/flutter_test.dart';

import 'package:crabsensemobile/shared/services/bidirectional_sync_manager.dart';
import 'package:crabsensemobile/shared/services/sync_queue_item.dart';

void main() {
  test('daily operation types are represented by the sync queue', () {
    expect(
      <String>{
        SyncEntityType.box.code,
        SyncEntityType.crab.code,
        SyncEntityType.feeding.code,
        SyncEntityType.care.code,
        SyncEntityType.transfer.code,
        SyncEntityType.waterReading.code,
        SyncEntityType.task.code,
        SyncEntityType.photo.code,
      },
      containsAll(<String>[
        'box',
        'crab',
        'feeding',
        'care',
        'transfer',
        'water_reading',
        'task',
        'photo',
      ]),
    );
  });

  test('sync retries use bounded exponential backoff', () {
    expect(calculateExponentialBackoff(1), const Duration(seconds: 1));
    expect(calculateExponentialBackoff(4), const Duration(seconds: 8));
    expect(calculateExponentialBackoff(20), const Duration(seconds: 16));
  });
}
