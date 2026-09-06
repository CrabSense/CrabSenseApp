import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/crab_condition.dart';
import '../../models/crab_individual.dart';
import '../../models/crab_profile.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';
import 'crab_auth_image.dart';

class CrabProfileJourney extends StatelessWidget {
  const CrabProfileJourney({
    super.key,
    required this.crab,
    this.profile,
    this.token = '',
  });

  final CrabIndividual crab;
  final CrabProfile? profile;
  final String token;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _IdentityHeader(crab: crab, profile: profile, token: token),
        const SizedBox(height: 16),
        _LocationCard(crab: crab, profile: profile),
        const SizedBox(height: 16),
        _BodyCard(crab: crab, profile: profile),
        const SizedBox(height: 16),
        _AiCard(profile: profile),
        const SizedBox(height: 16),
        _MediaCard(crab: crab, profile: profile, token: token),
        const SizedBox(height: 16),
        _TimelineCard(profile: profile, crab: crab),
        const SizedBox(height: 16),
        _AlertsCard(profile: profile, crab: crab),
      ],
    );
  }
}

String _fmtDate(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
}

String _fmtDateTime(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  return '${_fmtDate(l)} ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

CrabCondition _conditionOf(CrabIndividual crab, CrabProfile? p) {
  return CrabConditionX.parse(
    condition: p?.condition,
    crabStatus: p?.status ?? crab.lifeStatus.name,
    hasCrab: true,
  );
}

String _genderLabel(CrabIndividual crab, CrabProfile? p) {
  final raw = (p?.gender ?? crab.gender.name).toLowerCase();
  if (raw.contains('male') && !raw.contains('fe') || raw == 'đực' || raw == 'm') {
    return 'Đực';
  }
  if (raw.contains('female') || raw == 'cái' || raw == 'f') return 'Cái';
  return crab.gender.label;
}

class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({required this.crab, this.profile, this.token = ''});

  final CrabIndividual crab;
  final CrabProfile? profile;
  final String token;

  @override
  Widget build(BuildContext context) {
    final cond = _conditionOf(crab, profile);
    final lot = profile?.lotCode.isNotEmpty == true ? profile!.lotCode : crab.batchId;
    final import = profile?.importDate ?? crab.releaseDate;
    final avatar = profile?.avatarUrl;
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(
            url: avatar,
            crabId: crab.id,
            token: token,
            hasPhoto: (profile?.imageUrls.isNotEmpty ?? false) || (avatar?.isNotEmpty ?? false),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.code.isNotEmpty == true ? profile!.code : crab.code,
                  style: GoogleFonts.notoSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cond.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cond.color.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    '${cond.emoji}  ${cond.label}',
                    style: GoogleFonts.notoSans(
                      color: cond.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${lot.isEmpty ? '—' : lot}  •  Nhập ngày ${_fmtDate(import)}',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                if (profile?.lotName.isNotEmpty == true)
                  Text(
                    profile!.lotName,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    this.url,
    required this.crabId,
    required this.token,
    required this.hasPhoto,
  });

  final String? url;
  final String crabId;
  final String token;
  final bool hasPhoto;

  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(Icons.pets, size: 48, color: DashboardColors.oceanBlue);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 112,
        height: 112,
        color: DashboardColors.oceanBlue.withValues(alpha: 0.12),
        child: !hasPhoto
            ? placeholder
            : CrabAuthImage(
                crabId: crabId,
                index: 0,
                token: token,
                fallbackUrl: url,
                fit: BoxFit.cover,
                width: 112,
                height: 112,
                error: placeholder,
              ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.crab, this.profile});

  final CrabIndividual crab;
  final CrabProfile? profile;

  @override
  Widget build(BuildContext context) {
    final khu = profile?.areaName.isNotEmpty == true
        ? profile!.areaName
        : (crab.areaName.isEmpty ? '—' : crab.areaName);
    final day = profile?.rowName.isNotEmpty == true
        ? profile!.rowName
        : (crab.rowName.isEmpty ? '—' : crab.rowName);
    final hop = profile?.boxCode.isNotEmpty == true
        ? profile!.boxCode
        : crab.boxLabel;
    return _Section(
      title: 'Vị trí hiện tại',
      icon: Icons.place_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _chip('Khu', khu),
          Icon(Icons.arrow_forward_rounded, size: 16, color: DashboardColors.textMuted),
          _chip('Dãy', day),
          Icon(Icons.arrow_forward_rounded, size: 16, color: DashboardColors.textMuted),
          _chip('Hộp', hop),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 11,
              ),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.notoSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: DashboardColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyCard extends StatelessWidget {
  const _BodyCard({required this.crab, this.profile});

  final CrabIndividual crab;
  final CrabProfile? profile;

  @override
  Widget build(BuildContext context) {
    final initial = profile?.initialWeightGram ?? 0;
    final current = (profile?.weightGram ?? 0) > 0 ? profile!.weightGram : crab.weightGram;
    final width = (profile?.carapaceWidthMm ?? 0) > 0
        ? profile!.carapaceWidthMm
        : crab.shellSizeCm;
    final length = (profile?.carapaceLengthMm ?? 0) > 0
        ? profile!.carapaceLengthMm
        : crab.carapaceLengthMm;
    final health = profile?.healthNote.isNotEmpty == true
        ? profile!.healthNote
        : crab.healthStatus.label;
    return _Section(
      title: 'Thông tin cơ thể',
      icon: Icons.monitor_weight_outlined,
      child: Column(
        children: [
          _kv('Giới tính', _genderLabel(crab, profile)),
          _kv('Trọng lượng ban đầu', initial > 0 ? '${initial.toStringAsFixed(0)} g' : '—'),
          _kv('Trọng lượng hiện tại', current > 0 ? '${current.toStringAsFixed(0)} g' : '—'),
          _kv('Bề ngang mai', length > 0 ? '${length.toStringAsFixed(1)} mm' : '—'),
          _kv('Bề rộng mai', width > 0 ? '${width.toStringAsFixed(1)} mm' : '—'),
          _kv('Tình trạng sức khỏe', health),
          if (profile?.crabType?.isNotEmpty == true) _kv('Loại cua', profile!.crabType!),
          if (crab.quickNote.isNotEmpty) _kv('Ghi chú', crab.quickNote),
        ],
      ),
    );
  }
}

class _AiCard extends StatelessWidget {
  const _AiCard({this.profile});

  final CrabProfile? profile;

  @override
  Widget build(BuildContext context) {
    final pred = profile?.aiPrediction?.trim();
    final rec = profile?.aiRecommendation?.trim();
    final conf = profile?.aiConfidence;
    if (pred == null && rec == null && conf == null) {
      return _Section(
        title: 'AI phân tích',
        icon: Icons.smart_toy_outlined,
        child: Text(
          'Chưa có phân tích AI cho cua này',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        ),
      );
    }
    final pct = conf == null ? null : (conf <= 1 ? conf * 100 : conf);
    return _Section(
      title: 'AI phân tích',
      icon: Icons.smart_toy_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pred != null && pred.isNotEmpty)
            Text(
              pred,
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: DashboardColors.textPrimary,
              ),
            ),
          if (pct != null) ...[
            const SizedBox(height: 10),
            Text(
              'Độ tin cậy: ${pct.toStringAsFixed(0)}%',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: (pct / 100).clamp(0, 1),
              minHeight: 8,
              backgroundColor: DashboardColors.cardBorder,
              color: DashboardColors.oceanBlue,
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Phân tích gần nhất: ${_fmtDateTime(profile?.aiAnalyzedAt)}',
            style: GoogleFonts.notoSans(fontSize: 12, color: DashboardColors.textMuted),
          ),
          if (rec != null && rec.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DashboardColors.oceanBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Khuyến nghị: $rec',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({required this.crab, this.profile, this.token = ''});

  final CrabIndividual crab;
  final CrabProfile? profile;
  final String token;

  @override
  Widget build(BuildContext context) {
    final urls = profile?.imageUrls ?? const <String>[];
    return _Section(
      title: 'Hình ảnh & video',
      icon: Icons.photo_library_outlined,
      child: urls.isEmpty
          ? Text(
              'Chưa có ảnh lúc nhập hoặc ảnh AI',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            )
          : SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: urls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CrabAuthImage(
                      crabId: crab.id,
                      index: i,
                      token: token,
                      fallbackUrl: urls[i],
                      width: 110,
                      height: 110,
                      error: Container(
                        width: 110,
                        color: DashboardColors.darkNavy,
                        child: Icon(Icons.broken_image_outlined,
                            color: DashboardColors.textMuted),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({this.profile, required this.crab});

  final CrabProfile? profile;
  final CrabIndividual crab;

  @override
  Widget build(BuildContext context) {
    final events = profile?.timeline ?? const <CrabTimelineEvent>[];
    return _Section(
      title: 'Lịch sử vòng đời',
      icon: Icons.timeline,
      child: events.isEmpty
          ? Text(
              'Nhập hệ thống ${_fmtDate(crab.releaseDate)}',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            )
          : Column(
              children: [
                for (var i = events.length - 1; i >= 0; i--)
                  _TimelineRow(event: events[i], isLast: i == 0),
              ],
            ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.isLast});

  final CrabTimelineEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: DashboardColors.oceanBlue,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: DashboardColors.cardBorder,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_fmtDate(event.at)}  ${event.title}',
                  style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
                ),
                if (event.detail != null && event.detail!.isNotEmpty)
                  Text(
                    event.detail!,
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: DashboardColors.textMuted,
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

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({this.profile, required this.crab});

  final CrabProfile? profile;
  final CrabIndividual crab;

  @override
  Widget build(BuildContext context) {
    final alerts = profile?.alerts ?? const <CrabProfileAlert>[];
    return _Section(
      title: 'Cảnh báo',
      icon: Icons.warning_amber_rounded,
      child: alerts.isEmpty && crab.diseases.isEmpty
          ? Text(
              'Không có cảnh báo',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            )
          : Column(
              children: [
                for (final a in alerts)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.warning_amber_rounded, color: DashboardColors.warning),
                    title: Text(a.title),
                    subtitle: Text(
                      [
                        if (a.detail != null && a.detail!.isNotEmpty) a.detail!,
                        _fmtDate(a.at),
                      ].join(' · '),
                    ),
                  ),
                for (final d in crab.diseases)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.warning_amber_rounded, color: DashboardColors.monitoring),
                    title: Text(d.name),
                    subtitle: Text(d.symptoms),
                  ),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: DashboardColors.oceanBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

Widget _kv(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(
          width: 180,
          child: Text(
            label,
            style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
