import 'package:flutter/material.dart';
import '../../services/crab_service.dart';
import '../../services/cloud_api_client.dart';

String _v(Map<String,dynamic> row,String key) =>
  (row[key] ?? row[key[0].toUpperCase()+key.substring(1)])?.toString() ?? '';

Future<bool?> showHistoryCorrections(BuildContext context, CrabService service, {
  required String entityId, required bool byBox, required String label,
}) => showDialog<bool>(context:context,barrierDismissible:false,
  builder: (_) => _HistoryCorrections(service:service,entityId:entityId,byBox:byBox,label:label));

class _HistoryCorrections extends StatefulWidget {
  const _HistoryCorrections({required this.service,required this.entityId,required this.byBox,required this.label});
  final CrabService service;
  final String entityId,label;
  final bool byBox;
  @override State<_HistoryCorrections> createState()=>_HistoryCorrectionsState();
}

class _HistoryCorrectionsState extends State<_HistoryCorrections> {
  late final String _area = widget.service.farmId;
  late final int _generation = widget.service.scopeGeneration;
  late String _kind = widget.byBox ? 'status-history' : 'allocations';
  List<Map<String,dynamic>> _rows=[];
  Set<String> _boxIds={};
  bool _busy=false, _changed=false;
  String? _error;
  bool get _valid => mounted && widget.service.canManageCurrentArea &&
    widget.service.farmId==_area && widget.service.scopeGeneration==_generation &&
    (widget.byBox || widget.service.canCorrectCrab(widget.entityId));
  bool _rowAllowed(Map<String,dynamic> row) => _valid && _v(row,'id').isNotEmpty &&
    _boxIds.contains(_v(row,'boxId')) &&
    (widget.byBox ? _v(row,'boxId')==widget.entityId : _v(row,'crabId')==widget.entityId);
  @override void initState(){ super.initState(); _load(); }
  Future<void> _load() async {
    if (!_valid) return;
    setState((){_busy=true;_error=null;_rows=[];});
    final svc=widget.service;
    try {
      final boxes=await svc.api.fetchAllBoxes(svc.token,areaId:_area);
      if (!_valid) return;
      _boxIds=boxes.map((b)=>b.id).toSet();
      if(widget.byBox&&!_boxIds.contains(widget.entityId)) throw StateError('Hộp không thuộc khu hiện tại.');
      final rows=await svc.api.fetchCorrectionHistory(svc.token,areaId:_area,
        entityId:widget.entityId,byBox:widget.byBox,kind:_kind);
      if(!_valid)return;
      _rows=rows.where(_rowAllowed).toList();
    }catch(e){if(_valid)_error='$e';}
    finally{if(mounted)setState(()=>_busy=false);}
  }

