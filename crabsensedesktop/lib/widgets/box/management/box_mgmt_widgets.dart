import 'package:flutter/material.dart';

import '../../../models/box_list_item.dart';
import '../../../models/crab_individual.dart';
import '../../../models/crab_status.dart';
import '../../../models/production_models.dart';
import '../../../services/box_management_service.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';

const _kBlue = Color(0xFF2495E8);
const _kAmber = Color(0xFFF5B700);
const _kRed = Color(0xFFEF4444);
const _kSlate = Color(0xFF94A3B8);
String boxUiStatusLabel(BoxUiStatus s) => switch (s) {
      BoxUiStatus.occupied => 'Đang nuôi',
      BoxUiStatus.empty => 'Trống',
      BoxUiStatus.maintenance => 'Bảo trì',
      BoxUiStatus.locked => 'Khóa',
      BoxUiStatus.offline => 'Mất kết nối',
    };

Color boxUiStatusColor(BoxUiStatus s) => switch (s) {
      BoxUiStatus.occupied => DashboardColors.brand,
      BoxUiStatus.empty => _kSlate,
      BoxUiStatus.maintenance => _kAmber,
      BoxUiStatus.locked => _kAmber,
      BoxUiStatus.offline => _kRed,
    };

String boxHealthLabel(BoxHealthUi h) => switch (h) {
      BoxHealthUi.none => 'Không có cua',
      BoxHealthUi.healthy => 'Khỏe mạnh',
      BoxHealthUi.monitoring => 'Cần theo dõi',
      BoxHealthUi.weak => 'Bệnh / Yếu',
      BoxHealthUi.alert => 'Cảnh báo',
    };

Color boxHealthColor(BoxHealthUi h) => switch (h) {
      BoxHealthUi.none => _kSlate,
      BoxHealthUi.healthy => DashboardColors.brand,
      BoxHealthUi.monitoring => _kAmber,
      BoxHealthUi.weak => _kRed,
      BoxHealthUi.alert => _kRed,
    };

String boxStatusFilterLabel(BoxStatusFilter f) => switch (f) {
      BoxStatusFilter.all => 'Tất cả',
      BoxStatusFilter.occupied => 'Đang nuôi',
      BoxStatusFilter.empty => 'Trống',
      BoxStatusFilter.maintenance => 'Bảo trì',
      BoxStatusFilter.locked => 'Khóa',
      BoxStatusFilter.offline => 'Mất kết nối',
    };

String boxHealthFilterLabel(BoxHealthFilter f) => switch (f) {
      BoxHealthFilter.all => 'Tất cả',
      BoxHealthFilter.healthy => 'Khỏe mạnh',
      BoxHealthFilter.monitoring => 'Theo dõi',
      BoxHealthFilter.weak => 'Bệnh / Yếu',
      BoxHealthFilter.alert => 'Cảnh báo',
      BoxHealthFilter.empty => 'Không có cua',
    };

String boxListSortLabel(BoxListSort s) => switch (s) {
      BoxListSort.newest => 'Mới nhất trước',
      BoxListSort.codeAz => 'Mã hộp A → Z',
      BoxListSort.codeZa => 'Mã hộp Z → A',
      BoxListSort.mostAlerts => 'Cảnh báo nhiều nhất',
      BoxListSort.watchFirst => 'Cua cần theo dõi trước',
      BoxListSort.emptyFirst => 'Hộp trống trước',
    };

({String label, Color color}) boxAiLine(BoxListItem item) {
  if (item.uiStatus == BoxUiStatus.maintenance) {
    return (label: 'AI: Tạm dừng', color: _kSlate);
  }
  if (item.uiStatus == BoxUiStatus.empty && item.cameraOnline == null && item.deviceTotal == 0) {
    return (label: 'AI: Không áp dụng', color: _kSlate);
  }
  if (item.cameraOnline == null && item.deviceTotal == 0) {
    return (label: 'AI: Chưa cấu hình', color: _kSlate);
  }
  if (item.cameraOnline == false) {
    return (label: 'AI: Tạm dừng — Camera mất kết nối', color: _kAmber);
  }
  final raw = (item.box.aiSummary ?? '').trim();
  final low = raw.toLowerCase();
  if (raw.isNotEmpty &&
      (low.contains('bất thường') && !low.contains('không phát hiện') ||
          low.contains('cảnh báo') ||
          low.contains('cần kiểm tra') ||
          low.contains('warning'))) {
    return (label: 'AI: $raw', color: _kAmber);
  }
  if (item.cameraOnline == true) {
    return (label: 'AI: Không phát hiện bất thường', color: DashboardColors.brand);
  }
  if (raw.isNotEmpty) {
    return (label: 'AI: $raw', color: DashboardColors.textMuted);
  }
  return (label: 'AI: Chưa cấu hình', color: _kSlate);
}

