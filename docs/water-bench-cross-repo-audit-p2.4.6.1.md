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

## Vite major migration candidate — FE main 123e5a5
FE #34 merged after all four PR workflows passed; main Audit #7 confirms 2 affected packages full/omit-dev, Sonar #144 passed and Pages #132 pending at snapshot. App #67 CI #216 passed and merged a30bcca. FE #35 7070609 adds isolated Vite 8.4.0/stable React plugin candidate, strict peer/engine checks on Node 22, manifest guard, npm ci, Node/Pages/Chromium and zero-audit acceptance; preserve exact evidence without deploying or modifying committed dependencies. Candidate CI not yet verified. Sonar currently Node 20; align at adoption if required. No permanent security gate or T06/P2.4.6.1 acceptance yet; T04/T05, JWT and physical tests remain open.
Candidate #1 run 46107502769 failed strict ERESOLVE on React plugin 6.3.0 optional Rolldown Babel peer chain; no install/build/browser/audit candidate completed. PR #35 revised to resolve latest stable plugin major 5 and retain strict peer/engine checks, head d260097; candidate #2 not verified. No forced dependency resolution or main changes.

## Verified Vite 8 adoption — FE main 37ef191
FE #35 candidate #2 run 46107568726 passed strict peers/engines, npm ci, 28 Node tests, Pages build, Chromium, zero full and omit-dev findings; Vite 8.4.0/plugin 5.2.0/Node 22.23.5. #35 merged 37ef191; main Audit #10/Sonar #147/Pages #135 PASS. App #68 merged 7f08e4f; main #220/Mobile #83/Desktop #86/Pages #107 PASS. Artifact 15247014866 ZIP SHA256 and both exact manifest/lock blob hashes independently verified. FE #36 0629558 adopts exact files and aligns Sonar Node 22; PR CI initially pending, no main Vite upgrade yet. Permanent gate, production smoke and remaining T04/T05 acceptance still open.

## Zero main audit and permanent security gate — FE main 4ee58b7
FE #36 merged after all four PR workflows passed. Main Audit #12 job 140865755695 verifies zero affected packages in both scopes, Sonar #149 and Pages #137 PASS. App #69 CI #221 PASS, merged 0e58ba1; new main CI pending. FE #37 c16e459 implements fail-closed zero audit policy, evidence on failure, three gate regressions, daily audit and reusable security dependency before Pages deploy. CI pending. Branch protection read returned 403, rulesets list empty; required merge status enforcement not verified/configured, admin action needed. No application/dependency changes; T04/T05, production smoke, JWT and physical acceptance remain open.

## Security gate main and Dashboard water provenance — 2026-11-28
FE #37 merged 3d20f94; main Audit #14 and Pages #139 security job both 6/6 tests and zero full/omit-dev, build/browser/deploy passed; Sonar #151 passed. Required branch protection remains unverified (admin access needed). App #70 merged 48004ae after CI #223. BE DashboardService waterQualityScore is a sensor last-seen coverage heuristic with alert penalties, not measured water quality; overall score may omit absent components. FE #38 c2207d4 replaces legacy score/breakdown with existing qualified per-sensor RAS grid on explicitly verified area, no All Areas aggregate, removes metrics request, preserves business overview/KPIs and hides absent device card. One wiring regression, PR CI pending. Other KPI semantics, browser lifecycle, T04, JWT/production/physical acceptance remain open. No BE/schema/role/dependency changes.

## RAS Chromium lifecycle — 2026-11-28
FE #38 merged a96343e; main Audit #16/Sonar #153/Pages #141 passed. App #71 CI #225 passed, merged d8f06d2; new main CI pending. FE #39 4f8077c adds real Chromium synthetic API test for separate sensors/zero, wrong scope/chemistry/null, delayed prior area, All Areas no request, offline/reconnect, token rotation/403 recovery and Monitoring parity, wired into mandatory existing browser workflow and deploy gate. Browser #18/Pages #142 queued. No production logic, dependency, BE/schema/role changes. Production JWT/native/physical, other KPI/legacy and T04, required branch check remain open.

## RAS browser acceptance and Mobile history lifecycle — 2026-11-28
FE #39 merged 2b9aa32; six RAS Chromium markers verified on PR #18 and main Pages #143, all main workflows pass and deployment gate full/omit-dev zero. App #72 merged 861520c after CI #227. App #73 ff15ea9 isolates busy guard by session generation and clears chart directly on foreground/background transitions with two mandatory regression tests; CI pending. Offline reads remain disabled. Native hardware, production JWT, other KPI/legacy and required branch check remain open.

