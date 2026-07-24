# Danh Sách API Mobile App Cần Nhưng Backend (Swagger) Chưa Có & Phân Công Nhiệm Vụ

**Thời gian lập:** 2026-07-22  
**Backend Host:** `http://103.69.96.143:5080` (Swagger v1)  
**Tệp nguồn Flutter:** `lib/core/constants/api_constants.dart`  
**Báo cáo phân công chi tiết:** [api_assignment_by_member.md](file:///d:/CrabSense/CrabSenseApp/crabsensemobile/api_assignment_by_member.md)

---

## 📌 Tổng Quan Phân Công Theo Nhân Sự

| Nhân sự | Module phụ trách | Số lượng API Backend đã có | Số lượng API Thiếu / Cần làm mới | Trạng thái chung |
| :--- | :--- | :---: | :---: | :--- |
| **Duy** | 1. Quản lý trang trại cua lột<br>2. Giám sát môi trường nuôi<br>3. Cảnh báo thông minh | 12/15 | 3 | 🟢 Hoàn thiện 80% (Cần đổi tên endpoint & bổ sung Push Notif/Telegram) |
| **Khanh** | 4. Giám sát hình ảnh<br>5. Phát hiện cua lột bằng AI | 3/9 | 6 | 🟡 Cần Backend làm mới API Phân tích AI & Lịch quay video |
| **Hai** | 6. Quản lý thu hoạch<br>7. Quản lý kho cấp đông | 8/8 | 0 | 🟢 **100% Sẵn sàng** (Backend đã hỗ trợ đủ, Mobile chỉ cần nối API) |
| **Dat** | 8. Truy xuất nguồn gốc<br>9. Báo cáo và phân tích | 5/10 | 5 | 🟡 Cần Backend làm API tổng hợp Traceability & Dashboard Metrics |

---

## 1. 👤 Duy — Quản Lý Trang Trại, Môi Trường & Cảnh Báo

| STT | HTTP Method | Endpoint Mobile gọi / Cần có | Mục đích | Trạng thái Swagger Backend | Ghép nối / Xử lý |
| :---: | :--- | :--- | :--- | :---: | :--- |
| 1 | `GET/POST` | `/api/farming-areas` | Quản lý khu nuôi | ✅ **Đã có** | Đổi tên từ `/farms` sang `/farming-areas` |
| 2 | `GET/POST` | `/api/farming-rows` | Quản lý dãy nuôi | ✅ **Đã có** | Đổi tên từ `/ponds` sang `/farming-rows` |
| 3 | `GET/POST` | `/api/boxes` | Quản lý Crab Farm Box | ✅ **Đã có** | Đã sẵn sàng |
| 4 | `GET/POST` | `/api/crabs`, `/api/crab-lots` | Quản lý cua & lô cua nhập | ✅ **Đã có** | Đã sẵn sàng |
| 5 | `GET` | `/api/iot/live` | Xem chất lượng nước realtime | ⚠️ **Khác tên** | Đổi tên từ `/water-quality/latest` |
| 6 | `GET` | `/api/iot/sensor-data/{id}` | Biểu đồ lịch sử nước | ⚠️ **Khác tên** | Đổi tên từ `/water-quality/historical` |
| 7 | `GET` | `/api/alerts` | Danh sách cảnh báo thông số | ✅ **Đã có** | Đã sẵn sàng |
| 8 | `POST` | `/api/v1/notifications/register` | Đăng ký Push Notification (FCM) | ❌ **Thiếu** | Cần Backend bổ sung |
| 9 | `POST` | `/api/v1/notifications/settings` | Cấu hình gửi Telegram / Zalo | ❌ **Thiếu** | Cần Backend bổ sung |

---

## 2. 👤 Khanh — Giám Sát Hình Ảnh & Phân Tích AI

| STT | HTTP Method | Endpoint Mobile gọi / Cần có | Mục đích | Trạng thái Swagger Backend | Ghép nối / Xử lý |
| :---: | :--- | :--- | :--- | :---: | :--- |
| 1 | `POST` | `/api/media/upload` | Tải video từ camera box | ⚠️ **Khác tên** | Backend tải lên Google Drive |
| 2 | `GET` | `/api/v1/videos/schedule` | Lịch quay video cần thực hiện trong ngày | ❌ **Thiếu** | Cần Backend bổ sung |
| 3 | `GET` | `/api/v1/boxes/{boxId}/videos` | Danh sách video theo box | ❌ **Thiếu** | Cần Backend bổ sung filter |
| 4 | `POST` | `/api/v1/ai/analyze` | Yêu cầu AI phân tích video | ❌ **Thiếu** | Cần Backend bổ sung |
| 5 | `GET` | `/api/v1/ai/results/{videoId}` | Kết quả AI nhận diện (bình thường, sắp lột, đang lột, soft-shell) | ⚠️ **Mới có Stub** | Backend mới có `/api/ai/detections` Stub |
| 6 | `POST` | `/api/v1/ai/feedback` | Phản hồi kết quả AI | ⚠️ **Mới có Stub** | Backend mới có Stub |

---

## 3. 👤 Hai — Quản Lý Thu Hoạch & Kho Cấp Đông

| STT | HTTP Method | Endpoint Mobile gọi / Cần có | Mục đích | Trạng thái Swagger Backend | Ghép nối / Xử lý |
| :---: | :--- | :--- | :--- | :---: | :--- |
| 1 | `POST` | `/api/harvest-vouchers` | Tạo phiếu thu hoạch | ✅ **Đã có** | Mobile đổi từ `/harvests/record` |
| 2 | `GET` | `/api/harvest-vouchers` | Lấy danh sách & sản lượng thu hoạch | ✅ **Đã có** | Đã sẵn sàng |
| 3 | `GET` | `/api/harvest-vouchers/statistics` | Thống kê thu hoạch (ngày/tuần/tháng) & tỷ lệ lột | ✅ **Đã có** | Đã sẵn sàng |
| 4 | `GET/POST` | `/api/frozen-lots` | Quản lý lô cua cấp đông, trọng lượng tồn kho | ✅ **Đã có** | Mobile cần thêm vào `ApiConstants` |
| 5 | `GET` | `/api/frozen-lots/expiring` | Cảnh báo lô cấp đông sắp hết hạn | ✅ **Đã có** | Mobile cần thêm vào `ApiConstants` |

---

## 4. 👤 Dat — Truy Xuất Nguồn Gốc & Báo Cáo Phân Tích

| STT | HTTP Method | Endpoint Mobile gọi / Cần có | Mục đích | Trạng thái Swagger Backend | Ghép nối / Xử lý |
| :---: | :--- | :--- | :--- | :---: | :--- |
| 1 | `GET` | `/api/v1/traceability/{productId}` | Chi tiết truy xuất từ box nuôi đến lô thu hoạch | ❌ **Thiếu** | Cần Backend viết API tổng hợp |
| 2 | `GET` | `/api/boxes/{boxId}/qr.png` | Tạo/Xuất QR Code cho Box nuôi | ✅ **Đã có** | Đã sẵn sàng |
| 3 | `GET` | `/api/box-qr/scan` | Quét QR Code tra cứu thông tin Box | ✅ **Đã có** | Đã sẵn sàng |
| 4 | `GET` | `/api/v1/traceability/qr/{qrCode}` | Quét QR truy xuất nguồn gốc sản phẩm thương mại | ❌ **Thiếu** | Cần Backend bổ sung |
| 5 | `GET` | `/api/dashboard/overview` | Dashboard tổng quan trang trại | ⚠️ **Mới có Stub** | Backend cần hoàn thiện dữ liệu |
| 6 | `GET` | `/api/v1/dashboard/metrics` | Thống kê tỷ lệ lột xác & tỷ lệ sống | ❌ **Thiếu** | Cần Backend bổ sung |
| 7 | `GET` | `/api/v1/operations` | Nhật ký & Thống kê hiệu quả vận hành | ❌ **Thiếu** | Cần Backend bổ sung |

---

## 💡 Đề Xuất Kế Hoạch Hành Động Cho Đội Ngũ

1. **Cho Hải & Duy:**
   - Cập nhật ngay `ApiConstants.dart` để ghép nối với các API đã sẵn sàng trên Backend (Khu nuôi, Dãy nuôi, Box, Cua, Thu hoạch, Kho cấp đông, IoT live).

2. **Cho Khanh & Đạt:**
   - Chuyển danh sách các API **❌ Thiếu** và **⚠️ Stub** ở trên cho đội Backend để ưu tiên xây dựng các Endpoint phân tích AI, truy xuất nguồn gốc sản phẩm, và Dashboard Metrics.
   - Trong thời gian chờ Backend triển khai, tiếp tục dùng Mock Data Local trong Mobile App để không bị gián đoạn giao diện.
