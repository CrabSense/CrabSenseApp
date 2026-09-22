import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';

class ModernHomeScreen extends StatelessWidget {
  const ModernHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2D7A43);
    const ink = Color(0xFF173A28);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8EF),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  SizedBox(
                    height: 330,
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/crab_farm_hero.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    height: 330,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC173A28)],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 24,
                    top: 22,
                    child: Text(
                      'CrabSense',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 24,
                    bottom: 30,
                    child: Text(
                      'Chào buổi sáng, Duy 👋\nGreen Valley Crab Farm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'Tổng quan hôm nay',
                    style: TextStyle(
                      color: ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          title: 'Box đang nuôi',
                          value: '18 / 24',
                          detail: '6 box trống',
                          color: const Color(0xFFDCEFCF),
                          icon: Icons.grid_view_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          title: 'Thời tiết',
                          value: '28°C',
                          detail: 'Nắng · thuận lợi',
                          color: const Color(0xFFFFE39A),
                          icon: Icons.wb_sunny_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.water_drop_rounded,
                    title: 'Chất lượng nước',
                    value: 'Ổn định',
                    detail: 'Nhiệt độ 28.4°C  ·  pH 7.8  ·  DO 6.8',
                    color: const Color(0xFFD8F0F0),
                    onTap: () => context.push(RoutePaths.waterQuality),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    icon: Icons.task_alt_rounded,
                    title: 'Việc cần làm hôm nay',
                    value: '3 nhiệm vụ',
                    detail: 'Kiểm tra nước · chăm sóc · xem 2 cua lột',
                    color: const Color(0xFFE9DDF6),
                    onTap: () => context.push(RoutePaths.scheduledTasks),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Thao tác nhanh',
                    style: TextStyle(
                      color: ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _QuickAction(
                        icon: Icons.grid_view_rounded,
                        label: 'Farm box',
                        onTap: () => context.push(RoutePaths.boxes),
                      ),
                      _QuickAction(
                        icon: Icons.camera_alt_rounded,
                        label: 'AI lột',
                        onTap: () => context.push(RoutePaths.aiCenter),
                      ),
                      _QuickAction(
                        icon: Icons.shopping_basket_rounded,
                        label: 'Thu hoạch',
                        onTap: () => context.push(RoutePaths.harvest),
                      ),
                      _QuickAction(
                        icon: Icons.bar_chart_rounded,
                        label: 'Báo cáo',
                        onTap: () => context.push(RoutePaths.reports),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final String detail;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    height: 122,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF28623B), size: 22),
        const Spacer(),
        Text(title, style: const TextStyle(fontSize: 11)),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        Text(detail, style: const TextStyle(fontSize: 10)),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF28623B), size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(detail, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: const Color(0xFF2D7A43)),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    ),
  );
}