## Mobile lifecycle acceptance and legacy box overview isolation — 2026-11-28
App #73 and #74 merged; exact new Mobile regressions passed CI #229, main #232/Mobile #90/Desktop #92/Pages #114 passed. Offline cache remains disabled; native/production outstanding. BE #113 c6dbba1 addresses first-area reuse and global-device fallback in boxes/overview, uses canonical area resolution, captured alerts, unique fresh scoped scalar readings, retains threshold alarms and actual zero, no global header for All Areas. DTO retained; empty devices false/0 legacy boolean requires consumer interpretation. Two-area regression added; revised head CI pending. Health/AI heuristics, client semantics and production integration remain open. No schema/role/sampling changes.

## Box overview deployment and inventory consumer semantics — 2026-11-28
BE #113 merged 949927b, exact regression passed CI #429, main CI #430/VPS #228 passed; App #75 merged 70324b0 with all main workflows green. FE #40 30475be implements strict inventory/missing count semantics and labels legacy health heuristic. Mobile PR includes strict BoxDeviceStatus decoder, nullable verifiedOnline, card/filter wiring and mandatory model regression. Both pending CI. Legacy fallback/cache and health/AI metrics remain unresolved, Desktop review and production JWT/native acceptance pending. No schema/role/sampling changes.

## Online-only Mobile Boxes — 2026-11-28
FE #40 and App #76 merged, all corresponding PR/main workflows PASS. Mobile removes legacy API composition and cached snapshot returns, pins read credentials, validates freshly authorized area inventory and overview area/items/summary, rejects errors without fallback; provider drops previous state on load/switch/credential or transport invalidation and guards late results. Four synthetic HTTP adapter regressions wired to mandatory Mobile CI, pending. UI Hive preferences remain. Automatic selection uses only freshly allowed areas; remaining legacy health/AI defaults, per-box timestamps, Desktop and native/provider lifecycle/production JWT still open. No role/API/schema/sampling changes.

## App #77 CI correction — 2026-11-28
Sonar #237 mobile job 140883819519 failed (88 pass, 4 fail) because Hive preference storage was not initialized in all four new repository tests; analysis, Desktop, Mobile Preview #94 and Pages #118 passed. Initialize isolated temporary Hive storage per test, open real ui_prefs, close and delete in teardown. Preserve production code, regression assertions and required gate. Revised PR head pending CI, no merge. L03–L06 deferred until L01/L02 acceptance; no production or physical acceptance claim.

## Mobile legacy assessment containment — 2026-11-28
App #77 46a77cd merged 6c55fa7 after CI #238 (92/92 Mobile tests including four online-only regressions), Mobile #95 and Pages #119 passed; main #239/Mobile #96/Desktop #95/Pages #120 passed. Mobile Boxes suppresses all unproven legacy health/confidence/trend/recommendations/priority, normalizes unsupported filters/sorts, retains business alerts, nullable source timestamp with explicit timezone and missing/invalid/future rejection, neutral UI and unknown-last sorting. Three new mandatory regressions pending CI. Backend still has legacy heuristics and timestamp DefaultIfEmpty(UtcNow), so end-to-end provenance not accepted; Desktop and native/production acceptance remain open. No API/schema/role changes.

## Assessment source and Desktop map containment — 2026-11-28
App #78 merged 5e8e96d; CI #240 Mobile 95/95 and all main workflows passed. BE #114 d88e741 removes synthetic scores/AI recommendations and default timestamp, changes existing JSON fields to nullable, retains operational status and scoped RAS/alerts, extends two-area regression. Desktop independently removes map and hash-based grid score, rejects inconsistent area/row scope without first-area fallback and guards load generation, clears snapshots on errors/session, neutral mascot; two mandatory tests pending. Desktop dashboard legacy metrics, Web assessment columns/filters, source contract integration and native/production acceptance remain open. No DB migration or role/sampling changes.

