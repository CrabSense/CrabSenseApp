import '../lib/models/tank_level.dart';

void main() {
  double? floats(String code) => switch (code) {
        'float_1' => 1,
        'float_2' => 0,
        _ => null,
      };
  final map = {
    'lowFloat': 'float_1',
    'lowWhen': 'on',
    'highFloat': 'float_2',
    'highWhen': 'on',
  };
  final low = tankLevelLabel(map, floats);
  if (low != 'Cạn') throw StateError('expected Cạn, got $low');

  final quiet = tankLevelLabel(map, (code) => 0);
  if (quiet != 'Bình thường') throw StateError('expected Bình thường, got $quiet');

  final overflow = tankLevelLabel(map, (code) => code == 'float_2' ? 1 : 0);
  if (overflow != 'Tràn') throw StateError('expected Tràn, got $overflow');

  if (tankLevelLabel(const {}, floats) != null) {
    throw StateError('unassigned tank should stay blank');
  }
  print('tank level ok');
}
