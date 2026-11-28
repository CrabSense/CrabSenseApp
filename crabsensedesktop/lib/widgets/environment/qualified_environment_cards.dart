import 'package:flutter/material.dart';
import '../../models/area_environment_metric.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/mgmt_ui.dart';

/// Common area RAS references. Never aggregate the inlet and outlet sensors.
class QualifiedEnvironmentCards extends StatelessWidget {
  const QualifiedEnvironmentCards({super.key,required this.metrics});
  final List<AreaEnvironmentMetric> metrics;
  @override
  Widget build(BuildContext context) {
    if(metrics.isEmpty)return const Text('Chưa có phép đo đủ điều kiện hiển thị.');
    return Wrap(spacing:12,runSpacing:12,children:[
      for(final m in metrics)
        Container(
          key:ValueKey('qualified-environment-'+(m.sensorId??'')),
          width:260,padding:const EdgeInsets.all(14),
          decoration:mgmtCardDeco(radius:12),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(m.label+' · '+(m.sensorCode ?? m.sensorId ?? '—'),style:bvText(fontWeight:FontWeight.w700)),
            Text((m.value==0 ? '0' : m.value.toString())+' '+m.unit,style:bvText(fontSize:20,fontWeight:FontWeight.w800)),
            if(m.locationName?.isNotEmpty??false)Text('Vị trí cảm biến: '+m.locationName!),
            Text('Đo: '+fmtDateTimeVn(m.recordedAt)),
            Text('Nhận: '+fmtDateTimeVn(m.receivedAt)),
            Text('Ngưỡng: '+m.thresholdText),
            Text(m.assessment,style:bvText(fontWeight:FontWeight.w600,
              color:m.assessment=='Cảnh báo từ cấu hình' ? DashboardColors.risk :
                DashboardColors.textMuted)),
          ]),
        ),
    ]);
  }
}
