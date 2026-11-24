# CrabSense Desktop — two preview modes

## Local (already supported)

Open repository root in VS Code, Run and Debug → Desktop Preview (Chrome) → F5.
Save Dart files to hot reload at http://localhost:5500. Keep Flutter 3.35+
and a non-secret .env with the local/test API URL. This remains debug-only.

## Hosted (GitHub Actions)

Main pushes trigger a release build. Pull requests build an artifact but
never deploy. Use Actions → Desktop Hosted Preview → Run workflow for a
manual main build. Deployment is deliberately off until configured.
The proposed URL is https://desktop-preview.khanhtn45.id.vn.

### One-time setup (operator)

1. Create DNS for the preview subdomain and configure TLS on the VPS.
   Set up a separate HTTPS **test** API and database with hardware control
   disabled, and allow the exact preview origin in its CORS config.
   Do not point this preview at production or reuse production credentials.
2. Create a dedicated non-root SSH deployment user (e.g. crabpreview)
   with its own SSH key. Grant write access only to the preview directory.
   Example as VPS administrator (adjust Nginx group for your distribution):
   
   ```sh
   sudo install -d -o crabpreview -g www-data -m 0755 /var/www/crabsense-desktop-preview
   sudo install -d -o crabpreview -g www-data -m 0755 /var/www/crabsense-desktop-preview/releases
   sudo install -d -o crabpreview -g www-data -m 0700 /var/www/crabsense-desktop-preview/incoming
   sudo htpasswd -c /etc/nginx/crabsense-desktop-preview.htpasswd preview
   sudo chown root:www-data /etc/nginx/crabsense-desktop-preview.htpasswd
   sudo chmod 0640 /etc/nginx/crabsense-desktop-preview.htpasswd
   ```
   
   Install deploy/desktop-preview/nginx.conf.example as a separate site,
   after adjusting certificate paths. Run nginx -t before reloading Nginx.
   Ensure unauthenticated HTTPS GET / returns 401 (not a public site).
   Do not change the existing FE virtual host or API service.
3. In **CrabSenseApp** → Settings → Secrets and variables → Actions,
   add repository variables:
   
   | Variable | Value |
   |---|---|
   | DESKTOP_PREVIEW_ORIGIN | https://desktop-preview.khanhtn45.id.vn |
   | DESKTOP_PREVIEW_API_URL | HTTPS origin of the isolated test Backend |
   | DESKTOP_PREVIEW_SSH_HOST | VPS hostname/IP |
   | DESKTOP_PREVIEW_SSH_USER | Dedicated non-root deployment user |
   | DESKTOP_PREVIEW_DEPLOY_ENABLED | true (set last) |
   
   Create GitHub environment desktop-preview, restrict deployments to main,
   and add environment secrets (or repository Actions secrets):
   
   | Secret | Value |
   |---|---|
   | DESKTOP_PREVIEW_SSH_KEY | Dedicated deployment private key |
   | DESKTOP_PREVIEW_SSH_KNOWN_HOSTS | Verified SSH host key line (not blindly ssh-keyscan) |
   | DESKTOP_PREVIEW_HTTP_USER | Basic Auth smoke-test username |
   | DESKTOP_PREVIEW_HTTP_PASSWORD | Its password |
   
   Do not copy VPS root credentials from another repository. Secrets are
   not embedded in the Flutter build. API URL is public configuration.
4. Enable the variable and run Desktop Hosted Preview on main. A successful
   deploy verifies anonymous access is denied and authenticated version.json
   matches the commit; otherwise it rolls back the current symlink.
   Log in with a **test Farm Manager** account. Admin/Staff roles remain denied.
   Test UI routes and browser-specific limitations manually.

## Deployment isolation

The workflow only uploads to /var/www/crabsense-desktop-preview.
It never restarts the Backend, migrates a database, modifies other Web
roots, or changes Nginx config on each deployment. SSH host keys are pinned.
Deploys are serialized and stale main revisions are skipped. Old preview
releases can be removed manually after confirming current/rollback targets.
The site requires HTTPS Basic Auth and normal Manager authentication.
Client origin checks are defense in depth, not authorization.
Use a test Backend; the preview can perform real operations against its
configured API. Native camera, Wi-Fi, LAN, file handling and hardware
workflows still require Windows acceptance. Do not use preview for
production operations.

Check exact deployed revision at /version.json after login to the site.
The hosted workflow refreshes after push, not on Ctrl+S; local mode is
the hot-reload option. With deploy disabled, download the CI artifact for
inspection, but it will only run on the configured HTTPS origin.

## GitHub Pages — no VPS for the preview frontend

1. In CrabSenseApp Settings → Pages, select GitHub Actions as the source.
   The public project-site URL is https://crabsense.github.io/CrabSenseApp/.
2. Optionally configure repository Actions variable DESKTOP_PAGES_TEST_API_URL
   with the HTTPS origin of an isolated test API (no /api suffix). The
   Pages workflow refuses the known production site and Pages origin. An
   unset variable publishes the login UI only; no login or session restore.
3. Configure CORS on the isolated test API: add https://crabsense.github.io
   (origin only, no /CrabSenseApp/ path). Production repo defaults already
   include this origin; Development defaults do not. Change the test
   instance's effective AllowedOrigins configuration, preserving existing
   entries, and restart only the test API if required. The workflow checks
   /health and login CORS preflight before publishing a configured build.
4. Run Actions → App GitHub Pages on main. Subsequent main pushes build
   and deploy Desktop and Mobile together automatically; pull requests only compile and run tests.
5. Open the deployed URL. Verify /CrabSenseApp/version.json for commit SHA.
   If an API is configured, verify Manager login, reject other roles, and
   check dashboard and menu routes using only test data.

GitHub Pages is public and not an access-controlled internal preview. All
projects under crabsense.github.io share an origin; use test credentials
only. Do not store secrets in variables or .env; build assets are public.
The normal API still enforces authentication/role/area authorization.
Use Local Preview or the protected VPS option for non-public datasets.
No DNS, SSH keys or separate Nginx setup are required for the Pages UI.

Mobile is published in the same Pages artifact at /CrabSenseApp/mobile/.
See [Mobile preview](MOBILE_PREVIEW_DEPLOY.md). Desktop root remains unchanged.
