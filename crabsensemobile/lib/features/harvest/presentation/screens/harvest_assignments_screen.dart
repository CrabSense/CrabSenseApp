import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';

/// Staff-only, online assignment workflow. Backend owns all transitions.
class HarvestAssignmentsScreen extends StatefulWidget {
  const HarvestAssignmentsScreen({super.key});
  @override
  State<HarvestAssignmentsScreen> createState() => _HarvestAssignmentsScreenState();
}

class _HarvestAssignmentsScreenState extends State<HarvestAssignmentsScreen> {
  final _api = sl<ApiClient>();
  List<Map<String,dynamic>> _tasks = [];
  Map<String,dynamic>? _detail;
  bool _busy = false;
  String? _error;
  String? _owner;
  String? _area;
  int _version=0;

  User? get _user {
    final auth=context.read<AuthBloc>().state;
    return auth is Authenticated && auth.user.role==UserRole.farmStaff ? auth.user:null;
  }
  bool _allowed(Map<String,dynamic> row) {
    final u=_user;
    return u!=null && u.id==_owner && row['assignedToUserId']?.toString()==u.id
      && u.assignedFarmIds.contains(row['farmingAreaId']?.toString()) && (_area==null||row['farmingAreaId']==_area);
  }
  dynamic _data(dynamic body) {
    if(body is! Map || body['success']==false || !body.containsKey('data')) throw StateError('Phản hồi thu hoạch không hợp lệ.');
    return body['data'];
  }
  List<Map<String,dynamic>> _rows(dynamic value) {
    if(value is! List)throw StateError('Thiếu danh sách kết quả.');
    return value.map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }
  String _status(Map<String,dynamic> row)=>(row['status']??'').toString().toLowerCase();
  List<Map<String,dynamic>> get _lines=>_detail==null?[]:_rows(_detail!['lines']);
  bool _activeLine(Map<String,dynamic> line)=>const {'assigned','eligible','inprogress'}.contains(_status(line));
  bool get _readyToSubmit => _lines.isNotEmpty && _lines.where(_activeLine).every((l)=>l['outcome']!=null);
  @override void initState(){super.initState();WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)_refresh();});}
  Future<void> _run(Future<void> Function() action) async {
    if(_busy||!mounted)return;
    final user=_user;
    if(user==null||(_owner!=null&&_owner!=user.id)){setState((){_tasks=[];_detail=null;_error='Phiên Staff đã thay đổi.';});return;}
    _owner=user.id;
    final version=++_version;
    setState((){_busy=true;_error=null;});
    try {await action();}
    on DioException catch(e){if(mounted&&version==_version)setState(()=>_error=(e.response?.data is Map?(e.response!.data as Map)['message']:null)?.toString()??'Không thể kết nối. Tải lại trước khi thử lại.');}
    catch(e){if(mounted&&version==_version)setState(()=>_error='$e');}
    finally{if(mounted&&version==_version)setState(()=>_busy=false);}
  }
  Future<void> _fetchList() async {
    final res=await _api.get<dynamic>('/harvest-assignments',queryParameters:{if(_area!=null)'farmingAreaId':_area});
    final rows=_rows(_data(res.data));
    if(!mounted||_user?.id!=_owner)return;
    setState(()=>_tasks=rows.where(_allowed).toList());
  }
  Future<void> _fetchDetail(String id) async {
    final dynamic res;
    try { res=await _api.get<dynamic>('/harvest-assignments/$id'); }
    on DioException catch(e){if(mounted&&const {403,404}.contains(e.response?.statusCode))setState(()=>_detail=null);rethrow;}
    final row=Map<String,dynamic>.from(_data(res.data) as Map);
    if(!mounted||_user?.id!=_owner)return;
    if(!_allowed(row)||row['id']?.toString()!=id){setState(()=>_detail=null);throw StateError('Nhiệm vụ ngoài phạm vi.');}
    setState(()=>_detail=row);
  }
  Future<void> _refresh()=>_run(()async{final id=_detail?['id']?.toString();await _fetchList();if(id!=null&&mounted)await _fetchDetail(id);});
  Future<void> _write(String action,Map<String,dynamic> body) => _run(()async{
    final row=_detail;
    if(row==null||!_allowed(row))throw StateError('Nhiệm vụ ngoài phạm vi.');
    final id=row['id'].toString();
    final res=await _api.post<dynamic>('/harvest-assignments/$id/$action',data:body);
    _data(res.data);
    if(!mounted||_user?.id!=_owner)return;
    await _fetchDetail(id);
    await _fetchList();
  });

  Future<void> _edit(Map<String,dynamic> line) async {
    if(_busy||_detail==null||!_allowed(_detail!)||_status(_detail!)!='inprogress'||!_activeLine(line))return;
    final taskId=_detail!['id'].toString();
    final lineId=line['id'].toString();
    final crabId=line['crabId'].toString();
    if(lineId.isEmpty||crabId.isEmpty||lineId=='null'||crabId=='null')return;
    final result=await showDialog<_LineResult>(context:context,builder:(_)=>_LineEditor(line:line));
    if(result==null||!mounted||_detail?['id']!=taskId||!_allowed(_detail!)||_status(_detail!)!='inprogress')return;
    await _run(()async{
      final body=Map<String,dynamic>.from(result.body);
      if(result.photos.isNotEmpty){
        final form=FormData();
        for(final photo in result.photos){
          final bytes=await photo.readAsBytes();
          if(bytes.length>8*1024*1024)throw StateError('Mỗi ảnh tối đa 8 MB.');
          form.files.add(MapEntry('files',MultipartFile.fromBytes(bytes,filename:photo.name)));
        }
        if(!mounted||!_allowed(_detail!))throw StateError('Phiên đã thay đổi.');
        final uploaded=await _api.post<dynamic>('/crabs/$crabId/images',data:form);
        dynamic raw=_data(uploaded.data);
        if(raw is Map)raw=raw['items']??raw['data'];
        final urls=_rows(raw).map((x)=>(x['url']??x['Url']??x['storageKey']??x['StorageKey']??'').toString()).where((u)=>u.isNotEmpty).toList();
        if(urls.length!=result.photos.length)throw StateError('Không xác nhận được toàn bộ ảnh. Chưa gửi kết quả.');
        body['photoUrls']=[...((body['photoUrls'] as List?)??[]),...urls];
      }
      if(!mounted||!_allowed(_detail!))throw StateError('Phiên đã thay đổi.');
      final res=await _api.post<dynamic>('/harvest-assignments/$taskId/results',data:{'lines':[body]});
      _data(res.data);
      if(mounted&&_user?.id==_owner)await _fetchDetail(taskId);
    });
  }

  Future<void> _complete()async {
    final row=_detail;
    if(row==null||!_allowed(row)||_status(row)!='inprogress'||!_readyToSubmit)return;
    final yes=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Gửi kết quả cho Manager?'),content:const Text('Kết quả sẽ được khóa để Manager kiểm tra. Phiếu và trạng thái cua chỉ được cập nhật khi Manager xác nhận. Nếu yêu cầu bổ sung, bạn có thể sửa lại.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Hủy')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Xác nhận'))]));
    if(yes==true&&mounted&&identical(row,_detail)&&_allowed(row))await _write('complete',{});
  }
  @override Widget build(BuildContext context){
    final auth=context.watch<AuthBloc>().state;
    if(auth is! Authenticated||auth.user.role!=UserRole.farmStaff||(_owner!=null&&auth.user.id!=_owner))return const Scaffold(body:Center(child:Text('Chỉ Staff được giao nhiệm vụ mới có quyền truy cập.')));
    final detail=_detail;
    return Scaffold(appBar:AppBar(title:const Text('Nhiệm vụ thu hoạch'),actions:[IconButton(onPressed:_busy?null:_refresh,icon:const Icon(Icons.refresh))]),body:ListView(padding:const EdgeInsets.all(16),children:[
      if(_busy)const LinearProgressIndicator(),
      if(_error!=null)Text(_error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
      if(detail==null)...[
        DropdownButton<String>(isExpanded:true,value:_area??'',items:[const DropdownMenuItem(value:'',child:Text('Tất cả khu được giao')),for(final id in auth.user.assignedFarmIds.toSet())DropdownMenuItem(value:id,child:Text(id))],onChanged:_busy?null:(id){setState((){_area=id==''?null:id;_tasks=[];});_refresh();}),
        if(!_busy&&_tasks.isEmpty)const Text('Không có nhiệm vụ được giao.'),
        for(final task in _tasks.where(_allowed))Card(child:ListTile(title:Text(task['assignmentCode'].toString()),subtitle:Text('Trạng thái: ${task['status']} · ${task['lineCount']} cua'),trailing:const Icon(Icons.chevron_right),onTap:_busy?null:()=>_run(()=>_fetchDetail(task['id'].toString())))),
      ]else if(_allowed(detail))...[
        TextButton.icon(onPressed:_busy?null:()=>setState(()=>_detail=null),icon:const Icon(Icons.arrow_back),label:const Text('Danh sách nhiệm vụ')),
        Text(detail['assignmentCode'].toString(),style:Theme.of(context).textTheme.titleLarge),
        Text('Khu: ${detail['farmingAreaId']} · ${detail['status']}'),
        if(detail['notes']!=null)Text(detail['notes'].toString()),
        if(_status(detail)=='pendingreview')const Text('Đã gửi kết quả. Đang chờ Manager xác nhận.'),
        if(detail['reviewNotes']!=null)Text('Phản hồi Manager: ${detail['reviewNotes']}'),
        if(detail['workflowAudit'] is List)for(final event in _rows(detail['workflowAudit']))ListTile(dense:true,title:Text('${event['action']} · ${event['at']}'),subtitle:Text(event['reason']?.toString()??'—')),
        if(_status(detail)=='assigned')FilledButton(onPressed:_busy?null:()=>_write('accept',{}),child:const Text('Nhận nhiệm vụ')),
        for(final line in _lines)Card(child:ListTile(title:Text('${line['crabCode']} · ${line['boxCode']}'),subtitle:Text('${line['status']} · ${line['outcome']??"Chưa xử lý"} · ${line['pendingWeightGram']??"—"} g'),trailing:_status(detail)=='inprogress'&&_activeLine(line)?const Icon(Icons.edit):null,onTap:_busy||_status(detail)!='inprogress'||!_activeLine(line)?null:()=>_edit(line))),
        if(_status(detail)=='inprogress')FilledButton(onPressed:_busy||!_readyToSubmit?null:_complete,child:const Text('Gửi kết quả chờ xác nhận')),
        if(detail['vouchers'] is List)for(final voucher in _rows(detail['vouchers']))ListTile(title:Text('Phiếu ${voucher['voucherCode']}'),subtitle:Text('${voucher['status']} · ${voucher['totalQuantity']} cua · ${voucher['totalWeightKg']} kg')),
      ]
    ]));
  }
}
class _LineResult {
  const _LineResult(this.body,this.photos);
  final Map<String,dynamic> body;
  final List<XFile> photos;
}
class _LineEditor extends StatefulWidget {
  const _LineEditor({required this.line});
  final Map<String,dynamic> line;
  @override State<_LineEditor> createState()=>_LineEditorState();
}
class _LineEditorState extends State<_LineEditor>{
  final _form=GlobalKey<FormState>();
  late bool _harvest=(widget.line['outcome']??'')=='Harvested';
  late bool _molt=widget.line['pendingMoltConfirmed']==true;
  late bool _soft=widget.line['pendingIsSoftshell']==true;
  late String _grade=['A','B','C','S','M','L','XL','XXL'].contains(widget.line['pendingGrade'])?widget.line['pendingGrade'].toString():'A';
  late final _weight=TextEditingController(text:widget.line['pendingWeightGram']?.toString()??'');
  late final _length=TextEditingController(text:widget.line['pendingCarapaceLengthMm']?.toString()??'');
  late final _width=TextEditingController(text:widget.line['pendingCarapaceWidthMm']?.toString()??'');
  late final _reason=TextEditingController(text:widget.line['eligibilityReason']?.toString()??'');
  late final _notes=TextEditingController(text:widget.line['pendingHarvestNotes']?.toString()??'');
  final _photos=<XFile>[];
  String? _photoError;
  late DateTime _at=DateTime.tryParse(widget.line['pendingHarvestedAt']?.toString()??'')?.toLocal()??DateTime.now();
  @override void dispose(){for(final c in [_weight,_length,_width,_reason,_notes]){c.dispose();}super.dispose();}
  double? _number(String? v)=>double.tryParse((v??'').replaceAll(',','.'));
  Widget _numeric(String title,TextEditingController c,{double max=10000})=>TextFormField(controller:c,decoration:InputDecoration(labelText:title),keyboardType:const TextInputType.numberWithOptions(decimal:true),validator:(v){final n=_number(v);return n==null||!n.isFinite||n<=0||n>max?'Nhập số hợp lệ':null;});
  Future<void> _pick()async{try{final files=await ImagePicker().pickMultiImage(imageQuality:80);if(mounted)setState(()=>_photos.addAll(files.take(3-_photos.length)));}catch(e){if(mounted)setState(()=>_photoError='Không chọn được ảnh: $e');}}
  Future<void> _date()async{final d=await showDatePicker(context:context,initialDate:_at,firstDate:DateTime(2020),lastDate:DateTime.now());if(d==null||!mounted)return;final t=await showTimePicker(context:context,initialTime:TimeOfDay.fromDateTime(_at));if(t!=null&&mounted)setState(()=>_at=DateTime(d.year,d.month,d.day,t.hour,t.minute));}
  void _save(){if(!_form.currentState!.validate())return;if(_harvest&&_at.isAfter(DateTime.now()))return;
    Navigator.pop(context,_LineResult({'assignmentLineId':widget.line['id'],'outcome':_harvest?'Harvested':'ContinueRaising','moltConfirmed':_molt,
      if(_harvest)...{'weightGram':_number(_weight.text),'carapaceLengthMm':_number(_length.text),'carapaceWidthMm':_number(_width.text),'grade':_grade,'isSoftshell':_soft,'harvestedAt':_at.toUtc().toIso8601String(),'notes':_notes.text,'photoUrls':widget.line['pendingPhotoUrls']??[]}
      else 'reason':_reason.text.trim()},_harvest?List.of(_photos):[]));}
  @override Widget build(BuildContext context)=>AlertDialog(title:Text('Xử lý ${widget.line['crabCode']}'),content:SizedBox(width:400,child:SingleChildScrollView(child:Form(key:_form,child:Column(mainAxisSize:MainAxisSize.min,children:[
    SwitchListTile(title:const Text('Thu hoạch'),subtitle:Text(_harvest?'Thu hoạch':'Tiếp tục nuôi'),value:_harvest,onChanged:(v)=>setState(()=>_harvest=v)),
    CheckboxListTile(title:const Text('Đã xác nhận cua lột'),value:_molt,onChanged:(v)=>setState(()=>_molt=v??false)),
    if(_harvest)...[_numeric('Cân nặng (g)',_weight),_numeric('Chiều dài mai (mm)',_length,max:1000),_numeric('Chiều rộng mai (mm)',_width,max:1000),
      DropdownButtonFormField<String>(value:_grade,items:const ['A','B','C','S','M','L','XL','XXL'].map((g)=>DropdownMenuItem(value:g,child:Text(g))).toList(),onChanged:(v)=>setState(()=>_grade=v??'A'),decoration:const InputDecoration(labelText:'Phân loại')),
      CheckboxListTile(title:const Text('Cua lột mềm'),value:_soft,onChanged:(v)=>setState(()=>_soft=v??false)),
      TextButton.icon(onPressed:_date,icon:const Icon(Icons.schedule),label:Text('Thời điểm: ${_at.toString().substring(0,16)}')),
      TextFormField(controller:_notes,decoration:const InputDecoration(labelText:'Ghi chú')),
      TextButton.icon(onPressed:_photos.length>=3?null:_pick,icon:const Icon(Icons.photo_library),label:Text('Thêm ảnh (${_photos.length}/3)')),
      for(final p in _photos.toList())ListTile(title:Text(p.name),trailing:IconButton(icon:const Icon(Icons.close),onPressed:()=>setState(()=>_photos.remove(p)))),
      if(_photoError!=null)Text(_photoError!),
    ]else TextFormField(controller:_reason,decoration:const InputDecoration(labelText:'Lý do nuôi tiếp (bắt buộc)'),validator:(v)=>(v??'').trim().isEmpty?'Nhập lý do':null),
  ])))),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Hủy')),FilledButton(onPressed:_save,child:const Text('Lưu kết quả'))]);
}
