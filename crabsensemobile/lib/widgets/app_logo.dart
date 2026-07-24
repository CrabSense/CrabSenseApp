import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

/// Widget tái sử dụng cho logo CrabSense Mobile
class AppLogo extends StatelessWidget {

  const AppLogo({
    super.key,
    this.size = 80,
    this.showText = false,
    this.textColor,
  });
  final double size;
  final bool showText;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    if (showText) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogoImage(context),
          const SizedBox(height: 8),
          Text(
            'CrabSense',
            style: TextStyle(
              fontSize: size * 0.2,
              fontWeight: FontWeight.bold,
              color: textColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      );
    }

    return _buildLogoImage(context);
  }

  Widget _buildLogoImage(BuildContext context) => Image.asset(
      AppConstants.logoPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback về icon mặc định nếu không có logo
        return _buildDefaultLogo(context);
      },
    );

  Widget _buildDefaultLogo(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(size / 4),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Icon nước/sóng
          Icon(
            Icons.water,
            size: size * 0.5,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          // Icon tôm nhỏ ở góc
          Positioned(
            right: size * 0.12,
            bottom: size * 0.12,
            child: Container(
              padding: EdgeInsets.all(size * 0.05),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.set_meal,
                size: size * 0.18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
}

/// Logo nhỏ cho AppBar
class AppBarLogo extends StatelessWidget {
  const AppBarLogo({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.all(8),
      child: AppLogo(size: 28),
    );
}

/// Logo loading với animation
class AnimatedAppLogo extends StatefulWidget {

  const AnimatedAppLogo({
    super.key,
    this.size = 80,
  });
  final double size;

  @override
  State<AnimatedAppLogo> createState() => _AnimatedAppLogoState();
}

class _AnimatedAppLogoState extends State<AnimatedAppLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
      scale: _animation,
      child: AppLogo(size: widget.size),
    );
}
