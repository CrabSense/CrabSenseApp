import 'package:flutter/material.dart';

import '../../services/notification_center_service.dart';
import '../../theme/dashboard_theme.dart';

/// Mở Notification Center dạng panel trượt từ phải.
Future<void> showNotificationCenter(
  BuildContext context,
  NotificationCenterService service, {
  VoidCallback? onOpenAlerts,
}) {
  service.load();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Thông báo',
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => Align(
      alignment: Alignment.centerRight,
      child: _NotificationCenterPanel(
        service: service,
        onOpenAlerts: onOpenAlerts,
      ),
    ),
    transitionBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

class _NotificationCenterPanel extends StatelessWidget {
  const _NotificationCenterPanel({
    required this.service,
    this.onOpenAlerts,
  });

  final NotificationCenterService service;
  final VoidCallback? onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 420,
        height: double.infinity,
        decoration: BoxDecoration(
          color: DashboardColors.card,
          border: Border(left: BorderSide(color: DashboardColors.cardBorder)),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: service,
            builder: (context, _) {
              final items = service.items;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(context, service.unreadCount),
                  const Divider(height: 1),
                  Expanded(child: _body(context, items)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, int unread) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Text(
            'Thông báo',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: DashboardColors.textPrimary,
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: DashboardColors.risk,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (unread > 0)
            TextButton(
              onPressed: service.markAllRead,
              child: const Text('Đọc tất cả'),
            ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded,
                size: 20, color: DashboardColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, List<AppNotification> items) {
    if (service.loading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (service.error != null && items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                service.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: DashboardColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: service.load,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 48, color: DashboardColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Chưa có thông báo nào',
              style: TextStyle(color: DashboardColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 20, endIndent: 20),
      itemBuilder: (context, i) => _tile(context, items[i]),
    );
  }

  Widget _tile(BuildContext context, AppNotification n) {
    final hasAlert = n.alertId != null && n.alertId!.isNotEmpty;
    return InkWell(
      onTap: () {
        service.markRead(n);
        if (hasAlert && onOpenAlerts != null) {
          Navigator.of(context).pop();
          onOpenAlerts!();
        }
      },
      child: Container(
        color: n.isRead ? null : DashboardColors.brand.withValues(alpha: 0.04),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: n.isRead
                      ? Colors.transparent
                      : DashboardColors.brand,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          n.isRead ? FontWeight.w500 : FontWeight.w700,
                      color: DashboardColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: DashboardColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _timeLabel(n.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: DashboardColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _timeLabel(DateTime? at) {
    if (at == null) return '';
    final t = at.toLocal();
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
  }
}
