// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/crab_management_models.dart';
import 'crab_badges.dart';
import 'crab_management_palette.dart';

/// Right-side detail panel / bottom sheet content (responsive).
class CrabDetailPanel extends StatelessWidget {
  const CrabDetailPanel({
    required this.crab,
    required this.onClose,
    required this.onViewHistory,
    required this.onViewBox,
    required this.onViewDetail,
    required this.onFarmAreaTap,
    required this.onRowTap,
    required this.onBoxTap,
    super.key,
    this.loading = false,
  });

  final CrabRecord crab;
  final bool loading;
  final VoidCallback onClose;
  final VoidCallback onViewHistory;
  final VoidCallback onViewBox;
  final VoidCallback onViewDetail;
  final void Function(String id) onFarmAreaTap;
  final void Function(String id) onRowTap;
  final void Function(String id) onBoxTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kCmSurface,
        border: Border(left: BorderSide(color: kCmBorder)),
      ),
      child: loading
          ? const Center(child: CircularProgressIndicator(color: kCmPrimary))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLocation(),
                        const SizedBox(height: 14),
                        _buildBasicInfo(),
                        const SizedBox(height: 14),
                        _buildStatus(),
                        const SizedBox(height: 14),
                        _buildTiming(),
                        if (crab.note != null && crab.note!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildNote(),
                        ],
                      ],
                    ),
                  ),
                ),
                _buildActions(),
              ],
            ),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
    decoration: const BoxDecoration(
      color: kCmMintBg,
      border: Border(bottom: BorderSide(color: kCmBorder)),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: kCmPrimaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text('🦀', style: TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      crab.id,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: kCmTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  CrabLifecycleBadge(crab.lifecycleStatus, compact: true),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Cua biển • ${crab.gender.label}',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: kCmTextSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(
            Icons.close_rounded,
            size: 18,
            color: kCmTextSecondary,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    ),
  );

  Widget _buildLocation() => _Section(
    icon: Icons.location_on_outlined,
    title: 'Vị trí hiện tại',
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kCmMintBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kCmBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => onFarmAreaTap(crab.location.farmAreaId),
            child: Row(
              children: [
                const Icon(
                  Icons.business_outlined,
                  size: 13,
                  color: kCmPrimary,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${crab.location.farmAreaId} — ${crab.location.farmAreaName}',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kCmPrimary,
                      decoration: TextDecoration.underline,
                      decorationColor: kCmPrimary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              GestureDetector(
                onTap: () => onRowTap(crab.location.rowId),
                child: Text(
                  crab.location.rowName,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kCmPrimaryDark,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text(
                ' → ',
                style: GoogleFonts.nunito(fontSize: 12, color: kCmTextHint),
              ),
              GestureDetector(
                onTap: () => onBoxTap(crab.location.boxId),
                child: Text(
                  crab.location.boxCode,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kCmPrimaryDark,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildBasicInfo() => _Section(
    icon: Icons.info_outline_rounded,
    title: 'Thông tin cơ bản',
    child: Column(
      children: [
        _InfoRow(
          'Lô cua',
          crab.batch.name?.isNotEmpty == true
              ? crab.batch.name!
              : crab.batch.id,
        ),
        _InfoRow('Cân nặng', crab.weightLabel),
        _InfoRow('Kích thước', crab.sizeLabel),
        _InfoRow('Giới tính', crab.gender.label),
        _InfoRow('Số lần lột xác', '${crab.moltCount}'),
      ],
    ),
  );

  Widget _buildStatus() {
    final ai = crab.aiStatus;
    return _Section(
      icon: Icons.health_and_safety_outlined,
      title: 'Tình trạng',
      child: Column(
        children: [
          _BadgeRow('Sức khỏe', CrabHealthBadge(crab.healthStatus)),
          const SizedBox(height: 6),
          _BadgeRow('Trạng thái', CrabLifecycleBadge(crab.lifecycleStatus)),
          if (ai != null) ...[
            const SizedBox(height: 6),
            _BadgeRow('AI giám sát', _AiBadge(ai)),
          ],
        ],
      ),
    );
  }

  Widget _buildTiming() {
    final now = DateTime.now();
    final daysIn = now.difference(crab.enteredAt).inDays;
    return _Section(
      icon: Icons.schedule_outlined,
      title: 'Thời gian',
      child: Column(
        children: [
          _InfoRow(
            'Nhập trại',
            '${_fmtDate(crab.enteredAt)} ($daysIn ngày trong hệ thống)',
          ),
          if (crab.lastMoltAt != null)
            _InfoRow('Lột xác gần nhất', _fmtDate(crab.lastMoltAt!)),
          _InfoRow('Cập nhật cuối', _fmtDatetime(crab.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildNote() => _Section(
    icon: Icons.notes_rounded,
    title: 'Ghi chú',
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kCmMintBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kCmBorder),
      ),
      child: Text(
        crab.note!,
        style: GoogleFonts.nunito(
          fontSize: 12,
          color: kCmTextPrimary,
          height: 1.5,
        ),
      ),
    ),
  );

  Widget _buildActions() => Container(
    padding: const EdgeInsets.all(12),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: kCmBorder)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _OutlinedActionBtn(
                icon: Icons.history_rounded,
                label: 'Xem lịch sử',
                onPressed: onViewHistory,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OutlinedActionBtn(
                icon: Icons.inventory_2_outlined,
                label: 'Xem hộp',
                onPressed: onViewBox,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onViewDetail,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(
              'Chi tiết cua →',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kCmPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  static String _fmtDate(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/'
        '${l.month.toString().padLeft(2, '0')}/${l.year}';
  }

  static String _fmtDatetime(DateTime dt) =>
      '${_fmtDate(dt)} ${dt.toLocal().hour.toString().padLeft(2, '0')}:'
      '${dt.toLocal().minute.toString().padLeft(2, '0')}';
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _AiBadge extends StatelessWidget {
  const _AiBadge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final isAnomaly = text.contains('bất thường');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAnomaly ? kCmAmberLight : kCmGreenLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isAnomaly ? '⚠ $text' : '● $text',
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isAnomaly ? kCmAmber : kCmPrimaryDark,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 14, color: kCmPrimary),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: kCmTextPrimary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.nunito(fontSize: 12, color: kCmTextSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kCmTextPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow(this.label, this.badge);
  final String label;
  final Widget badge;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 80,
        child: Text(
          label,
          style: GoogleFonts.nunito(fontSize: 12, color: kCmTextSecondary),
        ),
      ),
      badge,
    ],
  );
}

class _OutlinedActionBtn extends StatelessWidget {
  const _OutlinedActionBtn({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 14),
    label: Text(
      label,
      style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    style: OutlinedButton.styleFrom(
      foregroundColor: kCmPrimaryDark,
      side: const BorderSide(color: kCmBorder),
      padding: const EdgeInsets.symmetric(vertical: 9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );
}
