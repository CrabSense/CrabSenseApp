import 'package:flutter/material.dart';
import '../models/water_quality_data.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class DataCard extends StatelessWidget {
  final WaterQualityData data;

  const DataCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.location ?? 'Vị trí không xác định',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  Helpers.formatDateTime(data.timestamp),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Data grid
            _buildDataGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDataGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDataItem(
                context,
                'Nhiệt độ',
                '${Helpers.formatDecimal(data.temperature)}°C',
                Icons.thermostat,
                _getStatusColor(
                  data.temperature,
                  AppConstants.minTemperature,
                  AppConstants.maxTemperature,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDataItem(
                context,
                'pH',
                Helpers.formatDecimal(data.pH),
                Icons.science,
                _getStatusColor(
                  data.pH,
                  AppConstants.minPH,
                  AppConstants.maxPH,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDataItem(
                context,
                'Oxy hòa tan',
                '${Helpers.formatDecimal(data.dissolvedOxygen)} mg/L',
                Icons.air,
                _getStatusColor(
                  data.dissolvedOxygen,
                  AppConstants.minDissolvedOxygen,
                  AppConstants.maxDissolvedOxygen,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDataItem(
                context,
                'Độ mặn',
                '${Helpers.formatDecimal(data.salinity)} ppt',
                Icons.water_drop,
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
    );
  }

  Widget _buildDataItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color statusColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
          ),
        ],
      ),
    );
  }

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