## Nullable dashboard consumers — 2026-11-28
BE #114 merged a8306ca, CI #431/#432 and VPS #229 PASS. App #79 merged 78972cd, Desktop 58/58 (two map regressions), all main workflows green. FE #41 9a7b00d suppresses legacy score/health filters and uses operational status, scoped inventory and recorded alerts. Desktop Dashboard drops metrics and unqualified live overview fetch, strict nullable business counts, no fake trend/combined alert count or layout fallback, neutral assessment, generation guard. Two Desktop and two Node regressions pending CI. No production JWT/device acceptance, broader legacy reports and branch protection remain open.

## CI check — 2026-11-28
FE #41 merged 7fc170b after all four PR workflows passed; main Audit #22 and Sonar #159 passed, Pages #147 in_progress. App #80 de07c7d failed Sonar #244/Desktop Hosted #99/Local #32/Pages #125. Desktop analysis job 140900528366 has two undefined ParamStatus errors at farm_dashboard_service.dart:154, because dashboard_theme.dart import was removed; hosted build confirms same. Mobile job 140900528124 passed. Desktop tests not executed. App main unchanged 78972cd. Check-only; no source edits or merge, journal snapshot kept separate from failing PR head. Restore import and revalidate all checks before merge.

## Dashboard CI correction — 2026-11-28
FE main 7fc170b Audit #22, Sonar #159 and Pages #147 completed success. App #80 corrected the missing ParamStatus import with a selective theme import and removed the redundant Map type check on the typed _decode result, preserving envelope success/nonempty validation, scoped nullable counters, regression tests and required CI. Journal 57 integrated from d1c6baa; section 58 records correction. Single replacement commit on the isolated PR branch, not main; revised CI must pass before merge. Production JWT/native acceptance, remaining legacy reports and required branch protection remain open.

## Home/Health/Reports audit and Home scope containment — 2026-11-28
App #80 merged d72edf3 after all four workflows passed and Desktop job 140902992869 60/60, main #247/Mobile #100/Desktop #102/Pages #128 passed. Mobile Home had old-area relabel, cached failure return, fabricated area and legacy KPI/AI/history/time defaults. Desktop Health page uses empty profile and exports placeholder assessments; BE Efficiency score 30 for empty cohort and zero-denominator rates, Web scope/format issues. Home H01–H03 patch removes cached snapshots, pins immutable identity, checks session/network/area, strict envelope and boxes overview scope, no unscoped history, separates unread from open alerts, clears provider and rejects late data. Four mandatory synthetic tests pending. Remaining Home assessment/default semantics, Desktop Health, BE/Web report contracts, native and production acceptance still open. No schema/role/sampling changes.

## Home CI check — 2026-11-28
App #82 131b9da not merged; main d72edf3 unchanged. Sonar #248 failed Mobile test job 140906580741, analysis passed, Desktop passed; Mobile Hosted #101 passed, Pages #129 success. Three of four new Home regressions failed due to mock adapter accepting /operations/scheduled-tasks/today while actual repository uses /operations/scheduled-tasks; old-area test also timed out; old-credential invalidation test passed. Fix fixture against actual route, verify list/today semantics, ensure delayed test cleanup and remove unnecessary cast warning. Check-only, journal snapshot separate from PR head, no source changes or merge. No production acceptance claim.

## Home CI fixture correction — 2026-11-28
App #82 initial head failed CI #248; Mobile Hosted #101 and Pages #129 passed. The BE list route and today route have different semantics: list is owner/area scoped, today also filters enabled and due date. Preserve existing production list endpoint for this CI correction; correct fixture and assert exact route, bounded start wait and finally/teardown release delayed requests without weakening stale-response assertions. Remove redundant promoted-field cast in HomeNotifier. Integrate journal 61 and 62 into a single replacement commit. Today's task semantics and timestamp defaults remain in follow-up, all revised CI must pass before merge. No role/schema/API changes or production acceptance.

## Home legacy KPI containment — 2026-11-28
App #82 merged 0c3b06c after Sonar #249 (99/99 Mobile tests incl. 4 Home regressions), Mobile #102 and Pages #130 passed; main #250/Mobile #103/Desktop #103/Pages #131 passed. H04–H09 Mobile Home removes legacy metrics/recommendation queries, nullable assessments/counts/time, neutral cards/detail, no fabricated safety claims, preserves disabled unscoped histories, unknown box condition, canonical scoped areaDevices with verified denominator, explicit source timestamps and today scheduled endpoint, pinned unread count independent of open alerts. Three regressions added to mandatory test file, revised CI pending. Native/production acceptance, scoped history contract, Desktop Health and BE/Web reports remain open. No schema/role changes.

