import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes.dart';
import '../../../../core/providers/selected_farm_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../data/models/profile_models.dart';
import '../providers/profile_provider.dart';
import '../widgets/logout_button.dart';
import '../widgets/profile_hub_scaffold.dart';
import '../widgets/profile_skeleton.dart';
import '../widgets/section_error_card.dart';

/// Tab Tài khoản — cùng nền, card và thang chữ với Home.
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
      body: SafeArea(
        child: profileAsyncState.when(
          loading: () => const ProfileSkeleton(),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ProfileSectionErrorCard(
                sectionTitle: 'Trang cá nhân',
                errorMessage: error.toString(),
                onRetry: () => ref
                    .read(profileStateProvider.notifier)
                    .loadData(forceRefresh: true),
              ),
            ),
          ),
          data: (data) {
            final pin = ref.watch(selectedFarmProvider);
            final farmLabel = pin.name.isNotEmpty
                ? pin.name
                : data.profile.currentFarm;
            return RefreshIndicator(
              color: kHomePrimary,
              backgroundColor: kHomeSurface,
              onRefresh: () =>
                  ref.read(profileStateProvider.notifier).refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _ProfileHero(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ProfileHeaderCard(
                                profile: data.profile,
                                farmName: farmLabel,
                              ),
                              const SizedBox(height: 12),
                              _KpiStrip(data: data),
                              const SizedBox(height: 18),
                              const HubSectionLabel(
                                label: 'Thông tin tài khoản',
                              ),
                              HubCard(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  6,
                                  14,
                                  6,
                                ),
                                child: Column(
                                  children: [
                                    _InfoRow(
                                      label: 'Email',
                                      value: data.profile.email,
                                    ),
                                    _InfoRow(
                                      label: 'Điện thoại',
                                      value: data.profile.phone,
                                    ),
                                    _InfoRow(
                                      label: 'Mã nhân viên',
                                      value: data.profile.employeeId,
                                    ),
                                    _InfoRow(
                                      label: 'Ngày tham gia',
                                      value: DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(data.profile.joinedDate),
                                      isLast: true,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              _Section(
                                icon: Icons.person_outline_rounded,
                                title: 'Tài khoản',
                                children: [
                                  HubTile(
                                    icon: Icons.person_outline_rounded,
                                    title: 'Chỉnh sửa hồ sơ',
                                    subtitle:
                                        'Cập nhật họ tên, email, điện thoại',
                                    onTap: () =>
                                        context.push(RoutePaths.editProfile),
                                  ),
                                  HubTile(
                                    icon: Icons.lock_outline_rounded,
                                    title: 'Đổi mật khẩu',
                                    onTap: () =>
                                        context.push(RoutePaths.changePassword),
                                  ),
                                  HubTile(
                                    icon: Icons.notifications_outlined,
                                    title: 'Cài đặt thông báo',
                                    onTap: () => context.push(
                                      RoutePaths.notificationSettings,
                                    ),
                                    showDivider: false,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _Section(
                                icon: Icons.sensors_rounded,
                                title: 'Trang trại & thiết bị',
                                children: [
                                  HubTile(
                                    icon: Icons.sensors_rounded,
                                    title: 'Thiết bị IoT',
                                    subtitle:
                                        '${data.devices.totalOnline} online · '
                                        '${data.devices.totalOffline} offline',
                                    onTap: () =>
                                        context.push(RoutePaths.devices),
                                  ),
                                  HubTile(
                                    icon: Icons.sync_rounded,
                                    title: 'Đồng bộ ngoại tuyến',
                                    subtitle: data.syncSummary.syncStatus,
                                    trailing:
                                        data.syncSummary.pendingUploadCount > 0
                                        ? _Badge(
                                            label:
                                                '${data.syncSummary.pendingUploadCount} chờ',
                                            color: kHomeWarning,
                                          )
                                        : null,
                                    onTap: () {
                                      ref
                                          .read(profileStateProvider.notifier)
                                          .triggerSync();
                                      _showToast('Đang đồng bộ...');
                                    },
                                    showDivider: false,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _Section(
                                icon: Icons.bar_chart_rounded,
                                title: 'Phân tích & báo cáo',
                                children: [
                                  HubTile(
                                    icon: Icons.psychology_rounded,
                                    title: 'Trung tâm AI',
                                    onTap: () =>
                                        context.push(RoutePaths.aiCenter),
                                  ),
                                  HubTile(
                                    icon: Icons.bar_chart_rounded,
                                    title: 'Báo cáo & thống kê',
                                    onTap: () =>
                                        context.push(RoutePaths.reports),
                                    showDivider: false,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _Section(
                                icon: Icons.tune_rounded,
                                title: 'Hệ thống',
                                children: [
                                  HubTile(
                                    icon: Icons.settings_outlined,
                                    title: 'Cài đặt ứng dụng',
                                    onTap: () =>
                                        context.push(RoutePaths.appSettings),
                                  ),
                                  HubTile(
                                    icon: Icons.security_outlined,
                                    title: 'Bảo mật & quyền riêng tư',
                                    onTap: () => context.push(
                                      RoutePaths.securityPrivacy,
                                    ),
                                  ),
                                  HubTile(
                                    icon: Icons.help_outline_rounded,
                                    title: 'Trợ giúp & hỗ trợ',
                                    onTap: () =>
                                        context.push(RoutePaths.helpSupport),
                                  ),
                                  HubTile(
                                    icon: Icons.info_outline_rounded,
                                    title: 'Thông tin ứng dụng',
                                    onTap: () =>
                                        context.push(RoutePaths.appInfo),
                                    showDivider: false,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              const LogoutButton(),
                              const SizedBox(height: 14),
                              const Center(
                                child: Text(
                                  'CrabSense v1.0.0 • Đồ án tốt nghiệp',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: kHomeTextHint,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Hero ───────────────────────────────────────────────────────────────────

/// Banner đầu tab — dùng đúng ảnh nền của Home (`background_chao_user.png`)
/// để ba tab Trang chủ / Hộp nuôi / Tài khoản cùng một ngôn ngữ hình ảnh.
class _ProfileHero extends StatelessWidget {
  const _ProfileHero();

  static const Color _navy = Color(0xFF123968);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(26),
              ),
              child: Image.asset(
                'assets/images/desktop/background_chao_user.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: kHomePrimaryBg),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xF5FFFFFF),
                    Color(0x59FFFFFF),
                    Color(0x00FFFFFF),
                  ],
                  stops: [0, .42, .72],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tài khoản',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Hồ sơ & cài đặt cá nhân',
                  style: TextStyle(
                    color: kHomeTextSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

/// Card hồ sơ: danh tính + khu đang điều hành (lấy từ `selectedFarmProvider`).
class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.profile, required this.farmName});

  final ProfileSummary profile;
  final String farmName;

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'CS';
    if (parts.length == 1) {
      final s = parts.first;
      return (s.length >= 2 ? s.substring(0, 2) : s).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = profile.isOnline;
    final statusColor = isActive ? CrabSenseColors.statusNormal : kHomeWarning;
    final statusBg = isActive ? CrabSenseColors.statusNormalBg : kHomeWarningBg;

    return Container(
      decoration: homeCardDecoration(radius: 18),
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kHomePrimary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: kHomePrimary.withValues(alpha: 0.22),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: kHomePrimaryBg,
              child: Text(
                _initials(profile.fullName),
                style: const TextStyle(
                  color: kHomePrimaryDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: kHomeTextMain,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(
                      label: isActive ? 'Online' : 'Offline',
                      color: statusColor,
                      background: statusBg,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Tag(
                      icon: Icons.verified_user_outlined,
                      label: profile.role.displayName,
                      color: kHomePrimaryDark,
                      background: kHomePrimaryBg,
                      border: kHomePrimary,
                    ),
                    if (farmName.isNotEmpty)
                      _Tag(
                        icon: Icons.location_on_outlined,
                        label: farmName,
                        color: kHomeSecondary,
                        background: kHomeSecondaryBg,
                        border: kHomeSecondary,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push(RoutePaths.editProfile),
            tooltip: 'Chỉnh sửa hồ sơ',
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: kHomePrimaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.border,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── KPI ─────────────────────────────────────────────────────────────────────

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.data});

  final ProfileStateData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: homeCardDecoration(radius: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      child: Row(
        children: [
          _Kpi(value: '${data.farmManagement.totalAreas}', label: 'Khu vực'),
          const _KpiDivider(),
          _Kpi(value: '${data.farmManagement.totalBoxes}', label: 'Hộp nuôi'),
          const _KpiDivider(),
          _Kpi(
            value: '${data.devices.totalOnline}',
            label: 'Thiết bị online',
            accent: CrabSenseColors.statusNormal,
          ),
          const _KpiDivider(),
          _Kpi(
            value: '${data.reports.totalReportsAvailable}',
            label: 'Báo cáo',
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.value, required this.label, this.accent});

  final String value;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent ?? kHomeTextMain,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kHomeTextHint,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiDivider extends StatelessWidget {
  const _KpiDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: kHomeBorder.withValues(alpha: 0.7),
    );
  }
}

// ─── Info rows ───────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final text = value.trim().isEmpty ? '—' : value.trim();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              SizedBox(
                width: 104,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: kHomeTextSub,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kHomeTextMain,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: kHomeBorder),
      ],
    );
  }
}

// ─── Section ─────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: HomeSectionHeader(icon: icon, title: title),
        ),
        HubCard(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Column(children: children),
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
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
