# P1.1 P0.2 — Manager crab permissions

Backend contracts: FarmingController (crabs), FarmHistoryController, DashboardController (operations), FarmLotController, FarmingService, FarmLotService.
- Staff only: create/update crab, allocate/transfer, record weight/molt, feeding and editing operation notes. Hide blocked actions in Manager list, growth charts, feeding history/drawer and inbound lot allocation controls.
- Manager: correct measurement notes; no changing measurement values. Terminal crab release uses DELETE /api/crabs/{id}; BE refuses live crabs, preserves historical record, and releases the box if appropriate. UI confirms explicit meaning, selected area and terminal state; BE is authoritative.
- Manager lot creation sends explicit farmingAreaId. Model retains farmingAreaIds and isPartialScope. Inbound list filters selected area's linked lots; partial or out-of-scope lots cannot be modified. A shared lot can represent totals across its accessible areas; do not treat its quantity as an individual area's stock.
- Discard stale crab list/detail loads on area/session changes; scope detail widget keys and prevent delayed notifications in growth/feeding read controllers.
- Tests cover lot create payload, unassigned Manager, unknown crab deletion, partial-scope lot and note permission.
- Remaining follow-up: Manager's allocation/molting/box-history correction and audit/void workflows, lot close/disposition and deletion UI, multi-area lot reporting and complete runtime acceptance. Do not treat these as implemented by this patch.
