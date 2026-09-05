import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/farm_record.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';

String formatFarmDate(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d/$m/${local.year}';
}

class FarmOverviewCard extends StatelessWidget {
  const FarmOverviewCard({
    super.key,
    required this.farm,
    required this.onOpen,
    required this.onEdit,
    this.onDelete,
  });

  final FarmRecord farm;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏠  ${farm.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mã khu: ${farm.code}',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          _StatusChip(status: farm.status),
          const SizedBox(height: 12),
          _FactRow(
            icon: Icons.place_outlined,
            label: 'Vị trí',
            value: farm.displayLocation,
          ),
          const SizedBox(height: 8),
          _CardStats(farm: farm),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Chi tiết'),
              ),
              IconButton(
                tooltip: 'Sửa',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Xóa',
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: DashboardColors.risk.withValues(alpha: 0.9),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class FarmHeader extends StatelessWidget {
  const FarmHeader({super.key, required this.farm, this.large = false});

  final FarmRecord farm;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final titleSize = large ? 22.0 : 17.0;
    final hasPhoto = farm.avatarUrl != null && farm.avatarUrl!.trim().isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPhoto) ...[
          _FarmAvatar(url: farm.avatarUrl, size: large ? 56 : 44),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasPhoto ? farm.name : '🏠  ${farm.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mã khu: ${farm.code}',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              _StatusChip(status: farm.status),
            ],
          ),
        ),
      ],
    );
  }
}

class FarmDetailFacts extends StatelessWidget {
  const FarmDetailFacts({
    super.key,
    required this.farm,
    this.compact = false,
  });

  final FarmRecord farm;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final desc = farm.displayDescription;

    return Column(
      children: [
        _FactRow(icon: Icons.place_outlined, label: 'Vị trí', value: farm.displayLocation),
        _FactRow(icon: Icons.square_foot_outlined, label: 'Diện tích', value: farm.displayArea),
        if (!compact || desc != null)
          _FactRow(
            icon: Icons.notes_outlined,
            label: 'Mô tả',
            value: desc ?? '—',
            maxLines: compact ? 2 : 6,
          ),
      ],
    );
  }
}

class FarmOverviewStats extends StatelessWidget {
  const FarmOverviewStats({super.key, required this.farm});

  final FarmRecord farm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(emoji: '📐', label: 'Tổng dãy', value: farm.rowCount),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(emoji: '📦', label: 'Tổng hộp', value: farm.boxCount),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(emoji: '🦀', label: 'Tổng cua', value: farm.crabCount),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(
            emoji: '⚠️',
            label: 'Hộp cảnh báo',
            value: farm.alertBoxCount,
            color: farm.alertBoxCount > 0
                ? DashboardColors.warning
                : DashboardColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _CardStats extends StatelessWidget {
  const _CardStats({required this.farm});

  final FarmRecord farm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(emoji: '📦', label: 'Tổng hộp', value: farm.boxCount),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(emoji: '🦀', label: 'Tổng cua', value: farm.crabCount),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(
            emoji: '⚠️',
            label: 'Cảnh báo',
            value: farm.alertBoxCount,
            color: farm.alertBoxCount > 0
                ? DashboardColors.warning
                : DashboardColors.textMuted,
          ),
        ),
      ],
    );
  }
}

Future<void> showFarmDetailDialog(
  BuildContext context, {
  required FarmRecord farm,
  required VoidCallback onEdit,
  VoidCallback? onDelete,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              FarmHeader(farm: farm, large: true),
              const SizedBox(height: 18),
              Text(
                'Thông tin chi tiết',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              FarmDetailFacts(farm: farm),
              const SizedBox(height: 18),
              Text(
                'Thông tin tổng quan',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              FarmOverviewStats(farm: farm),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            onEdit();
          },
          child: const Text('Sửa'),
        ),
        if (onDelete != null)
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: Text('Xóa', style: TextStyle(color: DashboardColors.risk)),
          ),
      ],
    ),
  );
}

class _FarmAvatar extends StatelessWidget {
  const _FarmAvatar({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          url!.trim(),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: DashboardColors.darkNavy.withValues(alpha: 0.35),
            child: Center(
              child: Text('🏠', style: TextStyle(fontSize: size * 0.42)),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final FarmStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      FarmStatus.active => DashboardColors.healthy,
      FarmStatus.suspended => DashboardColors.warning,
      FarmStatus.closed => DashboardColors.dead,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '${status.emoji}  Trạng thái: ${status.label}',
        style: GoogleFonts.notoSans(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 2,
  });

  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: DashboardColors.textMuted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label  ',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.emoji,
    required this.label,
    required this.value,
    this.color,
  });

  final String emoji;
  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? DashboardColors.cyan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji  $label',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: GoogleFonts.notoSans(
              color: accent,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
