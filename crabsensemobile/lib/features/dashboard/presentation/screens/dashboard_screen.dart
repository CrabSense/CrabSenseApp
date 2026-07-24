import 'package:flutter/material.dart';
import '../../../home/presentation/screens/home_screen.dart';

/// Legacy DashboardScreen entry point redirecting to Farm Command Center HomeScreen
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
