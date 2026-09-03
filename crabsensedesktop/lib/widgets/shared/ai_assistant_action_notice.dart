import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/dashboard_theme.dart';
import 'ai_assistant_avatar.dart';

/// Thông báo góc màn hình: mascot Crab Assistant + trạng thái thao tác.
abstract final class AiAssistantActionNotice {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context, {
    required String message,
    bool busy = false,
    bool success = false,
  }) {
    hide();
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (ctx) => Positioned(
        right: 24,
        bottom: 28,
        child: _ActionNoticeCard(
          message: message,
          busy: busy,
          success: success,
          onDismiss: busy ? null : hide,
        ),
      ),
    );
    overlay.insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }

  /// Hiện mascot khi đang chạy → thành công → tự ẩn sau [holdSuccess].
  static Future<T> run<T>(
    BuildContext context, {
    required Future<T> Function() action,
    required String busyMessage,
    required String successMessage,
    String Function(T result)? successFromResult,
    Duration holdSuccess = const Duration(milliseconds: 2400),
  }) async {
    if (!context.mounted) {
      return await action();
    }
    show(context, message: busyMessage, busy: true);
    try {
      final result = await action();
      if (context.mounted) {
        final done = successFromResult?.call(result) ?? successMessage;
        show(context, message: done, success: true);
        await Future<void>.delayed(holdSuccess);
        hide();
      }
      return result;
    } catch (e) {
      hide();
      rethrow;
    }
  }
}

class _ActionNoticeCard extends StatefulWidget {
  const _ActionNoticeCard({
    required this.message,
    required this.busy,
    required this.success,
    this.onDismiss,
  });

  final String message;
  final bool busy;
  final bool success;
  final VoidCallback? onDismiss;

  @override
  State<_ActionNoticeCard> createState() => _ActionNoticeCardState();
}

class _ActionNoticeCardState extends State<_ActionNoticeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void didUpdateWidget(_ActionNoticeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.busy && widget.success) {
      _controller.forward(from: 0.85);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.success
        ? DashboardColors.healthy.withValues(alpha: 0.55)
        : DashboardColors.purple.withValues(alpha: 0.45);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onDismiss,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: DashboardColors.card.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  DashboardColors.glowShadow,
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AiAssistantAvatar(
                    size: 56,
                    padding: const EdgeInsets.all(2),
                    background: DashboardColors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.success
                              ? 'Crab Assistant'
                              : 'Đang xử lý...',
                          style: GoogleFonts.notoSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: widget.success
                                ? DashboardColors.healthy
                                : DashboardColors.cyan,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.message,
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            height: 1.35,
                            color: DashboardColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (widget.busy)
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DashboardColors.purple,
                      ),
                    )
                  else if (widget.success)
                    Icon(
                      Icons.check_circle_rounded,
                      color: DashboardColors.healthy,
                      size: 24,
                    )
                  else if (widget.onDismiss != null)
                    IconButton(
                      onPressed: widget.onDismiss,
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: DashboardColors.textMuted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
