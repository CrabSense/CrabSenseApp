# CrabFarm Monitor Desktop

Ứng dụng Flutter desktop — **kết nối Cloud** (`ras-backend` Cloud API).

## Cấu hình `.env`

```bash
copy .env.example .env
```

| Biến | Mô tả |
|------|--------|
| `CLOUD_API_URL` | URL Cloud (vd. `http://localhost:8081` hoặc `http://168.144.38.133:8084`) |
| `DEFAULT_FARM_ID` | Farm chọn sẵn sau `/api/auth/me` (tùy chọn) |

## Đăng nhập Cloud

1. `POST /api/auth/login` — email + password  
2. `GET /api/auth/me` — chọn farm  
3. Vào dashboard — màn **Cảm biến môi trường** lấy pin 1–5 từ Cloud; DO/mặn/ORP/NH3/NO2 vẫn mock

Tài khoản dev (docker): `admin@iras.local` / `123456`

## Chạy ứng dụng

```bash
cd d:\CN8\PRM392\CrabFarmMonitorDesktop
flutter pub get
flutter run -d windows
```

Nếu chưa có cấu hình platform, tạo bằng:

```bash
flutter create . --platforms=windows,linux,macos
```

## Cấu trúc

- `lib/screens/login_screen.dart` — Giao diện đăng nhập theo mockup
- `lib/screens/home_screen.dart` — Màn hình sau khi đăng nhập thành công
- `lib/services/mock_auth_service.dart` — Xác thực mock
- `assets/images/logo.png` — Logo CrabFarm Monitor


## Local Desktop browser preview (development only)

Use Flutter 3.35+ (web hot reload is enabled by default), Chrome or Edge, and
the Dart/Flutter VS Code extensions. From the repository root, select
**Desktop Preview (Chrome)** in Run and Debug, then F5. Save Dart files
(Ctrl+S) to hot reload without restarting the Windows executable.

Manual equivalent from crabsensedesktop:

```powershell
# First setup only, if .env does not exist:
Copy-Item .env.example .env
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 5500 --dart-define=CRABSENSE_DESKTOP_PREVIEW=true
```

Open http://localhost:5500 in the Chrome debug session. In a terminal
session press r for hot reload; R for hot restart only when necessary.
Use the same Manager login and real API as Desktop. The Backend config
must allow the exact origin http://localhost:5500 (already present in BE
repository defaults). If connecting to VPS, check its active CORS config.
Keep .env free of credentials/secrets: Flutter Web serves its assets to the browser.

Preview is for local debug only, not a new production role or replacement
for CrabSenseFE. Do not publish it, bind it to a LAN/public interface, or
disable browser security. Remembered sessions are kept only in the current
browser tab's session storage, cleared on logout and normally on tab close.
Native WiFi/LAN setup, native file paths, file export, RTSP and hardware
verification may require Windows. RAS state comes from Backend in browser
preview; do not treat browser preview as hardware acceptance. Use a test
Backend/test account for UI review; real API mutations can change data.
