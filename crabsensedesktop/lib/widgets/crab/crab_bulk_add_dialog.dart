import 'package:flutter/material.dart';

import '../../services/crab_service.dart';
import 'bulk/bulk_add_crab_modal.dart';

Future<bool> showCrabBulkAddDialog(
  BuildContext context,
  CrabService service, {
  String? initialLotId,
  VoidCallback? onManageLots,
}) {
  return showBulkAddCrabModal(
    context,
    service,
    initialLotId: initialLotId,
    onManageLots: onManageLots,
  );
}
