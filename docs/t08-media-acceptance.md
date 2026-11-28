# T08 — Private media production acceptance

## Automated CI evidence and limitation
Private Water AI integration uses a storage double labelled GoogleDrive; no provider network, credentials or quota. Geometry and compatibility jobs must pass the media ACL rejection, no ACK/cleanup, authorized readback, post-receipt corruption and no inference reservation checks. Live Drive acceptance remains separate.

## Read-only smoke on an authorized workstation
Use an existing assessed WaterBench batch, an original unmodified JPEG from Kiosk spool/approved archive, and existing authorized identities. Never paste tokens into chat, logs or source. Python 3.10+:
```powershell
python docs/t08_media_smoke.py --area AREA_UUID --station STATION_UUID --boot BOOT_HEX16 --batch BATCH_HEX16 --analyte NO2 --original "D:\\path\\original.jpg"
```
Enter SystemAdministrator, same-area FarmAdministrator/FarmManager/FarmStaff and a FarmAdministrator assigned only elsewhere at hidden prompts. Script uses HTTPS GET only, no redirects, bounded downloads, compares original JPEG, receipt and signed-calibration inference provenance, checks metadata readiness with two distinct roots and current authorized byte readback, rejects unauthenticated and foreign-scope reads. No raw image or token output. It checks an existing inference snapshot (not a new estimate); the snapshot digest is not an external digital signature. A legacy or needs-retest record is not eligible. Exit 0 = selected read-only checks passed; exit 1 = failed/blocked. Do not generate an assessment or modify ACLs solely to make this smoke pass.

## Separate controlled real-provider acceptance (not executed)
1. On a designated non-production Drive root/account and test environment, use the real backend provider configuration; no shared public/private folder ID. Confirm metadata readiness, then upload one synthetic JPEG through normal Kiosk capture flow.
2. Compare Kiosk bytes, media ID, receipt and backend download hash/length. Inspect folder ancestry and permissions (including inherited anyone access); private media must not have public share link.
3. In an isolated test root only, test denied/missing provider permissions, altered bytes, quota failure, upload/readback failure and rollback/cleanup; no successful ACK or AI estimate from damaged bytes. Do not change production ACLs or delete production evidence. Verify restored clean fixture independently.
4. Check repeat and duplicate upload, retention/orphan reconciliation, private reference evidence and review/publication policy. Record redacted timestamps, role, provider and pass/fail only.

Live write/quota, actual ACL negative tests, physical calibration and chemistry remain open. Hardware control stays disabled.
