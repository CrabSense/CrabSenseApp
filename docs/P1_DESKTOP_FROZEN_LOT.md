# P1.1 — Frozen storage Manager workflows (continued)

Backend contract reviewed against FrozenStorageController, FrozenStorageDtos and FrozenStorageService.
- Create metadata-only lot (zero stock), optional completed same-area harvest voucher, frozen/expiry dates, grade S/M/L and storage location.
- Edit metadata only; original quantity, weight and status required by BE are echoed unchanged. Concurrent changes are rejected by BE. Delete only empty unreserved/unshipped lots with no visible transaction history; BE validates authoritative history.
- Lot details display crab barcode/traceability and inventory adjustments. Reconcile only legacy Unverified barcodes; explicitly select physical items still present and supply reason; BE rechecks quantity and weight before recording.
- Review opening balances assigned to the current area, verify quantity/weight against actual and recorded deltas, require a reason. No direct stock change; verified balances immutable. Unassigned legacy balances are left to the separate historical-evidence area assignment workflow.
- Show expiry dates and warning for lots expiring within 30 days. No invented stock values.
- Fix assignment submission crash from mutating a fixed-length list, and guard completion/error against area changes.
- Unit tests cover zero-stock create, preserving stock during metadata edits, cross-area rejection, invalid inputs, and opening balance verification payload.

Acceptance: run on the actual Manager account in test Desktop/Pages, with Staff-created transactions and legacy records. Next: area assignment exception workflow, barcode PNG printing/export, sales traceability, dashboard/report scope, full route and Windows acceptance.
