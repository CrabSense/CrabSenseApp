import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../data/models/profile_models.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_skeleton.dart';
import '../widgets/section_error_card.dart';

/// Profile Screen — Light theme rebuild.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kHomePrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsyncState = ref.watch(profileStateProvider);

    return Scaffold(
      backgroundColor: kHomeBg,
      body: profileAsyncState.when(
        loading: () => const ProfileSkeleton(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ProfileSectionErrorCard(
              sectionTitle: 'Trang cá nhân',
              errorMessage: error.toString(),
              onRetry: () =>
                  ref.read(profileStateProvider.notifier).loadData(forceRefresh: true),
            ),
          ),
        ),
        data: (data) => RefreshIndicator(
          color: kHomePrimary,
          onRefresh: () => ref.read(profileStateProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Gradient header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: kHomePrimary,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kHomePrimary, kHomePrimaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                  color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 44,
                              color: kHomePrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            data.profile.fullName,
                            style: const TextStyle(
                              color: kHomeTextMain,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              data.profile.role.displayName,
                              style: const TextStyle(
                                color: kHomeTextMain,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                title: const Text(
                  'Tài khoản',
                  style: TextStyle(
                    color: kHomeTextMain,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              // Body
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Section: Tài khoản
                    _MenuSection(
                      title: 'Tài khoản',
                      children: [
                        _MenuItem(
                          icon: Icons.person_outline_rounded,
                          title: 'Chỉnh sửa hồ sơ',
                          onTap: () => context.push(RoutePaths.editProfile),
                        ),
                        _MenuItem(
                          icon: Icons.lock_outline_rounded,
                          title: 'Đổi mật khẩu',
                          onTap: () => _showToast('Mở đổi mật khẩu'),
                        ),
                        _MenuItem(
                          icon: Icons.notifications_outlined,
                          title: 'Cài đặt thông báo',
                          onTap: () =>
                              context.push(RoutePaths.notificationSettings),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Section: Trang trại & Thiết bị
                    _MenuSection(
                      title: 'Trang trại & Thiết bị',
                      children: [
                        _MenuItem(
                          icon: Icons.sensors_rounded,
                          title: 'Thiết bị IoT',
                          subtitle: '${data.devices.totalOnline} online · ${data.devices.totalOffline} offline',
                          onTap: () => context.push(RoutePaths.devices),
                        ),
                        _MenuItem(
                          icon: Icons.sync_rounded,
                          title: 'Đồng bộ ngoại tuyến',
                          trailing: data.syncSummary.pendingUploadCount > 0
                              ? _Badge(
                                  label: '${data.syncSummary.pendingUploadCount} chờ',
                                  color: kHomeWarning,
                                )
                              : null,
                          onTap: () {
                            ref
                                .read(profileStateProvider.notifier)
                                .triggerSync();
                            _showToast('Đang đồng bộ...');
                          },
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Section: Phân tích & Báo cáo
                    _MenuSection(
                      title: 'Phân tích & Báo cáo',
                      children: [
                        _MenuItem(
                          icon: Icons.psychology_rounded,
                          title: 'Trung tâm AI',
                          onTap: () => context.push(RoutePaths.aiCenter),
                        ),
                        _MenuItem(
                          icon: Icons.bar_chart_rounded,
                          title: 'Báo cáo & Thống kê',
                          onTap: () => context.push(RoutePaths.reports),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Section: Hệ thống
                    _MenuSection(
                      title: 'Hệ thống',
                      children: [
                        _MenuItem(
                          icon: Icons.settings_outlined,
                          title: 'Cài đặt ứng dụng',
                          onTap: () => _showToast('Cài đặt ứng dụng'),
                        ),
                        _MenuItem(
                          icon: Icons.security_outlined,
                          title: 'Bảo mật & Quyền riêng tư',
                          onTap: () => _showToast('Bảo mật & Quyền riêng tư'),
                        ),
                        _MenuItem(
                          icon: Icons.help_outline_rounded,
                          title: 'Trợ giúp & Hỗ trợ',
                          onTap: () => _showToast('Trợ giúp'),
                        ),
                        _MenuItem(
                          icon: Icons.info_outline_rounded,
                          title: 'Thông tin ứng dụng',
                          onTap: () => _showToast('CrabSense v1.0.0'),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Logout button
                    _LogoutButton(
                      onPressed: () {
                        // Logout handled by auth bloc
                        _showToast('Đăng xuất...');
                      },
                    ),
                    const SizedBox(height: 16),

                    // Version
                    const Center(
                      child: Text(
                        'CrabSense v1.0.0 • Phiên bản thử nghiệm',
                        style: TextStyle(
                          fontSize: 12,
                          color: kHomeTextHint,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Menu Section ─────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kHomeTextSub,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: homeCardDecoration(),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kHomePrimaryBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: kHomePrimary, size: 18),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kHomeTextMain,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 12, color: kHomeTextSub),
                )
              : null,
          trailing: trailing ??
              const Icon(Icons.chevron_right_rounded,
                  color: kHomeTextHint, size: 20),
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: kHomeBorder),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout_rounded, color: kHomeDanger),
        label: const Text(
          'Đăng xuất',
          style: TextStyle(
            color: kHomeDanger,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: kHomeDangerBg,
          side: const BorderSide(color: kHomeDanger, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: Size.zero,
        ),
      ),
    );
  }
}
