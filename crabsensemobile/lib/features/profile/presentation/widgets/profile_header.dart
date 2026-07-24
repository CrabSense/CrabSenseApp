import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/profile_models.dart';

/// 1. Profile Header Widget (Mặt tiền trang cá nhân)
class ProfileHeader extends StatelessWidget {
  final ProfileSummary profile;
  final VoidCallback onEditProfile;
  final VoidCallback onChangeAvatar;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onEditProfile,
    required this.onChangeAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CrabSenseColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CrabSenseColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with Online indicator dot
              Stack(
                children: [
                  GestureDetector(
                    onTap: onChangeAvatar,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: CrabSenseColors.primaryGradient,
                        border: Border.all(color: CrabSenseColors.primary.withValues(alpha: 0.6), width: 2),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: CrabSenseColors.container,
                        child: Text(
                          profile.fullName.isNotEmpty
                              ? profile.fullName.trim().split(' ').last.substring(0, 1).toUpperCase()
                              : 'K',
                          style: const TextStyle(
                            color: CrabSenseColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: profile.isOnline ? CrabSenseColors.success : CrabSenseColors.hintText,
                        shape: BoxShape.circle,
                        border: Border.all(color: CrabSenseColors.surface, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // User Info Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.fullName,
                            style: const TextStyle(
                              color: CrabSenseColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: profile.role.badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: profile.role.badgeColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            profile.role.displayName,
                            style: TextStyle(
                              color: profile.role.badgeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: CrabSenseColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Đang làm việc: ',
                          style: TextStyle(
                            color: CrabSenseColors.textSecondary.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          profile.currentFarm,
                          style: const TextStyle(
                            color: CrabSenseColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: profile.isOnline ? CrabSenseColors.success : CrabSenseColors.hintText,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          profile.isOnline ? 'Online (Trực tuyến)' : 'Offline (Ngoại tuyến)',
                          style: TextStyle(
                            color: profile.isOnline ? CrabSenseColors.success : CrabSenseColors.hintText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: CrabSenseColors.divider, height: 1),
          const SizedBox(height: 12),

          // Action Buttons: Edit Profile & Change Avatar
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: onEditProfile,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Chỉnh sửa hồ sơ', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CrabSenseColors.primary,
                      side: const BorderSide(color: CrabSenseColors.primary, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: onChangeAvatar,
                    icon: const Icon(Icons.photo_camera_rounded, size: 16),
                    label: const Text('Đổi ảnh đại diện', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CrabSenseColors.container,
                      foregroundColor: CrabSenseColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: CrabSenseColors.border),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