## Home nullable consumer CI correction — 2026-11-28
App #83 5c39954 failed Sonar #251 and Mobile Hosted #104 due to 17 nullable consumer compile errors in legacy CrabHomeScreen; Desktop passed, Mobile tests not run. Correct counts/denominator/empty box source, unread badge, nullable timestamps, unknown donut segment and scope guard; preserve existing regression gate. Remaining legacy water card thresholds/sensor selection and Desktop Health export require follow-up. No merge before revised CI, no production acceptance.

## Desktop Health unavailable and export containment — 2026-11-28
App #83 merged dca80f4 after CI #252 102/102 Mobile and all PR/main workflows passed. Desktop Health D01–D08 removed the empty fabricated profile, numeric/diagnostic defaults, formula charts, auto alerts, live label, report construction and clipboard export. Explicit unavailable state, neutral cards, disabled export, back/detail navigation; remove sample/first crab fallback from related shell routes. Three mandatory Desktop regressions pending CI. No verified assessment source connected yet, no new API or DB contract. Remaining Mobile legacy water card, BE/Web report semantics, native/production JWT and branch protection open.

## Desktop Health CI correction — 2026-11-28
App #84 4161846 failed Sonar #254, Desktop Hosted #105, Desktop Local #35 and Pages #135; Mobile validation passed. Desktop analysis job 140912732422 reports nine const errors in the two Health UI files, and all three builds confirm compilation failure. DashboardColors.textPrimary/textMuted are runtime palette getters; remove const only from affected expressions and non-const FilledButton.icon, retain const static children, disabled export, unavailable state, navigation and all mandatory tests. Journal 66. Revised CI must pass before merge; no local Flutter validation or production acceptance. Remaining Mobile water thresholds and BE/Web report semantics stay open; no DB/API/role/sampling changes.

## Mobile Dashboard water provenance — 2026-11-28
App #84 merged 93affe3, all four PR and main workflows passed, Desktop 63/63 including three Health regressions. Mobile dashboard now reuses qualified Home per-sensor overview instead of legacy hardcoded thresholds, 10% margin, value-based selection, conflated TDS/salinity and forced units. Scoped navigation, existing session/transport/lifecycle/freshness guards, RAS shared-area note, separate chemical tests. Delete unused NineWaterMetrics duplicate, two tests in mandatory suite. Journal 67. CI pending; BE/Web Efficiency contract and native/production acceptance remain open.

## Operational Efficiency contract — 2026-11-28
App #86 merged 87e3b53, all PR/main workflows PASS, Mobile 104/104. BE #115, FE #42 and App consumer PR implement nullable empty rates, no unverified health score, current stocked cohort and area gate/marker, strict scope/count/rate validation and UI invalidation, mandatory regressions. Explicit current box/current status limitation; no historical reconstruction. Journal 68. CI and coordinated deployment pending, no production acceptance.

## Operational Efficiency CI / deployment evidence — 2026-11-28
Journal 69–70: BE #433 fixture regression corrected without production changes; #434 PASS and merged 7ecaae7; main #435 PASS (744 passed, 1 skipped), VPS #230 exact SHA PASS and hardwareControlDisabled=true. FE #42 merged e7e939b (main #161/audit #24/Pages #149 PASS, 39 Node tests); App #87 merged 0825eac (main #262/Mobile #113/Desktop #112/Pages #143 PASS, 106 Mobile and 64 Desktop). All eight Efficiency regressions passed. FE/App merged before VPS completion; record ordering deviation. External endpoint reads unavailable, JWT production and cross-client/native smoke checks remain unverified. T05 final acceptance stays open. Docs-only update.

## T05 final acceptance review — 2026-11-28
App #88 merged 9235698, #263/#264 and hosted/Pages main all PASS (106 Mobile, 64 Desktop). Backend/FE exact main evidence remains green. DNS/network prevents direct production checks; no JWT test executed. NT01–NT06 open. Mobile-only FarmStaff cannot use management ReportsController (FA/FM only): remove forbidden management tiles and block direct routes/provider, keep other field tools, no privilege change. Two mandatory regression tests pending. Read-only smoke script and manual acceptance matrix added; no production/hardware tests claimed. Journal 71. T05 not closed; wider P2.4.6.1 still requires separate T04/T06–T12 evidence and refreshed integration pins.

