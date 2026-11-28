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
