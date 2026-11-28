# T11 — Security, CI/CD, Backup and Recovery acceptance

Status: preliminary review, waiting on Private Water AI #13 PR/main CI. Do not perform production restore, change live ACLs, enable hardware, or bypass required checks.

| Gate | Existing evidence | Required next action |
|---|---|---|
| SEC01 CI merge safety | BE auto-merge-dev-khanh.yml pushes a merge directly to main with contents:write, no CI check in the workflow | Remove direct push path; use reviewed PR and required CI, verify no bypass with repository admin |
| SEC02 Branch protection | BE protection GET 403, rulesets response empty | Admin verify required checks per repo, PR requirement, no force pushes or deletions and authorized exceptions; record redacted configuration |
| SEC03 Dependency and credentials | FE audit previously zero, production deployment has private staging and secret file permissions | Recheck current audits, secret handling and least privilege; no token or secret values in output |
| SEC04 Deploy gate | exact successful main SHA, migration guard, predeploy archive, health and hardware-disabled checks | Negative CI tests for stale SHA, failed health, mismatched schema rollback; preserve fail-closed behavior |
| REC01 Backup archive | schema be custom pg_dump, partial file, archive list validation and retention | Verify integrity of an actual backup via SHA-256 stored independently; verify permissions, separate copy, retention and free space |
| REC02 Restore safety | platform role + literal confirm, operation lock, maintenance flag, pre-restore backup and single transaction | Review maintenance scope, archive validation, backup compatibility and authorization; test on isolated DB only |
| REC03 Recovery drill | clean and legacy migration suite passed, not a restore test | Create synthetic isolated PostgreSQL DB, dump via real provider tools, restore into a distinct disposable DB; verify schema/migration history, row counts and relational invariants, tamper/truncation rejection and no overwrite of source |
| REC04 Recovery time | not measured | Measure backup/restore duration and recovery point from drill; record observed RTO/RPO, do not promise a target without evidence |
| REC05 External evidence | real Drive/JWT checks not accepted | Verify restored private Media/Receipt/Provenance references with approved test provider; no production access or mutation without separate acceptance |

Sequence: complete private cross PR/main, implement CI merge guard first, add isolated restore integration and negative tests, then administrator verification and controlled recovery drill. Keep production deployment hardware disabled. No automatic production DB rollback. Backup list success and migration success do not demonstrate disaster recovery. Current archive checksum, actual offsite copy and restore verification are not established. No production database credentials needed for CI.

## 2026-11-28 implementation update
BE #116 (75d705a) implements SEC01, CI portion of SEC03 and SEC04; adds isolated service recovery for REC01–REC03. Mandatory PR CI pending. SEC02 remains blocked by administrator permissions. Do not mark production checksum/offsite backup, live rollback, recovery or RTO/RPO as accepted from CI. See BE docs/t11-security-recovery.md. Repin Kiosk and private AI only after new BE main CI and VPS deploy acceptance.

## CI #436 correction
BE #116 replacement 6fc5820 fixes CS4007 and actual audit schema, remediates three affected packages/four distinct High advisories observed in artifact 15258804804. Mandatory parser regression and recovery test remain enabled. No production recovery established; all acceptance conditions unchanged. See journal 81 and BE T11 security/recovery notes.

## CI #437 recovery correction
Actual five-project NuGet audit passed with zero advisories across severity levels; unit tests passed. Recovery reached final FK assertion but failed due to replay unique collision. BE #116 d74298e targets one restored measurement with verified absent parent and asserts correct FK code/table/schema plus post-rollback snapshot. Await full CI; production integrity/offsite and administrator acceptance remain open.

## CI #438 / main #439 and VPS #231 acceptance
SEC01, SEC03, SEC04 and isolated REC01–REC03 passed mandatory PR/main CI on BE 6648750. Five-project NuGet audit zero advisory occurrences; isolated recovery executed 1/1 with marker on both. Whole-test duration 2s PR, 1s main; exact backup/restore metrics not present in public workflow logs or separately retained TRX. Add metric export and retained recovery report in follow-up, do not infer production RTO/RPO. VPS #231 verified predeploy archive, exact CI/SHA, migration, health, CORS and hardware-disabled state. No production restore. SEC02/production backup integrity/offsite/REC04/REC05 still open. Repin Kiosk then private AI before accepting cross integration against new BE.

