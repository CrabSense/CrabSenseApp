import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../home/presentation/widgets/crab_hologram_painter.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../providers/profile_provider.dart';

/// Màn chỉnh sửa hồ sơ — PUT /auth/me.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _empCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileStateProvider).valueOrNull?.profile;
    _nameCtrl = TextEditingController(text: p?.fullName ?? '');
    _emailCtrl = TextEditingController(text: p?.email ?? '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _empCtrl = TextEditingController(text: p?.employeeId ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _empCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            fullName: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            employeeId: _empCtrl.text.trim(),
          );
      await ref.read(profileStateProvider.notifier).loadData(forceRefresh: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật hồ sơ')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                          'CHỈNH SỬA HỒ SƠ',
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
                      decoration: homeCardDecoration(radius: 18, glowAlpha: 0.12),
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
                                  _field(
                                    controller: _nameCtrl,
                                    label: 'Họ và tên',
                                    icon: Icons.person_outline_rounded,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Nhập họ tên'
                                            : null,
                                  ),
                                  const SizedBox(height: 12),
                                  _field(
                                    controller: _emailCtrl,
                                    label: 'Email',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Nhập email';
                                      }
                                      if (!v.contains('@')) {
                                        return 'Email không hợp lệ';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _field(
                                    controller: _phoneCtrl,
                                    label: 'Số điện thoại',
                                    icon: Icons.phone_android_rounded,
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 12),
                                  _field(
                                    controller: _empCtrl,
                                    label: 'Mã nhân viên',
                                    icon: Icons.badge_outlined,
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
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Lưu thay đổi',
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: kHomeCyan, size: 20),
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
