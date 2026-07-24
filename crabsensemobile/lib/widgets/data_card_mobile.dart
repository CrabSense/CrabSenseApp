import 'package:flutter/material.dart';
import '../models/water_quality_data.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Card hiển thị dữ liệu chất lượng nước - Tối ưu cho mobile
class DataCardMobile extends StatelessWidget {

  const DataCardMobile({required this.data, super.key});
  final WaterQualityData data;

  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: AppConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Location and time
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppConstants.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          data.location ?? 'Vị trí không xác định',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  Helpers.formatRelativeTime(data.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Data grid - 2 columns
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDataItem(
                        context,
                        Icons.thermostat,
                        'Nhiệt độ',
                        '${Helpers.formatDecimal(data.temperature)}°C',
                        _getStatusColor(
                          data.temperature,
                          AppConstants.minTemperature,
                          AppConstants.maxTemperature,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDataItem(
                        context,
                        Icons.science,
                        'pH',
                        Helpers.formatDecimal(data.pH),
                        _getStatusColor(
                          data.pH,
                          AppConstants.minPH,
                          AppConstants.maxPH,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDataItem(
                        context,
                        Icons.air,
                        'Oxy',
                        '${Helpers.formatDecimal(data.dissolvedOxygen)} mg/L',
                        _getStatusColor(
                          data.dissolvedOxygen,
                          AppConstants.minDissolvedOxygen,
                          AppConstants.maxDissolvedOxygen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDataItem(
                        context,
                        Icons.water_drop,
                        'Độ mặn',
                        '${Helpers.formatDecimal(data.salinity)} ppt',
                        _getStatusColor(
                          data.salinity,
                          AppConstants.minSalinity,
                          AppConstants.maxSalinity,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Footer - Timestamp
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  Helpers.formatDateTime(data.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  Widget _buildDataItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color statusColor,
  ) => Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: statusColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );

  Color _getStatusColor(double value, double min, double max) {
    if (value < min || value > max) {
      return AppConstants.errorColor;
    }
    if (value < min * 1.1 || value > max * 0.9) {
      return AppConstants.warningColor;
    }
    return AppConstants.successColor;
  }
}
