import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../authentication/domain/entities/user.dart';
import '../../home/presentation/widgets/home_palette.dart';
import '../data/water_bench_service.dart';
import '../data/water_bench_model.dart';

class WaterBenchScreen extends StatefulWidget {
  const WaterBenchScreen({super.key,required this.user,required this.api,this.initialAreaId,this.service});
  final User user;
  final ApiClient? api;
  final String? initialAreaId;
  final StaffWaterBenchService? service;
  @override
  State<WaterBenchScreen> createState()=>_WaterBenchScreenState();
}

class _WaterBenchScreenState extends State<WaterBenchScreen> {
  late final StaffWaterBenchService _service;
  List<BenchJson> _areas=[];
  String? _area,_error;
  BenchOverview? _overview;
  BenchBatch? _batch;
  BenchDetail? _detail;
  bool _busy=false;
  int _generation=0;
  Timer? _timer;
  @override
  void initState(){
    super.initState();
    _service=widget.service??StaffWaterBenchService(widget.api!);
    unawaited(_refresh());
    _timer=Timer.periodic(const Duration(seconds:30),(_){
      if(mounted&&!_busy&&_error==null&&ModalRoute.of(context)?.isCurrent==true)unawaited(_refresh());
    });
  }
  @override
  void didUpdateWidget(covariant WaterBenchScreen oldWidget){
    super.didUpdateWidget(oldWidget);
    if(oldWidget.user!=widget.user){
      _areas=[];_area=null;_overview=null;_batch=null;_detail=null;
      unawaited(_refresh());
    }
  }
  bool _current(int n)=>mounted&&n==_generation;
  Future<void> _refresh({String? area,String? batchKey})async{
    final n=++_generation,user=widget.user;
    final requested=area??_area??widget.initialAreaId,previous=batchKey??(area==null?_batch?.key:null);
    setState((){_busy=true;_error=null;_overview=null;_detail=null;_batch=null;});
    try{
      final areas=await _service.areas(user);
      if(!_current(n))return;
      // A deep link cannot grant access. Do not silently switch to another area.
      final selected=areas.any((a)=>a['id']==requested)?requested:
        requested==null&&areas.isNotEmpty?areas.first['id'].toString():null;
      setState((){_areas=areas;_area=selected;});
      if(selected==null)return;
      final overview=await _service.overview(user,selected);
      if(!_current(n))return;
      BenchBatch? batch;
      for(final b in overview.batches){if(b.key==previous)batch=b;}
      batch??=overview.batches.isEmpty?null:overview.batches.first;
      setState((){_overview=overview;_batch=batch;});
      final detail=batch==null?null:await _service.detail(user,selected,batch!);
      if(_current(n))setState(()=>_detail=detail);
    }catch(_){
      if(_current(n))setState((){_areas=[];_area=null;_overview=null;_detail=null;_batch=null;_error='Không tải được dữ liệu hoặc quyền truy cập đã thay đổi. Kiểm tra kết nối và đăng nhập.';});
    }finally{if(_current(n))setState(()=>_busy=false);}
  }
  @override
  void dispose(){++_generation;_timer?.cancel();super.dispose();}
  String _label(Object? v)=>switch(v){
    'running_observed'=>'Đã quan sát đang chạy',
    'firmware_complete_reported'=>'Firmware báo hoàn tất',
    'fault_reported'=>'Báo lỗi',
    'interrupted_observed'=>'Gián đoạn',
    'preparing_observed'=>'Chuẩn bị',
    'reacting_observed'=>'Phản ứng',
    'capture_requested'=>'Yêu cầu chụp',
    'drained_reported'=>'Đã báo xả',
    'awaiting_media'=>'Chờ ảnh',
    'awaiting_firmware_completion'=>'Chờ firmware',
    'awaiting_assessment'=>'Chờ đánh giá',
    'estimate_review_required'=>'Ước tính – chờ duyệt',
    'needs_retest'||'retest_recommended'=>'Cần đo lại',
    'retry_available'||'retry_backoff'=>'Chờ Admin retry AI',
    'retry_exhausted'||'technical_review_required'=>'Cần kiểm tra kỹ thuật',
    'operator_confirmation_required'=>'Chờ Admin xác nhận',
    'pending_review'=>'Chờ duyệt',
    'approved'=>'Đã duyệt, chưa công bố',
    'rejected'=>'Đã từ chối',
    'published'=>'Đã công bố hồ sơ',
    'inference_running'=>'AI đang xử lý',
    'not_attempted'=>'Chưa phân tích',
    'completed'=>'Đã xử lý',
    _=>v?.toString()??'Chưa có dữ liệu',
  };
  Widget _line(String name,Object? v)=>Padding(padding:const EdgeInsets.only(bottom:5),
    child:Text('$name: ${v??"—"}',style:const TextStyle(color:kHomeTextMain)));
  Widget _card(String title,List<Widget> children)=>Container(
    margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(14),decoration:homeCardDecoration(),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(title,style:const TextStyle(color:kHomePrimaryDark,fontSize:17,fontWeight:FontWeight.w700)),
      const SizedBox(height:10),...children]));
  Widget _channel(BenchChannel c,bool stale){
    final retest=c.result?['status']=='needs_retest'||c.retry?['status']=='retest_recommended';
    return _card(c.analyte,[
      _line('Firmware',stale?'Quan sát cũ – ${_label(c.observation?["status"])}':_label(c.observation?['status'])),
      _line('AI',_label(c.result?['status'])),_line('Ước tính',c.estimate==null?'—':'${c.estimate} ${c.unit}'),
      _line('Retry',_label(c.retry?['status'])),_line('Xét duyệt',c.reviewUnavailable?'Chưa đọc được':_label(c.review?['status'])),
      if(c.publishedReference!=null)_line('Đối chứng đã công bố','${c.publishedReference} ${c.publication["unit"]}'),
      if(retest)const Text('Cần đo lại: báo Farm Manager/Farm Admin để phối hợp. Đây không phải lệnh chạy trạm.',style:TextStyle(color:kHomeWarning,fontWeight:FontWeight.w600)),
    ]);
  }
  @override
  Widget build(BuildContext context){
    final overview=_overview,detail=_detail,station=overview?.station;
    return Scaffold(backgroundColor:kHomeBg,
      appBar:AppBar(title:const Text('Phân tích nước'),backgroundColor:kHomeBg,
        actions:[IconButton(tooltip:'Tải lại',onPressed:_busy?null:()=>unawaited(_refresh()),icon:const Icon(Icons.refresh))]),
      body:SafeArea(child:RefreshIndicator(onRefresh:()=>_refresh(),child:ListView(
        physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.all(16),children:[
          const Text('WaterBench · Farm Staff · Chỉ giám sát',style:TextStyle(color:kHomeTextSub)),
          const SizedBox(height:12),
          if(_busy)const LinearProgressIndicator(),
          if(_error!=null)_card('Không tải được', [Text(_error!,style:const TextStyle(color:kHomeDanger))]),
          if(_areas.isNotEmpty)_card('Khu nuôi',[
            DropdownButtonFormField<String>(key:ValueKey(_area),value:_area,isExpanded:true,
              decoration:const InputDecoration(labelText:'Chọn khu được phân công'),
              items:_areas.map((a)=>DropdownMenuItem(value:a['id'].toString(),
                child:Text((a['name']??a['code']??a['id']).toString(),overflow:TextOverflow.ellipsis))).toList(),
              onChanged:_busy?null:(v){if(v!=null)unawaited(_refresh(area:v));}),
            if(_area==null)const Text('Chọn khu hợp lệ để xem dữ liệu.'),
          ]),
          if(!_busy&&_error==null&&_areas.isEmpty)const Text('Chưa có khu được phân công.'),
          if(overview!=null)...[
            _card('Trạm và lịch',[
              if(station==null)const Text('Chưa đăng ký trạm.')else...[
                _line('Lịch',station['enabled']==true?'Có hiệu lực':'Chưa có hiệu lực'),
                _line('Giờ',station['times'] is List?(station['times'] as List).join(', '):null),
                _line('Múi giờ',station['timezone']),
              ],
              const Text('Lịch không xác nhận phần cứng đã chạy.',style:TextStyle(color:kHomeTextSub)),
            ]),
            _card('Phiên phân tích',[
              if(overview.batches.isEmpty)const Text('Chưa có phiên.')else
                DropdownButtonFormField<String>(key:ValueKey(_batch?.key),value:_batch?.key,isExpanded:true,
                  decoration:const InputDecoration(labelText:'50 phiên gần nhất'),
                  items:overview.batches.map((b)=>DropdownMenuItem(value:b.key,
                    child:Text('${b.batchId} · ${b.mode=="scheduled"?"Định kỳ":"Thủ công"}',overflow:TextOverflow.ellipsis))).toList(),
                  onChanged:_busy?null:(v){if(v!=null)unawaited(_refresh(batchKey:v));}),
            ]),
          ],
          if(detail!=null)...[
            _card('Tiến độ và bằng chứng',[
              _line('Trạng thái',_label(detail.timeline['status'])),
              _line('Quan sát cuối',detail.timeline['lastObservedAt']),
              if(detail.stale)const Text('Quan sát đã cũ hoặc không rõ. Không suy ra trạng thái thiết bị hiện tại.',style:TextStyle(color:kHomeWarning)),
              _line('Biên nhận',detail.receipts['total']),_line('Ảnh',detail.receipts['mediaCount']),
            ]),
            ...detail.channels.map((c)=>_channel(c,detail.stale)),
          ],
          const Text('Ước tính AI chưa được xác thực hóa học. Hiệu chuẩn, retry và công bố thuộc Farm Admin Web.',style:TextStyle(color:kHomeTextSub)),
        ]))));
  }
}