## T05–T12 readiness review — 2026-11-28
App #89 merged 92e0b7b; all PR/main checks PASS, 108 Mobile and 64 Desktop. NT01–NT06 remain open for live acceptance (direct DNS failure, no JWT/fixture, no client smoke). FE #24 security gate 6/6 and full/omit-dev audit zero; branch protection inaccessible, rulesets empty. Kiosk #31 a0f95a8 repins mandatory cross integration to BE 7ecaae7, pending CI; private AI still pins BE 5f4415f and Kiosk 98458f3 with geometry disabled. T07–T12 are outstanding acceptance work, not completed by a green CI. See journal 72 for details; no role/schema/firmware/sampling changes and no P3 transition.

## T07 private integration repin — 2026-11-28
Kiosk #31 merged 9265e1d after #79 PASS; main #80 PASS, public cross PR/main exact BE 7ecaae7 TRX 1/1, no skips. App #90 merged 57d8590, #267/#268 and hosted/Pages main PASS, 108 Mobile/64 Desktop. Private AI #10 5180317 repins both merged public heads, retains existing synthetic HTTP/PostgreSQL fixture and mandatory TRX gate; CI pending. Geometry remains disabled in this compatibility suite. Journal 73; actual JWT, native, geometry, media and physical acceptance remain open.

## T08 geometry-required cross integration — 2026-11-28
Water AI #10 merged df0d4a6; CI #39/#40 and private cross #12/#13 PASS, exact BE/Kiosk pins, TRX 1/1 no skips, Python main 14 passed (1 warning). App #91 merged 528637a, all PR/main checks PASS. Water AI #11 da7ee46 adds separate mandatory compatibility and strict geometry matrix jobs, deterministic synthetic anchor PNG/JPEG, signed fit and shifted in-range NO3 rejection, preserved accepted channels and persisted geometry evidence, no publication, focus-loss regression. Journal 74; revised CI pending, production geometry enforcement, actual fixture/chemistry, media/Drive, real JWT, native and hardware acceptance remain open.

## T08 media acceptance — 2026-11-28
Water AI #11 merged 3fa11fe; Python #43 15 passed/1 warning, private cross #14/#15 both modes passed 1/1 no skip; App #92 merged 3454036 with all main checks PASS. Water AI #12 4b31e1f adds private ACL denial, receipt hash readback, post-receipt tamper and no inference reservation tests (storage double). Added read-only actual provider smoke and isolated write/ACL/quota acceptance guide; live tests not executed. Journal 75. T08 remains open for CI and real Drive/physical acceptance.

## T09 snapshot consistency — 2026-11-28
Water AI #12 merged cb55a0c, #45/#46 and cross #16/#17 both modes PASS (1/1 each no skip, 15 Python); App #93 merged 230cd7c with all main checks PASS. T09 first increment validates complete receipt inventory and batch/connection identities, unique channel/receipt IDs and review publication assessment/measurand in both Dart monitors. Four regression tests added. CI pending. Live Drive/JWT/native and full T09 cross-client acceptance remain open. Journal 76.

## T09 estimate provenance — 2026-11-28
App #94 and FE #43 PR/main checks PASS; merged af83b39/642df73. App next increment requires verified server evidence, matches receipt IDs/digests and values, rejects legacy mismatch; logical cancellation stops follow-up and stale render. Four regressions pending CI. Journal 77. Live Drive/JWT/native and T09 acceptance open.

## T09 code/CI and T10 isolation — 2026-11-28
App #95 and FE #44 merged c74285e/d74196b; all PR/main checks PASS, 112 Mobile/68 Desktop/43 Node, real Chromium retry and invalid-provenance refresh PASS. T09 software evidence accepted, production/native open. Firmware main b552498 #24 host + three target builds PASS; legacy draft #1 not merged. Firmware #14 35ba61e blocks root legacy sketch compilation and adds isolation/default-off guards; Kiosk #32 d9603f8 tests wrong gateway versions, negative ACK and raw actions. Both pending CI. BE #435 job 140925155841 clean and legacy full migrations PASS; no new schema. Journal 78. Actual UART, wiring, chemical calibration, Drive and JWT remain open.

