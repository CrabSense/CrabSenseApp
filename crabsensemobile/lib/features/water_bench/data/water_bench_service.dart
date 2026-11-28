import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../authentication/domain/entities/user.dart';
import 'water_bench_model.dart';

typedef BenchGet = Future<Object?> Function(String path, Map<String,dynamic>? query);

/// Uses the existing authenticated Dio client. Scope is obtained from BE, not
/// from the URL, cached farm identifiers, or assumed default farm.
class StaffWaterBenchService {
  StaffWaterBenchService(ApiClient api) : _get = ((path,query) async {
    final r=await api.get<Map<String,dynamic>>(path,queryParameters:query,
      options:Options(headers:{'Cache-Control':'no-cache'}));
    return r.data;
  });
  StaffWaterBenchService.testing(this._get);
  final BenchGet _get;
  final Map<String,Set<String>> _allowed={};

  void _staff(User user) {
    if(!user.role.canUseMobile || user.id.isEmpty) throw StateError('Không có quyền Farm Staff.');
  }
  Future<Object?> _read(String path,[Map<String,dynamic>? query]) async {
    final envelope=benchMap(await _get(path,query));
    if(envelope['success']!=true || !envelope.containsKey('data')) {
      throw const FormatException('Phản hồi WaterBench không hợp lệ.');
    }
    return envelope['data'];
  }
  BenchJson _object(Object? data) {
    if(data is! Map) throw const FormatException('Thiếu dữ liệu WaterBench.');
    return benchMap(data);
  }
  Future<List<BenchJson>> areas(User user) async {
    _staff(user);
    _allowed.remove(user.id);
    final result=<BenchJson>[];
    // Farming areas is a scoped paged result; handle legacy list too.
    for(var page=1;page<=100;page++){
      final data=await _read('/farming-areas',{'page':page,'pageSize':100});
      final rows=data is List?benchRows(data):benchRows(_object(data)['items']);
      result.addAll(rows.where((r)=>benchGuid(r['id']?.toString()??'')));
      if(data is List) break;
      final info=_object(data);
      final total=info['totalCount']??info['total'];
      if(rows.isEmpty || (total is num && result.length>=total) || rows.length<100)break;
      if(page==100)throw StateError('Danh sách khu vượt giới hạn tải.');
    }
    final unique={for(final r in result)r['id'].toString():r};
    _allowed[user.id]=unique.keys.toSet();
    return unique.values.toList();
  }
  String _scope(User user,String area) {
    _staff(user);
    if(!benchGuid(area)||_allowed[user.id]?.contains(area)!=true)throw StateError('Khu nuôi chưa được cấp quyền.');
    return '/areas/$area/water-bench';
  }
  Future<BenchOverview> overview(User user,String area) async {
    final p=_scope(user,area);
    final data=await Future.wait([_read('$p/station'),_read('$p/batches')]);
    if(data[1] is! List)throw const FormatException('Danh sách phiên không hợp lệ.');
    final batches=(data[1] as List).map((e)=>BenchBatch.fromJson(_object(e))).toList();
    if(batches.map((b)=>b.key).toSet().length!=batches.length)throw const FormatException('Trùng danh tính phiên.');
    return BenchOverview(data[0]==null?null:_object(data[0]),batches);
  }
  Future<BenchDetail> detail(User user,String area,BenchBatch batch) async {
    final p='${_scope(user,area)}/batches/${batch.key}';
    final data=await Future.wait([_read(p),_read('$p/results'),_read('$p/results/ai-readiness'),
      _read('$p/results/retry-status'),_read('$p/receipts')]);
    final detail=_object(data[0]),timeline=_object(_object(data[0])['timeline']);
    if(timeline['stationId']!=batch.stationId||timeline['bootId']!=batch.bootId||timeline['batchId']!=batch.batchId){
      throw const FormatException('Danh tính phiên không khớp.');
    }
    final results=_object(data[1]),ready=_object(data[2]),retry=_object(data[3]);
    final receipts=_object(data[4]);
    verifyBenchSnapshot(batch,timeline,receipts,[results,ready,retry]);
    final channels=await Future.wait(benchAnalytes.map((a)async{
      final result=benchChannel(results,a);
      BenchJson? review;
      var unavailable=false;
      if(benchMap(result?['assessment'])['status']=='estimate_review_required'){
        try{
          review=_object(await _read('$p/results/$a/review'));
          if(review['assessmentId']!=benchMap(result?['assessment'])['id']){review=null;unavailable=true;}
        }on DioException catch(e){
          if(e.response?.statusCode==401||e.response?.statusCode==403)rethrow;
          unavailable=true;
        }catch(_){unavailable=true;}
      }
      return BenchChannel(a,benchChannel(timeline,a),result,benchChannel(ready,a),benchChannel(retry,a),review,unavailable);
    }));
    return BenchDetail(timeline:timeline,stale:detail['observationStale']!=false,receipts:receipts,channels:channels);
  }
}
