import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'crab_management_palette.dart';

// ── Empty (no crabs at all) ───────────────────────────────────────────────────

class CrabEmptyState extends StatelessWidget {
  const CrabEmptyState({
    required this.onAddCrab,
    required this.onImportBatch,
    super.key,
  });
  final VoidCallback onAddCrab;
  final VoidCallback onImportBatch;

  @override
  Widget build(BuildContext context) => _StateBase(
    emoji: '🦀',
    title: 'Chưa có cua trong hệ thống',
    subtitle:
        'Các cá thể cua sau khi nhập lô hoặc thêm thủ công\nsẽ xuất hiện tại đây.',
    actions: [
      OutlinedButton.icon(
        onPressed: onImportBatch,
        icon: const Icon(Icons.upload_rounded, size: 15),
        label: Text(
          'Nhập lô',
          style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: kCmPrimaryDark,
          side: const BorderSide(color: kCmBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      const SizedBox(width: 10),
      ElevatedButton.icon(
        onPressed: onAddCrab,
        icon: const Icon(Icons.add_rounded, size: 15),
        label: Text(
          '+ Thêm cua',
          style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kCmPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    ],
  );
}

// ── No results (filtered) ─────────────────────────────────────────────────────

class CrabNoResultState extends StatelessWidget {
  const CrabNoResultState({required this.onClearFilter, super.key});
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) => _StateBase(
    emoji: '🔍',
    title: 'Không tìm thấy cua',
    subtitle: 'Không có cá thể nào phù hợp với bộ lọc hiện tại.',
    actions: [
      ElevatedButton.icon(
        onPressed: onClearFilter,
        icon: const Icon(Icons.filter_alt_off_rounded, size: 15),
        label: Text(
          'Xóa bộ lọc',
          style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kCmPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    ],
  );
}

// ── Error state ───────────────────────────────────────────────────────────────

class CrabErrorState extends StatelessWidget {
  const CrabErrorState({required this.onRetry, super.key, this.message});
  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) => _StateBase(
    emoji: '⚠',
    title: 'Không thể tải danh sách cua.',
    subtitle: message ?? 'Vui lòng thử lại.',
    emojiSize: 36,
    actions: [
      ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 15),
        label: Text(
          'Thử lại',
          style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kCmPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    ],
  );
}

// ── Table skeleton rows ───────────────────────────────────────────────────────

class CrabTableSkeleton extends StatelessWidget {
  const CrabTableSkeleton({super.key, this.rows = 8});
  final int rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCmSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kCmBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header skeleton
          Container(height: 38, color: kCmMintBg),
          const Divider(height: 1, color: kCmBorder),
          ...List.generate(
            rows,
            (i) => Column(
              children: [
                _SkeletonRow(light: i.isEven),
                const Divider(height: 1, color: kCmBorder),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatefulWidget {
  const _SkeletonRow({this.light = true});
  final bool light;
  @override
  State<_SkeletonRow> createState() => _SkeletonRowState();
}

class _SkeletonRowState extends State<_SkeletonRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, _) {
        final base = widget.light
            ? kCmSurface
            : kCmMintBg.withValues(alpha: 0.5);
        final highlight = kCmPrimary.withValues(alpha: 0.06);
        return Container(
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              stops: [
                (_anim.value - 0.3).clamp(0.0, 1.0),
                _anim.value.clamp(0.0, 1.0),
                (_anim.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

// ── Base state layout ─────────────────────────────────────────────────────────

class _StateBase extends StatelessWidget {
  const _StateBase({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.emojiSize = 48,
  });
  final String emoji;
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final double emojiSize;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: TextStyle(fontSize: emojiSize)),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: kCmTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: kCmTextSecondary,
            height: 1.5,
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: actions),
        ],
      ],
    ),
  );
}
