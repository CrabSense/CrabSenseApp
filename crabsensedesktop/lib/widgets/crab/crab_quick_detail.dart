import 'package:flutter/material.dart';

import '../../models/crab_individual.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/mgmt_ui.dart';
import 'crab_status_badge.dart';

class CrabQuickDetail extends StatelessWidget {
  const CrabQuickDetail({
    super.key,
    required this.crab,
    this.loading = false,
    this.onClose,
    this.onOpenArea,
    this.onOpenRow,
    this.onOpenBox,
    this.onHistory,
    this.onOpenFull,
  });

  final CrabIndividual crab;
  final bool loading;
  final VoidCallback? onClose;
  final VoidCallback? onOpenArea;
  final VoidCallback? onOpenRow;
  final VoidCallback? onOpenBox;
  final VoidCallback? onHistory;
  final VoidCallback? onOpenFull;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Text(
                  'Chi tiết cua',
                  style: bvText(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: onClose,
                  icon: Icon(Icons.close_rounded, size: 18, color: DashboardColors.textMuted),
                  splashRadius: 16,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: DashboardColors.mint),
          Expanded(
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CrabDetailSkeleton(),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                    children: [
                      _header(),
                      const SizedBox(height: 16),
                      _sectionTitle(Icons.place_outlined, 'Vị trí hiện tại'),
                      const SizedBox(height: 8),
                      _locationCard(),
                      const SizedBox(height: 16),
                      _sectionTitle(Icons.info_outline, 'Thông tin cơ bản'),
                      const SizedBox(height: 8),
                      _kv('Lô cua', crab.batchId.trim().isEmpty ? '—' : crab.batchId),
                      _kv('Cân nặng', crab.weightLabel),
                      _kv('Kích thước', crab.sizeLabel, hint: _sizeHint()),
                      _kv('Giới tính', crab.gender.label),
                      _kv('Số lần lột xác', '${crab.moltCount}'),
                      const SizedBox(height: 12),
                      _sectionTitle(Icons.monitor_heart_outlined, 'Tình trạng'),
                      const SizedBox(height: 8),
                      _kvWidget('Sức khỏe', CrabHealthBadge(status: crab.displayHealth)),
                      _kvWidget('Trạng thái', CrabLifecycleBadge(status: crab.lifecycleStatus)),
                      const SizedBox(height: 12),
                      _sectionTitle(Icons.schedule_outlined, 'Thời gian'),
                      const SizedBox(height: 8),
                      _kv(
                        'Nhập trại',
                        fmtDateVn(crab.releaseDate),
                        hint: '(${crab.ageDays} ngày trong hệ thống)',
                      ),
                      _kv('Lột xác gần nhất', fmtDateVn(crab.lastMoltDate)),
                      _kv('Cập nhật cuối', fmtDateTimeVn(crab.lastUpdated)),
                      const SizedBox(height: 12),
                      _sectionTitle(Icons.notes_outlined, 'Ghi chú'),
                      const SizedBox(height: 6),
                      Text(
                        _note,
                        style: bvText(
                          fontSize: 13,
                          color: DashboardColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
          ),
          const Divider(height: 1, color: DashboardColors.mint),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MgmtOutlineButton(
                        icon: Icons.history_rounded,
                        label: 'Xem lịch sử',
                        onTap: onHistory,
                        height: 38,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MgmtOutlineButton(
                        icon: Icons.edit_outlined,
                        label: 'Xem hộp',
                        onTap: onOpenBox,
                        height: 38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                MgmtPrimaryButton(
                  label: 'Chi tiết cua',
                  trailing: Icons.arrow_forward_rounded,
                  onTap: onOpenFull,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: DashboardColors.mint,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.set_meal_rounded, size: 22, color: DashboardColors.brand),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                crab.code,
                style: bvText(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              CrabLifecycleBadge(status: crab.lifecycleStatus),
              const SizedBox(height: 4),
              Text(
                '${crab.crabType} • ${crab.gender.label}',
                style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _locationCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.mint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _link(crab.areaLabel, onOpenArea),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _link(crab.rowLabel, onOpenRow),
              Text('  →  ', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
              _link(crab.boxLabel, onOpenBox),
            ],
          ),
        ],
      ),
    );
  }

  Widget _link(String text, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: bvText(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: DashboardColors.brand,
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: DashboardColors.brand),
        const SizedBox(width: 6),
        Text(
          title,
          style: bvText(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: DashboardColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _kv(String label, String value, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: bvText(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                if (hint != null)
                  Text(hint, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kvWidget(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
          ),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: value)),
        ],
      ),
    );
  }

  String? _sizeHint() {
    final w = CrabIndividual.normalizeCarapaceMm(crab.shellSizeCm);
    final l = CrabIndividual.normalizeCarapaceMm(crab.carapaceLengthMm);
    if (w <= 0 && l <= 0) return null;
    return 'Chiều rộng mai: ${CrabIndividual.formatMm(w)} mm\nChiều dài mai: ${CrabIndividual.formatMm(l)} mm';
  }

  String get _note {
    final t = crab.quickNote.trim();
    if (t.isEmpty || t.toLowerCase() == 'null' || t.toLowerCase() == 'undefined') {
      return '—';
    }
    return t;
  }
}

class CrabDetailSkeleton extends StatelessWidget {
  const CrabDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar({double w = double.infinity, double h = 12}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: DashboardColors.mint,
            borderRadius: BorderRadius.circular(8),
          ),
        );
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(w: 160, h: 18),
          const SizedBox(height: 12),
          bar(h: 64),
          const SizedBox(height: 16),
          bar(w: 120),
          const SizedBox(height: 8),
          bar(),
          const SizedBox(height: 8),
          bar(),
          const SizedBox(height: 8),
          bar(w: 180),
        ],
      ),
    );
  }
}
