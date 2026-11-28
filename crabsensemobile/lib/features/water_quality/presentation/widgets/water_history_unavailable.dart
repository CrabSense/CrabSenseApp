import 'package:flutter/material.dart';
import '../../../home/presentation/widgets/home_palette.dart';

/// Temporary fail-closed presentation: legacy per-sensor history DTO uses
/// zero for absent parameters. Until presence, unit and quality are preserved,
/// no historical line or fabricated reading may be shown as measured data.
class WaterHistoryUnavailable extends StatelessWidget {
  const WaterHistoryUnavailable({super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('water-history-unavailable'),
    padding: const EdgeInsets.all(16),
    decoration: homeCardDecoration(radius: 22),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Biểu đồ theo dõi', style: TextStyle(
          fontWeight: FontWeight.w800, color: kHomeTextMain)),
        SizedBox(height: 8),
        Text('Chưa đủ dữ liệu lịch sử đã xác minh để vẽ biểu đồ.',
          style: TextStyle(color: kHomeWarning)),
        SizedBox(height: 6),
        Text('Không sử dụng dữ liệu giả hoặc thay thông số chưa đo bằng 0. '
          'Kết quả phân tích hóa học xem tại Phân tích nước WaterBench.',
          style: TextStyle(color: kHomeTextSub)),
      ],
    ),
  );
}
