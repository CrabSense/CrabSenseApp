# Báo cáo Đối Soát API Backend Swagger vs Mobile App (CrabSense)

**Thời gian đối soát:** 2026-07-22  
**Backend Host:** `http://103.69.96.143:5080` (Swagger v1)  
**Tệp định nghĩa App:** `lib/core/constants/api_constants.dart`

---

## 1. Cấu hình Tiền tố Đường dẫn (API Prefix)

- **Mobile App hiện tại:** `http://103.69.96.143:5080/api/v1/...`
- **Backend Swagger quy định:** Đều có tiền tố `/api/...` (ví dụ: `/api/auth/login`, `/api/boxes`, không sử dụng `/v1`).
- 💡 **Khuyến nghị:** Đổi `apiVersion = '/api'` trong file `lib/core/constants/api_constants.dart` để đồng bộ hoàn toàn với Backend.

---

## 2. Danh sách API Mobile App đang dùng nhưng THIẾU hoặc KHÁC TÊN trên Backend

### 🔑 A. Xác thực & Người dùng (Auth & Users)

| Tính năng Mobile App | Endpoint Mobile đang gọi | Endpoint tương ứng trên Backend Swagger | Ghi chú / Trạng thái |
| :--- | :--- | :--- | :--- |
| **Đăng nhập** | `/api/v1/auth/login` | `/api/auth/login` | ✅ Có (Khác tiền tố `/v1`) |
| **Đăng xuất** | `/api/v1/auth/logout` | `/api/auth/logout` | ✅ Có |
| **Lấy lại Token** | `/api/v1/auth/refresh` | `/api/auth/refresh` | ✅ Có |
| **Đổi mật khẩu** | `/api/v1/auth/change-password` | `/api/auth/change-password` | ✅ Có |
| **Lấy Profile User** | `/api/v1/users/profile` | `/api/auth/me` | ⚠️ Backend dùng `/api/auth/me` |
| **Cập nhật ảnh đại diện**| `/api/v1/users/profile/photo` | *Chưa có* | ❌ **Thiếu trên Backend** |
| **Phân quyền người dùng** | `/api/v1/users/permissions` | *Chưa có* | ❌ **Thiếu trên Backend** |

---

### 📊 B. Bảng điều khiển (Dashboard)

| Tính năng Mobile App | Endpoint Mobile đang gọi | Endpoint tương ứng trên Backend Swagger | Ghi chú / Trạng thái |
| :--- | :--- | :--- | :--- |
| **Tổng quan Dashboard** | `/api/v1/dashboard/summary` | `/api/dashboard/overview` | ⚠️ Backend đánh dấu là Stub |
| **Chỉ số kỹ thuật** | `/api/v1/dashboard/metrics` | *Chưa có* | ❌ **Thiếu trên Backend** |
| **Cảnh báo Dashboard** | `/api/v1/dashboard/alerts` | *Chưa có* | ❌ **Thiếu trên Backend** |

---

### 🤖 C. AI & Video Detections

| Tính năng Mobile App | Endpoint Mobile đang gọi | Endpoint tương ứng trên Backend Swagger | Ghi chú / Trạng thái |
| :--- | :--- | :--- | :--- |
| **Tải lên Video** | `/api/v1/videos/upload` | `/api/media/upload` | ⚠️ Backend upload lên Google Drive |
| **Lịch quay video** | `/api/v1/videos/schedule` | *Chưa có* | ❌ **Thiếu trên Backend** |
| **Phân tích AI** | `/api/v1/ai/analyze` | *Chưa có* | ❌ **Thiếu trên Backend** |
| **Kết quả AI theo Video** | `/api/v1/ai/results/{videoId}`| `/api/ai/detections` | ⚠️ Backend đánh dấu là Stub |
| **Gửi phản hồi AI** | `/api/v1/ai/feedback` | `/api/ai/feedback` | ⚠️ Backend đánh dấu là Stub |

---

### 📝 D. Kiểm tra Thủ công (Manual Inspection) & Nhật ký Vận hành

| Tính năng Mobile App | Endpoint Mobile đang gọi | Endpoint tương ứng trên Backend Swagger | Ghi chú / Trạng thái |
| :--- | :--- | :--- | :--- |
| **Gửi phiếu kiểm tra** | `/api/v1/inspections/submit` | *Chưa có Controller riêng* | ⚠️ Có thể dùng `/api/crabs/{crabId}/moltings` hoặc `/api/boxes/{boxId}/status` |
| **Nhật ký vận hành** | `/api/v1/operations` | *Chưa có* | ❌ **Thiếu trên Backend** |

---

### 💧 E. Chất lượng Nước (Water Quality & IoT)

| Tính năng Mobile App | Endpoint Mobile đang gọi | Endpoint tương ứng trên Backend Swagger | Ghi chú / Trạng thái |
| :--- | :--- | :--- | :--- |
| **Nước mới nhất** | `/api/v1/water-quality/latest` | `/api/iot/sensor-data/{sensorId}/latest` hoặc `/api/iot/live` | ⚠️ Backend quy hoạch theo Sensor ID |
| **Lịch sử cảm biến** | `/api/v1/water-quality/historical` | `/api/iot/sensor-data/{sensorId}` | ⚠️ Backend quy hoạch theo Sensor ID |

