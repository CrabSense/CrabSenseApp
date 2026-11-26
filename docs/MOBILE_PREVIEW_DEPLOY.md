# CrabSense Mobile Web Preview

GitHub Pages publishes both Flutter applications in a single artifact through
the existing desktop-github-pages.yml workflow (App GitHub Pages).

- Desktop: https://crabsense.github.io/CrabSenseApp/
- Mobile: https://crabsense.github.io/CrabSenseApp/mobile/
- Mobile revision: /CrabSenseApp/mobile/version.json

Main pushes publish both apps; PRs compile without deployment. Enable
Settings → Pages → GitHub Actions if not already enabled.

Set the repository variable MOBILE_PAGES_TEST_API_URL to the HTTPS origin
of an isolated test API (no /api suffix). If unset, the workflow uses
DESKTOP_PAGES_TEST_API_URL. If neither is set, Mobile login and session
restore are disabled. The workflow checks test API health and login CORS.
Allow https://crabsense.github.io in test API CORS. Never use production
credentials or a production database. Pages assets are public and both
apps share an origin; Mobile auth keys are prefixed to avoid accidental
session collisions, not to provide a security boundary.

The separate Mobile Hosted Preview workflow is optional for private VPS
hosting and disabled unless configured. It is not required for Pages.

Local: cd crabsensemobile; flutter pub get; flutter run -d chrome
--dart-define=API_BASE_URL=http://localhost:5080.

Test with the existing authorized Mobile roles and synthetic data.
Check login, logout, navigation, dashboard and online CRUD. Camera, QR,
uploads, push and biometrics need browser/device acceptance. The existing
web database executor does not persist offline data; do not rely on offline
writes or background synchronization in the browser.
