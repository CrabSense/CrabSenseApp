# P1.1.4 / P1.1.5 — Manager harvest and storage

- Harvest decision APIs: POST approve/reject/confirm; no retired status PATCH. PendingApproval/Planned can be decided; InProgress with executionCompletedAt can be confirmed. Staff records actual work and evidence. Creation submits for approval rather than fake draft.
- Assignment list/details scoped to selected assigned area, shows line results and related vouchers; discard late area-switch responses.
- Frozen tab: list selected-area lots and transactions, approve/reject PendingApproval only; staff executes and updates inventory. No fake stock changes.
- Sales: remove placeholder print/PDF/refund/history action buttons; existing create/complete/cancel endpoints retained.
- Tests: invalid area, duplicate assignment IDs, invalid actions/reasons, status parsing. Acceptance still requires real BE requests, staff mobile integration, frozen lot CRUD/reconciliation/opening balance UI, sales finance and traceability, Windows build and live data.