  Future<void> _edit(Map<String,dynamic> row,{bool voiding=false}) async {
    if(!_rowAllowed(row)||_busy||_v(row,'isVoided').toLowerCase()=='true')return;
    final kind=_kind;
    final reason=TextEditingController();
    final note=TextEditingController(text:_v(row,'notes'));
    final start=TextEditingController(text:_v(row,kind=='allocations'?'startTime':kind=='moltings'?'moltTime':'changedAt'));
    final end=TextEditingController(text:_v(row,'endTime'));
    final weight=TextEditingController(text:_v(row,'weightAfterGram'));
    final originalStatus=_v(row,kind=='moltings'?'result':'newStatus').toLowerCase();
    final statuses=kind=='moltings'?const ['success','monitoring','abnormal','failed']:const ['empty','active','molting','quarantine','maintenance','harvested','watch'];
    String? status=statuses.contains(originalStatus)?originalStatus:null;
    final hasEnd=_v(row,'endTime').isNotEmpty;
    final originalOccupied=_v(row,'newIsOccupied').toLowerCase();
    bool? occupied=originalOccupied=='true'?true:originalOccupied=='false'?false:null;
    bool saved=false;
    String? error;
    try{
      final confirmed=await showDialog<bool>(context:context,barrierDismissible:false,builder:(ctx)=>StatefulBuilder(builder:(ctx,change)=>AlertDialog(
        title:Text(voiding?'Vô hiệu hóa bản ghi lột xác':'Hiệu chỉnh lịch sử'),
        content:SizedBox(width:480,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
          const Text('Chỉ sửa lịch sử, không thay đổi trạng thái vận hành hiện tại. Backend lưu audit.'),
          if(!voiding)...[
            TextField(controller:start,decoration:const InputDecoration(labelText:'Thời điểm (ISO 8601, có múi giờ)')),
            if(kind=='allocations'&&hasEnd)TextField(controller:end,decoration:const InputDecoration(labelText:'Thời điểm kết thúc')),
            if(kind=='allocations'&&!hasEnd)const Text('Phân bổ đang mở: không được đóng bằng hiệu chỉnh.'),
            if(kind!='allocations')DropdownButtonFormField<String>(value:status,
              decoration:const InputDecoration(labelText:'Kết quả / trạng thái'),
              items:statuses.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>change(()=>status=v)),
            if(kind=='moltings')TextField(controller:weight,decoration:const InputDecoration(labelText:'Khối lượng sau lột (g)')),
            if(kind=='status-history')CheckboxListTile(value:occupied??false,onChanged:(v)=>change(()=>occupied=v),title:const Text('Có cua tại thời điểm lịch sử')),
            if(kind!='status-history')TextField(controller:note,decoration:const InputDecoration(labelText:'Ghi chú')),
          ],
          TextField(controller:reason,maxLength:1000,decoration:const InputDecoration(labelText:'Lý do bắt buộc')),
          if(error!=null)Text(error!,style:TextStyle(color:Theme.of(ctx).colorScheme.error)),
        ]))),
        actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Hủy')),
          FilledButton(onPressed:(){
            final dt=DateTime.tryParse(start.text.trim());
            final et=DateTime.tryParse(end.text.trim());
            final wt=double.tryParse(weight.text.trim());
            if(reason.text.trim().isEmpty||(!voiding&&(dt==null||dt.isAfter(DateTime.now())||
              (kind=='allocations'&&hasEnd&&(et==null||et.isBefore(dt)||et.isAfter(DateTime.now())))||
              (kind=='moltings'&&weight.text.trim().isNotEmpty&&(wt==null||!wt.isFinite||wt<=0))||
              (kind!='allocations'&&status==null)))){
              change(()=>error='Kiểm tra lý do, thời điểm, kết quả và khối lượng.');return;}
            Navigator.pop(ctx,true);
          },child:const Text('Xác nhận'))],
      )));
      if(confirmed!=true||!_rowAllowed(row))return;
      setState((){_busy=true;_error=null;});
      final svc=widget.service;
      final id=_v(row,'id');
      final why=reason.text.trim();
      if(voiding){
        await svc.api.voidMolting(svc.token,id,_area,why);
      }else if(kind=='allocations'){
        await svc.api.correctAllocation(svc.token,id,_area,notes:'${note.text.trim()}\nLý do hiệu chỉnh: $why',
          startTime:DateTime.parse(start.text.trim()),endTime:hasEnd?DateTime.parse(end.text.trim()):null);
      }else if(kind=='moltings'){
        await svc.api.correctMolting(svc.token,id,_area,reason:why,notes:note.text.trim(),result:status,
          moltTime:DateTime.parse(start.text.trim()),weightAfterGram:double.tryParse(weight.text.trim()));
      }else{
        await svc.api.correctBoxHistory(svc.token,id,_area,reason:why,newStatus:status,
          changedAt:DateTime.parse(start.text.trim()),newIsOccupied:occupied);
      }
      saved=true;
      if(_valid){_changed=true;await _load();}
    }catch(e){if(_valid)setState(()=>_error='$e');}
    finally{reason.dispose();note.dispose();start.dispose();end.dispose();weight.dispose();
      if(mounted)setState(()=>_busy=false);
      if(saved&&!_valid&&mounted)Navigator.pop(context,true);
    }
  }
  @override Widget build(BuildContext context)=>PopScope(canPop:!_busy,child:AlertDialog(
    title:Text('Hiệu chỉnh lịch sử — ${widget.label}'),
    content:SizedBox(width:720,height:460,child:Column(children:[
      const Text('Chỉ hiện các bản ghi gắn với hộp trong khu được chọn. Không xóa lịch sử phân hộp hoặc trạng thái hộp.'),
      DropdownButton<String>(value:_kind,onChanged:_busy?null:(v){if(v!=null){setState(()=>_kind=v);_load();}},
        items:[const DropdownMenuItem(value:'allocations',child:Text('Phân hộp')),
          const DropdownMenuItem(value:'moltings',child:Text('Lột xác')),
          if(widget.byBox)const DropdownMenuItem(value:'status-history',child:Text('Trạng thái hộp'))]),
      if(_busy)const LinearProgressIndicator(),
      if(_error!=null)Text(_error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
      Expanded(child:_rows.isEmpty?const Center(child:Text('Không có bản ghi trong phạm vi hiện tại.')):ListView(
        children:[for(final row in _rows) Card(child:ListTile(
          title:Text(_kind=='allocations'?'${_v(row,"startTime")} → ${_v(row,"endTime").isEmpty?"Đang mở":_v(row,"endTime")}':
            _kind=='moltings'?'${_v(row,"moltTime")} · ${_v(row,"result")}':'${_v(row,"changedAt")} · ${_v(row,"newStatus")}'),
          subtitle:Text('ID: ${_v(row,"id")}\n${_v(row,"isVoided").toLowerCase()=="true"?"Đã vô hiệu: ${_v(row,"voidReason")}":_v(row,_kind=="status-history"?"reason":"notes")}'),
          trailing:Wrap(children:[
            if(_v(row,'isVoided').toLowerCase()!='true')TextButton(onPressed:_busy?null:()=>_edit(row),child:const Text('Sửa')),
            if(_kind=='moltings'&&_v(row,'isVoided').toLowerCase()!='true')TextButton(onPressed:_busy?null:()=>_edit(row,voiding:true),child:const Text('Vô hiệu')),
          ]),
        ))],
      )),
    ])),
    actions:[TextButton(onPressed:_busy?null:()=>Navigator.pop(context,_changed),child:const Text('Đóng'))],
  ));
}