String boxDeviceLine(BoxListItem item) {
  if (item.deviceTotal <= 0) return 'Thiết bị: Chưa cấu hình';
  return 'Thiết bị: ${item.deviceOnline}/${item.deviceTotal} Online';
}

// ── KPI ────────────────────────────────────────────────────────────────────

class BoxSummaryCards extends StatelessWidget {
  const BoxSummaryCards({
    super.key,
    required this.kpi,
    required this.loading,
    required this.statusFilter,
    required this.healthFilter,
    required this.alertOnly,
    required this.onSelect,
  });

  final BoxKpiSnapshot kpi;
  final bool loading;
  final BoxStatusFilter statusFilter;
  final BoxHealthFilter healthFilter;
  final bool alertOnly;
  final void Function({BoxStatusFilter? status, BoxHealthFilter? health, bool alerts}) onSelect;

  @override
  Widget build(BuildContext context) {
    if (loading && kpi.total == 0) {
      return LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 1100 ? 5 : 2;
        final w = (c.maxWidth - 12 * (cols - 1)) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < 5; i++)
              SizedBox(
                width: w,
                child: Container(
                  height: 86,
                  decoration: BoxDecoration(
                    color: DashboardColors.lightMint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
          ],
        );
      });
    }

    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 1100 ? 5 : 2;
      final w = (c.maxWidth - 12 * (cols - 1)) / cols;
      final cards = [
        _Kpi(
          icon: Icons.inventory_2_outlined,
          label: 'TỔNG HỘP',
          value: '${kpi.total}',
          color: _kBlue,
          active: statusFilter == BoxStatusFilter.all && healthFilter == BoxHealthFilter.all && !alertOnly,
          onTap: () => onSelect(),
        ),
        _Kpi(
          icon: Icons.set_meal_outlined,
          label: 'ĐANG NUÔI',
          value: '${kpi.occupied}',
          color: DashboardColors.brand,
          active: statusFilter == BoxStatusFilter.occupied,
          onTap: () => onSelect(status: BoxStatusFilter.occupied),
        ),
        _Kpi(
          icon: Icons.inbox_outlined,
          label: 'HỘP TRỐNG',
          value: '${kpi.empty}',
          color: _kSlate,
          active: statusFilter == BoxStatusFilter.empty,
          onTap: () => onSelect(status: BoxStatusFilter.empty),
        ),
        _Kpi(
          icon: Icons.visibility_outlined,
          label: 'THEO DÕI',
          value: '${kpi.monitoring}',
          color: _kAmber,
          active: healthFilter == BoxHealthFilter.monitoring,
          onTap: () => onSelect(health: BoxHealthFilter.monitoring),
        ),
        _Kpi(
          icon: Icons.warning_amber_rounded,
          label: 'CẢNH BÁO',
          value: '${kpi.alerts}',
          color: _kRed,
          active: alertOnly,
          onTap: () => onSelect(alerts: true),
        ),
      ];
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final k in cards) SizedBox(width: w, child: k)],
      );
    });
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? DashboardColors.lightMint : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? DashboardColors.brand.withValues(alpha: 0.4) : DashboardColors.cardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: DashboardColors.brand.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: bvText(fontSize: 11, fontWeight: FontWeight.w800, color: DashboardColors.textMuted)),
                    Text(value, style: bvText(fontSize: 24, fontWeight: FontWeight.w800, color: color, height: 1.15)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filters ────────────────────────────────────────────────────────────────

class BoxFilterToolbar extends StatelessWidget {
  const BoxFilterToolbar({
    super.key,
    required this.search,
    required this.areas,
    required this.rows,
    required this.areaFilterId,
    required this.rowFilterId,
    required this.statusFilter,
    required this.healthFilter,
    required this.onSearch,
    required this.onArea,
    required this.onRow,
    required this.onStatus,
    required this.onHealth,
    required this.onClear,
    required this.onAdd,
  });

  final TextEditingController search;
  final List<AreaRecord> areas;
  final List<RowRecord> rows;
  final String? areaFilterId;
  final String? rowFilterId;
  final BoxStatusFilter statusFilter;
  final BoxHealthFilter healthFilter;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onArea;
  final ValueChanged<String?> onRow;
  final ValueChanged<BoxStatusFilter> onStatus;
  final ValueChanged<BoxHealthFilter> onHealth;
  final VoidCallback onClear;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final areaLabel = areaFilterId == null
        ? 'Tất cả khu'
        : areas.where((a) => a.id == areaFilterId).map((a) => a.areaName).firstOrNull ?? 'Khu vực';
    final rowLabel = rowFilterId == null
        ? 'Tất cả'
        : rows.where((r) => r.id == rowFilterId).map((r) => r.rowName).firstOrNull ?? 'Dãy';

    final searchField = MgmtSearchField(
      controller: search,
      onChanged: onSearch,
      hint: 'Tìm mã hộp, mã cua...',
    );
    final areaDd = MgmtDropdown<String>(
      width: 200,
      leading: Icons.home_outlined,
      valueLabel: areaLabel,
      items: [
        ('', 'Tất cả khu'),
        for (final a in areas) (a.id, a.areaName),
      ],
      onSelected: (v) => onArea(v.isEmpty ? null : v),
    );
    final rowDd = MgmtDropdown<String>(
      width: 160,
      valueLabel: rowLabel,
      items: [
        ('', 'Tất cả'),
        for (final r in rows) (r.id, r.rowName),
      ],
      onSelected: (v) => onRow(v.isEmpty ? null : v),
    );
    final statusDd = MgmtDropdown<BoxStatusFilter>(
      width: 168,
      valueLabel: boxStatusFilterLabel(statusFilter),
      items: [for (final f in BoxStatusFilter.values) (f, boxStatusFilterLabel(f))],
      onSelected: onStatus,
    );
    final healthDd = MgmtDropdown<BoxHealthFilter>(
      width: 176,
      valueLabel: boxHealthFilterLabel(healthFilter),
      items: [for (final f in BoxHealthFilter.values) (f, boxHealthFilterLabel(f))],
      onSelected: onHealth,
    );
    final clear = TextButton(
      onPressed: onClear,
      child: Text('Xóa lọc', style: bvText(fontWeight: FontWeight.w700, color: DashboardColors.brand)),
    );
    final add = MgmtPrimaryButton(icon: Icons.add_rounded, label: 'Thêm hộp', onTap: onAdd);

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 1100) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            searchField,
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [areaDd, rowDd, statusDd, healthDd, clear, add],
            ),
          ],
        );
      }
      return Column(
        children: [
          searchField,
          const SizedBox(height: 10),
          Row(
            children: [
              areaDd,
              const SizedBox(width: 8),
              rowDd,
              const SizedBox(width: 8),
              statusDd,
              const SizedBox(width: 8),
              healthDd,
              const Spacer(),
              clear,
              const SizedBox(width: 8),
              add,
            ],
          ),
        ],
      );
    });
  }
}

