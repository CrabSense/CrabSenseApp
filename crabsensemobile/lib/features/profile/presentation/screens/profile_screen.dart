import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

import '../../data/models/profile_models.dart';
import '../providers/profile_provider.dart';
import '../widgets/logout_button.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_section.dart';
import '../widgets/profile_menu_tile.dart';
import '../widgets/profile_skeleton.dart';
import '../widgets/section_error_card.dart';

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
        backgroundColor: CrabSenseColors.container,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showRowDetailDialog(String title, String value, String description) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CrabSenseColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_rounded, color: CrabSenseColors.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: CrabSenseColors.textPrimary,
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
              decoration: BoxDecoration(
                color: CrabSenseColors.container,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CrabSenseColors.border),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: CrabSenseColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                color: CrabSenseColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CrabSenseColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFarmSwitcherDialog(ProfileStateData data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CrabSenseColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: CrabSenseColors.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: CrabSenseColors.primary),
            SizedBox(width: 10),
            Text(
              'Chuyển đổi Trang trại',
              style: TextStyle(
                color: CrabSenseColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: data.farmManagement.availableFarms.map((farm) {
            final isSelected = farm.name.contains(data.farmManagement.currentFarmName);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? CrabSenseColors.primary.withValues(alpha: 0.15) : CrabSenseColors.container,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? CrabSenseColors.primary : CrabSenseColors.border,
                ),
              ),
              child: ListTile(
                title: Text(
                  farm.name,
                  style: TextStyle(
                    color: isSelected ? CrabSenseColors.primary : CrabSenseColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  '${farm.areaCount} • ${farm.boxCount}',
                  style: const TextStyle(color: CrabSenseColors.hintText, fontSize: 12),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: CrabSenseColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(profileStateProvider.notifier).switchFarm(farm.name.split(' - ').first);
                  _showToast('Đã chuyển sang ${farm.name}');
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAboutAppDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'CrabSense Mobile',
      applicationVersion: '1.0.0+1',
      applicationLegalese: '© 2026 CrabSense Smart Aquaculture Platform',
      children: [
        const SizedBox(height: 12),
        const Text(
          'Hệ thống quản lý trang trại cua thông minh tích hợp IoT, camera AI và đồng bộ dữ liệu ngoại tuyến.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsyncState = ref.watch(profileStateProvider);

    return Scaffold(
      backgroundColor: CrabSenseColors.background,
      appBar: AppBar(
        backgroundColor: CrabSenseColors.surface,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.account_circle_rounded, color: CrabSenseColors.primary, size: 24),
            SizedBox(width: 8),
            Text(
              'Trung tâm Tài khoản & Cá nhân',
              style: TextStyle(
                color: CrabSenseColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: CrabSenseColors.primary),
            tooltip: 'Đồng bộ ngay',
            onPressed: () {
              ref.read(profileStateProvider.notifier).triggerSync();
              _showToast('Đang tiến hành đồng bộ dữ liệu...');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: profileAsyncState.when(
          loading: () => const ProfileSkeleton(),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ProfileSectionErrorCard(
                sectionTitle: 'Trang cá nhân',
                errorMessage: error.toString(),
                onRetry: () => ref.read(profileStateProvider.notifier).loadData(forceRefresh: true),
              ),
            ),
          ),
          data: (data) {
            return RefreshIndicator(
              onRefresh: () => ref.read(profileStateProvider.notifier).refresh(),
              color: CrabSenseColors.primary,
              backgroundColor: CrabSenseColors.surface,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Offline Cached Data Banner
                        if (data.isOfflineCached || !data.isOnline) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: CrabSenseColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: CrabSenseColors.warning.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.wifi_off_rounded, color: CrabSenseColors.warning, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Chế độ ngoại tuyến • Đang dùng dữ liệu bộ nhớ đệm (${_dateFormatter.format(data.lastSyncedAt)})',
                                    style: const TextStyle(
                                      color: CrabSenseColors.warning,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => ref.read(profileStateProvider.notifier).triggerSync(),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Text(
                                      'Thử lại',
                                      style: TextStyle(
                                        color: CrabSenseColors.primary,
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

                        // SECTION 1: PROFILE HEADER
                        ProfileHeader(
                          profile: data.profile,
                          onEditProfile: () => _showToast('Mở màn hình Chỉnh sửa hồ sơ cá nhân'),
                          onChangeAvatar: () => _showToast('Mở Trình chọn ảnh đại diện'),
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
                              onTap: () => _showToast('Mở Danh sách & sơ đồ Box nuôi'),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: CrabSenseColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${data.devices.totalOnline} Online • ${data.devices.totalOffline} Offline',
                              style: const TextStyle(
                                color: CrabSenseColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          children: data.devices.devices.map((device) {
                            final isLast = device.id == data.devices.devices.last.id;
                            return ProfileMenuTile(
                              icon: device.icon,
                              title: device.name,
                              subtitle: 'Online: ${device.onlineCount} | Offline: ${device.offlineCount}',
                              valueText: device.statusBadge,
                              showDivider: !isLast,
                              onTap: () => _showToast('Chi tiết thiết bị ${device.name}'),
                            );
                          }).toList(),
                        ),

                        // SECTION 5: AI CENTER
                        ProfileMenuSection(
                          title: 'TRUNG TÂM AI CRABSENSE',
                          icon: Icons.psychology_rounded,
                          trailingBadge: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: CrabSenseColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              data.aiSummary.modelVersion,
                              style: const TextStyle(
                                color: CrabSenseColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          children: [
                            ProfileMenuTile(
                              icon: Icons.history_rounded,
                              title: 'Lịch sử phát hiện AI (Detection History)',
                              valueText: '${data.aiSummary.detectionHistoryCount} lượt',
                              onTap: () => _showToast('Mở Lịch sử nhận diện hình ảnh AI'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.auto_awesome_rounded,
                              title: 'Lịch sử khuyến nghị AI',
                              valueText: '${data.aiSummary.recommendationHistoryCount} đề xuất',
                              onTap: () => _showToast('Mở Lịch sử gợi ý tự động AI'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.verified_rounded,
                              title: 'Phiên bản & Trạng thái Mô hình AI',
                              subtitle: data.aiSummary.modelStatus,
                              valueText: '${data.aiSummary.avgConfidencePercentage}% Độ chính xác',
                              onTap: () => _showToast('Thông tin Model CrabSense-AI v2.4.1'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.feedback_outlined,
                              title: 'Gửi phản hồi AI (Feedback AI)',
                              valueText: '${data.aiSummary.feedbackCount} Phản hồi',
                              onTap: () => _showToast('Gửi đánh giá kết quả AI'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.model_training_rounded,
                              title: 'Thông tin huấn luyện (Training Info)',
                              subtitle: data.aiSummary.trainingInfo,
                              showDivider: false,
                              onTap: () => _showRowDetailDialog('Training Info', data.aiSummary.trainingInfo, 'Dữ liệu huấn luyện nhận diện lột vỏ, sức khỏe cua và tình trạng nước.'),
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
                              onTap: () => _showToast('Mở Báo cáo thu hoạch cua'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.point_of_sale_rounded,
                              title: 'Báo cáo Bán hàng & Doanh thu',
                              onTap: () => _showToast('Mở Báo cáo doanh thu & sản lượng'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.trending_up_rounded,
                              title: 'Báo cáo Tăng trưởng (Growth Report)',
                              onTap: () => _showToast('Mở Báo cáo tốc độ tăng trưởng cua'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.warning_amber_rounded,
                              title: 'Báo cáo Tỷ lệ hao hụt (Mortality Report)',
                              onTap: () => _showToast('Mở Báo cáo tỷ lệ chết & sức khỏe'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.water_rounded,
                              title: 'Báo cáo Chất lượng nước (Water Report)',
                              onTap: () => _showToast('Mở Báo cáo thông số môi trường nước'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.smart_toy_outlined,
                              title: 'Báo cáo AI & Dự báo',
                              onTap: () => _showToast('Mở Báo cáo tổng hợp từ AI'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.developer_board_rounded,
                              title: 'Báo cáo Tình trạng thiết bị (Device Report)',
                              showDivider: false,
                              onTap: () => _showToast('Mở Báo cáo uptime và lỗi cảm biến'),
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
                              color: CrabSenseColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              data.syncSummary.syncStatus,
                              style: const TextStyle(
                                color: CrabSenseColors.success,
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
                              onTap: () => _showToast('Hệ thống đang đồng bộ dữ liệu bình thường'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.queue_play_next_rounded,
                              title: 'Hàng chờ ngoại tuyến (Offline Queue)',
                              valueText: '${data.syncSummary.offlineQueueCount} Mục',
                              onTap: () => _showToast('Danh sách dữ liệu lưu trên máy'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.cloud_upload_outlined,
                              title: 'Dữ liệu chờ tải lên (Pending Upload)',
                              valueText: '${data.syncSummary.pendingUploadCount} Mục',
                              onTap: () => _showToast('Không có dữ liệu chờ tải'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.access_time_rounded,
                              title: 'Thời gian đồng bộ gần nhất',
                              valueText: DateFormat('HH:mm dd/MM').format(data.syncSummary.lastSyncedAt),
                              onTap: () => _showToast('Đồng bộ lúc ${DateFormat('HH:mm:ss').format(data.syncSummary.lastSyncedAt)}'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.sync_problem_rounded,
                              title: 'Xử lý xung đột (Conflict Resolution)',
                              valueText: '${data.syncSummary.conflictCount} Xung đột',
                              onTap: () => _showToast('Không có xung đột dữ liệu'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.refresh_rounded,
                              title: 'Thực hiện đồng bộ ngay (Retry Sync)',
                              iconColor: CrabSenseColors.primary,
                              titleColor: CrabSenseColors.primary,
                              showDivider: false,
                              onTap: () {
                                ref.read(profileStateProvider.notifier).triggerSync();
                                _showToast('Đã kích hoạt đồng bộ toàn bộ dữ liệu!');
                              },
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
                              onTap: () => _showToast('CrabSense ưu tiên giao diện Dark Mode'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.language_rounded,
                              title: 'Ngôn ngữ (Language)',
                              valueText: data.settings.language,
                              onTap: () => _showToast('Hỗ trợ Tiếng Việt & English'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.notifications_none_rounded,
                              title: 'Thông báo cảnh báo',
                              subtitle: 'Nhận cảnh báo môi trường & sức khỏe cua',
                              trailing: Switch(
                                value: data.settings.notificationsEnabled,
                                activeColor: CrabSenseColors.primary,
                                onChanged: (val) {
                                  ref.read(profileStateProvider.notifier).toggleNotification(val);
                                  _showToast(val ? 'Đã bật thông báo' : 'Đã tắt thông báo');
                                },
                              ),
                            ),
                            ProfileMenuTile(
                              icon: Icons.straighten_rounded,
                              title: 'Đơn vị đo lường (Measurement Unit)',
                              valueText: data.settings.measurementUnit,
                              onTap: () => _showToast('Cấu hình °C, mg/L, ppt, pH'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.camera_alt_outlined,
                              title: 'Cấu hình Camera AI',
                              valueText: data.settings.cameraResolution,
                              onTap: () => _showToast('Độ phân giải luồng video camera AI'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.storage_rounded,
                              title: 'Dung lượng bộ nhớ đệm (Cache)',
                              valueText: data.settings.cacheSize,
                              onTap: () => _showToast('Xóa bộ nhớ đệm ứng dụng'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.autorenew_rounded,
                              title: 'Tự động đồng bộ (Auto Sync)',
                              trailing: Switch(
                                value: data.settings.autoSync,
                                activeColor: CrabSenseColors.primary,
                                onChanged: (val) => _showToast('Đã thay đổi tự động đồng bộ'),
                              ),
                            ),
                            ProfileMenuTile(
                              icon: Icons.timer_outlined,
                              title: 'Tần suất làm mới dữ liệu',
                              valueText: '${data.settings.refreshRateSeconds} Giây',
                              showDivider: false,
                              onTap: () => _showToast('Tần suất lấy dữ liệu IoT: 30 giây'),
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
                              onTap: () => _showToast('Mở màn hình Đổi mật khẩu'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.fingerprint_rounded,
                              title: 'Đăng nhập sinh trắc học (Biometric)',
                              subtitle: 'Vân tay / FaceID',
                              trailing: Switch(
                                value: data.security.biometricEnabled,
                                activeColor: CrabSenseColors.primary,
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
                              onTap: () => _showToast('Quản lý mã xác thực OTP 2FA'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.devices_rounded,
                              title: 'Thiết bị đang đăng nhập',
                              valueText: '${data.security.activeDevicesCount} Thiết bị',
                              onTap: () => _showToast('Danh sách thiết bị kết nối tài khoản'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.history_toggle_off_rounded,
                              title: 'Lịch sử đăng nhập',
                              valueText: '${data.security.loginHistoryCount} Lần',
                              onTap: () => _showToast('Xem nhật ký đăng nhập tài khoản'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.privacy_tip_outlined,
                              title: 'Cài đặt quyền riêng tư',
                              showDivider: false,
                              onTap: () => _showToast('Mở Cài đặt quyền riêng tư'),
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
                              onTap: () => _showToast('Mở Sách hướng dẫn sử dụng CrabSense'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.quiz_outlined,
                              title: 'Câu hỏi thường gặp (FAQ)',
                              onTap: () => _showToast('Mở Danh sách câu hỏi FAQ'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.support_agent_rounded,
                              title: 'Liên hệ Hỗ trợ kỹ thuật',
                              valueText: 'Hotline: 1900 8888',
                              onTap: () => _showToast('Gọi Tổng đài Hỗ trợ CrabSense'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.rate_review_outlined,
                              title: 'Gửi ý kiến đóng góp (Feedback)',
                              onTap: () => _showToast('Gửi phản hồi cho nhóm phát triển'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.bug_report_outlined,
                              title: 'Báo lỗi ứng dụng (Report Bug)',
                              onTap: () => _showToast('Mở Form báo lỗi kỹ thuật'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.info_outline_rounded,
                              title: 'Về dự án CrabSense',
                              showDivider: false,
                              onTap: _showAboutAppDialog,
                            ),
                          ],
                        ),

                        // SECTION 11: APPLICATION INFORMATION
                        ProfileMenuSection(
                          title: 'THÔNG TIN ỨNG DỤNG',
                          icon: Icons.apps_rounded,
                          children: [
                            const ProfileMenuTile(
                              icon: Icons.verified_outlined,
                              title: 'Phiên bản ứng dụng',
                              valueText: '1.0.0',
                            ),
                            const ProfileMenuTile(
                              icon: Icons.build_circle_outlined,
                              title: 'Mã bản dựng (Build Number)',
                              valueText: '1001',
                            ),
                            ProfileMenuTile(
                              icon: Icons.description_outlined,
                              title: 'Điều khoản dịch vụ (Terms of Service)',
                              onTap: () => _showToast('Xem Điều khoản sử dụng dịch vụ'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.policy_outlined,
                              title: 'Chính sách bảo mật (Privacy Policy)',
                              onTap: () => _showToast('Xem Chính sách bảo mật dữ liệu'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.code_rounded,
                              title: 'Giấy phép nguồn mở (Open Source License)',
                              onTap: () => _showToast('Mở Danh sách thư viện nguồn mở'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.system_update_rounded,
                              title: 'Kiem tra cap nhat (Check Update)',
                              valueText: 'Phiên bản mới nhất',
                              showDivider: false,
                              onTap: () => _showToast('Bạn đang sử dụng phiên bản mới nhất!'),
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
    );
  }
}
