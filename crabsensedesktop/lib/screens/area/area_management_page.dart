import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/area_status.dart';
import '../../models/production_models.dart';
import '../../navigation/app_route.dart';
import '../../services/area_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/area/area_form_dialog.dart';
import '../../widgets/production/production_dialogs.dart'
    show confirmDelete, deleteAreaFlow;

const _kThumbFallback = 'assets/images/maps.png';
const _kBlue = Color(0xFF2563EB);
const _kAmber = Color(0xFFF5B700);
const _kSlate = Color(0xFF94A3B8);

TextStyle _bv({
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

enum _AreaSort { newest, oldest, nameAz, mostBoxes }

extension on _AreaSort {
  String get label => switch (this) {
        _AreaSort.newest => 'Mới nhất',
        _AreaSort.oldest => 'Cũ nhất',
        _AreaSort.nameAz => 'Tên A → Z',
        _AreaSort.mostBoxes => 'Nhiều hộp nhất',
      };
}

/// Quản lý khu — danh sách khu nuôi dạng card ngang (không phải bản đồ trại).
class AreaManagementPage extends StatefulWidget {
  const AreaManagementPage({
    super.key,
    required this.service,
    this.onNavigate,
    this.onOpenDetail,
    this.onViewRows,
  });

  final AreaManagementService service;
  final void Function(AppRoute route)? onNavigate;
  final void Function(AreaRecord area)? onOpenDetail;

  /// "Xem dãy →": mở Quản lý dãy đã lọc theo khu.
  final void Function(AreaRecord area)? onViewRows;

  @override
  State<AreaManagementPage> createState() => _AreaManagementPageState();
}

class _AreaManagementPageState extends State<AreaManagementPage> {
  final _searchCtrl = TextEditingController();
  _AreaSort _sort = _AreaSort.newest;

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    _searchCtrl.text = widget.service.search;
    if (!widget.service.loading && widget.service.areas.isEmpty) {
      widget.service.load();
    }
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    if (_searchCtrl.text != widget.service.search) {
      _searchCtrl.text = widget.service.search;
    }
    setState(() {});
  }

  List<AreaRecord> _sorted(List<AreaRecord> list) {
    final out = [...list];
    int byDate(AreaRecord a, AreaRecord b) {
      final da = a.updatedAt ?? a.createdAt;
      final db = b.updatedAt ?? b.createdAt;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    }

    switch (_sort) {
      case _AreaSort.newest:
        out.sort(byDate);
      case _AreaSort.oldest:
        out.sort((a, b) => byDate(b, a));
      case _AreaSort.nameAz:
        out.sort((a, b) =>
            a.areaName.toLowerCase().compareTo(b.areaName.toLowerCase()));
      case _AreaSort.mostBoxes:
        out.sort((a, b) => b.boxCount.compareTo(a.boxCount));
    }
    return out;
  }

  Future<void> _edit(AreaRecord a) =>
      showAreaFormDialog(context, widget.service, existing: a);

  Future<void> _delete(AreaRecord a) async {
    final svc = widget.service;
    if (!await confirmDelete(
      context,
      title: 'Xóa khu?',
      message: '${a.areaName} (${a.areaCode})?',
    )) {
      return;
    }
    if (!mounted) return;
    await deleteAreaFlow(
      context,
      areaName: a.areaName,
      remove: ({bool cascade = false}) => svc.deleteArea(a, cascade: cascade),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    final filtered = _sorted(svc.filteredAreas);
    const pageSize = AreaManagementService.pageSize;
    final totalPages = filtered.isEmpty ? 1 : (filtered.length + pageSize - 1) ~/ pageSize;
    final page = svc.page.clamp(0, totalPages - 1);
    final start = page * pageSize;
    final items = filtered.isEmpty
        ? const <AreaRecord>[]
        : filtered.sublist(start, (start + pageSize).clamp(0, filtered.length));

    final s = svc.summary;
    final totalRows = svc.areas.fold<int>(0, (sum, a) => sum + a.rowCount);
    final activePct = s.total == 0 ? 0 : (s.active * 100 / s.total).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── KPI ───────────────────────────────────────────────────────
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 1100 ? 4 : (c.maxWidth >= 620 ? 2 : 1);
              final gap = 16.0;
              final w = (c.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: w,
                    child: _KpiCard(
                      icon: Icons.apartment_outlined,
                      label: 'Tổng khu',
                      value: '${s.total}',
                      color: DashboardColors.brand,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: _KpiCard(
                      icon: Icons.check_circle_rounded,
                      label: 'Đang hoạt động',
                      value: '${s.active}',
                      suffix: s.total == 0 ? null : '($activePct%)',
                      color: DashboardColors.brandGreen,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: _KpiCard(
                      icon: Icons.grid_view_outlined,
                      label: 'Tổng dãy',
                      value: '$totalRows',
                      color: DashboardColors.brand,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: _KpiCard(
                      icon: Icons.inventory_2_outlined,
                      label: 'Tổng hộp',
                      value: '${s.totalBoxes}',
                      color: _kBlue,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // ── Search + filter + add ─────────────────────────────────────
          LayoutBuilder(
            builder: (context, c) {
              final stacked = c.maxWidth < 760;
              final search = _SearchField(
                controller: _searchCtrl,
                onChanged: svc.setSearch,
              );
              final controls = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Dropdown<AreaStatusFilter>(
                    width: 200,
                    valueLabel: svc.statusFilter == AreaStatusFilter.all
                        ? 'Tất cả trạng thái'
                        : svc.statusFilter.label,
                    items: [
                      for (final f in AreaStatusFilter.values)
                        (
                          f,
                          f == AreaStatusFilter.all
                              ? 'Tất cả trạng thái'
                              : f.label
                        ),
                    ],
                    onSelected: svc.setStatusFilter,
                  ),
                  const SizedBox(width: 12),
                  _PrimaryButton(
                    icon: Icons.add_rounded,
                    label: 'Thêm khu',
                    onTap: svc.loading
                        ? null
                        : () => showAreaFormDialog(context, svc),
                  ),
                ],
              );
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    search,
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: controls),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 12),
                  controls,
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // ── List header ──────────────────────────────────────────────
          Row(
            children: [
              Text(
                'Danh sách khu (${filtered.length})',
                style: _bv(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Sắp xếp: ',
                style: _bv(fontSize: 12.5, color: DashboardColors.textMuted),
              ),
              _InlineSort(
                value: _sort,
                onChanged: (v) => setState(() => _sort = v),
              ),
              if (!svc.loading) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Tải lại',
                  onPressed: svc.load,
                  iconSize: 18,
                  splashRadius: 18,
                  icon: Icon(Icons.refresh_rounded,
                      color: DashboardColors.textMuted),
                ),
              ],
            ],
          ),
          if (svc.error != null) ...[
            const SizedBox(height: 8),
            Text(
              svc.error!,
              style: _bv(color: DashboardColors.risk, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 12),

          // ── Cards ────────────────────────────────────────────────────
          if (svc.loading && svc.areas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: DashboardColors.brand,
                  ),
                ),
              ),
            )
          else if (items.isEmpty)
            _EmptyState(
              onAdd: () => showAreaFormDialog(context, svc),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              _AreaCard(
                area: items[i],
                onDetail: () => widget.onOpenDetail?.call(items[i]),
                onViewRows: widget.onViewRows == null
                    ? null
                    : () => widget.onViewRows!(items[i]),
                onEdit: () => _edit(items[i]),
                onDelete: () => _delete(items[i]),
              ),
              if (i != items.length - 1) const SizedBox(height: 16),
            ],
          const SizedBox(height: 18),

          // ── Pagination ───────────────────────────────────────────────
          _Pagination(
            page: page,
            totalPages: totalPages,
            start: filtered.isEmpty ? 0 : start + 1,
            end: filtered.isEmpty ? 0 : start + items.length,
            total: filtered.length,
            onPage: svc.setPage,
          ),
        ],
      ),
    );
  }
}

