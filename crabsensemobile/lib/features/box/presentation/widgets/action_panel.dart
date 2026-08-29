import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../home/presentation/widgets/home_palette.dart';

/// Lưới 2×2 thao tác nhanh trên màn chi tiết Box.
class BoxActionPanel extends StatelessWidget {
  const BoxActionPanel({required this.boxId, this.farmId, super.key});

  final String boxId;
  final String? farmId;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final role =
        authState is Authenticated ? authState.user.role : UserRole.viewer;

    final canField = role.canPerformFieldOperations;
    final canSales = role.canManageSales;

    const fieldPermMsg = 'Cần quyền Field Operator trở lên';
    const salesPermMsg = 'Cần quyền Sales trở lên';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 16,
              color: kHomeBlueLight,
              shadows: [
                Shadow(
                  color: kHomeBlueLight.withValues(alpha: 0.8),
                  blurRadius: 10,
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Text(
              'THAO TÁC NHANH',
              style: TextStyle(
                color: kHomePrimaryDark,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            _ActionTile(
              icon: Icons.videocam_rounded,
              label: 'Quay video AI',
              color: kHomeCyan,
              enabled: canField,
              disabledMessage: fieldPermMsg,
              onTap: canField
                  ? () => context.go(RoutePaths.boxVideo(boxId))
                  : null,
            ),
            _ActionTile(
              icon: Icons.manage_search_rounded,
              label: 'Kiểm tra tay',
              color: kHomeBlueLight,
              enabled: canField,
              disabledMessage: fieldPermMsg,
              onTap: canField
                  ? () => context.go(RoutePaths.boxInspect(boxId))
                  : null,
            ),
            _ActionTile(
              icon: Icons.inventory_2_rounded,
              label: 'Thu hoạch',
              color: kHomeGreen,
              enabled: canField,
              disabledMessage: fieldPermMsg,
              onTap: canField
                  ? () => context.go(RoutePaths.harvest, extra: boxId)
                  : null,
            ),
            _ActionTile(
              icon: Icons.point_of_sale_rounded,
              label: 'Bán nhanh',
              color: kHomeOrange,
              enabled: canSales,
              disabledMessage: salesPermMsg,
              onTap: canSales
                  ? () => context.go(RoutePaths.salesForBox(boxId))
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.disabledMessage,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final String disabledMessage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kHomeSurface, kHomeBg, kHomeBg],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: enabled ? 0.55 : 0.2),
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Opacity(
            opacity: enabled ? 1.0 : 0.4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.45)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!enabled) {
      return Tooltip(message: disabledMessage, child: tile);
    }
    return tile;
  }
}
