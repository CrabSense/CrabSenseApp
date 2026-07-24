# 🔐 Báo Cáo Tổng Hợp API Đăng Nhập (Login) & Các API Liên Quan — CrabSense Mobile

**Ngày lập:** 23/07/2026  
**Dự án:** CrabSense Smart Aquaculture Platform  
**Backend Base URL:** `http://103.69.96.143:5080/api`  
**Swagger Tag:** `00. Auth`  

---

## 📌 1. Tổng Quan Luồng Đăng Nhập (Login Flow)

Màn hình Đăng nhập (Login Screen) của CrabSense Mobile chịu trách nhiệm xác thực người dùng (Quản trị viên `SystemAdmin`, Chủ trang trại `FarmOwner`, Cán bộ vận hành `Staff`), cấp JWT Access Token và Refresh Token, đồng thời đồng bộ thông tin phiên làm việc.

---

## 🟢 2. Danh Sách API Đăng Nhập Đã Có (Backend `AuthController.cs` Đã Hỗ Trợ)

Dưới đây là các API xác thực đã sẵn sàng trên Backend Swagger và mobile app đã có tích hợp:

| STT | Endpoint | HTTP Method | Mục đích | Body / Parameter | Status Code | Trạng thái Backend |
| :---: | :--- | :---: | :--- | :--- | :---: | :---: |
| **1** | `/api/auth/login` | `POST` | Đăng nhập tài khoản bằng Email/Username & Mật khẩu | `{ "email": "...", "username": "...", "password": "..." }` | `200 OK`<br>`401 Unauthorized`<br>`403 Forbidden` | ✅ **Đã có sẵn** |
| **2** | `/api/auth/refresh` | `POST` | Làm mới Access Token khi token cũ hết hạn | `{ "refreshToken": "..." }` | `200 OK`<br>`401 Unauthorized` | ✅ **Đã có sẵn** |
| **3** | `/api/auth/logout` | `POST` | Đăng xuất người dùng & thu hồi token phía Server | Header: `Authorization: Bearer <token>` | `200 OK` | ✅ **Đã có sẵn** |
| **4** | `/api/auth/me` | `GET` | Lấy thông tin chi tiết người dùng đang đăng nhập & vai trò | Header: `Authorization: Bearer <token>` | `200 OK`<br>`401 Unauthorized` | ✅ **Đã có sẵn** |
| **5** | `/api/auth/register` | `POST` | Đăng ký tài khoản mới (Dành cho Admin / Farm Owner khởi tạo Staff) | `{ "fullName", "email", "password", "role" }` | `200 OK`<br>`400 Bad Request` | ✅ **Đã có sẵn** |
| **6** | `/api/auth/change-password` | `POST` | Thay đổi mật khẩu cá nhân cho người dùng đã đăng nhập | `{ "currentPassword", "newPassword" }` | `200 OK`<br>`400 Bad Request` | ✅ **Đã có sẵn** |

---

## 🚨 3. Danh Sách API Liên Quan Đến Trang Login Đang THIẾU (Missing APIs)

Dưới đây là các API phụ trợ cho màn hình Login đã được khai báo trên Mobile App (`ApiConstants.dart` & `AuthRemoteDataSource.dart`), nhưng **Backend Cần Bổ Sung Gấp**:

| STT | Endpoint Thiếu | HTTP Method | Chức năng trên Trang Login | Mức độ ưu tiên | Trạng thái Hiện Tại |
| :---: | :--- | :---: | :--- | :---: | :---: |
| **1** | `/api/auth/google` | `POST` | Đăng nhập nhanh bằng tài khoản Google (OAuth 2.0 / ID Token) | 🟡 **Trung bình** | ❌ **Thiếu Backend** (Mobile đã có stub mock) |
| **2** | `/api/auth/forgot-password` | `POST` | Yêu cầu khôi phục mật khẩu (Gửi mã OTP / Link reset qua Email) | 🔴 **Cao** | ❌ **Thiếu Backend** (Tính năng "Quên mật khẩu" ở màn login) |
| **3** | `/api/auth/reset-password` | `POST` | Đặt mật khẩu mới sau khi xác thực OTP thành công | 🔴 **Cao** | ❌ **Thiếu Backend** (Trang Reset Password) |
| **4** | `/api/auth/verify-email` | `POST` | Kích hoạt / Xác thực Email tài khoản mới đăng ký | 🟡 **Trung bình** | ❌ **Thiếu Backend** (Kích hoạt Email nhân viên) |
| **5** | `/api/auth/biometric-verify` | `POST` | Đăng nhập nhanh bằng Sinh trắc học (Vân tay / FaceID) kết hợp Token Secure Storage | 🟢 **Thấp** | ❌ **Thiếu Backend** (Mobile hiện tự xác thực local via `local_auth`) |
| **6** | `/api/notifications/register` | `POST` | Đăng ký FCM Device Token ngay sau khi bấm Login thành công | 🔴 **Cao** | ❌ **Thiếu Backend** (Để gửi Push Notification cảnh báo khẩn) |

---

## 📋 4. Chi Tiết Payload & Response Của Các API Đăng Nhập

### 4.1. `POST /api/auth/login`
- **Request Body:**
```json
{
  "email": "staff@crabsense.io",
  "username": "staff@crabsense.io",
  "password": "Password123!"
}
```
- **Response Success (200 OK):**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiR...",
    "refreshToken": "d9b2a1e0-4c3d-...",
    "accessTokenExpiresAt": "2026-07-23T20:00:00Z",
    "refreshTokenExpiresAt": "2026-07-30T19:00:00Z",
    "user": {
      "id": "usr_01H12345",
      "email": "staff@crabsense.io",
      "name": "Trương Minh Khánh",
      "role": "Staff",
      "assignedFarmIds": ["farm_a_001"]
    }
  },
  "message": "Đăng nhập thành công"
}
```

### 4.2. `POST /api/auth/refresh`
- **Request Body:**
```json
{
  "refreshToken": "d9b2a1e0-4c3d-..."
}
```
- **Response Success (200 OK):**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiR...",
    "refreshToken": "e0c3b2a1-5d4e-...",
    "accessTokenExpiresAt": "2026-07-23T21:00:00Z"
  }
}
```

---

## 💡 5. Đề Xuất Cho Đội Ngũ Phát Triển (Action Items)

1. **Đối với Mobile App Team:**
   - Sử dụng `/api/auth/login`, `/api/auth/refresh`, `/api/auth/logout`, `/api/auth/me` đã sẵn sàng để đấu nối thật với server backend (`103.69.96.143:5080`).
   - Giữ mock fallback cho tính năng "Quên mật khẩu" (`forgot-password`) và "Đăng nhập Google" (`google`) cho tới khi Backend bổ sung endpoints.

2. **Đối với Backend Team:**
   - Ưu tiên bổ sung endpoint **`POST /api/auth/forgot-password`** và **`POST /api/auth/reset-password`** để hoàn thiện luồng quên mật khẩu cho màn hình đăng nhập.
   - Bổ sung **`POST /api/notifications/register`** để lưu FCM Token sau khi người dùng vừa bấm nút Login thành công.
