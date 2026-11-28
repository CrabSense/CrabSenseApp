# T05 — production acceptance (NT01–NT06)

**Status:** code/CI evidence is green for BE/FE/App before this patch; production acceptance BLOCKED by inaccessible DNS/network and absent authenticated test credentials. Do not close P2.4.6.1 or proceed to physical control on this evidence.

## Read-only API smoke (NT01–NT03)
Run Python 3.10+ from an authorized workstation connected to production:
```powershell
python docs/t05_production_smoke.py --area AREA_UUID --denied-area OTHER_UUID --from-date YYYY-MM-DD --to-date YYYY-MM-DD --empty-from YYYY-MM-DD --empty-to YYYY-MM-DD --expected-total N
```
Replace placeholders with actual GUIDs, a known independently verified positive cohort count in the selected area, and a disjoint known empty date interval. Both FA and FM test accounts must be assigned to AREA_UUID and not OTHER_UUID; use existing authorized test identities for four roles. Enter access JWTs locally at hidden prompts; never paste them into chat, commit them, or record headers. The script only uses HTTPS GET, rejects redirects, validates identity, 401/403, counts/rates/area/basis, no health score and hardware-disabled health. Exit 0 = tested API assertions pass, 1 = failed/blocked, 2 = no actual zero demonstrated. No production data writes, no fixture creation. A real-zero cohort must contain a zero rate.

## Manual UI acceptance (NT04–NT05)
| Role/platform | Action | Expected |
|---|---|---|
| FA/Web | Open Operational Reports and Analytics with same area/date cohort | API and displayed totals/rates agree; null has no unit/progress or health score |
| FA/Web | Apply area switch during slow request, refresh, export JSON | Old result disappears, no stale export; JSON scope matches selected report, no fabricated score |
| FM/Desktop | Select same area/date and open Efficiency | Same cohort as Web; selected area and current-status basis, unknown rates rendered as dash |
| FS/Mobile | Open Reports hub, direct deep link each management report | No management cards, no fetch or export; explicit forbidden state, water-quality/field tools remain |
| SA/Web | Attempt management report using own account | API 403; no business report export |
| Mobile/desktop/web | Test shared RAS with known sensor data, absent data and disconnect/reconnect | Area representative inlet/outlet data only; separate TDS and chemistry, no synthetic readings, reject stale/wrong scope |
| Desktop native | Test authorized scoped sensor history CSV and cancel/save dialog, session change | Exact timestamp/value/units, no legacy/cache fallback, deny stale export |
| Mobile native | Switch account/area, background/foreground, cache invalidation | No cross-scope or offline fabricated readings |

No uploads of real business exports to public locations. If using the same cohort on Web/Desktop, avoid concurrent stocking/status changes or repeat comparison with independent current data. Date windows are UTC calendar dates, not historical as-of.

## NT06 closure
Record UTC timestamp, exact deploy SHA, anonymized role/case, HTTP status and pass/fail (no tokens, personal data or raw business JSON). Repeat unresolved checks after the App role patch passes CI. Review remaining T04 offline/native, T06 security/branch protection and T07–T12 cross-repo, real JWT, geometry/media, recovery and hardware acceptance separately. Current-box scope is not historical assignment. Never enable hardware control for this smoke.
