import 'package:flutter/material.dart';

import '../../../../core/utils/app_back.dart';
import '../../../home/presentation/widgets/home_palette.dart';

/// Shell chung cho các màn con của Tài khoản (cài đặt, bảo mật, trợ giúp, …).
class ProfileHubScaffold extends StatelessWidget {
  const ProfileHubScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.onRefresh,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final content = body;
    return Scaffold(
      backgroundColor: kHomeBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Row(
                children: [
                  _BackCircle(onTap: () => appBack(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kHomeTextMain,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  ...?actions,
                ],
              ),
            ),
            Expanded(
              child: onRefresh == null
                  ? content
                  : RefreshIndicator(
                      color: kHomePrimary,
                      backgroundColor: kHomeSurface,
                      onRefresh: onRefresh!,
                      child: content,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackCircle extends StatelessWidget {
  const _BackCircle({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kHomeSurface,
      shape: const CircleBorder(side: BorderSide(color: kHomeBorder)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 38,
          height: 38,
          child: Icon(Icons.arrow_back_rounded, color: kHomeTextMain, size: 20),
        ),
      ),
    );
  }
}

/// Card block dùng trong các màn con.
///
/// Bọc `Material` ở trong (thay vì chỉ `Container` có màu nền) để `ListTile`,
/// `SwitchListTile`, `ExpansionTile` bên trong vẫn vẽ được ink splash — nếu
/// không Flutter assert "ListTile background color or ink splashes may be
/// invisible" và hiệu ứng chạm bị che.
class HubCard extends StatelessWidget {
  const HubCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  static const double _radius = 16;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: kHomeShadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: kHomeSurface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
            side: const BorderSide(color: kHomeBorder),
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(14),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Nhãn nhóm nhỏ phía trên một [HubCard].
class HubSectionLabel extends StatelessWidget {
  const HubSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: kHomeTextHint,
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class HubTile extends StatelessWidget {
  const HubTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.trailing,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: kHomePrimaryBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: kHomePrimaryDark, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: kHomeTextMain,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                color: kHomeTextSub,
                                fontSize: 11.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                          if (value != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              value!,
                              style: const TextStyle(
                                color: kHomeSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (trailing != null)
                      trailing!
                    else if (onTap != null)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: kHomeTextHint,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 46, color: kHomeBorder),
      ],
    );
  }
}
