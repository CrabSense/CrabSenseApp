# P1.1 second batch — Desktop Manager

- Crab list and overview: staff-only mutations removed from main management entry points. Manager still imports lots and reads history; authorized weight-note correction remains.
- RAS: manual relay commands submitted through scoped BE node command endpoint. UI acknowledges queue acceptance, not physical completion. No direct ESP write from controller overview or RAS drive path. Topology and mapping blocked at service boundary.
- Reports: seven real report endpoints including period harvest, inventory, survival, molting, operations and lot comparison; selected area and supported date queries, error/empty/loading states. Validate actual response schemas and area filters on staging before production.
- Legacy menu paths redirected; report route added.
- CI: add focused permission regression tests. Remaining acceptance: full Windows build, live devices, every harvest/frozen/sales transition, Dashboard KPIs, profile/offline UX and cross-role E2E. Do not close P1.1 on analyzer alone.
