import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/auth_models.dart';
import '../services/cloud_api_client.dart';
import '../services/cloud_auth_service.dart';
import 'login_screen.dart';
import 'main_shell_screen.dart';

/// Palette CrabSense — smart aquaculture.
abstract final class _FarmInk {
  static const primary = Color(0xFF087F5B);
  static const green = Color(0xFF12A87A);
  static const mintBright = Color(0xFF35C997);
  static const mint = Color(0xFFDDF7EE);
  static const lightMint = Color(0xFFF1FBF7);
  static const darkText = Color(0xFF12332D);
  static const secondary = Color(0xFF66847C);
  static const warning = Color(0xFFF97316);
  static const muted = Color(0xFF94A8A2);
  static const card = Color(0xF9F7FFFB);
  static const risk = Color(0xFFDC2626);
}

class FarmSelectScreen extends StatefulWidget {
  const FarmSelectScreen({
    super.key,
    required this.token,
    required this.user,
    this.refreshToken,
    this.persistSession = true,
    this.username,
  });

  final String token;
  final String? refreshToken;
  final AuthUser user;
  final bool persistSession;
  final String? username;

  @override
  State<FarmSelectScreen> createState() => _FarmSelectScreenState();
}

class _FarmSelectScreenState extends State<FarmSelectScreen> {
  final _auth = CloudAuthService();
  bool _loading = true;
  String? _error;
  AuthMePayload? _me;
  FarmSummary? _selected;

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final me = await _auth.fetchMe(widget.token);
      if (!me.isFarmOwner) {
        setState(() {
          _loading = false;
          _error =
              'Desktop chỉ dành cho chủ trại (FarmOwner). Role hiện tại: ${me.user.role}.';
        });
        return;
      }
      final farms = me.farms;
      final selected =
          _auth.resolveDefaultFarm(farms, me) ?? FarmSummary.unassigned;
      final payload = farms.isEmpty
          ? AuthMePayload(
              user: me.user,
              farms: const [FarmSummary.unassigned],
              isOrgAdmin: me.isOrgAdmin,
              canViewAllFarms: me.canViewAllFarms,
              defaultFarmId: me.defaultFarmId,
            )
          : me;
      setState(() {
        _me = payload;
        _selected = selected;
        _loading = false;
      });
      if (farms.length <= 1 && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _continue();
        });
      }
    } on CloudApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Lỗi tải farm: $e';
      });
    }
  }

  Future<void> _continue() async {
    final me = _me;
    final farm = _selected;
    if (me == null || farm == null) return;

    final session = AuthSession(
      token: widget.token,
      refreshToken: widget.refreshToken,
      user: me.user,
      farms: me.farms,
      selectedFarm: farm,
      isOrgAdmin: me.isOrgAdmin,
    );

    if (widget.persistSession) {
      await _auth.persistSession(
        session,
        username: widget.username ?? me.user.username ?? me.user.email,
      );
    } else {
      await _auth.clearSession(keepUsername: false);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainShellScreen(session: session)),
    );
  }

  /// Login dùng `pushReplacement` nên không còn route để `pop`.
  Future<void> _goBackToLogin() async {
    await _auth.clearSession(keepUsername: true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FarmInk.mint,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
            child: Image.asset(
              'assets/images/login_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF0A5C48).withValues(alpha: 0.12),
            ),
          ),
          // Slogan thương hiệu — góc trên phải, phóng to.
          const Positioned(
            top: 28,
            right: 36,
            child: IgnorePointer(
              child: _KnockoutBlackImage(
                asset: 'assets/images/login/slogan_right_tv.png',
                height: 160,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextButton.icon(
                    onPressed: _goBackToLogin,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      'Quay lại',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: _FarmSelectCard(
                          loading: _loading,
                          error: _error,
                          user: widget.user,
                          me: _me,
                          selected: _selected,
                          onRetry: _loadMe,
                          onBack: _goBackToLogin,
                          onFarmChanged: (v) => setState(() => _selected = v),
                          onContinue: _continue,
                        ),
                      ),
                    ),
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

class _FarmSelectCard extends StatelessWidget {
  const _FarmSelectCard({
    required this.loading,
    required this.error,
    required this.user,
    required this.me,
    required this.selected,
    required this.onRetry,
    required this.onBack,
    required this.onFarmChanged,
    required this.onContinue,
  });

  final bool loading;
  final String? error;
  final AuthUser user;
  final AuthMePayload? me;
  final FarmSummary? selected;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final ValueChanged<FarmSummary> onFarmChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _FarmInk.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _FarmInk.primary.withValues(alpha: 0.14),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            const Positioned(
              right: -8,
              bottom: -12,
              child: _CardDecor(),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 40,
              child: CustomPaint(painter: _WavePainter()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 28, 36, 30),
              child: _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 240,
        child: Center(
          child: CircularProgressIndicator(
            color: _FarmInk.green,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: _FarmInk.risk),
          const SizedBox(height: 14),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              color: _FarmInk.darkText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _FarmInk.secondary,
                    backgroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(
                      color: _FarmInk.mint.withValues(alpha: 0.9),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Text(
                    'Quay lại',
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CtaButton(
                  label: 'Thử lại',
                  onPressed: onRetry,
                ),
              ),
            ],
          ),
        ],
      );
    }

    final payload = me!;
    final farms = payload.farms;
    final greeting = user.displayName.trim().isEmpty
        ? 'Chủ trại'
        : user.displayName;
    final selectedFarm = selected;
    final ctaLabel = selectedFarm == null || selectedFarm.isUnassigned
        ? 'Tiếp tục'
        : 'Tiếp tục vào ${selectedFarm.name}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Image.asset(
            'assets/images/logo.png',
            height: 88,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Chọn khu nuôi',
          textAlign: TextAlign.center,
          style: GoogleFonts.beVietnamPro(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: _FarmInk.darkText,
            letterSpacing: -0.4,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Xin chào, $greeting!',
          textAlign: TextAlign.center,
          style: GoogleFonts.beVietnamPro(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: _FarmInk.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Bạn muốn quản lý khu nuôi nào hôm nay?',
          textAlign: TextAlign.center,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13.5,
            color: _FarmInk.muted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'DANH SÁCH KHU NUÔI',
          style: GoogleFonts.beVietnamPro(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: _FarmInk.secondary,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(farms.length, (i) {
          final farm = farms[i];
          final isSelected = selected?.id == farm.id;
          return Padding(
            padding: EdgeInsets.only(bottom: i == farms.length - 1 ? 0 : 10),
            child: _AreaCard(
              farm: farm,
              selected: isSelected,
              status: _FarmAreaStatus.normal,
              onTap: () => onFarmChanged(farm),
            ),
          );
        }),
        const SizedBox(height: 16),
        const _SystemStatusBar(),
        const SizedBox(height: 22),
        _CtaButton(
          label: ctaLabel,
          onPressed: selectedFarm == null ? null : onContinue,
        ),
      ],
    );
  }
}

enum _FarmAreaStatus { normal, warning, paused }

class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.farm,
    required this.selected,
    required this.status,
    required this.onTap,
  });

  final FarmSummary farm;
  final bool selected;
  final _FarmAreaStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (status) {
      _FarmAreaStatus.normal => ('Bình thường', _FarmInk.green),
      _FarmAreaStatus.warning => ('Có cảnh báo', _FarmInk.warning),
      _FarmAreaStatus.paused => ('Tạm ngưng', _FarmInk.muted),
    };

    final subtitle = farm.isUnassigned
        ? 'Chưa gán mã khu nuôi'
        : (farm.code.isEmpty || farm.code == farm.name
            ? 'Khu nuôi CrabSense'
            : farm.code);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? _FarmInk.lightMint : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _FarmInk.green : const Color(0xFFD7EBE3),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _FarmInk.green.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? _FarmInk.mint
                      : _FarmInk.lightMint.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.home_work_outlined,
                  color: selected ? _FarmInk.primary : _FarmInk.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.name,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: _FarmInk.darkText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12.5,
                        color: _FarmInk.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusLabel,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: selected ? _FarmInk.primary : _FarmInk.muted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemStatusBar extends StatelessWidget {
  const _SystemStatusBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _FarmInk.lightMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _FarmInk.mint.withValues(alpha: 0.9)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sensors_rounded,
            size: 18,
            color: _FarmInk.green,
          ),
          const SizedBox(width: 8),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: _FarmInk.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Hệ thống hoạt động bình thường',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _FarmInk.darkText,
              ),
            ),
          ),
          Text(
            'Cập nhật: vừa xong',
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: _FarmInk.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF087F5B),
                    Color(0xFF12A87A),
                    Color(0xFF35C997),
                  ],
                )
              : null,
          color: enabled ? null : const Color(0xFFD0E5DC),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: _FarmInk.green.withValues(alpha: 0.32),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: enabled ? Colors.white : _FarmInk.muted,
                    ),
                  ),
                  if (enabled) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardDecor extends StatelessWidget {
  const _CardDecor();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 140,
      child: Stack(
        children: [
          Positioned(
            right: 28,
            bottom: 40,
            child: Icon(
              Icons.eco_rounded,
              size: 40,
              color: _FarmInk.mintBright.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            right: 68,
            bottom: 28,
            child: Icon(
              Icons.eco_rounded,
              size: 26,
              color: _FarmInk.green.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            right: 36,
            bottom: 78,
            child: _Bubble(size: 9, opacity: 0.2),
          ),
          Positioned(
            right: 80,
            bottom: 58,
            child: _Bubble(size: 6, opacity: 0.16),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _FarmInk.mintBright.withValues(alpha: opacity),
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity + 0.08),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _FarmInk.mintBright.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.1,
        size.width * 0.55,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.9,
        size.width,
        size.height * 0.35,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// PNG nền đen → trong suốt (giống màn login).
class _KnockoutBlackImage extends StatelessWidget {
  const _KnockoutBlackImage({
    required this.asset,
    this.height,
  });

  final String asset;
  final double? height;

  static const _knockout = ColorFilter.matrix(<double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0.33, 0.5, 0.17, 0, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: _knockout,
      child: Image.asset(
        asset,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
