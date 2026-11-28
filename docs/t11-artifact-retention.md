# T11 Actions artifact retention policy

P0 App: compile/test/packaging still runs on existing triggers. Only upload preview handoff when the exact corresponding deploy condition is true. Retain Desktop/Mobile preview package 1 day; Pages package 1 day. Deployment still depends on successful build and artifact download; disabled preview/PR build still runs. No changes to staging guards or credentials. Long approval waits exceeding one day require a fresh workflow run rather than weakening controls.

P1 Kiosk: existing optional cross-integration TRX 3 days; leave unchanged. Historical usage requires admin inventory, not inferred current bytes from GB-hours.

P2 Backend: proposed 2-day test/coverage, 7-day NuGet audit, preserve mandatory REC04 14 days; no change to migration/deploy gates. P3 FE: proposed browser failure diagnostics 2 days and candidate artifacts 3 days, retain dependency audit evidence. P4 Private AI: preserve REC05 required upload, metrics and TRX 14 days. P5 verify CI and exact main, then quota availability before rerunning #23/#24. No artifact deletion or spending change. Reducing retention affects future uploads only; no immediate quota resolution claimed.