## T10 main and T11 readiness — 2026-11-28
Firmware #14 merged b00ad7d main #26 PASS (host and all three targets); Kiosk #32 merged ad3e21e main #82 PASS (85 Windows, cross 1/1 no skip); App #96 merged 0431532 and all main checks PASS. Private AI #13 f7d8564 repins Kiosk to ad3e21e, BE unchanged, both cross modes #18 and CI #48 pending. T11 preliminary: direct DEV-Khanh auto-merge/push has no CI gate in workflow, branch protection inaccessible; backup archive list is not full restore verification. See journal 79 and T11 acceptance plan. Do not close T10/T11 or change production before acceptance.

## T11 CI security and isolated recovery — 2026-11-28
Private AI #13 merged fffcfda with #48/#49 and #18/#19 both modes PASS (each 1/1 no skip, Python 15 passed); App #97 merged b1c98cc and all main checks PASS. BE #116 75d705a removes unsafe direct merge, adds mandatory security/NuGet gate, latest exact-main deploy check and production-service backup/restore in disposable PostgreSQL. CI pending. Branch protection/admin, production checksums/offsite and real recovery remain open. Journal 80.

## T11 CI #436 correction — 2026-11-28
BE #116 original CI failed CS4007 in both unit and PostgreSQL jobs, audit parser rejected omitted clean frameworks. Actual audit artifact 15258804804 reports 3 packages/4 distinct High advisories. Replacement commit 6fc5820 (one commit, 13 files) fixes span/await, parser with mandatory six regressions, patches dependencies, keeps high/critical gate and all recovery checks. Recovery not executed successfully. App #98 merged 622bda1; journal 80 merged. Journal 81 records failure and correction. No production or schema change, new CI pending.

## T11 CI #437 recovery correction — 2026-11-28
BE #116 6fc5820 unit 744 PASS/2 integration skips and security actual audit zero across all severity levels; recovery final FK probe failed 23505 instead of 23503, not a full recovery pass. Replacement d74298e isolates one measurement and verifies absent parent, exact FK code/table/schema plus post-rollback snapshot. Full CI pending. App #99 merged 1433d20, journal 81. Journal 82 documents correction. No production restore or merge/deploy of BE.

## T11 isolated recovery and deployed BE — 2026-11-28
BE #116 merged 6648750; CI #438/#439 all PASS, NuGet five projects all severities zero. Recovery jobs 140952358322/140953532783 each 1/1 PASS with mandatory marker and clean/legacy migration markers; rounded whole-test durations 2s/1s, individual timing not exposed/retained. VPS #231 job 140954410188 exact SHA deploy PASS, predeploy archive verified, health/CORS PASS, hardware control disabled. App #100 merged 55112fd, all main checks PASS. Journal 83. Next refresh Kiosk/AI pins; SEC02, production backup integrity/offsite, individual metrics/production RTO/RPO, real Drive/JWT/physical acceptance remain open.

## T11 Kiosk Backend repin — 2026-11-28
App #101 merged 8efa00c, #289/#290 and all main preview/Pages checks PASS. BE 6648750 remains deployed, #439/#231 PASS. Kiosk #33 78b05db updates exact BE checkout/assertion and explicit executed/no-skip TRX guard, one CI-only commit; PR/main validation pending. Private AI pins unchanged until Kiosk acceptance. Journal 84; live and recovery metrics gates remain open.

## T11 Kiosk acceptance and private repin — 2026-11-28
Kiosk #33 merged 3447793, #83/#84 all PASS; both exact BE 6648750 cross jobs 1/1 executed, zero skip, Windows 85/85. BE #439/VPS #231 PASS. App #102 merged dc93281, #291/#292 and all main previews/Pages PASS. Private AI #14 540637a updates both exact pins and assertions, mandatory compatibility and geometry-required checks retained, PR/main pending. Journal 85. No additional live acceptance; recovery timing and production gates remain open.

## T11 private integration accepted and REC04 instrumentation — 2026-11-28
Private AI #14 merged 0b770f6, #51/#52 and cross #20/#21 both modes PASS, 1/1/no skip per job, exact BE 6648750/Kiosk 3447793; Python 15 passed/1 warning. App #103 merged fc71a44 and all main checks PASS. BE #117 84bd3a7 adds mandatory separate measured backup/restore metrics and retained TRX outside disposable cluster, artifacts 14 days; CI pending. Journal 86. Do not infer production RTO/RPO from isolated service-call times. SEC02/actual backup integrity, offsite, media and production/physical acceptance open.

