import 'package:flutter/material.dart';

import '../../models/crab_lot_status.dart';
import '../shared/mgmt_ui.dart';

class CrabLotStatusBadge extends StatelessWidget {
  const CrabLotStatusBadge({super.key, required this.status});

  final CrabLotWorkflowStatus status;

  @override
  Widget build(BuildContext context) {
    return MgmtStatusBadge(label: status.label, color: status.color);
  }
}
