import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/crab_model.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../widgets/crab_avatar.dart';

/// Chi tiết một con cua.
class CrabDetailScreen extends StatelessWidget {
  const CrabDetailScreen({
    super.key,
    required this.crabId,
    this.boxId,
    this.boxCode,
    this.initial,
  });

  final String crabId;
  final String? boxId;
  final String? boxCode;
  final CrabModel? initial;

  @override
  Widget build(BuildContext context) {
    final crab = initial;
    final title = crab == null ? 'Chi tiết cua' : crabDisplayTag(crab);

    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: CrabSenseColors.headerGradient,
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kHomePrimaryDark),
              onPressed: () => context.pop(),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: kHomePrimaryDark,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
        ),
      ),
      body: crab == null
          ? const Center(
              child: Text(
                'Không có dữ liệu',
                style: TextStyle(color: kHomeTextSub),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CrabAvatar(size: 88),
                  const SizedBox(height: 20),
                  _infoCard([
                    _row('Mã cua', crabDisplayTag(crab)),
                    _row('Cân nặng', '${crab.weight.round()} g'),
                    _row('Loài', crabSpeciesVi(crab.species)),
                    _row('Tình trạng vỏ', crabMoltingVi(crab.moltingStatus)),
                    _row('Sức khoẻ', crabHealthVi(crab.healthStatus)),
                    _row('Nguồn gốc', crabSourceVi(crab.source)),
                    _row(
                      'Hộp nuôi',
                      (boxCode != null && boxCode!.isNotEmpty)
                          ? boxCode!
                          : 'Hộp',
                    ),
                  ]),
                ],
              ),
            ),
    );
  }

  Widget _infoCard(List<Widget> rows) => Container(
        decoration: BoxDecoration(
          color: kHomeSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kHomeBorder),
          boxShadow: const [
            BoxShadow(color: Color(0x12000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(children: rows),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(color: kHomeTextSub, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: kHomeTextMain,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
}
