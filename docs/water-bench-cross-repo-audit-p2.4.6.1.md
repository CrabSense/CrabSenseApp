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

## Desktop scoped history (App main 536c0d7)
Main #193: 45 Desktop / 69 Mobile tests verified. Proposed explicit sensor history chart using strict scoped v1 contract, complete bounded pages and selected metadata, no legacy fallback, expiry and generation guards. Combined recent table/CSV still disabled; pending CI, real browser/device and JWT testing. Area/box, dashboard synthetic paths and FE dependencies remain open.

## Desktop history table/CSV — App main 9f12792
Main #195 confirmed 48 Desktop / 69 Mobile tests. Proposed chart/table/native CSV from same validated scoped snapshot, 25-row pagination, exact wire timestamps and provenance, recheck revision after save dialog. Shared freshness watchdog; no legacy or browser export. Three additional tests in existing mandatory suite, CI pending. Native picker lifecycle and production JWT/browser/device smoke remain open, as do area/box, dashboard synthetic paths and FE audit.

## Shared RAS area reference — App main acc5ebf
User clarified one recirculating water loop per area; all rows/boxes use shared representative inlet/outlet measurements, not row/box-specific measurements. Keep observed location metadata in history, do not infer sample placement or copy records. New area/box projection shares qualified live decoder, explicit area context, distinct sensor IDs and freshness, no legacy local comparison/history or chemistry fallback. Three regression tests pending CI. Area heatmap, dashboard synthetic paths, Mobile row presentation and FE require alignment with shared RAS semantics. Multiple independent loops would require explicit water-system scope; production and physical verification remain open.

## Mobile shared RAS area view — App main 1bf313a
Main #199 confirmed 69 Mobile / 54 Desktop tests, including the three shared RAS area/box regressions. Environment screen chooses area only, avoids row fetch/filter, retains sensor's observed location in scoped history request and validation. Route row remains compatible context in BLoC, not a water measurement filter. Two new tests in existing mandatory suites; CI pending. Chemistry sampling inlet/return location is not confirmed; no schema or metadata assumption. Desktop dashboard/heatmap, FE and physical/production tests remain open.

## Desktop shared RAS overview — App main 628846b
Main #202: 71 Mobile and 54 Desktop tests verified. Proposed area overview replaces inferred row heatmap with qualified common-area cards. Dashboard reads qualified per-sensor values and disables fabricated seven-day chart and unscoped combined trend/DO fallback; links to scoped history. Two new mandatory tests pending CI. Other summary/KPI paths, unused synthetic helpers, FE dependencies, JWT/browser/physical testing remain open.

## Web Farm Admin shared RAS monitoring — App main 8ee6f46
Main #205 confirmed 71 Mobile / 56 Desktop tests, including both dashboard provenance tests. FE PR #31 f3a64e3 proposes explicit selected area /iot/live per-sensor cards, box reference labels, no all-area aggregation, dedicated bearer and freshness/visibility/session guards. Four new mandatory Node tests, CI pending. New browser lifecycle and production JWT tests not yet performed. FE dependency audit and other dashboard KPI/legacy surfaces remain open.

## Dependency inventory — FE main be31769
FE #31 merged; main #137 and Deploy #125 passed, 25 Node tests, 19 affected npm packages (10 high, 9 moderate). Sonar scan skipped; browser #8 validated existing WaterBench/roles, not new RAS lifecycle. App #62 journal merged e551dce. FE PR #32 7adcd5f proposes validated full/omit-dev npm audit inventory, raw evidence and package/path/version/advisory/fix summaries, three parser tests. Valid findings warn; invalid report or registry failure fails the diagnostic job. No package version changes, no forced upgrade, CI and actual package classification pending. T06 not accepted.

## Compatible dependency remediation candidate — FE main 556c06f
FE #32 merged; audit #2 confirms full 19 / omit-dev 17 affected packages. Main #139 28 Node tests, Deploy #127 PASS. App #63 merged 6a0247b. shadcn CSS is required, existing React plugin peer excludes Vite 8. FE #33 c275c55 proposes isolated shadcn 4 + non-force compatible npm remediation with actual registry resolution, lock evidence, full/omit-dev audit, npm ci and browser/build tests. No committed dependency upgrade until candidate validation; separate Vite major migration required. T06 remains open.

## Candidate runner correction
FE #33 Candidate #1 resolved shadcn 4.23.1, reduced full/omit-dev audit to 2 (Vite/esbuild), npm ci/28 tests/Pages build passed; Chromium install failed because ubuntu-latest is Ubuntu 26.04 unsupported by Playwright 1.56.1. Commit 2d5445b pins Ubuntu 24.04; no test bypass or package changes. Exact candidate must pass browser tests before adoption. App #64 merged fdd8d12 after CI #210. T06 remains open.

## Verified compatible dependency adoption — FE main 43e4ff9
FE #33 merged; Candidate #2 run 46105670510 passed npm ci, Node/build and actual Chromium browser contracts. Full and omit-dev each retain 2 affected packages (Vite High, esbuild Moderate). Artifact 15247876071 ZIP SHA256 matched GitHub; exact manifest/lock blob SHAs matched downloaded files after reconstructing the logged delta. FE PR #34 1a9dab5 contains only those two files in one commit; shadcn pinned 4.23.1, no force fix or major upgrade. Audit #6 queued at initial check; await Sonar/Pages/Chromium/audit on PR before merge. App #65 merged 929c91b after CI #212. Vite/plugin migration, security gate, production JWT, RAS browser and hardware tests remain open; no P2.4.6.1 sign-off.

## Progress reconciliation — 2026-11-28
Verified six main heads: firmware b552498, Kiosk 98458f3, BE 5f4415f, AI 700d5b2, FE 43e4ff9, App 929c91b (then #66 merged 5e7277d after CI #214). Main workflows at the pre-merge snapshot passed; new App main CI not yet confirmed. FE #34 1a9dab5 passed all four PR workflows including Chromium #12; Sonar scan skipped. FE main audit #5 still full 19/omit-dev 17; PR audit #6 full/omit-dev 2. No FE merge or functional changes in this documentation check. T04 offline remains disabled; T05 KPI/legacy/RAS browser and actual JWT/production smoke remain open. Vite/plugin and security gate next; no P2.4.6.1 sign-off.