## REC04 acceptance — 2026-11-28
BE #117 merged 6e1fd8d, CI #440/#441 PASS. Downloaded/inspected recovery artifacts 15266347768/15267215600: exact two files, TRX 1/1/no skip, 107 tables, SHA-256 verified; PR backup/restore 204/480ms, main 300/832ms, restore includes safety backup. Scope isolated synthetic only. App #104 merged 757cc9d, all main checks PASS. VPS #232 pending at review; dependent pins still BE 6648750. Branch protection 403 across five repos, BE Sonar scan skipped, production checksum/offsite/RTO/RPO/media and live acceptance open. Journal 87.

## REC04 VPS and REC05 readiness — 2026-11-28
VPS #232 exact BE 6e1fd8d PASS (health/CORS/hardware disabled, DEPLOY_OK 21:22:09 ICT); App #105 merged ac49fc7 and all main workflows PASS. Kiosk #34 c34e5cd pin update CI #85 pending; private AI unchanged until Kiosk main acceptance. REC05 source review confirms existing storage double negative tests and snapshot-only provenance flag; isolated DB/media restoration matrix documented, not yet executed. Journal 88.

## REC05 isolated implementation — 2026-11-28
Kiosk #34 merged db9aeb8, #85/#86 PASS with exact BE 6e1fd8d, cross 1/1 no skip each, Windows 85/85. App #106 merged 6d3a82e and all main checks PASS. Private AI #15 a325b0d combines both pin updates and actual isolated DB/media restore test, mandatory metrics/TRX for both modes. Raw content SHA guard explicitly remains false; assessment path rejects mismatch. CI pending; actual Drive and production gates remain open. Journal 89.

## REC05 CI #22 correction — 2026-11-28
Private AI #15 a325b0d Python PASS but both cross modes FAIL pg_restore 18.7 -> server 16 unsupported transaction_timeout; both artifact uploads also failed storage quota, no artifacts. Replacement 7105dc6 explicitly matches PostgreSQL 16 client and verifies server major, retains all gates and required uploads; redacted summary added. App #107 merged 3fa79ca and all main checks PASS. Journal 90. No new REC05 marker or raw-content guard acceptance. Actual Drive and production gates open.

## REC05 isolated test PASS, artifact blocked — 2026-11-28
Private AI #15 7105dc6 #56 PASS, cross #23 both real test steps PASS and both emit REC05_ISOLATED_RECOVERY_PASSED=1, TRX counters 1/1/no skip per mode, 3 media/16 receipts, PG client 16.16, exact new pins. Both required uploads fail storage quota; no downloadable artifacts and overall FAIL, unmerged. Raw content hash guard remains false and real Drive unverified. App #108 merged 446fe84 all main checks PASS. Journal 91. Resolve quota, rerun and verify downloadable evidence before merge; then M05 backend guard.

## REC05 rerun after premature merge — 2026-11-28
Private AI #15 already merged externally at 20f75bb despite #23 quota failure. Water AI main #57 PASS, cross #24 running; failed-job rerun of #23 accepted, both new jobs running. Neither run has artifacts at review. Billing/storage endpoints unsupported by connector, no quota change or deletion. App #109 merged a6071ef and all main checks PASS. Journal 92. Require actual main and retry markers and downloadable evidence before M05 guard work; production gates unchanged.

## REC05 retry and main results — 2026-11-28
Private AI #23 attempt 2 (46156195649) jobs 141020791377 compatibility/141020791531 geometry-required and main #24 (46158438969) jobs 141020139399 compatibility/141020139101 geometry-required all executed actual REC05 tests, each total=executed=passed=1, failed=notExecuted=0. All four emit REC05_ISOLATED_RECOVERY_PASSED=1, 3 media/16 receipts, restored/source_unchanged/missing_rejected/acl_rejected/inference_hash_rejected/receipt_digest_rejected/provenance_digest_rejected/correct_bytes_verified=true, raw_content_hash_guard/production_published/real_drive_verified=false. Test durations 25/35s on retry and 36/25s on main. All four required uploads failed artifact storage quota, both run artifact lists empty; overall both workflows FAILURE. No downloadable TRX/JSON; M08 evidence retention and M05 raw-content guard remain open. No rerun requested again because quota remains unresolved; no deletion, billing change or gate bypass. Admin must resolve quota before rerunning, then verify retained artifacts and main. Private AI #15 previously merged 20f75bb despite failed gate, not newly merged in this review.
App #110 merged 7a36c10, all main checks PASS. Journal 93. No runtime changes.
