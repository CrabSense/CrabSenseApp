import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Shimmer Skeleton for Profile Screen Loading State
/// Custom Shimmer with Base `#10233A`, Highlight `#173552`, Duration `1.2s`
class ProfileSkeleton extends StatefulWidget {
  const ProfileSkeleton({super.key});

  @override
  State<ProfileSkeleton> createState() => _ProfileSkeletonState();
}

class _ProfileSkeletonState extends State<ProfileSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  static const Color baseColor = CrabSenseColors.surface; // #10233A
  static const Color highlightColor = CrabSenseColors.container; // #173552

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double borderRadius = 8,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: const [baseColor, highlightColor, baseColor],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonCard({
    required String title,
    required int itemCount,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CrabSenseColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CrabSenseColors.border),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildShimmerBox(width: 24, height: 24, borderRadius: 6),
              const SizedBox(width: 12),
              _buildShimmerBox(width: 140, height: 16, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: CrabSenseColors.divider, height: 1),
          const SizedBox(height: 12),
          ...List.generate(
            itemCount,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _buildShimmerBox(width: 20, height: 20, borderRadius: 4),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildShimmerBox(
                      width: double.infinity,
                      height: 14,
                      borderRadius: 4,
                    ),
                  ),
                  const SizedBox(width: 20),
                  _buildShimmerBox(width: 40, height: 14, borderRadius: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              // 1. Profile Header Skeleton
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: CrabSenseColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CrabSenseColors.border),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildShimmerBox(width: 68, height: 68, borderRadius: 34),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildShimmerBox(width: 160, height: 18, borderRadius: 4),
                              const SizedBox(height: 8),
                              _buildShimmerBox(width: 120, height: 14, borderRadius: 4),
                              const SizedBox(height: 6),
                              _buildShimmerBox(width: 90, height: 12, borderRadius: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildShimmerBox(width: double.infinity, height: 40, borderRadius: 10)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildShimmerBox(width: double.infinity, height: 40, borderRadius: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Account Card Skeleton
              _buildSkeletonCard(title: 'Thông tin tài khoản', itemCount: 3),

              // 3. Farm Card Skeleton
              _buildSkeletonCard(title: 'Quản lý trang trại', itemCount: 3),

              // 4. IoT Card Skeleton
              _buildSkeletonCard(title: 'Thiết bị & IoT', itemCount: 4),

              // 5. AI Card Skeleton
              _buildSkeletonCard(title: 'Trung tâm AI', itemCount: 3),

              // 6. Reports Card Skeleton
              _buildSkeletonCard(title: 'Báo cáo & Phân tích', itemCount: 3),

              // 7. Offline Card Skeleton
              _buildSkeletonCard(title: 'Ngoại tuyến & Đồng bộ', itemCount: 2),

              // 8. Settings Card Skeleton
              _buildSkeletonCard(title: 'Cài đặt ứng dụng', itemCount: 3),

              // 9. Security Card Skeleton
              _buildSkeletonCard(title: 'Bảo mật & Quyền riêng tư', itemCount: 3),

              // 10. Help Card Skeleton
              _buildSkeletonCard(title: 'Trợ giúp & Hỗ trợ', itemCount: 3),

              // 11. Application Info Skeleton
              _buildSkeletonCard(title: 'Thông tin ứng dụng', itemCount: 2),

              // 12. Logout Button Skeleton
              _buildShimmerBox(width: double.infinity, height: 50, borderRadius: 14),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