// ── KPI card ────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
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
      decoration: _cardDeco(radius: 16),
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
                  style: _bv(
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
                      style: _bv(
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
                        style: _bv(
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: _bv(color: DashboardColors.textPrimary, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: 'Tìm kiếm theo tên khu, mã khu...',
        hintStyle: _bv(color: DashboardColors.textMuted, fontSize: 13),
        prefixIcon: Icon(Icons.search_rounded,
            size: 20, color: DashboardColors.textMuted),
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

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.valueLabel,
    required this.items,
    required this.onSelected,
    this.width,
  });

  final String valueLabel;
  final List<(T, String)> items;
  final ValueChanged<T> onSelected;
  final double? width;

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
                style: _bv(fontSize: 13, color: DashboardColors.textPrimary),
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
              Expanded(
                child: Text(
                  valueLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _bv(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: DashboardColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineSort extends StatelessWidget {
  const _InlineSort({required this.value, required this.onChanged});

  final _AreaSort value;
  final ValueChanged<_AreaSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AreaSort>(
      tooltip: '',
      offset: const Offset(0, 30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final s in _AreaSort.values)
          PopupMenuItem(
            value: s,
            height: 36,
            child: Text(
              s.label,
              style: _bv(
                fontSize: 13,
                fontWeight: s == value ? FontWeight.w700 : FontWeight.w500,
                color: s == value
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
            value.label,
            style: _bv(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: DashboardColors.textPrimary,
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: DashboardColors.textMuted),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
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
                  style: _bv(
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

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.onTap,
    this.label,
    this.icon,
    this.color = DashboardColors.brand,
    this.borderColor,
    this.tooltip,
  });

  final VoidCallback? onTap;
  final String? label;
  final IconData? icon;
  final Color color;
  final Color? borderColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
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
                  style: _bv(
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

// ── Area card ──────────────────────────────────────────────────────────────

class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.area,
    required this.onDetail,
    required this.onEdit,
    required this.onDelete,
    this.onViewRows,
  });

  final AreaRecord area;
  final VoidCallback onDetail;
  final VoidCallback? onViewRows;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String get _title {
    final n = area.areaName.trim();
    if (n.isEmpty) return area.areaCode;
    // "A" → "Khu A"; tên đã có chữ "Khu" giữ nguyên.
    if (n.toLowerCase().startsWith('khu')) return n;
    return 'Khu $n';
  }

  String? get _placeName => area.placeName;

  @override
  Widget build(BuildContext context) {
    final total = area.boxCount;
    final occupied = area.occupiedBoxCount > 0
        ? area.occupiedBoxCount
        : (area.crabCount.clamp(0, total));
    final usage = total == 0 ? 0.0 : occupied / total;
    final usagePct = (usage * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(radius: 18),
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 900;
          const thumbW = 250.0;
          const gapW = 18.0;
          // Bề rộng phần info được tính sẵn ở đây (thay cho LayoutBuilder bên
          // trong) vì IntrinsicHeight không lấy được intrinsic size từ LayoutBuilder.
          final infoWidth = narrow ? c.maxWidth : c.maxWidth - thumbW - gapW;
          final info =
              _buildInfo(context, infoWidth, total, occupied, usage, usagePct);
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Thumbnail(
                  url: area.avatarUrl,
                  width: double.infinity,
                  height: 170,
                ),
                const SizedBox(height: 14),
                info,
              ],
            );
          }
          // Thumbnail ~250px, cao bằng phần thông tin (≈176px) → card không quá cao,
          // 1920×1080 vẫn thấy đủ 2 khu.
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Thumbnail(
                  url: area.avatarUrl,
                  width: thumbW,
                  height: double.infinity,
                ),
                const SizedBox(width: gapW),
                Expanded(child: info),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfo(
    BuildContext context,
    double infoWidth,
    int total,
    int occupied,
    double usage,
    int usagePct,
  ) {
    final compact = infoWidth < 620;
    final status = area.status;
    final statusLabel = switch (status) {
      'maintenance' => 'Bảo trì',
      'disabled' => 'Ngưng sử dụng',
      _ => 'Đang hoạt động',
    };
    final statusColor = switch (status) {
      'maintenance' => _kAmber,
      'disabled' => _kSlate,
      _ => DashboardColors.brandGreen,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row: title + badge | usage
        Builder(
          builder: (context) {
            final left = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.home_rounded,
                        size: 20, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _bv(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusBadge(label: statusLabel, color: statusColor),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      'Mã khu: ',
                      style: _bv(
                          fontSize: 12.5, color: DashboardColors.textMuted),
                    ),
                    Text(
                      area.areaCode,
                      style: _bv(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                    if (_placeName != null) ...[
                      Container(
                        width: 1,
                        height: 12,
                        color: DashboardColors.cardBorder,
                      ),
                      Text(
                        _placeName!,
                        style: _bv(
                          fontSize: 12.5,
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
                if ((area.location ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: DashboardColors.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Vị trí: ${area.location!.trim()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _bv(
                            fontSize: 12.5,
                            color: DashboardColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
            final right = _UsageBlock(
              occupied: occupied,
              total: total,
              usage: usage,
              pct: usagePct,
              width: compact ? double.infinity : 260,
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [left, const SizedBox(height: 10), right],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                const SizedBox(width: 16),
                right,
              ],
            );
          },
        ),
        const SizedBox(height: 12),

        // Mini stats: hàng 1 = 3 ô (dãy / hộp / đang nuôi), hàng 2 = 4 ô trạng thái.
        Builder(
          builder: (context) {
            const gap = 8.0;
            String pct(int v) => total == 0 ? '0%' : '${(v * 100 / total).round()}%';
            final normal = area.healthyBoxCount;
            final row1 = <_MiniStatData>[
              _MiniStatData(Icons.view_week_outlined, 'Tổng dãy',
                  '${area.rowCount}', null, DashboardColors.brand),
              _MiniStatData(Icons.inventory_2_outlined, 'Tổng hộp', '$total',
                  null, _kBlue),
              _MiniStatData(Icons.set_meal_outlined, 'Đang nuôi', '$occupied',
                  pct(occupied), _kBlue),
            ];
            final row2 = <_MiniStatData>[
              _MiniStatData(Icons.check_circle_outline_rounded, 'Bình thường',
                  '$normal', pct(normal), DashboardColors.healthy),
              _MiniStatData(Icons.visibility_outlined, 'Theo dõi',
                  '${area.watchBoxCount}', pct(area.watchBoxCount), _kAmber),
              _MiniStatData(Icons.warning_amber_rounded, 'Cảnh báo',
                  '${area.alertBoxCount}', pct(area.alertBoxCount),
                  DashboardColors.risk),
              _MiniStatData(Icons.crop_square_outlined, 'Hộp trống',
                  '${area.emptyBoxCount}', pct(area.emptyBoxCount), _kSlate),
            ];

            if (compact) {
              final w = (infoWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final st in [...row1, ...row2])
                    SizedBox(width: w, child: _MiniStat(data: st)),
                ],
              );
            }

            Widget line(List<_MiniStatData> items) => Row(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      Expanded(child: _MiniStat(data: items[i])),
                      if (i != items.length - 1) const SizedBox(width: gap),
                    ],
                  ],
                );
            return Column(
              children: [
                line(row1),
                const SizedBox(height: gap),
                line(row2),
              ],
            );
          },
        ),
        const SizedBox(height: 12),

        // Footer: updated + actions
        Builder(
          builder: (context) {
            final updated = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_outlined,
                    size: 14, color: DashboardColors.textMuted),
                const SizedBox(width: 5),
                Text(
                  'Cập nhật cuối: ${_fmtDate(area.updatedAt ?? area.createdAt)}',
                  style: _bv(fontSize: 12, color: DashboardColors.textMuted),
                ),
              ],
            );
            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OutlineButton(
                  icon: Icons.visibility_outlined,
                  label: 'Chi tiết',
                  onTap: onDetail,
                ),
                const SizedBox(width: 8),
                _PrimaryButton(
                  label: 'Xem dãy',
                  trailing: Icons.arrow_forward_rounded,
                  height: 38,
                  onTap: onViewRows,
                ),
                const SizedBox(width: 8),
                _OutlineButton(
                  icon: Icons.edit_outlined,
                  color: DashboardColors.textPrimary,
                  borderColor: DashboardColors.cardBorder,
                  tooltip: 'Chỉnh sửa',
                  onTap: onEdit,
                ),
                const SizedBox(width: 8),
                _OutlineButton(
                  icon: Icons.delete_outline_rounded,
                  color: DashboardColors.risk,
                  borderColor: DashboardColors.risk.withValues(alpha: 0.35),
                  tooltip: 'Xóa khu',
                  onTap: onDelete,
                ),
              ],
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  updated,
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              );
            }
            return Row(
              children: [updated, const Spacer(), actions],
            );
          },
        ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url, required this.width, required this.height});

  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final u = url?.trim() ?? '';
    Widget fallback = Image.asset(
      _kThumbFallback,
      fit: BoxFit.cover,
      alignment: const Alignment(-0.4, -0.5),
      errorBuilder: (_, __, ___) => Container(
        color: DashboardColors.mint,
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined,
            size: 28, color: DashboardColors.brand.withValues(alpha: 0.5)),
      ),
    );
    final img = u.isEmpty
        ? fallback
        : Image.network(
            u,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          );
    // Kích thước vô hạn → để cha (Row/Column stretch) quyết định, tránh
    // intrinsic size lỗi khi nằm trong IntrinsicHeight.
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: width.isFinite ? width : null,
        height: height.isFinite ? height : null,
        child: img,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

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
            style: _bv(
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

class _UsageBlock extends StatelessWidget {
  const _UsageBlock({
    required this.occupied,
    required this.total,
    required this.usage,
    required this.pct,
    required this.width,
  });

  final int occupied;
  final int total;
  final double usage;
  final int pct;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Mức sử dụng hộp',
                style: _bv(fontSize: 12.5, color: DashboardColors.textMuted),
              ),
              const Spacer(),
              Text(
                '$occupied/$total ($pct%)',
                style: _bv(
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
              height: 8,
              child: Stack(
                children: [
                  Container(color: DashboardColors.mint),
                  FractionallySizedBox(
                    widthFactor: usage.clamp(0.0, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DashboardColors.brand,
                            DashboardColors.brandGreen,
                          ],
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
    );
  }
}

class _MiniStatData {
  const _MiniStatData(this.icon, this.label, this.value, this.pct, this.color);
  final IconData icon;
  final String label;
  final String value;

  /// "(92%)" nhạt hơn số chính; null = không hiển thị.
  final String? pct;
  final Color color;
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.data});

  final _MiniStatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
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
                  style: _bv(fontSize: 11, color: DashboardColors.textMuted),
                ),
                const SizedBox(height: 1),
                Text.rich(
                  TextSpan(
                    text: data.value,
                    style: _bv(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: DashboardColors.textPrimary,
                    ),
                    children: [
                      if (data.pct != null)
                        TextSpan(
                          text: ' (${data.pct})',
                          style: _bv(
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

// ── Empty / pagination ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44),
      decoration: _cardDeco(radius: 18),
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
            child: const Icon(Icons.apartment_outlined,
                size: 26, color: DashboardColors.brand),
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có khu phù hợp bộ lọc',
            style: _bv(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Thử đổi từ khóa / trạng thái, hoặc tạo khu nuôi mới.',
            style: _bv(fontSize: 12.5, color: DashboardColors.textMuted),
          ),
          const SizedBox(height: 14),
          _PrimaryButton(icon: Icons.add_rounded, label: 'Thêm khu', onTap: onAdd),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.totalPages,
    required this.start,
    required this.end,
    required this.total,
    required this.onPage,
  });

  final int page;
  final int totalPages;
  final int start;
  final int end;
  final int total;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final pages = totalPages.clamp(1, 99);
    return Row(
      children: [
        Text(
          total == 0 ? 'Không có khu' : 'Hiển thị $start–$end của $total khu',
          style: _bv(fontSize: 12.5, color: DashboardColors.textMuted),
        ),
        const Spacer(),
        _PageBtn(
          icon: Icons.chevron_left_rounded,
          onTap: page > 0 ? () => onPage(page - 1) : null,
        ),
        for (var i = 0; i < pages; i++) ...[
          const SizedBox(width: 6),
          _PageBtn(
            label: '${i + 1}',
            active: i == page,
            onTap: () => onPage(i),
          ),
        ],
        const SizedBox(width: 6),
        _PageBtn(
          icon: Icons.chevron_right_rounded,
          onTap: page < pages - 1 ? () => onPage(page + 1) : null,
        ),
      ],
    );
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({this.label, this.icon, this.active = false, this.onTap});

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
                  icon,
                  size: 18,
                  color: enabled
                      ? DashboardColors.textPrimary
                      : DashboardColors.textMuted.withValues(alpha: 0.5),
                )
              : Text(
                  label!,
                  style: _bv(
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

// ── Helpers ────────────────────────────────────────────────────────────────

BoxDecoration _cardDeco({required double radius}) => BoxDecoration(
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

String _fmtDate(DateTime? dt) {
  if (dt == null) return '—';
  final l = dt.isUtc ? dt.toLocal() : dt;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
}
