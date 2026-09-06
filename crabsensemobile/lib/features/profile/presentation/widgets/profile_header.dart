import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../data/models/profile_models.dart';

/// Header hồ sơ — phong cách hologram như Alerts/Boxes.
class ProfileHeader extends StatelessWidget {
  final ProfileSummary profile;
  final VoidCallback onEditProfile;
  final VoidCallback onChangeAvatar;
  final VoidCallback? onSync;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onEditProfile,
    required this.onChangeAvatar,
    this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final initial = profile.fullName.isNotEmpty
        ? profile.fullName.trim().split(' ').last.substring(0, 1).toUpperCase()
        : 'K';

    return Container(
      width: double.infinity,
      decoration: homeCardDecoration(radius: 22, glowAlpha: 0.16),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const HomeCrabWatermark(alpha: 0.06, trayExtent: 26),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_circle_rounded,
                      size: 20,
                      color: kHomeBlueLight,
                      shadows: [
                        Shadow(
                          color: kHomeBlueLight.withValues(alpha: 0.8),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'TÀI KHOẢN',
                          style: TextStyle(
                            color: kHomePrimaryDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    if (onSync != null)
                      IconButton(
                        tooltip: 'Đồng bộ',
                        onPressed: onSync,
                        icon: const Icon(
                          Icons.sync_rounded,
                          color: kHomeCyan,
                          size: 22,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: onChangeAvatar,
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: kHomeCyan.withValues(alpha: 0.7),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kHomeBlue.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(2),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: kHomeBg,
                              backgroundImage: profile.avatarUrl != null &&
                                      profile.avatarUrl!.isNotEmpty
                                  ? NetworkImage(profile.avatarUrl!)
                                  : null,
                              child: profile.avatarUrl == null ||
                                      profile.avatarUrl!.isEmpty
                                  ? Text(
                                      initial,
                                      style: const TextStyle(
                                        color: kHomeCyan,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 26,
                                      ),
                                    )
                                  : null,
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
                              color: profile.isOnline
                                  ? kHomeGreen
                                  : Colors.white54,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: kHomeBg,
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                                  style: const TextStyle(
                                    color: kHomeTextMain,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: profile.role.badgeColor
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: profile.role.badgeColor
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Text(
                                  profile.role.displayName,
                                  style: TextStyle(
                                    color: profile.role.badgeColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: kHomeCyan,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  profile.currentFarm,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.isOnline
                                ? 'Online · ${profile.email}'
                                : 'Offline · ${profile.email}',
                            style: TextStyle(
                              color: profile.isOnline
                                  ? kHomeGreen
                                  : Colors.white54,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEditProfile,
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text(
                          'Chỉnh sửa hồ sơ',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kHomeCyan,
                          side: BorderSide(
                            color: kHomeCyan.withValues(alpha: 0.7),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onChangeAvatar,
                        icon: const Icon(Icons.photo_camera_rounded, size: 16),
                        label: const Text(
                          'Đổi ảnh',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: kHomeBlue.withValues(alpha: 0.45),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
