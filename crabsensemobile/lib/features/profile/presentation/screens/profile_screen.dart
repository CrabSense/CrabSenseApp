import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes.dart';
import '../../../home/presentation/widgets/crab_hologram_painter.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../data/models/profile_models.dart';
import '../providers/profile_provider.dart';
import '../widgets/logout_button.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_section.dart';
import '../widgets/profile_menu_tile.dart';
import '../widgets/profile_skeleton.dart';
import '../widgets/section_error_card.dart';
import 'legal_document_screen.dart';

/// CrabSense Master Profile Management Screen
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kHomeNavyLift,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showRowDetailDialog(String title, String value, String description) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const HomeCrabWatermark(alpha: 0.05, trayExtent: 28),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_rounded, color: kHomeCyan),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: homeTileDecoration(radius: 12),
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: kHomeCyan,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: kHomeCyan,
                        foregroundColor: kHomeNavyDeep,
                      ),
                      child: const Text(
                        'Đóng',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFarmSwitcherDialog(ProfileStateData data) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.5)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              const HomeCrabWatermark(alpha: 0.06, trayExtent: 28),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: kHomeCyan.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const Text(
                        'CHUYỂN TRANG TRẠI',
                        style: TextStyle(
                          color: kHomeBlueLight,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...data.farmManagement.availableFarms.map((farm) {
                        final isSelected = farm.name
                            .contains(data.farmManagement.currentFarmName);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? kHomeBlue.withValues(alpha: 0.2)
                                : kHomeNavyDeep.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? kHomeCyan
                                  : kHomeBorderBlue.withValues(alpha: 0.4),
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              farm.name,
                              style: TextStyle(
                                color: isSelected ? kHomeCyan : Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '${farm.areaCount} • ${farm.boxCount}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: kHomeCyan,
                                  )
                                : null,
                            onTap: () {
                              Navigator.pop(ctx);
                              ref
                                  .read(profileStateProvider.notifier)
                                  .switchFarm(farm.name.split(' - ').first);
                              _showToast('Đã chuyển sang ${farm.name}');
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsyncState = ref.watch(profileStateProvider);

    return Scaffold(
      backgroundColor: kHomeNavyDeep,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CrabHologramPainter(
                  color: kHomeBlueLight.withValues(alpha: 0.05),
                  trayExtent: 32,
                ),
              ),
            ),
          ),
          SafeArea(
            child: profileAsyncState.when(
              loading: () => const ProfileSkeleton(),
              error: (error, stackTrace) => Center(
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
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(profileStateProvider.notifier).refresh(),
                  color: kHomeCyan,
                  backgroundColor: kHomeNavyLift,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data.isOfflineCached || !data.isOnline) ...[
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: kHomeOrange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: kHomeOrange.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.wifi_off_rounded,
                                      color: kHomeOrange,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Ngoại tuyến • Cache ${_dateFormatter.format(data.lastSyncedAt)}',
                                        style: const TextStyle(
                                          color: kHomeOrange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => ref
                                          .read(profileStateProvider.notifier)
                                          .triggerSync(),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        child: Text(
                                          'Thử lại',
                                          style: TextStyle(
                                            color: kHomeCyan,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            ProfileHeader(
                              profile: data.profile,
                              onEditProfile: () =>
                                  context.push(RoutePaths.editProfile),
                              onChangeAvatar: () =>
                                  context.push(RoutePaths.editProfile),
                              onSync: () {
                                ref
                                    .read(profileStateProvider.notifier)
                                    .triggerSync();
                                _showToast('Đang đồng bộ...');
                              },
                            ),
                            const SizedBox(height: 12),

                        // SECTION 2: ACCOUNT INFORMATION
                        ProfileMenuSection(
                          title: 'THÔNG TIN TÀI KHOẢN',
                          icon: Icons.badge_rounded,
                          subtitle: 'Nhấn vào hàng để xem chi tiết',
                          children: [
                            ProfileMenuTile(
                              icon: Icons.person_outline_rounded,
                              title: 'Họ và tên',
                              valueText: data.profile.fullName,
                              onTap: () => _showRowDetailDialog('Họ và tên', data.profile.fullName, 'Họ tên đầy đủ của cán bộ vận hành đăng ký trên hệ thống CrabSense.'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.email_outlined,
                              title: 'Địa chỉ Email',
                              valueText: data.profile.email,
                              onTap: () => _showRowDetailDialog('Email', data.profile.email, 'Email chính thức nhận báo cáo và thông báo cảnh báo hệ thống.'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.phone_android_rounded,
                              title: 'Số điện thoại',
                              valueText: data.profile.phone,
                              onTap: () => _showRowDetailDialog('Số điện thoại', data.profile.phone, 'Số điện thoại nhận tin nhắn SMS cảnh báo khẩn cấp.'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.assignment_ind_outlined,
                              title: 'Mã nhân viên (Employee ID)',
                              valueText: data.profile.employeeId,
                              onTap: () => _showRowDetailDialog('Mã nhân viên', data.profile.employeeId, 'Mã định danh nội bộ trong trang trại.'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.workspace_premium_outlined,
                              title: 'Vai trò hệ thống',
                              valueText: data.profile.role.displayName,
                              onTap: () => _showRowDetailDialog('Vai trò', data.profile.role.displayName, 'Quyền hạn truy cập và điều khiển các tính năng trên CrabSense.'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.storefront_rounded,
                              title: 'Trang trại trực thuộc',
                              valueText: data.profile.currentFarm,
                              onTap: () => _showFarmSwitcherDialog(data),
                            ),
                            ProfileMenuTile(
                              icon: Icons.calendar_today_rounded,
                              title: 'Ngày gia nhập',
                              valueText: DateFormat('dd/MM/yyyy').format(data.profile.joinedDate),
                              onTap: () => _showRowDetailDialog('Ngày gia nhập', DateFormat('dd/MM/yyyy').format(data.profile.joinedDate), 'Thời gian khởi tạo tài khoản trên hệ thống.'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.check_circle_outline_rounded,
                              title: 'Trạng thái tài khoản',
                              valueText: data.profile.status,
                              showDivider: false,
                              onTap: () => _showRowDetailDialog('Trạng thái', data.profile.status, 'Tài khoản hoạt động bình thường với đầy đủ quyền vận hành.'),
                            ),
                          ],
                        ),

                        // SECTION 3: FARM MANAGEMENT (Filtered by user role)
                        ProfileMenuSection(
                          title: 'QUẢN LÝ TRANG TRẠI',
                          icon: Icons.agriculture_rounded,
                          subtitle: 'Phân quyền cho vai trò ${data.profile.role.displayName}',
                          children: [
                            ProfileMenuTile(
                              icon: Icons.list_alt_rounded,
                              title: 'Danh sách trang trại',
                              valueText: '${data.farmManagement.availableFarms.length} Trang trại',
                              onTap: () => _showFarmSwitcherDialog(data),
                            ),
                            if (data.profile.role == UserRole.manager || data.profile.role == UserRole.admin) ...[
                              ProfileMenuTile(
                                icon: Icons.map_outlined,
                                title: 'Quản lý khu vực nuôi (Area)',
                                valueText: '${data.farmManagement.totalAreas} Khu',
                                onTap: () => _showToast('Mở Quản lý khu vực nuôi'),
                              ),
                            ],
                            ProfileMenuTile(
                              icon: Icons.grid_view_rounded,
                              title: 'Quản lý Box nuôi',
                              valueText: '${data.farmManagement.totalBoxes} Box',
                              onTap: () => context.go(RoutePaths.boxes),
                            ),
                            if (data.profile.role == UserRole.manager || data.profile.role == UserRole.admin) ...[
                              ProfileMenuTile(
                                icon: Icons.set_meal_outlined,
                                title: 'Quản lý lứa nuôi (Batch)',
                                valueText: '${data.farmManagement.activeBatches} Lứa đang nuôi',
                                onTap: () => _showToast('Mở Quản lý lứa cua nuôi'),
                              ),
                            ],
                            ProfileMenuTile(
                              icon: Icons.swap_horiz_rounded,
                              title: 'Chuyển đổi trang trại đang chọn',
                              valueText: data.farmManagement.currentFarmName,
                              showDivider: false,
                              onTap: () => _showFarmSwitcherDialog(data),
                            ),
                          ],
                        ),

                        // SECTION 4: DEVICE & IOT
                        ProfileMenuSection(
                          title: 'THIẾT BỊ & IOT',
                          icon: Icons.memory_rounded,
                          trailingBadge: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: kHomeGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: kHomeGreen.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              '${data.devices.totalOnline} Online · ${data.devices.totalOffline} Offline',
                              style: const TextStyle(
                                color: kHomeGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          children: [
                            ProfileMenuTile(
                              icon: Icons.list_alt_rounded,
                              title: 'Xem tất cả thiết bị',
                              valueText:
                                  'Tổng ${data.devices.totalOnline + data.devices.totalOffline} thiết bị',
                              onTap: () => context.push(RoutePaths.devices),
                            ),
                            ...data.devices.devices.map((device) {
                              final isLast =
                                  device.id == data.devices.devices.last.id;
                              return ProfileMenuTile(
                                icon: device.icon,
                                title: device.name,
                                subtitle:
                                    'Online: ${device.onlineCount}  ·  Offline: ${device.offlineCount}',
                                valueText: device.statusBadge,
                                showDivider: !isLast,
                                onTap: () => context.push(
                                  '${RoutePaths.devices}?type=${device.id}',
                                ),
                              );
                            }),
                          ],
                        ),

                        // SECTION 5: AI CENTER
                        ProfileMenuSection(
                          title: 'TRUNG TÂM AI CRABSENSE',
                          icon: Icons.psychology_rounded,
                          trailingBadge: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: kHomeCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              data.aiSummary.modelVersion,
                              style: const TextStyle(
                                color: kHomeCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          children: [
                            ProfileMenuTile(
                              icon: Icons.dashboard_customize_rounded,
                              title: 'Mở Trung tâm AI',
                              valueText: data.aiSummary.modelVersion,
                              onTap: () => context.push(RoutePaths.aiCenter),
                            ),
                            ProfileMenuTile(
                              icon: Icons.history_rounded,
                              title: 'Lịch sử phát hiện AI',
                              valueText:
                                  '${data.aiSummary.detectionHistoryCount} lượt',
                              onTap: () => context.push(
                                '${RoutePaths.aiCenter}?tab=detections',
                              ),
                            ),
                            ProfileMenuTile(
                              icon: Icons.auto_awesome_rounded,
                              title: 'Lịch sử khuyến nghị AI',
                              valueText:
                                  '${data.aiSummary.recommendationHistoryCount} đề xuất',
                              onTap: () => context.push(
                                '${RoutePaths.aiCenter}?tab=recommendations',
                              ),
                            ),
                            ProfileMenuTile(
                              icon: Icons.verified_rounded,
                              title: 'Phiên bản & trạng thái mô hình',
                              subtitle: data.aiSummary.modelStatus,
                              valueText:
                                  '${data.aiSummary.avgConfidencePercentage}% tin cậy',
                              onTap: () => context.push(RoutePaths.aiCenter),
                            ),
                            ProfileMenuTile(
                              icon: Icons.feedback_outlined,
                              title: 'Gửi phản hồi AI',
                              valueText:
                                  '${data.aiSummary.feedbackCount} phản hồi',
                              onTap: () => context.push(
                                '${RoutePaths.aiCenter}?tab=detections',
                              ),
                            ),
                            ProfileMenuTile(
                              icon: Icons.model_training_rounded,
                              title: 'Thông tin huấn luyện',
                              subtitle: data.aiSummary.trainingInfo,
                              showDivider: false,
                              onTap: () => context.push(RoutePaths.aiCenter),
                            ),
                          ],
                        ),

                        // SECTION 6: REPORTS
                        ProfileMenuSection(
                          title: 'BÁO CÁO & PHÂN TÍCH',
                          icon: Icons.bar_chart_rounded,
                          children: [
                            ProfileMenuTile(
                              icon: Icons.inventory_2_outlined,
                              title: 'Báo cáo Thu hoạch (Harvest Report)',
                              onTap: () => context.push(
                                '${RoutePaths.reports}?type=harvest',
                              ),
                            ),
                            ProfileMenuTile(
                              icon: Icons.point_of_sale_rounded,
                              title: 'Báo cáo Bán hàng & Doanh thu',
                              onTap: () => context.push(
                                '${RoutePaths.reports}?type=inventory',
                              ),
                            ),
                            ProfileMenuTile(
                              icon: Icons.trending_up_rounded,
                              title: 'Báo cáo Tăng trưởng (Growth Report)',
                              onTap: () => context.push(
                                '${RoutePaths.reports}?type=molting',
                              ),
                            ),
                            ProfileMenuTile(
                              icon: Icons.warning_amber_rounded,
                              title: 'Báo cáo Tỷ lệ hao hụt (Mortality Report)',
                              onTap: () => context.push(
                                '${RoutePaths.reports}?type=survival',
                              ),
                            ),
                            ProfileMenuTile(
                              icon: Icons.water_rounded,
                              title: 'Báo cáo Chất lượng nước (Water Report)',
                              onTap: () =>
                                  context.push(RoutePaths.waterQuality),
                            ),
                            ProfileMenuTile(
                              icon: Icons.smart_toy_outlined,
                              title: 'Báo cáo AI & Dự báo',
                              onTap: () => context.push(RoutePaths.aiCenter),
                            ),
                            ProfileMenuTile(
                              icon: Icons.developer_board_rounded,
                              title: 'Báo cáo Tình trạng thiết bị (Device Report)',
                              showDivider: false,
                              onTap: () => context.push(RoutePaths.devices),
                            ),
                          ],
                        ),

                        // SECTION 7: OFFLINE & SYNCHRONIZATION
                        ProfileMenuSection(
                          title: 'NGOẠI TUYẾN & ĐỒNG BỘ',
                          icon: Icons.sync_rounded,
                          trailingBadge: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: kHomeGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              data.syncSummary.syncStatus,
                              style: const TextStyle(
                                color: kHomeGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          children: [
                            ProfileMenuTile(
                              icon: Icons.cloud_done_outlined,
                              title: 'Trạng thái đồng bộ',
                              valueText: data.syncSummary.syncStatus,
                              onTap: () =>
                                  context.push(RoutePaths.offlineSync),
                            ),
                            ProfileMenuTile(
                              icon: Icons.queue_play_next_rounded,
                              title: 'Hàng chờ ngoại tuyến (Offline Queue)',
                              valueText: '${data.syncSummary.offlineQueueCount} Mục',
                              onTap: () =>
                                  context.push(RoutePaths.offlineSync),
                            ),
                            ProfileMenuTile(
                              icon: Icons.cloud_upload_outlined,
                              title: 'Dữ liệu chờ tải lên (Pending Upload)',
                              valueText: '${data.syncSummary.pendingUploadCount} Mục',
                              onTap: () =>
                                  context.push(RoutePaths.offlineSync),
                            ),
                            ProfileMenuTile(
                              icon: Icons.access_time_rounded,
                              title: 'Thời gian đồng bộ gần nhất',
                              valueText: DateFormat('HH:mm dd/MM').format(data.syncSummary.lastSyncedAt),
                              onTap: () =>
                                  context.push(RoutePaths.offlineSync),
                            ),
                            ProfileMenuTile(
                              icon: Icons.sync_problem_rounded,
                              title: 'Xử lý xung đột (Conflict Resolution)',
                              valueText: '${data.syncSummary.conflictCount} Xung đột',
                              onTap: () =>
                                  context.push(RoutePaths.offlineSync),
                            ),
                            ProfileMenuTile(
                              icon: Icons.refresh_rounded,
                              title: 'Thực hiện đồng bộ ngay (Retry Sync)',
                              iconColor: kHomeCyan,
                              titleColor: kHomeCyan,
                              showDivider: false,
                              onTap: () =>
                                  context.push(RoutePaths.offlineSync),
                            ),
                          ],
                        ),

                        // SECTION 8: SETTINGS
                        ProfileMenuSection(
                          title: 'CÀI ĐẶT ỨNG DỤNG',
                          icon: Icons.settings_rounded,
                          children: [
                            ProfileMenuTile(
                              icon: Icons.dark_mode_outlined,
                              title: 'Giao diện ứng dụng (Theme)',
                              valueText: data.settings.isDarkMode ? 'Tối (Dark Mode)' : 'Sáng',
                              onTap: () =>
                                  context.push(RoutePaths.appSettings),
                            ),
                            ProfileMenuTile(
                              icon: Icons.language_rounded,
                              title: 'Ngôn ngữ (Language)',
                              valueText: data.settings.language,
                              onTap: () =>
                                  context.push(RoutePaths.appSettings),
                            ),
                            ProfileMenuTile(
                              icon: Icons.notifications_none_rounded,
                              title: 'Cài đặt thông báo',
                              subtitle: 'Cảnh báo, nhắc việc, âm thanh',
                              onTap: () =>
                                  context.push(RoutePaths.notificationSettings),
                            ),
                            ProfileMenuTile(
                              icon: Icons.straighten_rounded,
                              title: 'Đơn vị đo lường (Measurement Unit)',
                              valueText: data.settings.measurementUnit,
                              onTap: () =>
                                  context.push(RoutePaths.appSettings),
                            ),
                            ProfileMenuTile(
                              icon: Icons.camera_alt_outlined,
                              title: 'Cấu hình Camera AI',
                              valueText: data.settings.cameraResolution,
                              onTap: () =>
                                  context.push(RoutePaths.appSettings),
                            ),
                            ProfileMenuTile(
                              icon: Icons.storage_rounded,
                              title: 'Dung lượng bộ nhớ đệm (Cache)',
                              valueText: data.settings.cacheSize,
                              onTap: () =>
                                  context.push(RoutePaths.appSettings),
                            ),
                            ProfileMenuTile(
                              icon: Icons.autorenew_rounded,
                              title: 'Tự động đồng bộ (Auto Sync)',
                              trailing: Switch(
                                value: data.settings.autoSync,
                                activeColor: kHomeCyan,
                                onChanged: (_) =>
                                    context.push(RoutePaths.appSettings),
                              ),
                            ),
                            ProfileMenuTile(
                              icon: Icons.timer_outlined,
                              title: 'Tần suất làm mới dữ liệu',
                              valueText: '${data.settings.refreshRateSeconds} Giây',
                              showDivider: false,
                              onTap: () =>
                                  context.push(RoutePaths.appSettings),
                            ),
                          ],
                        ),

                        // SECTION 9: SECURITY
                        ProfileMenuSection(
                          title: 'BẢO MẬT & QUYỀN RIÊNG TƯ',
                          icon: Icons.security_rounded,
                          children: [
                            ProfileMenuTile(
                              icon: Icons.lock_outline_rounded,
                              title: 'Đổi mật khẩu tài khoản',
                              onTap: () =>
                                  context.push(RoutePaths.changePassword),
                            ),
                            ProfileMenuTile(
                              icon: Icons.fingerprint_rounded,
                              title: 'Đăng nhập sinh trắc học (Biometric)',
                              subtitle: 'Vân tay / FaceID',
                              trailing: Switch(
                                value: data.security.biometricEnabled,
                                activeColor: kHomeCyan,
                                onChanged: (val) {
                                  ref.read(profileStateProvider.notifier).toggleBiometric(val);
                                  _showToast(val ? 'Đã bật đăng nhập Vân tay/FaceID' : 'Đã tắt đăng nhập sinh trắc học');
                                },
                              ),
                            ),
                            ProfileMenuTile(
                              icon: Icons.shield_outlined,
                              title: 'Xác thực 2 yếu tố (2FA)',
                              valueText: data.security.twoFactorEnabled ? 'Đã bật' : 'Tắt',
                              onTap: () =>
                                  context.push(RoutePaths.securityPrivacy),
                            ),
                            ProfileMenuTile(
                              icon: Icons.devices_rounded,
                              title: 'Thiết bị đang đăng nhập',
                              valueText: '${data.security.activeDevicesCount} Thiết bị',
                              onTap: () =>
                                  context.push(RoutePaths.securityPrivacy),
                            ),
                            ProfileMenuTile(
                              icon: Icons.history_toggle_off_rounded,
                              title: 'Lịch sử đăng nhập',
                              valueText: '${data.security.loginHistoryCount} Lần',
                              onTap: () =>
                                  context.push(RoutePaths.securityPrivacy),
                            ),
                            ProfileMenuTile(
                              icon: Icons.privacy_tip_outlined,
                              title: 'Cài đặt quyền riêng tư',
                              showDivider: false,
                              onTap: () =>
                                  context.push(RoutePaths.securityPrivacy),
                            ),
                          ],
                        ),

                        // SECTION 10: HELP & SUPPORT
                        ProfileMenuSection(
                          title: 'TRỢ GIÚP & HỖ TRỢ',
                          icon: Icons.help_outline_rounded,
                          children: [
                            ProfileMenuTile(
                              icon: Icons.menu_book_rounded,
                              title: 'Hướng dẫn sử dụng (User Guide)',
                              onTap: () =>
                                  context.push(RoutePaths.helpSupport),
                            ),
                            ProfileMenuTile(
                              icon: Icons.quiz_outlined,
                              title: 'Câu hỏi thường gặp (FAQ)',
                              onTap: () =>
                                  context.push(RoutePaths.helpSupport),
                            ),
                            ProfileMenuTile(
                              icon: Icons.support_agent_rounded,
                              title: 'Liên hệ Hỗ trợ kỹ thuật',
                              valueText: 'Hotline: 1900 8888',
                              onTap: () =>
                                  context.push(RoutePaths.helpSupport),
                            ),
                            ProfileMenuTile(
                              icon: Icons.rate_review_outlined,
                              title: 'Gửi ý kiến đóng góp (Feedback)',
                              onTap: () =>
                                  context.push(RoutePaths.helpSupport),
                            ),
                            ProfileMenuTile(
                              icon: Icons.bug_report_outlined,
                              title: 'Báo lỗi ứng dụng (Report Bug)',
                              onTap: () =>
                                  context.push(RoutePaths.helpSupport),
                            ),
                            ProfileMenuTile(
                              icon: Icons.info_outline_rounded,
                              title: 'Về dự án CrabSense',
                              showDivider: false,
                              onTap: () =>
                                  context.push(RoutePaths.helpSupport),
                            ),
                          ],
                        ),

                        // SECTION: FIREBASE
                        ProfileMenuSection(
                          title: 'FIREBASE',
                          icon: Icons.local_fire_department_rounded,
                          subtitle: 'Auth · Storage · Crashlytics · FCM',
                          children: [
                            ProfileMenuTile(
                              icon: Icons.dashboard_customize_outlined,
                              title: 'Trung tâm Firebase',
                              subtitle: 'Trạng thái + hướng dẫn setup',
                              valueText: 'crabssense',
                              onTap: () =>
                                  context.push(RoutePaths.firebaseHub),
                            ),
                            ProfileMenuTile(
                              icon: Icons.lock_person_outlined,
                              title: 'Authentication',
                              subtitle: 'Google / Email trên Firebase Auth',
                              onTap: () => context.push(
                                '${RoutePaths.firebaseHub}?service=authentication',
                              ),
                            ),
                            ProfileMenuTile(
                              icon: Icons.cloud_upload_outlined,
                              title: 'Storage',
                              subtitle: 'Ảnh, video, file trên Cloud Storage',
                              onTap: () => context.push(
                                '${RoutePaths.firebaseHub}?service=storage',
                              ),
                            ),
                            ProfileMenuTile(
                              icon: Icons.bug_report_outlined,
                              title: 'Crashlytics',
                              subtitle: 'Theo dõi crash trên Console',
                              onTap: () => context.push(
                                '${RoutePaths.firebaseHub}?service=crashlytics',
                              ),
                            ),
                            ProfileMenuTile(
                              icon: Icons.notifications_active_outlined,
                              title: 'Cloud Messaging',
                              subtitle: 'FCM push + copy token',
                              showDivider: false,
                              onTap: () => context.push(
                                '${RoutePaths.firebaseHub}?service=cloudMessaging',
                              ),
                            ),
                          ],
                        ),

                        // SECTION 11: APPLICATION INFORMATION
                        ProfileMenuSection(
                          title: 'THÔNG TIN ỨNG DỤNG',
                          icon: Icons.apps_rounded,
                          children: [
                            ProfileMenuTile(
                              icon: Icons.verified_outlined,
                              title: 'Phiên bản ứng dụng',
                              valueText: '1.0.0',
                              onTap: () => context.push(RoutePaths.appInfo),
                            ),
                            ProfileMenuTile(
                              icon: Icons.build_circle_outlined,
                              title: 'Mã bản dựng (Build Number)',
                              valueText: '1001',
                              onTap: () => context.push(RoutePaths.appInfo),
                            ),
                            ProfileMenuTile(
                              icon: Icons.description_outlined,
                              title: 'Điều khoản dịch vụ (Terms of Service)',
                              onTap: () => context.push(
                                RoutePaths.legalDocument,
                                extra: LegalDocumentArgs.terms,
                              ),
                            ),
                            ProfileMenuTile(
                              icon: Icons.policy_outlined,
                              title: 'Chính sách bảo mật (Privacy Policy)',
                              onTap: () => context.push(
                                RoutePaths.legalDocument,
                                extra: LegalDocumentArgs.privacy,
                              ),
                            ),
                            ProfileMenuTile(
                              icon: Icons.code_rounded,
                              title: 'Giấy phép nguồn mở (Open Source License)',
                              onTap: () => context.push(RoutePaths.appInfo),
                            ),
                            ProfileMenuTile(
                              icon: Icons.system_update_rounded,
                              title: 'Kiểm tra cập nhật (Check Update)',
                              valueText: 'Phiên bản mới nhất',
                              showDivider: false,
                              onTap: () => context.push(RoutePaths.appInfo),
                            ),
                          ],
                        ),

                        // SECTION 12: LOGOUT
                        LogoutButton(
                          onLogoutConfirmed: () {
                            ref.read(profileStateProvider.notifier).logout();
                            _showToast('Đã đăng xuất tài khoản an toàn.');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
              },
            ),
          ),
        ],
      ),
    );
  }
}
