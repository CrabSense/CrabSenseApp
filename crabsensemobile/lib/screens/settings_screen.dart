import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/app_logo.dart';

/// Màn hình cài đặt
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _language = 'vi';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        children: [
          // App Info
          Container(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: const Column(
              children: [
                AppLogo(size: 80),
                SizedBox(height: 12),
                Text(
                  'CrabSense Mobile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Version ${AppConstants.appVersion}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // General Settings
          _buildSectionTitle('Chung'),
          SwitchListTile(
            title: const Text('Thông báo'),
            subtitle: const Text('Nhận thông báo khi có cảnh báo'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            secondary: const Icon(Icons.notifications),
          ),
          SwitchListTile(
            title: const Text('Chế độ tối'),
            subtitle: const Text('Sử dụng giao diện tối'),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          
          // Connection Settings
          const Divider(),
          _buildSectionTitle('Kết nối'),
          ListTile(
            leading: const Icon(Icons.router),
            title: const Text('Địa chỉ server'),
            subtitle: Text(AppConstants.apiBaseUrl),
            trailing: const Icon(Icons.edit),
            onTap: () {
              _showEditDialog(
                context,
                'Địa chỉ server',
                AppConstants.apiBaseUrl,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Tần suất cập nhật'),
            subtitle: const Text('30 giây'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          
          // About
          const Divider(),
          _buildSectionTitle('Về ứng dụng'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Giới thiệu'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Chính sách bảo mật'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Trợ giúp'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          
          const SizedBox(height: 24),
          
          // Copyright
          Center(
            child: Text(
              '© 2024 CrabSense Team',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppConstants.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String title, String currentValue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          decoration: InputDecoration(
            hintText: currentValue,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã lưu cài đặt')),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'CrabSense Mobile',
      applicationVersion: AppConstants.appVersion,
      applicationIcon: const AppLogo(size: 60),
      children: [
        const Text(
          'Hệ thống giám sát chất lượng nước thông minh cho ao nuôi tôm.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Phát triển bởi CrabSense Team',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
