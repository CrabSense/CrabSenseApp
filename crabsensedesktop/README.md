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
