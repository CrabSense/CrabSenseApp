# P1.1 — Desktop Farm Manager review

Desktop is Manager-only. Backend is authoritative; do not widen roles to match stale UI.

- Area/row/box structure: read, filter, inspect, navigate. Farm Administrator manages structure on Web.
- Box operations explicitly assigned to Farm Staff by current API (status, crab creation): do not offer these from the Desktop box list/detail. Preserve existing QR viewing and history.
- Controller overview and sensor history: view; hardware registration and configuration belong to System Administrator.
- RAS relay operations remain available under existing BE permissions.
- Show existing activity log and AI insight routes in navigation; old device setup/sensor upgrade links route to controller overview.
- Still to review: crab management CRUD, QR printing semantics, RAS control path, report and old batch placeholders, all remaining technical dialogs and cross-platform workflow.
- Acceptance: assigned and unassigned area views, all list/detail states, switching area, no structure mutation request, Controller read and RAS commands, notification/back navigation, Manager-to-Staff harvesting. Runtime and full build not yet verified by this change.
