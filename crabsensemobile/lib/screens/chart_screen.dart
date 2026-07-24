import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Màn hình biểu đồ và phân tích
class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  String _selectedPeriod = '24h';

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Biểu đồ & Phân tích'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector
            _buildPeriodSelector(),
            
            const SizedBox(height: 24),
            
            // Temperature chart
            _buildChartCard(
              title: 'Nhiệt độ',
              icon: Icons.thermostat,
              color: AppConstants.successColor,
            ),
            
            const SizedBox(height: 16),
            
            // pH chart
            _buildChartCard(
              title: 'pH',
              icon: Icons.science,
              color: AppConstants.primaryColor,
            ),
            
            const SizedBox(height: 16),
            
            // Dissolved Oxygen chart
            _buildChartCard(
              title: 'Oxy hòa tan',
              icon: Icons.air,
              color: AppConstants.secondaryColor,
            ),
            
            const SizedBox(height: 16),
            
            // Salinity chart
            _buildChartCard(
              title: 'Độ mặn',
              icon: Icons.water_drop,
              color: AppConstants.warningColor,
            ),
          ],
        ),
      ),
    );

  Widget _buildPeriodSelector() => Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 12),
            const Text(
              'Khoảng thời gian:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '24h', label: Text('24h')),
                ButtonSegment(value: '7d', label: Text('7d')),
                ButtonSegment(value: '30d', label: Text('30d')),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedPeriod = newSelection.first;
                });
              },
            ),
          ],
        ),
      ),
    );

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Color color,
  }) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Placeholder for chart
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 48, color: color),
                    const SizedBox(height: 8),
                    Text(
                      'Biểu đồ $_selectedPeriod',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đang phát triển...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Stats summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Trung bình', '28.5', color),
                _buildStatItem('Min', '25.0', color),
                _buildStatItem('Max', '32.0', color),
              ],
            ),
          ],
        ),
      ),
    );

  Widget _buildStatItem(String label, String value, Color color) => Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
}
