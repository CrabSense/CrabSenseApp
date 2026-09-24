import 'package:flutter/material.dart';

import '../../../models/production_models.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';
import 'box_labels.dart';

enum BoxHeaderAction { qr, print, history, transfer, maintenance, delete }

class BoxDetailBreadcrumb extends StatelessWidget {
  const BoxDetailBreadcrumb({
    super.key,
    required this.areaName,
    required this.rowName,
    required this.boxCode,
    this.onBoxes,
    this.onArea,
    this.onRow,
  });

  final String areaName;
  final String rowName;
  final String boxCode;
  final VoidCallback? onBoxes;
  final VoidCallback? onArea;
  final VoidCallback? onRow;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _crumb('Quản lý hộp', onBoxes),
        _sep(),
        _crumb(areaName.isEmpty ? 'Khu vực' : areaName, onArea),
        _sep(),
        _crumb(rowName.isEmpty ? 'Dãy' : 'Dãy $rowName', onRow),
        _sep(),
        Text(boxCode, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
      ],
    );
  }

  Widget _sep() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Icon(Icons.chevron_right_rounded, size: 16, color: DashboardColors.textMuted),
      );

  Widget _crumb(String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(label, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: DashboardColors.brand)),
      ),
    );
  }
}

class BoxDetailHeader extends StatelessWidget {
  const BoxDetailHeader({
    super.key,
    required this.box,
    required this.areaName,
    required this.rowName,
    required this.hasCrab,
    this.locked = false,
    this.locking = false,
    this.onEdit,
    this.onLock,
    this.onMore,
  });

  final BoxRecord box;
  final String areaName;
  final String rowName;
  final bool hasCrab;
  final bool locked;
  final bool locking;
  final VoidCallback? onEdit;
  final VoidCallback? onLock;
  final ValueChanged<BoxHeaderAction>? onMore;

  @override
  Widget build(BuildContext context) {
    final place = [
      if (areaName.trim().isNotEmpty) areaName,
      if (rowName.trim().isNotEmpty) 'Dãy $rowName',
      if ((box.position ?? '').trim().isNotEmpty) 'Vị trí ${box.position}',
    ].join('  /  ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.inventory_2_outlined, color: DashboardColors.brand),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(box.boxCode, style: bvText(fontSize: 22, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
                  MgmtStatusBadge(
                    label: crabLifecycleLabel(box.crabStatus, hasCrab: hasCrab),
                    color: hasCrab ? DashboardColors.brand : DashboardColors.textMuted,
                  ),
                ],
              ),
              if (place.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(place, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
                ),
            ],
          ),
        ),
        Flexible(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              PopupMenuButton<BoxHeaderAction>(
                tooltip: 'Thêm',
                onSelected: onMore,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: BoxHeaderAction.qr, child: Text('Xem QR')),
                  const PopupMenuItem(value: BoxHeaderAction.print, child: Text('In mã hộp')),
                  const PopupMenuItem(value: BoxHeaderAction.history, child: Text('Xem lịch sử')),
                  const PopupMenuItem(value: BoxHeaderAction.transfer, child: Text('Chuyển cua ra')),
                  const PopupMenuItem(value: BoxHeaderAction.maintenance, child: Text('Đánh dấu bảo trì')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: BoxHeaderAction.delete, child: Text('Xóa hộp')),
                ],
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DashboardColors.cardBorder),
                  ),
                  child: Icon(Icons.more_vert_rounded, color: DashboardColors.textMuted),
                ),
              ),
              MgmtOutlineButton(icon: Icons.edit_outlined, label: 'Chỉnh sửa', onTap: onEdit),
              MgmtOutlineButton(
                icon: locked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                label: locking ? 'Đang xử lý...' : (locked ? 'Mở khóa hộp' : 'Khóa hộp'),
                color: locked ? DashboardColors.brand : const Color(0xFFF5B700),
                onTap: locking ? null : onLock,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BoxMetaBar extends StatelessWidget {
  const BoxMetaBar({
    super.key,
    required this.box,
    required this.areaCode,
    required this.rowLabel,
    this.updatedAt,
  });

  final BoxRecord box;
  final String areaCode;
  final String rowLabel;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      (Icons.qr_code_2_rounded, 'Mã hộp', box.boxCode),
      (Icons.holiday_village_outlined, 'Khu vực', areaCode.isEmpty ? '—' : areaCode),
      (Icons.view_week_outlined, 'Dãy', rowLabel.isEmpty ? '—' : rowLabel),
      (Icons.place_outlined, 'Vị trí', (box.position ?? '').trim().isEmpty ? '—' : box.position!),
      (Icons.inbox_outlined, 'Sức chứa', '1 cua'),
      (Icons.sensors_outlined, 'Trạng thái', boxOperationalLabel(box.status)),
      (Icons.schedule_outlined, 'Cập nhật cuối', fmtDateTimeVn(updatedAt)),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: mgmtCardDeco(radius: 14),
      child: Wrap(
        spacing: 18,
        runSpacing: 10,
        children: [
          for (final it in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(it.$1, size: 15, color: DashboardColors.brand),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.$2, style: bvText(fontSize: 10.5, color: DashboardColors.textMuted)),
                    Text(it.$3, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class BoxDetailTabBar extends StatelessWidget {
  const BoxDetailTabBar({super.key, required this.controller});
  final TabController controller;

  static const labels = ['Tổng quan', 'Cua trong hộp', 'Cảm biến', 'Camera AI', 'Cảnh báo', 'Lịch sử'];

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelStyle: bvText(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: bvText(fontSize: 13, fontWeight: FontWeight.w600),
      labelColor: DashboardColors.brand,
      unselectedLabelColor: DashboardColors.textMuted,
      indicatorColor: DashboardColors.brand,
      indicatorWeight: 2.4,
      indicatorSize: TabBarIndicatorSize.label,
      dividerHeight: 0.6,
      dividerColor: DashboardColors.mint,
      tabs: [for (final t in labels) Tab(text: t)],
    );
  }
}

class BoxDetailSkeleton extends StatelessWidget {
  const BoxDetailSkeleton({super.key});

  Widget _bar({double h = 16, double? w}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(8)),
      );

  Widget _card({double h = 160}) => Container(
        height: h,
        decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(16)),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [_bar(h: 48, w: 48), const SizedBox(width: 12), Expanded(child: _bar(h: 28))]),
        const SizedBox(height: 12),
        _bar(h: 56),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(flex: 40, child: _card()),
            const SizedBox(width: 12),
            Expanded(flex: 25, child: _card()),
            const SizedBox(width: 12),
            Expanded(flex: 35, child: _card()),
          ],
        ),
      ],
    );
  }
}
