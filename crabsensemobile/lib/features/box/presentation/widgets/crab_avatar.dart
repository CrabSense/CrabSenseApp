import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/box_enums.dart';
import '../../domain/entities/crab.dart';

class CrabAvatar extends StatelessWidget {
  const CrabAvatar({super.key, this.size = 46});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CrabSenseColors.primaryMuted,
        shape: BoxShape.circle,
        border: Border.all(color: CrabSenseColors.primaryLight),
      ),
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(size * 0.14),
      child: Image.asset(
        'assets/images/crab_icon.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.set_meal_rounded,
          color: CrabSenseColors.primaryDark,
          size: size * 0.48,
        ),
      ),
    );
  }
}

String crabDisplayTag(Crab crab) {
  final raw = crab.addedBy.trim();
  final lower = raw.toLowerCase();
  if (raw.isEmpty || lower == 'system' || lower == 'mobile') {
    final id = crab.id.replaceAll('-', '');
    if (id.length >= 6) return 'Cua ${id.substring(0, 6).toUpperCase()}';
    return 'Cua';
  }
  return raw;
}

String crabSpeciesVi(CrabSpecies value) => switch (value) {
      CrabSpecies.blueCrab => 'Cua xanh',
      CrabSpecies.mudCrab => 'Cua lột',
      CrabSpecies.softShell => 'Cua vỏ mềm',
    };

String crabMoltingVi(MoltingStatus value) => switch (value) {
      MoltingStatus.preMolt => 'Vỏ vừa',
      MoltingStatus.molting => 'Đang lột',
      MoltingStatus.postMolt => 'Vỏ mềm',
      MoltingStatus.hardShell => 'Vỏ cứng',
    };

String crabHealthVi(HealthStatus value) => switch (value) {
      HealthStatus.normal => 'Bình thường',
      HealthStatus.disease => 'Bệnh',
      HealthStatus.stress => 'Căng thẳng',
      HealthStatus.unknown => 'Chưa rõ',
    };

String crabSourceVi(CrabSource value) => switch (value) {
      CrabSource.farm => 'Trại nuôi',
      CrabSource.purchase => 'Mua về',
      CrabSource.transfer => 'Chuyển hộp',
    };
