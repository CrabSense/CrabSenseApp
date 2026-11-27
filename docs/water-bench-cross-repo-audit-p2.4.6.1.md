# P2.4.6.1 integration audit — 2026-11-27
Baseline: firmware b552498695bb12c8267768d58b0759e73c36a10c, Kiosk ceb194a3b285738ac3a41a9f27d64071eb61db98, BE 14ccffdb9633b46a99e39187dba82db8990b4b55, private AI 51de29ab351650ec606b9999449c6f93dbd7915a, FE 0e1178d93d4689647fb172580d915ad21e713096, App ae93674a8099e50f8e348fcf2179671cc135448e. Main CI green at audit start; not evidence of latest cross-repo compatibility.

Findings:
- P0 data integrity: legacy Mobile water-quality screen calls _mockChartHistory in production. Remove synthetic series, do not substitute legacy history that collapses missing sensor values to zero. Explicit unavailable panel until verified per-sensor data contract (presence, unit, timestamp, quality, area, period, pagination) is implemented. WaterBench estimates and reviewed records remain independent; no sensor publication. Clear old metrics on selection change and ignore obsolete metric responses. This is containment, not restoration of real charts.
- P0 CI drift: public Kiosk BE pin a9d62d0, private AI BE a9d62d0 and Kiosk 150f9d5 lag current mains. Kiosk PR #28 and private AI PR #6 refresh exact pins; require passing integration.
- P1 legacy Mobile current-reading DTO also uses missing-as-zero and aggregate latest timestamps; default thresholds and offline/unknown handling need review. WaterQualityBloc requests can overlap when switching area; scope/cache and live history need end-to-end tests before restoring chart.
- P1 contract review: FE AUTO is supported by BE calibration controller (normalizes protocol and sets AI-selected channel); read-only App routes and BE receipt/review fields match inspected source. Review publication explicitly distinct from sensor measurement.
- P1 system integration: private cross test uses geometry requirement disabled with synthetic samples; latest platform technical PostgreSQL query and real JWT four-role policy not yet verified in shared integration suite. Add actual API integration assertions in P2.4.6.2.
- P1 security: FE npm reports 19 vulnerabilities (9 moderate/10 high); inspect audit dependency paths before remediation, do not blanket force update.
- P1 hardware: legacy firmware PR #1 remains open; v2 integration doc explicitly says not to merge legacy code. No hardware flash or chemical validation in this audit.
- P2 full schema/migration, UART traffic, AI production geometry, Drive privacy, cancellation, stale reads, device test and all remaining legacy code paths require subsequent audit/test. No claim of complete P2.4.6.1 acceptance until refreshed CI and review.

## Refreshed evidence — 2026-11-27 (App main c23e5b8)

| Repository | Verified main SHA | Evidence / boundary |
|---|---|---|
| Firmware | b552498695bb12c8267768d58b0759e73c36a10c | Historical P0/P1 software evidence; no flash or physical acceptance |
| BE | 40464ce34de8384383ff14f7243dc069625f7ebe | Main CI #425 / VPS #226 previously verified; HTTP/PostgreSQL scoped history, test auth rather than real JWT |
| Kiosk | 3fc897caa558d5186139d2452f3a7b5f3eb4e912 | Main #76 previously verified, exact BE pin |
| Private Water AI | 2c63944d2717819ba247b24e66d5fdc6a8e62e67 | Main CI #33/private cross #9 previously verified; synthetic fixtures, geometry disabled |
| FE | 0e1178d93d4689647fb172580d915ad21e713096 | Previous Chromium/deploy evidence; npm audit remediation still open |
| App | c23e5b81fa9d79ee3933d052a2db90891753f0d4 | Main #185/Pages #80/Mobile #62/Desktop #64 PASS; 57 Mobile tests executed |

- T01–T03: exact pins refreshed, BE scoped history and App measured chart merged. No production JWT or physical sensor proof.
- T04: SQLite v4 migration, scope, session, expiry and fail-closed offline behavior tested. Offline reading is deliberately NOT enabled. Device/browser lifecycle smoke remains open.
- T05: HTTP adapter/credential regression gate added in next App PR; current metrics/status/threshold source and actual authenticated smoke remain open.
- T06: FE dependency audit/review remains open; old count is not a fresh npm audit.
- T07–T12: real JWT 4-role PostgreSQL diagnostics; geometry and private media; cross-platform receipt/review; legacy firmware; security/recovery; physical tests remain separate outstanding acceptance items. No complete P2.4.6.1 sign-off.

HTTP gate: actual ApiClient and interceptors with an isolated Dio adapter; exact URI/query/asOf, pinned bearer, no retry/refresh on 401/403, reject redirect, no sensitive debug logging, invalid envelope. No network/real JWT in this test. Review new CI before merge.

## T05 live provenance and metrics refresh — 2026-11-27
BE main 5f4415f CI #427/VPS #227, Kiosk main 98458f3 CI #78, AI main 700d5b2 CI #37/private cross #11 verified; all three integration counters passed (one executed test each, no skips). App baseline 6fae55e CI #187 62 tests passed. New Mobile change removes duplicate home-summary request from environment screen, projects qualified per-sensor metadata, exact type/unit, separate TDS, timestamps, status and configured limits, fail-closed reconnect. New CI pending; Home overview still uses a separate summary and requires review. TDS history, missing-sensor inventory, production JWT/real hardware, FE dependency audit remain open. No overall P2.4.6.1 sign-off.

## Home metrics follow-up (App main 46664dc)
Main CI #189 verified 67 Mobile tests. Proposed Home patch shares qualified live decoder, pinned credential and revision, scope/transport checks, no offline metrics fallback, per-sensor labels, configured limits and freshness; prevents obsolete Home request publication. Two additional projection tests mandatory; CI pending. Other Home data/cache and Desktop/FE legacy clients remain outside this patch. No production smoke or complete T05 acceptance.

## Desktop realtime T05 containment (App main 69d7793)
Main #191 confirmed 69 Mobile tests. Realtime Desktop service and page changed to strict scoped live decoder, per-sensor cards and backend threshold, generation guards, clear on denial, no legacy historical/CSV data. New Desktop tests pending CI. Area/box panels, dashboard trend bootstrap/smoothing and remaining legacy endpoints not accepted; scoped Desktop history must be implemented before restoration. FE audit remains open.
