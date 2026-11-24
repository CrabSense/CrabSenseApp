# CrabSense Mobile — two preview modes

## Local (already supported)

From crabsensemobile, run `flutter pub get` and `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5080` for local testing.

## Hosted (GitHub Actions)

Main pushes trigger a release build. Pull requests build an artifact but
never deploy. Use Actions → Mobile Hosted Preview → Run workflow for a
manual main build. Deployment is deliberately off until configured.
The proposed URL is https://mobile-preview.khanhtn45.id.vn.

### One-time setup (operator)

1. Create DNS for the preview subdomain and configure TLS on the VPS.
   Set up a separate HTTPS **test** API and database with hardware control
   disabled, and allow the exact preview origin in its CORS config.
   Do not point this preview at production or reuse production credentials.
2. Create a dedicated non-root SSH deployment user (e.g. crabpreview)
   with its own SSH key. Grant write access only to the preview directory.
   Example as VPS administrator (adjust Nginx group for your distribution):
   
   ```sh
   sudo install -d -o crabpreview -g www-data -m 0755 /var/www/crabsense-mobile-preview
   sudo install -d -o crabpreview -g www-data -m 0755 /var/www/crabsense-mobile-preview/releases
   sudo install -d -o crabpreview -g www-data -m 0700 /var/www/crabsense-mobile-preview/incoming
   sudo htpasswd -c /etc/nginx/crabsense-mobile-preview.htpasswd preview
   sudo chown root:www-data /etc/nginx/crabsense-mobile-preview.htpasswd
   sudo chmod 0640 /etc/nginx/crabsense-mobile-preview.htpasswd
   ```
   
   Install deploy/mobile-preview/nginx.conf.example as a separate site,
   after adjusting certificate paths. Run nginx -t before reloading Nginx.
   Ensure unauthenticated HTTPS GET / returns 401 (not a public site).
   Do not change the existing FE virtual host or API service.
3. In **CrabSenseApp** → Settings → Secrets and variables → Actions,
   add repository variables:
   
   | Variable | Value |
   |---|---|
   | MOBILE_PREVIEW_ORIGIN | https://mobile-preview.khanhtn45.id.vn |
   | MOBILE_PREVIEW_API_URL | HTTPS origin of the isolated test Backend |
   | MOBILE_PREVIEW_SSH_HOST | VPS hostname/IP |
   | MOBILE_PREVIEW_SSH_USER | Dedicated non-root deployment user |
   | MOBILE_PREVIEW_DEPLOY_ENABLED | true (set last) |
   
   Create GitHub environment mobile-preview, restrict deployments to main,
   and add environment secrets (or repository Actions secrets):
   
   | Secret | Value |
   |---|---|
   | MOBILE_PREVIEW_SSH_KEY | Dedicated deployment private key |
   | MOBILE_PREVIEW_SSH_KNOWN_HOSTS | Verified SSH host key line (not blindly ssh-keyscan) |
   | MOBILE_PREVIEW_HTTP_USER | Basic Auth smoke-test username |
   | MOBILE_PREVIEW_HTTP_PASSWORD | Its password |
   
   Do not copy VPS root credentials from another repository. Secrets are
   not embedded in the Flutter build. API URL is public configuration.
4. Enable the variable and run Mobile Hosted Preview on main. A successful
   deploy verifies anonymous access is denied and authenticated version.json
   matches the commit; otherwise it rolls back the current symlink.
   Log in with a test account authorized for Mobile by the existing role contract. Verify that disallowed roles are rejected.
   Test UI routes and browser-specific limitations manually.

## Deployment isolation

The workflow only uploads to /var/www/crabsense-mobile-preview.
It never restarts the Backend, migrates a database, modifies other Web
roots, or changes Nginx config on each deployment. SSH host keys are pinned.
Deploys are serialized and stale main revisions are skipped. Old preview
releases can be removed manually after confirming current/rollback targets.
The site requires HTTPS Basic Auth and normal Mobile authentication.
Client origin checks are defense in depth, not authorization.
Use a test Backend; the preview can perform real operations against its
configured API. Native camera, QR, video uploads, push, biometrics and background tasks require device acceptance. Web uses a no-op database executor: offline queue and persistence are not supported; use online test flows. Do not use preview for
production operations.

Check exact deployed revision at /version.json after login to the site.
The hosted workflow refreshes after push, not on Ctrl+S; local mode is
the hot-reload option. With deploy disabled, download the CI artifact for
inspection, but it will only run on the configured HTTPS origin.

