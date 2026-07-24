import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../authentication/domain/repositories/auth_repository.dart';
import '../../../home/presentation/widgets/crab_hologram_painter.dart';
import '../../../home/presentation/widgets/home_palette.dart';

/// Đổi mật khẩu — POST /auth/change-password.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = await sl<AuthRepository>().changePassword(
      currentPassword: _currentCtrl.text,
      newPassword: _newCtrl.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đổi mật khẩu thành công')),
        );
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: kHomeBlueLight,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'ĐỔI MẬT KHẨU',
                          style: TextStyle(
                            color: kHomeBlueLight,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Container(
                      decoration:
                          homeCardDecoration(radius: 18, glowAlpha: 0.12),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          const HomeCrabWatermark(alpha: 0.05, trayExtent: 24),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _pwdField(
                                    controller: _currentCtrl,
                                    label: 'Mật khẩu hiện tại',
                                    obscure: _obscureCurrent,
                                    onToggle: () => setState(
                                      () =>
                                          _obscureCurrent = !_obscureCurrent,
                                    ),
                                    validator: (v) =>
                                        (v == null || v.isEmpty)
                                            ? 'Nhập mật khẩu hiện tại'
                                            : null,
                                  ),
                                  const SizedBox(height: 12),
                                  _pwdField(
                                    controller: _newCtrl,
                                    label: 'Mật khẩu mới',
                                    obscure: _obscureNew,
                                    onToggle: () => setState(
                                      () => _obscureNew = !_obscureNew,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.length < 6) {
                                        return 'Ít nhất 6 ký tự';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _pwdField(
                                    controller: _confirmCtrl,
                                    label: 'Xác nhận mật khẩu mới',
                                    obscure: _obscureConfirm,
                                    onToggle: () => setState(
                                      () =>
                                          _obscureConfirm = !_obscureConfirm,
                                    ),
                                    validator: (v) {
                                      if (v != _newCtrl.text) {
                                        return 'Mật khẩu xác nhận không khớp';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: FilledButton(
                                      onPressed: _saving ? null : _save,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: kHomeCyan,
                                        foregroundColor: kHomeNavyDeep,
                                      ),
                                      child: _saving
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Đổi mật khẩu',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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

  Widget _pwdField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: kHomeCyan),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.white54,
          ),
        ),
        filled: true,
        fillColor: kHomeNavyDeep.withValues(alpha: 0.65),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kHomeBorderBlue.withValues(alpha: 0.45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kHomeBorderBlue.withValues(alpha: 0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kHomeCyan),
        ),
      ),
    );
  }
}