// ── Card ───────────────────────────────────────────────────────────────────

enum BoxCardAction { detail, edit, qr, print, lock, unlock, maintenance, transfer, addCrab, delete }

class BoxGridCard extends StatelessWidget {
  const BoxGridCard({
    super.key,
    required this.item,
    this.crab,
    required this.onOpen,
    required this.onAction,
    this.onAlerts,
    this.onAddCrab,
  });

  final BoxListItem item;
  final CrabIndividual? crab;
  final VoidCallback onOpen;
  final ValueChanged<BoxCardAction> onAction;
  final VoidCallback? onAlerts;
  final VoidCallback? onAddCrab;

  @override
  Widget build(BuildContext context) {
    final status = item.uiStatus;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
          decoration: mgmtCardDeco(radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: DashboardColors.lightMint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.inventory_2_outlined, size: 18, color: DashboardColors.brand),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.box.boxCode, maxLines: 1, overflow: TextOverflow.ellipsis, style: bvText(fontSize: 15, fontWeight: FontWeight.w800)),
                        Text(item.displayName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
                      ],
                    ),
                  ),
                  MgmtStatusBadge(label: boxUiStatusLabel(status), color: boxUiStatusColor(status)),
                  BoxActionMenu(item: item, onAction: onAction),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.place_outlined, size: 14, color: DashboardColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.placeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _body(status),
              const SizedBox(height: 10),
              _meta(),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.schedule_outlined, size: 13, color: item.isStale ? _kAmber : DashboardColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.updatedAt == null ? 'Chưa có cập nhật' : 'Cập nhật: ${fmtDateTimeVn(item.updatedAt)}',
                      style: bvText(fontSize: 11.5, color: item.isStale ? _kAmber : DashboardColors.textMuted),
                    ),
                  ),
                  if (item.isStale) Text('Dữ liệu cũ', style: bvText(fontSize: 11, fontWeight: FontWeight.w700, color: _kAmber)),
                ],
              ),
              const SizedBox(height: 10),
              _actions(status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BoxUiStatus status) {
    if (status == BoxUiStatus.maintenance) {
      return _centerState(Icons.build_outlined, 'Đang bảo trì', 'Không thể phân cua vào hộp này.');
    }
    if (status == BoxUiStatus.locked) {
      return _centerState(Icons.lock_outline_rounded, 'Hộp đang bị khóa', 'Liên hệ quản trị viên để mở khóa.');
    }
    if (status == BoxUiStatus.empty) {
      return _centerState(Icons.set_meal_outlined, 'Chưa có cua', 'Hộp sẵn sàng để phân cua.');
    }
    final gender = crab == null ? null : switch (crab!.gender) {
          CrabGender.male => 'Đực',
          CrabGender.female => 'Cái',
          CrabGender.unknown => null,
        };
    final type = (crab?.crabType ?? '').trim();
    final sub = [
      if (type.isNotEmpty) type,
      if (gender != null) gender,
    ].join(' • ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.box.crabTag ?? crab?.code ?? '1 cua', style: bvText(fontSize: 14.5, fontWeight: FontWeight.w800)),
        if (sub.isNotEmpty) Text(sub, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.favorite_rounded, size: 14, color: boxHealthColor(item.healthUi)),
            const SizedBox(width: 5),
            Text(boxHealthLabel(item.healthUi), style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: boxHealthColor(item.healthUi))),
          ],
        ),
      ],
    );
  }

  Widget _centerState(IconData icon, String title, String sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FBF8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: DashboardColors.brand),
          const SizedBox(height: 4),
          Text(title, style: bvText(fontWeight: FontWeight.w800)),
          Text(sub, textAlign: TextAlign.center, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
        ],
      ),
    );
  }

  Widget _meta() {
    final ai = boxAiLine(item);
    final alertColor = item.hasAlert ? _kRed : DashboardColors.textMuted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ai.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: bvText(fontSize: 12, fontWeight: FontWeight.w600, color: ai.color)),
        const SizedBox(height: 3),
        Tooltip(
          message: 'Camera / Controller / Sensor gắn với hộp',
          child: Text(boxDeviceLine(item), style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
        ),
        const SizedBox(height: 3),
        InkWell(
          onTap: item.hasAlert ? onAlerts : null,
          child: Text(
            'Cảnh báo: ${item.box.alertCount}',
            style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: alertColor),
          ),
        ),
      ],
    );
  }

  Widget _actions(BoxUiStatus status) {
    if (status == BoxUiStatus.empty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          MgmtPrimaryButton(icon: Icons.add_rounded, label: 'Thêm cua', height: 34, onTap: onAddCrab),
          MgmtOutlineButton(label: 'Chi tiết', height: 34, onTap: onOpen),
        ],
      );
    }
    return MgmtOutlineButton(
      label: 'Xem chi tiết',
      icon: Icons.arrow_forward_rounded,
      height: 34,
      onTap: onOpen,
    );
  }
}