---

### 🌾 F. Thu hoạch (Harvest)

| Tính năng Mobile App | Endpoint Mobile đang gọi | Endpoint tương ứng trên Backend Swagger | Ghi chú / Trạng thái |
| :--- | :--- | :--- | :--- |
| **Tạo phiếu thu hoạch** | `/api/v1/harvests/record` | `/api/harvest-vouchers` | ⚠️ Backend sử dụng mô hình Phiếu thu hoạch (POST) |
| **Thống kê thu hoạch** | `/api/v1/harvests/summary` | `/api/harvest-vouchers/statistics` | ✅ Đã có trên Backend |

---

## 3. Tổng hợp danh sách Endpoint hiện có trên Swagger Backend (Tham chiếu)

### 00. Auth
- `POST /api/auth/login` - [AUTH] Login
- `POST /api/auth/register` - [CREATE] Register user
- `POST /api/auth/refresh` - [AUTH] Refresh token
- `POST /api/auth/logout` - [AUTH] Logout
- `GET  /api/auth/me` - [READ] Current user
- `POST /api/auth/change-password` - [UPDATE] Change password

### 01-03. Cấu trúc Trang trại (Khu - Dãy - Hộp)
- `GET/POST/PUT/DELETE /api/farming-areas` - Quản lý Khu
- `GET/POST/PUT/DELETE /api/farming-rows` - Quản lý Dãy
- `GET/POST/PUT/DELETE /api/boxes` - Quản lý Hộp
- `GET /api/boxes/available` - Danh sách hộp trống sẵn sàng
- `PATCH /api/boxes/{boxId}/status` - Cập nhật trạng thái hộp

### 04. Cua & Lịch sử nuôi
- `GET/POST/PUT/DELETE /api/crabs` - Quản lý Cua
- `POST/PUT/DELETE /api/allocations` - Phân bổ cua vào hộp / di chuyển
- `POST/GET/PUT/DELETE /api/crabs/{crabId}/moltings` - Ghi nhận lịch sử lột xác
- `GET /api/boxes/{boxId}/farming-timeline` - Timeline tổng hợp của hộp

### 05-06. Lô Cua & Vụ Nuôi
- `GET/POST/PUT/DELETE /api/crab-lots` - Quản lý Lô Cua nhập
- `GET/POST/PUT/DELETE /api/crop-batches` - Quản lý Vụ Nuôi

### 07. Quét mã QR Hộp
- `GET/POST /api/boxes/{boxId}/qr` - Mã QR hộp
- `GET /api/boxes/{boxId}/qr.png` - Tải ảnh PNG QR để in nhãn
- `GET /api/box-qr/scan` - Quét mã QR trả về thông tin Hộp + Cua
- `PATCH /api/box-qr/{code}/crabs/{crabId}` - Cập nhật thông tin cua từ QR
- `POST /api/box-qr/{code}/move-crab` - Di chuyển cua qua QR

### 08-09. Cảm biến & IoT
- `POST /api/iot/sensor-data` - Đẩy dữ liệu cảm biến
- `GET /api/iot/sensor-data/{sensorId}` - Lịch sử cảm biến
- `GET /api/iot/live` - Dữ liệu live tất cả cảm biến
- `GET/POST/PUT/DELETE /api/sensors` - Quản lý Cảm biến
- `GET/POST/PUT/DELETE /api/devices` - Quản lý thiết bị ESP32

### 10-11. Cảnh báo & Thông báo
- `GET /api/alerts` - Danh sách cảnh báo
- `PATCH /api/alerts/{id}/acknowledge` - Xác nhận cảnh báo
- `PATCH /api/alerts/{id}/resolve` - Xử lý xong cảnh báo
- `GET/POST/PUT/DELETE /api/alert-thresholds` - Ngưỡng cảnh báo
- `GET /api/notifications/user/{userId}` - Thông báo người dùng

### 12. Quản lý Media (Google Drive)
- `POST /api/media/upload` - Tải ảnh/video/log lên Google Drive
- `GET/DELETE /api/media` - Quản lý media

### 20. Thu hoạch (Harvest) & 21. Kho Cấp Đông
- `GET/POST/DELETE /api/harvest-vouchers` - Phiếu thu hoạch
- `GET/POST/PUT/DELETE /api/frozen-lots` - Lô cua cấp đông
- `GET /api/frozen-lots/expiring` - Lô cấp đông sắp hết hạn

---

## 4. Hướng xử lý tiếp theo cho Flutter App

1. **Khớp nối URL prefix:** Đổi `apiVersion` thành `/api` trong `ApiConstants`.
2. **Khớp nối Model / Contract:** Cập nhật các Data Source trong Flutter (`auth_remote_data_source.dart`, `box_remote_data_source.dart`) để gọi đúng đường dẫn của Swagger.
3. **Mockup các API chưa có:** Đối với các API AI/Video schedule/Operations chưa sẵn sàng trên Backend, bổ sung fallback Mock Data tạm thời để App không bị ngắt quãng.
