import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_env.dart';
import '../models/auth_models.dart';
import '../services/cloud_api_client.dart';
import '../services/cloud_auth_service.dart';
import '../services/theme_mode_service.dart';
import '../theme/dashboard_theme.dart';
import '../widgets/dashboard/wave_background.dart';
import '../widgets/shared/theme_mode_toggle.dart';
import 'main_shell_screen.dart';

class FarmSelectScreen extends StatefulWidget {
  const FarmSelectScreen({
    super.key,
    required this.token,
    required this.user,
  });

  final String token;
  final AuthUser user;

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
      final selected = _auth.resolveDefaultFarm(farms, me) ?? FarmSummary.unassigned;
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

  void _continue() {
    final me = _me;
    final farm = _selected;
    if (me == null || farm == null) return;

    final session = AuthSession(
      token: widget.token,
      user: me.user,
      farms: me.farms,
      selectedFarm: farm,
      isOrgAdmin: me.isOrgAdmin,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainShellScreen(session: session)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appThemeMode,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: DashboardColors.darkNavy,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const WaveBackground(),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: DashboardColors.textPrimary,
                            ),
                            tooltip: 'Quay lại',
                          ),
                          Image.asset(
                            'assets/images/logo.png',
                            height: 36,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Chọn trại',
                              style: GoogleFonts.notoSans(
                                color: DashboardColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const ThemeModeToggle(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: _FarmSelectCard(
                              loading: _loading,
                              error: _error,
                              user: widget.user,
                              me: _me,
                              selected: _selected,
                              onRetry: _loadMe,
                              onBack: () => Navigator.of(context).pop(),
                              onFarmChanged: (v) =>
                                  setState(() => _selected = v),
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
      },
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
  final ValueChanged<FarmSummary?> onFarmChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DashboardColors.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DashboardColors.purple.withValues(alpha: 0.35),
        ),
        boxShadow: [
          DashboardColors.glowShadow,
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (loading) {
      return SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            color: DashboardColors.purple,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 52,
            color: DashboardColors.risk.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 16),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              fontSize: 14,
              color: DashboardColors.textPrimary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DashboardColors.textMuted,
                    side: BorderSide(color: DashboardColors.cardBorder),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Quay lại',
                    style: GoogleFonts.notoSans(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AccentButton(
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            'assets/images/logo.png',
            height: 88,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Chọn khu nuôi',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: DashboardColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Xin chào, ${user.displayName}',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSans(
            fontSize: 14,
            color: DashboardColors.textMuted,
          ),
        ),
        if (payload.canViewAllFarms) ...[
          const SizedBox(height: 8),
          Text(
            'Quyền admin: xem và chuyển giữa ${payload.farms.length} trại trong tổ chức.',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: DashboardColors.cyan.withValues(alpha: 0.95),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: DashboardColors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: DashboardColors.cardBorder.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            'Cloud: ${AppEnv.cloudApiUrl}',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              fontSize: 10,
              color: DashboardColors.cyan.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Khu nuôi',
          style: GoogleFonts.notoSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: DashboardColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<FarmSummary>(
          value: selected,
          dropdownColor: DashboardColors.card,
          style: GoogleFonts.notoSans(
            fontSize: 14,
            color: DashboardColors.textPrimary,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: DashboardColors.textMuted,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: DashboardColors.darkNavy.withValues(alpha: 0.45),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: DashboardColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: DashboardColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: DashboardColors.purple,
                width: 1.5,
              ),
            ),
          ),
          items: payload.farms
              .map(
                (f) => DropdownMenuItem(
                  value: f,
                  child: Text(
                    f.toString(),
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onFarmChanged,
        ),
        const SizedBox(height: 28),
        _AccentButton(
          label: 'Vào hệ thống',
          onPressed: selected == null ? null : onContinue,
        ),
      ],
    );
  }
}

class _AccentButton extends StatelessWidget {
  const _AccentButton({
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
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? DashboardColors.accentGradient : null,
          color: enabled ? null : DashboardColors.cardBorder.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: DashboardColors.purple.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
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
              child: Text(
                label,
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? Colors.white
                      : DashboardColors.textMuted.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
