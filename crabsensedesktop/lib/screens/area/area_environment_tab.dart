import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/production_models.dart';
import '../../models/area_environment_metric.dart';
import '../../services/cloud_api_client.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/shared/mgmt_ui.dart';
import '../../widgets/environment/qualified_environment_cards.dart';

/// One shared RAS reference for all rows and boxes in the area.
class AreaEnvironmentTab extends StatefulWidget {
  const AreaEnvironmentTab({super.key,required this.token,required this.areaId,
    required this.areaName,required this.rows,this.onOpenAlerts});
  final String token,areaId,areaName;
  final List<RowRecord> rows;
  final VoidCallback? onOpenAlerts;
  @override
  State<AreaEnvironmentTab> createState()=>_AreaEnvironmentTabState();
}

class _AreaEnvironmentTabState extends State<AreaEnvironmentTab> with WidgetsBindingObserver {
  final _api=CloudApiClient();
  Timer? _timer;
  int _generation=0;
  bool _loading=false,_foreground=false;
  List<AreaEnvironmentMetric> _metrics=const [];
  DateTime? _verifiedAt;
  String? _error;

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state=WidgetsBinding.instance.lifecycleState;
    _foreground=state==null || state==AppLifecycleState.resumed;
    _timer=Timer.periodic(const Duration(seconds:2),(_){
      if(!mounted)return;
      setState((){});
      if(_foreground && !_loading && (_verifiedAt==null ||
          DateTime.now().difference(_verifiedAt!)>=const Duration(seconds:10)))unawaited(_load());
    });
    if(_foreground)unawaited(_load());
  }
  void _clear(){
    ++_generation;_loading=false;_metrics=const [];_verifiedAt=null;_error=null;
  }
  @override
  void didUpdateWidget(covariant AreaEnvironmentTab oldWidget){
    super.didUpdateWidget(oldWidget);
    if(oldWidget.areaId!=widget.areaId || oldWidget.token!=widget.token){
      _clear();
      if(_foreground)unawaited(_load());
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state){
    if(!mounted)return;
    setState((){_foreground=state==AppLifecycleState.resumed;_clear();});
    if(_foreground)unawaited(_load());
  }
  @override
  void dispose(){
    ++_generation;_timer?.cancel();WidgetsBinding.instance.removeObserver(this);super.dispose();
  }
  Future<void> _load() async {
    if(!_foreground || _loading || widget.areaId.isEmpty || widget.token.isEmpty)return;
    final generation=++_generation;
    final area=widget.areaId,token=widget.token;
    setState(()=>_loading=true);
    bool current()=>mounted && generation==_generation && _foreground &&
        area==widget.areaId && token==widget.token;
    try{
      final live=await _api.fetchIotLive(token,farmingAreaId:area).timeout(const Duration(seconds:10));
      if(!current())return;
      final data=AreaSensorLatestData.fromIotLive(areaId:area,live:live);
      setState((){_metrics=data.metrics;_verifiedAt=DateTime.now();_error=null;});
    }catch(_){
      if(current())setState((){_metrics=const [];_verifiedAt=null;_error='Không xác minh được dữ liệu môi trường.';});
    }finally{
      if(current())setState(()=>_loading=false);
    }
  }
  @override
  Widget build(BuildContext context){
    final age=_verifiedAt==null ? null : DateTime.now().difference(_verifiedAt!);
    final verified=_foreground && age!=null && !age.isNegative && age<const Duration(seconds:15);
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text('Môi trường RAS · '+widget.areaName,style:bvText(fontSize:16,fontWeight:FontWeight.w800)),
      const SizedBox(height:8),
      Text('Dữ liệu nước chung cho '+widget.rows.length.toString()+' dãy và các hộp cùng khu. Không đo riêng từng dãy/hộp.'),
      Wrap(spacing:12,runSpacing:8,children:[
        MgmtOutlineButton(icon:Icons.refresh,label:'Tải lại',onTap:_loading ? null : _load),
        if(widget.onOpenAlerts!=null) MgmtOutlineButton(icon:Icons.notifications_outlined,
          label:'Hệ thống cảnh báo',onTap:widget.onOpenAlerts),
      ]),
      if(_loading)const LinearProgressIndicator(),
      if(_error!=null)Text(_error!,style:bvText(color:DashboardColors.risk)),
      const SizedBox(height:10),
      QualifiedEnvironmentCards(metrics:verified ? _metrics : const []),
      const SizedBox(height:12),
      const Text('Lịch sử và CSV: Giám sát thời gian thực, chọn cảm biến. Không dùng biểu đồ so sánh riêng các dãy.'),
      const Text('NH₃/NH₄, NO₂, NO₃: xem Phân tích nước WaterBench. Ngưỡng cấu hình không kết luận nước an toàn.'),
    ]);
  }
}
