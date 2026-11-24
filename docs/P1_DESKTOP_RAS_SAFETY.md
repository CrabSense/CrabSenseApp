# P1.1.3 — RAS runtime safety and area isolation

- Manager Desktop reads Backend relay observations and command status; remove direct LAN relay polling and cross-device same-channel inference.
- Explicitly separate requested output, device reported output, queued/ACK/waiting report/confirmed/failed/expired status. Unreported output is unknown, not OFF.
- Disable commands if hardware control disabled/missing, wrong area, unknown/offline controller, absent port, pending command, stale diagram, or request already in flight.
- Batch operations retain captured area, stop when UI area changes, and report accepted counts (not physical success). Hardware state remains authoritative in BE.
- RAS and area-environment services invalidate delayed reads and suppress notification after disposal.
- Hide Manager-only blocked configuration actions from RAS device cards and topology dialog; keep server-authorized role guards.
- Regression tests mock delayed area response, disabled hardware, pending command and unknown observation. Hardware acceptance must use an enabled test environment; do not activate production relays during CI.
- Next P0 batches: crab permission/weight correction and harvest/sales stale-area state. Then finish P1 report/dashboard and UI acceptance.
