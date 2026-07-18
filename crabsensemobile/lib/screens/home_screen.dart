import 'package:flutter/material.dart';
import '../widgets/app_logo.dart';
import '../utils/constants.dart';

/// Màn hình trang chủ - Dashboard tổng quan
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar với gradient
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('CrabSense'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppConstants.primaryColor,
                      AppConstants.secondaryColor,
                    ],
                  ),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: AppLogo(size: 50),
                  ),
                ),
              ),
            ),
          ),
          
          // Nội dung
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message
                  Text(
                    'Chào mừng! 👋',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hệ thống giám sát chất lượng nước',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Thông số nhanh - 2x2 grid
                  _buildQuickStats(),
                  
                  const SizedBox(height: 24),
                  
                  // Trạng thái hệ thống
                  Text(
                    'Trạng thái hệ thống',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSystemStatus(),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  Text(
                    'Chức năng',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.thermostat,
          title: 'Nhiệt độ',
          value: '28.5°C',
          color: AppConstants.successColor,
        ),
        _buildStatCard(
          icon: Icons.science,
          title: 'pH',
          value: '7.8',
          color: AppConstants.primaryColor,
        ),
        _buildStatCard(
          icon: Icons.air,
          title: 'Oxy',
          value: '6.2 mg/L',
          color: AppConstants.secondaryColor,
        ),
        _buildStatCard(
          icon: Icons.water_drop,
          title: 'Độ mặn',
          value: '15 ppt',
          color: AppConstants.warningColor,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
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
        ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusRow(
              icon: Icons.sensors,
              title: 'Cảm biến',
              status: 'Hoạt động tốt',
              isOnline: true,
            ),
            const Divider(height: 24),
            _buildStatusRow(
              icon: Icons.wifi,
              title: 'Kết nối',
              status: 'Đang kết nối',
              isOnline: true,
            ),
            const Divider(height: 24),
            _buildStatusRow(
              icon: Icons.update,
              title: 'Cập nhật lần cuối',
              status: '5 phút trước',
              isOnline: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String title,
    required String status,
    required bool isOnline,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isOnline 
                ? AppConstants.successColor.withOpacity(0.1)
                : AppConstants.errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isOnline ? AppConstants.successColor : AppConstants.errorColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.check_circle,
          color: isOnline ? AppConstants.successColor : AppConstants.errorColor,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        _buildActionButton(
          context,
          icon: Icons.refresh,
          title: 'Tải lại dữ liệu',
          subtitle: 'Cập nhật thông tin mới nhất',
          onTap: () {
            // TODO: Implement refresh
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đang tải lại dữ liệu...')),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          icon: Icons.notifications,
          title: 'Cảnh báo',
          subtitle: 'Xem các thông báo và cảnh báo',
          onTap: () {
            // TODO: Navigate to notifications
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
