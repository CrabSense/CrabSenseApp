import 'package:flutter_test/flutter_test.dart';
import '../lib/models/production_models.dart';
import '../lib/models/box_status.dart';
import '../lib/models/farm_layout.dart';
import '../lib/utils/farm_layout_mapper.dart';

void main() {
  const a = AreaRecord(id:'a', farmId:'farm', areaCode:'A', areaName:'A');
  const b = AreaRecord(id:'b', farmId:'farm', areaCode:'B', areaName:'B');
  const row = RowRecord(id:'r', areaId:'a', rowCode:'R', rowName:'R');
  const valid = BoxRecord(id:'box', rowId:'r', boxCode:'BOX', status:'active',
    areaId:'a', crabCount:1, crabCondition:'problem', aiSummary:'legacy AI');
  test('map preserves operational status but no fabricated score or AI', () {
    final item = scopedFarmMapBox(box:valid, areas:{'a':a,'b':b},
      rows:{'r':row}, selectedAreaId:'a')!;
    expect(item.display.status, BoxStatus.alert);
    expect(item.display.healthScore, isNull);
    expect(item.aiSummary, isNull);
    expect([item].mascotMessage(), isNot(contains('RAS đang hoạt động ổn định')));
  });
  test('map rejects wrong area, missing row and unauthorized inventory', () {
    FarmMapBox? resolve(BoxRecord box, Map<String,AreaRecord> areas,
      Map<String,RowRecord> rows, String? selected) =>
      scopedFarmMapBox(box:box, areas:areas, rows:rows, selectedAreaId:selected);
    expect(resolve(valid, {'a':a}, {'r':row}, 'b'), isNull);
    expect(resolve(valid, {'b':b}, {'r':row}, null), isNull);
    expect(resolve(valid, {'a':a}, {}, 'a'), isNull);
    const conflicting = BoxRecord(id:'bad', rowId:'r', boxCode:'BAD',
      status:'active', areaId:'b');
    expect(resolve(conflicting, {'a':a,'b':b}, {'r':row}, null), isNull);
    expect(resolve(valid, {'a':a}, {'r':row}, null)?.areaId, 'a');
  });
}
