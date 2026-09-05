import 'package:flutter/material.dart';

import '../../theme/dashboard_theme.dart';

/// Nền toàn app: ảnh banner chế độ sáng.
class WaveBackground extends StatefulWidget {
  const WaveBackground({super.key});

  static const lightBackgroundAsset = 'assets/images/background_light.png';

  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground> {
  @override
  Widget build(BuildContext context) {
    return const _ThemeBackgroundImage(
      asset: WaveBackground.lightBackgroundAsset,
      overlayColors: [
        Color(0x14FFFFFF),
        Color(0x38FFFFFF),
      ],
    );
  }
}

class _ThemeBackgroundImage extends StatelessWidget {
  const _ThemeBackgroundImage({
    required this.asset,
    required this.overlayColors,
  });

  final String asset;
  final List<Color> overlayColors;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: DashboardColors.darkNavy,
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: DashboardColors.textMuted,
                size: 48,
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: overlayColors,
            ),
          ),
        ),
      ],
    );
  }
}
