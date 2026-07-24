import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import 'monitoring_screen.dart';
import 'chart_screen.dart';

/// Màn hình điều hướng chính với Bottom Navigation Bar 5 mục (Material 3 Dark)
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MonitoringScreen(), // Boxes / Monitoring
    const SizedBox.shrink(), // Scan QR Placeholder
    const ChartScreen(), // Alerts / Analytics
    const ProfileScreen(), // Profile / Management Center
  ];

  void _onQrScanPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Mở Camera quét mã QR Box...'),
        backgroundColor: CrabSenseColors.container,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: CrabSenseColors.surface,
          border: Border(top: BorderSide(color: CrabSenseColors.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: CrabSenseColors.surface,
          indicatorColor: CrabSenseColors.primary.withValues(alpha: 0.15),
          onDestinationSelected: (index) {
            if (index == 2) {
              _onQrScanPressed();
              return;
            }
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: CrabSenseColors.primary),
              label: 'Trang chủ',
            ),
            const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded, color: CrabSenseColors.primary),
              label: 'Box nuôi',
            ),
            // Central Highlighted Scan QR Button
            NavigationDestination(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: CrabSenseColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: CrabSenseColors.primary,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.black,
                  size: 24,
                ),
              ),
              label: 'Quét QR',
            ),
            const NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications_rounded, color: CrabSenseColors.primary),
              label: 'Cảnh báo',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: CrabSenseColors.primary),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}