## Kiosk repin after deployed BE acceptance
Kiosk #33 (78b05db) pins exact deployed BE 6648750 and strengthens mandatory executed/no-skip TRX assertion. Require Kiosk PR/main PASS before private AI repin. Previous write was blocked, current PR created. No production changes or additional recovery acceptance. Journal 84.

## Kiosk main accepted; private AI repin
Kiosk #33 merged 3447793, PR/main #83/#84 PASS; exact BE 6648750 cross 1/1/no skip on each and Windows 85/85. App #102 merged dc93281, all main checks PASS. Private AI #14 540637a repins both repositories, PR/main mandatory matrix acceptance pending. Journal 85. Retain all production and individual recovery timing gates.

## Private integration acceptance and REC04 implementation
Private AI #14 merged 0b770f6, both PR/main compatibility and geometry modes 1/1 PASS without skips on exact BE 6648750/Kiosk 3447793. BE #117 84bd3a7 adds actual separate service-call durations in validated JSON and retains Recovery TRX, both uploaded for 14 days. Restore duration includes pre-restore safety backup. New CI required for numeric results and artifact verification. No production RTO/RPO claim or live restore. Journal 86.

## REC04 accepted in isolated CI
BE #117 6e1fd8d, #440/#441 PASS. Verified both downloaded recovery ZIPs (PR 15266347768, main 15267215600) against CI logs: backup 204/300ms, restore 480/832ms, 107 tables and SHA-256 verified, TRX 1/1 PASS/no skip. Restore includes safety backup; not production RTO/RPO. App #104 main accepted. Deploy #232 pending at review and Kiosk/AI pins remain on 6648750. SEC02 protection inaccessible (403 on five repos); actual BE Sonar scan skipped. Persistent production backup checksum/offsite copy, actual RTO/RPO and REC05 real media recovery still open. Journal 87.

## REC04 deployment and REC05 design
VPS #232 exact 6e1fd8d accepted; Kiosk #34 repin CI #85 pending. Private AI repin requires accepted Kiosk main. REC05 proposed isolated recovery acceptance matrix in docs/t11-rec05-media-recovery.md. Existing snapshot_verified does not prove current media bytes; mediaContentRechecked=false is explicit. No provider/production recovery accepted. Journal 88.

## REC05 isolated test implementation
Kiosk #34 main db9aeb8 accepted with BE 6e1fd8d. Private AI #15 a325b0d repins both and extends existing matrix fixture with actual local database restore, independent synthetic media map, receipt/provenance validation, missing/ACL/corrupt bytes and tampered linkage checks, retained TRX and redacted metrics. CI pending. Raw content GET integrity guard remains open (raw_content_hash_guard=false); real Drive/RTO/RPO/production still unverified. Journal 89.

## REC05 CI #22 failure correction
Both private cross jobs failed actual restore with client 18.7 against server 16; artifact quota exhausted independently. Private AI #15 replacement 7105dc6 fixes runner/client selection and asserts server version; mandatory artifacts and all integrity tests retained. No artifacts from #22 and no REC05 acceptance. Admin must resolve quota if persistent. Raw content SHA guard deferred until baseline PASS. Journal 90.

## REC05 isolated test results and evidence blocker
Cross #23 jobs 141013278383/141013278538 both emitted actual REC05 marker and 1/1/no-skip TRX counters; 3 media and 16 receipts, exact BE 6e1fd8d/Kiosk db9aeb8, 36s/22s. All tested isolated integrity assertions passed. Both required artifact uploads fail quota, no downloadable artifacts and workflow failure. No merge or quota bypass. M05 raw content SHA guard and M08 retention still open; real Drive and production not accepted. App #108 main PASS. Journal 91.
