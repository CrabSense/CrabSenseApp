import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/dashboard_theme.dart';

/// Bộ widget dùng chung cho các màn quản trị (Quản lý khu / dãy / hộp…):
/// KPI card, ô tìm kiếm, dropdown pill, nút primary/outline, badge trạng thái,
/// mini-stat, phân trang. Style: Be Vietnam Pro + palette mint/emerald.

const kMgmtBlue = Color(0xFF2563EB);
const kMgmtAmber = Color(0xFFF5B700);
const kMgmtSlate = Color(0xFF94A3B8);

TextStyle bvText({
  double fontSize = 13,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) =>
    GoogleFonts.beVietnamPro(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

BoxDecoration mgmtCardDeco({double radius = 16}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: DashboardColors.cardBorder),
      boxShadow: [
        BoxShadow(
          color: DashboardColors.brand.withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );

String fmtDateTimeVn(DateTime? dt) {
  if (dt == null) return '—';
  final l = dt.isUtc ? dt.toLocal() : dt;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
}

// ── KPI card ────────────────────────────────────────────────────────────────

class MgmtKpiCard extends StatelessWidget {
  const MgmtKpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.suffix,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? suffix;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: mgmtCardDeco(radius: 16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: bvText(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: DashboardColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: bvText(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: DashboardColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    if (suffix != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        suffix!,
                        style: bvText(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search / dropdown / buttons ────────────────────────────────────────────

class MgmtSearchField extends StatelessWidget {
  const MgmtSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hint,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: bvText(color: DashboardColors.textPrimary, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: bvText(color: DashboardColors.textMuted, fontSize: 13),
        prefixIcon: Icon(Icons.search_rounded, size: 20, color: DashboardColors.textMuted),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: border(DashboardColors.cardBorder),
        enabledBorder: border(DashboardColors.cardBorder),
        focusedBorder: border(DashboardColors.brandGreen, 1.4),
      ),
    );
  }
}

class MgmtDropdown<T> extends StatelessWidget {
  const MgmtDropdown({
    super.key,
    required this.valueLabel,
    required this.items,
    required this.onSelected,
    this.width,
    this.leading,
  });

  final String valueLabel;
  final List<(T, String)> items;
  final ValueChanged<T> onSelected;
  final double? width;
  final IconData? leading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: PopupMenuButton<T>(
        tooltip: '',
        offset: const Offset(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        onSelected: onSelected,
        itemBuilder: (_) => [
          for (final (v, label) in items)
            PopupMenuItem<T>(
              value: v,
              height: 38,
              child: Text(
                label,
                style: bvText(fontSize: 13, color: DashboardColors.textPrimary),
              ),
            ),
        ],
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DashboardColors.cardBorder),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                Icon(leading, size: 17, color: DashboardColors.brand),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  valueLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bvText(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: DashboardColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Sắp xếp: Mới nhất ⌄" — popup nhỏ không viền.
class MgmtInlineSort<T> extends StatelessWidget {
  const MgmtInlineSort({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = items
        .where((e) => e.$1 == value)
        .map((e) => e.$2)
        .firstOrNull ??
        '';
    return PopupMenuButton<T>(
      tooltip: '',
      offset: const Offset(0, 30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final (v, label) in items)
          PopupMenuItem<T>(
            value: v,
            height: 36,
            child: Text(
              label,
              style: bvText(
                fontSize: 13,
                fontWeight: v == value ? FontWeight.w700 : FontWeight.w500,
                color: v == value
                    ? DashboardColors.brand
                    : DashboardColors.textPrimary,
              ),
            ),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sắp xếp: ',
            style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
          ),
          Text(
            current,
            style: bvText(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: DashboardColors.textPrimary,
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: DashboardColors.textMuted),
        ],
      ),
    );
  }
}

class MgmtPrimaryButton extends StatelessWidget {
  const MgmtPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.trailing,
    this.height = 42,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final IconData? trailing;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: DashboardColors.brand,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: DashboardColors.brand.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: bvText(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 6),
                  Icon(trailing, size: 16, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MgmtOutlineButton extends StatelessWidget {
  const MgmtOutlineButton({
    super.key,
    required this.onTap,
    this.label,
    this.icon,
    this.color = DashboardColors.brand,
    this.borderColor,
    this.tooltip,
    this.height = 38,
  });

  final VoidCallback? onTap;
  final String? label;
  final IconData? icon;
  final Color color;
  final Color? borderColor;
  final String? tooltip;
  final double height;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: label == null ? 10 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor ?? color.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 17, color: color),
              if (icon != null && label != null) const SizedBox(width: 6),
              if (label != null)
                Text(
                  label!,
                  style: bvText(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (tooltip == null) return child;
    return Tooltip(message: tooltip!, child: child);
  }
}

/// Nút icon vuông nhỏ (toggle grid/list view).
class MgmtIconToggle extends StatelessWidget {
  const MgmtIconToggle({
    super.key,
    required this.icon,
    required this.active,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final w = Material(
      color: active ? DashboardColors.brand : Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: active ? DashboardColors.brand : DashboardColors.cardBorder,
            ),
          ),
          child: Icon(icon, size: 17,
              color: active ? Colors.white : DashboardColors.textMuted),
        ),
      ),
    );
    return tooltip == null ? w : Tooltip(message: tooltip!, child: w);
  }
}

// ── Badge / mini stat ──────────────────────────────────────────────────────

class MgmtStatusBadge extends StatelessWidget {
  const MgmtStatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: bvText(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class MgmtMiniStatData {
  const MgmtMiniStatData(this.icon, this.label, this.value, this.pct, this.color);
  final IconData icon;
  final String label;
  final String value;

  /// "(92%)" nhạt hơn số chính; null = không hiển thị.
  final String? pct;
  final Color color;
}

class MgmtMiniStat extends StatelessWidget {
  const MgmtMiniStat({super.key, required this.data, this.height = 52});

  final MgmtMiniStatData data;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(data.icon, size: 16, color: data.color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bvText(fontSize: 11, color: DashboardColors.textMuted),
                ),
                const SizedBox(height: 1),
                Text.rich(
                  TextSpan(
                    text: data.value,
                    style: bvText(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: DashboardColors.textPrimary,
                    ),
                    children: [
                      if (data.pct != null)
                        TextSpan(
                          text: ' (${data.pct})',
                          style: bvText(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: DashboardColors.textPrimary
                                .withValues(alpha: 0.75),
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dòng trạng thái gọn: ● Bình thường 7 (chấm màu + nhãn + số đậm).
class MgmtDotStat extends StatelessWidget {
  const MgmtDotStat({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Icon(Icons.check, size: 10, color: Colors.white),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: bvText(fontSize: 10.5, color: DashboardColors.textMuted),
            ),
            Text(
              value,
              style: bvText(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: DashboardColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Progress "Mức sử dụng hộp" — nhãn trái, % phải, thanh emerald.
class MgmtUsageBar extends StatelessWidget {
  const MgmtUsageBar({
    super.key,
    required this.usage,
    required this.trailing,
    this.label = 'Mức sử dụng hộp',
    this.height = 8,
  });

  final double usage;
  final String trailing;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(label,
                style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
            const Spacer(),
            Text(
              trailing,
              style: bvText(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: DashboardColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Container(color: DashboardColors.mint),
                FractionallySizedBox(
                  widthFactor: usage.clamp(0.0, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [DashboardColors.brand, DashboardColors.brandGreen],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Pagination ─────────────────────────────────────────────────────────────

class MgmtPagination extends StatelessWidget {
  const MgmtPagination({
    super.key,
    required this.page,
    required this.totalPages,
    required this.start,
    required this.end,
    required this.total,
    required this.onPage,
    this.itemLabel = 'mục',
  });

  final int page;
  final int totalPages;
  final int start;
  final int end;
  final int total;
  final ValueChanged<int> onPage;
  final String itemLabel;

  @override
  Widget build(BuildContext context) {
    final pages = totalPages.clamp(1, 99);
    return Row(
      children: [
        Text(
          total == 0
              ? 'Không có $itemLabel'
              : 'Hiển thị $start–$end của $total $itemLabel',
          style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
        ),
        const Spacer(),
        MgmtPageBtn(
          icon: Icons.chevron_left_rounded,
          onTap: page > 0 ? () => onPage(page - 1) : null,
        ),
        for (var i = 0; i < pages; i++) ...[
          const SizedBox(width: 6),
          MgmtPageBtn(
            label: '${i + 1}',
            active: i == page,
            onTap: () => onPage(i),
          ),
        ],
        const SizedBox(width: 6),
        MgmtPageBtn(
          icon: Icons.chevron_right_rounded,
          onTap: page < pages - 1 ? () => onPage(page + 1) : null,
        ),
      ],
    );
  }
}

class MgmtPageBtn extends StatelessWidget {
  const MgmtPageBtn({
    super.key,
    this.label,
    this.icon,
    this.active = false,
    this.onTap,
  });

  final String? label;
  final IconData? icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: active ? DashboardColors.brand : Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: active ? DashboardColors.brand : DashboardColors.cardBorder,
            ),
          ),
          child: icon != null
              ? Icon(
                  icon, size: 18,
                  color: enabled
                      ? DashboardColors.textPrimary
                      : DashboardColors.textMuted.withValues(alpha: 0.5),
                )
              : Text(
                  label!,
                  style: bvText(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : DashboardColors.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Trang trống (chưa có dữ liệu / lọc không khớp).
class MgmtEmptyState extends StatelessWidget {
  const MgmtEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44),
      decoration: mgmtCardDeco(radius: 18),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: DashboardColors.mint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 26, color: DashboardColors.brand),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: bvText(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            action!,
          ],
        ],
      ),
    );
  }
}