class BoxActionMenu extends StatelessWidget {
  const BoxActionMenu({super.key, required this.item, required this.onAction});

  final BoxListItem item;
  final ValueChanged<BoxCardAction> onAction;

  @override
  Widget build(BuildContext context) {
    final locked = item.uiStatus == BoxUiStatus.locked || item.uiStatus == BoxUiStatus.maintenance;
    return PopupMenuButton<BoxCardAction>(
      tooltip: 'Thao tác hộp',
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert_rounded, size: 18, color: DashboardColors.textMuted),
      onSelected: onAction,
      itemBuilder: (_) => [
        const PopupMenuItem(value: BoxCardAction.detail, child: Text('Xem chi tiết')),
        const PopupMenuItem(value: BoxCardAction.edit, child: Text('Chỉnh sửa hộp')),
        const PopupMenuItem(value: BoxCardAction.qr, child: Text('Xem QR')),
        const PopupMenuItem(value: BoxCardAction.print, child: Text('In mã hộp')),
        PopupMenuItem(value: locked ? BoxCardAction.unlock : BoxCardAction.lock, child: Text(locked ? 'Mở khóa' : 'Khóa hộp')),
        if (item.uiStatus != BoxUiStatus.maintenance)
          const PopupMenuItem(value: BoxCardAction.maintenance, child: Text('Đánh dấu bảo trì')),
        if (item.hasCrab) const PopupMenuItem(value: BoxCardAction.transfer, child: Text('Chuyển cua')),
        if (item.canAddCrab) const PopupMenuItem(value: BoxCardAction.addCrab, child: Text('Thêm cua')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: BoxCardAction.delete, child: Text('Lưu trữ / gỡ hộp')),
      ],
    );
  }
}

