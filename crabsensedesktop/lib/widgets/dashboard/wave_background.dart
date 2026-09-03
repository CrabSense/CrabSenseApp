import 'package:flutter/material.dart';

import '../../services/theme_mode_service.dart';
import '../../theme/dashboard_theme.dart';

/// Nền toàn app: ảnh banner theo chế độ sáng / tối.
class WaveBackground extends StatefulWidget {
  const WaveBackground({super.key});

  static const lightBackgroundAsset = 'assets/images/background_light.png';
  static const darkBackgroundAsset = 'assets/images/background_dark.png';

  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground> {
  @override
  void initState() {
    super.initState();
    appThemeMode.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    appThemeMode.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (appThemeMode.isDark) {
      return const _ThemeBackgroundImage(
        asset: WaveBackground.darkBackgroundAsset,
        overlayColors: [
          Color(0x33000000),
          Color(0x4D0A0018),
        ],
      );
    }
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
