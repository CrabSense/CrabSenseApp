# CrabSense role contract (P0)

The BE UserRole enum is authoritative. Wire names are case sensitive.

| Role | Web | Desktop | Mobile |
| --- | --- | --- | --- |
| SystemAdministrator | yes | no | no |
| FarmAdministrator | yes | no | no |
| FarmManager | no | yes | no |
| FarmStaff | no | no | yes |

Missing or legacy role names must not grant access. Apply the allowlist before token persistence, session restore, and token refresh. The platform gate is not a substitute for server-side API authorization and farm-area scoping. No role migration or additional privileges are implied.