class BoxCardSkeletonGrid extends StatelessWidget {
  const BoxCardSkeletonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 1200 ? 4 : c.maxWidth >= 760 ? 2 : 1;
      final w = (c.maxWidth - 16 * (cols - 1)) / cols;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (var i = 0; i < 8; i++)
            SizedBox(
              width: w,
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: DashboardColors.lightMint,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class BoxMgmtGrid extends StatelessWidget {
  const BoxMgmtGrid({
    super.key,
    required this.items,
    required this.crabOf,
    required this.onOpen,
    required this.onAction,
    required this.onAlerts,
    required this.onAddCrab,
  });

  final List<BoxListItem> items;
  final CrabIndividual? Function(BoxListItem item) crabOf;
  final ValueChanged<BoxListItem> onOpen;
  final void Function(BoxListItem item, BoxCardAction action) onAction;
  final ValueChanged<BoxListItem> onAlerts;
  final ValueChanged<BoxListItem> onAddCrab;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 1200 ? 4 : c.maxWidth >= 760 ? 2 : 1;
      final w = (c.maxWidth - 16 * (cols - 1)) / cols;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final item in items)
            SizedBox(
              width: w,
              child: BoxGridCard(
                item: item,
                crab: crabOf(item),
                onOpen: () => onOpen(item),
                onAction: (a) => onAction(item, a),
                onAlerts: () => onAlerts(item),
                onAddCrab: () => onAddCrab(item),
              ),
            ),
        ],
      );
    });
  }
}

class BoxListTable extends StatelessWidget {
  const BoxListTable({
    super.key,
    required this.items,
    required this.crabOf,
    required this.onOpen,
    required this.onAction,
    required this.onAlerts,
    required this.onAddCrab,
  });

  final List<BoxListItem> items;
  final CrabIndividual? Function(BoxListItem item) crabOf;
  final ValueChanged<BoxListItem> onOpen;
  final void Function(BoxListItem item, BoxCardAction action) onAction;
  final ValueChanged<BoxListItem> onAlerts;
  final ValueChanged<BoxListItem> onAddCrab;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                _h('MÃ HỘP', 3),
                _h('TÊN HỘP', 3),
                _h('KHU', 2),
                _h('DÃY', 1),
                _h('CUA HIỆN TẠI', 2),
                _h('SỨC KHỎE', 2),
                _h('TRẠNG THÁI', 2),
                _h('AI', 2),
                _h('THIẾT BỊ', 2),
                _h('CẢNH BÁO', 1),
                _h('CẬP NHẬT', 2),
                const SizedBox(width: 36),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final item in items)
            InkWell(
              onTap: () => onOpen(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    _c(item.box.boxCode, 3, bold: true),
                    _c(item.displayName, 3),
                    _c(item.areaName.isEmpty ? item.areaCode : item.areaName, 2),
                    _c(item.rowName.isEmpty ? item.rowCode : item.rowName, 1),
                    _c(item.hasCrab ? (item.box.crabTag ?? '—') : '—', 2),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.hasCrab ? boxHealthLabel(item.healthUi) : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bvText(fontSize: 12, fontWeight: FontWeight.w700, color: item.hasCrab ? boxHealthColor(item.healthUi) : DashboardColors.textMuted),
                      ),
                    ),
                    Expanded(flex: 2, child: MgmtStatusBadge(label: boxUiStatusLabel(item.uiStatus), color: boxUiStatusColor(item.uiStatus))),
                    _c(boxAiLine(item).label.replaceFirst('AI: ', ''), 2),
                    _c(item.deviceTotal <= 0 ? '—' : '${item.deviceOnline}/${item.deviceTotal}', 2),
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: item.hasAlert ? () => onAlerts(item) : null,
                        child: Text('${item.box.alertCount}', style: bvText(fontWeight: FontWeight.w700, color: item.hasAlert ? _kRed : DashboardColors.textMuted)),
                      ),
                    ),
                    _c(fmtDateTimeVn(item.updatedAt), 2, muted: true),
                    BoxActionMenu(item: item, onAction: (a) => onAction(item, a)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _h(String t, int flex) => Expanded(
        flex: flex,
        child: Text(t, style: bvText(fontSize: 10.5, fontWeight: FontWeight.w800, color: DashboardColors.textMuted)),
      );

  Widget _c(String t, int flex, {bool bold = false, bool muted = false}) => Expanded(
        flex: flex,
        child: Text(
          t,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: bvText(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: muted ? DashboardColors.textMuted : DashboardColors.textPrimary,
          ),
        ),
      );
}
