import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';

/// A 2x2 grid of action buttons for a crab farming box.
///
/// Buttons shown: Capture Video, Manual Inspection, Harvest, Quick Sale.
/// Each button is enabled or disabled based on the current user's [UserRole].
/// Disabled buttons remain visible with reduced opacity and a [Tooltip]
/// explaining the required permission (Req 19.6, 19.8).
///
/// Requirements: 4.6, 19.1-19.10
class BoxActionPanel extends StatelessWidget {
  const BoxActionPanel({required this.boxId, this.farmId, super.key});

  /// The unique identifier of the box. Used to build navigation paths.
  final String boxId;

  /// Optional farming area id for water / sales scoping.
  final String? farmId;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final role = authState is Authenticated
        ? authState.user.role
        : UserRole.viewer;

    final canField = role.canPerformFieldOperations;
    final canSales = role.canManageSales;

    const fieldPermMsg = 'Requires Field Operator or higher';
    const salesPermMsg = 'Requires Sales role or higher';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _ActionTile(
          icon: Icons.videocam_outlined,
          label: 'Capture Video',
          color: CrabSenseColors.info,
          enabled: canField,
          disabledMessage: fieldPermMsg,
          onTap: canField
              ? () => context.go(RoutePaths.boxVideo(boxId))
              : null,
        ),
        _ActionTile(
          icon: Icons.manage_search_outlined,
          label: 'Manual Inspection',
          color: CrabSenseColors.primary,
          enabled: canField,
          disabledMessage: fieldPermMsg,
          onTap: canField
              ? () => context.go(RoutePaths.boxInspect(boxId))
              : null,
        ),
        _ActionTile(
          icon: Icons.inventory_2_outlined,
          label: 'Harvest',
          color: CrabSenseColors.success,
          enabled: canField,
          disabledMessage: fieldPermMsg,
          onTap: canField
              ? () => context.go(RoutePaths.harvest, extra: boxId)
              : null,
        ),
        _ActionTile(
          icon: Icons.point_of_sale_outlined,
          label: 'Quick Sale',
          color: CrabSenseColors.warning,
          enabled: canSales,
          disabledMessage: salesPermMsg,
          onTap: canSales
              ? () => context.go(RoutePaths.salesForBox(boxId))
              : null,
        ),
      ],
    );
  }
}

// Private tile widget

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
    final theme = Theme.of(context);

    final tile = Material(
      color: color.withValues(alpha: enabled ? 0.1 : 0.05),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(
                alpha: enabled ? 0.3 : 0.1,
              ),
            ),
          ),
          child: Opacity(
            opacity: enabled ? 1.0 : 0.4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
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
