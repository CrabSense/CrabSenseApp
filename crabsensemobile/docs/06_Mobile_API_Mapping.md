# Mobile API Mapping & Endpoint Catalog

> Danh sách chi tiết các API Endpoints backend tương ứng với từng Màn hình Mobile CrabSense / CrabGuardian (`http://103.69.96.143:5080/swagger`).

---

## 🔗 Endpoint Mapping Table

| Screen ID | Screen Name | HTTP Method | API Endpoint | Description / Payload |
| :--- | :--- | :---: | :--- | :--- |
| `MOB-Login` | Đăng nhập | `POST` | `/api/auth/login` | Email/Username + Password -> Auth Token |
| | | `POST` | `/api/auth/google` | ID Token Google Sign-In |
| `MOB-Home` | Home Dashboard | `GET` | `/api/dashboard/overview` | Aggregated dashboard stats (Alerts, Videos due, WQ) |
| `MOB-ScanQR` | Quét QR Box | `GET` | `/api/box-qr/scan?code={code}` | Trích xuất thông tin Box ID từ mã QR |
| `MOB-BoxStatus` | Trạng thái Box | `GET` | `/api/boxes/{id}` | Lấy chi tiết Hộp, Cua, WQ mini & Alerts |
| `MOB-CaptureVideo` | Quay Video AI | `POST` | `/api/videos` | Upload MP4 video file 5-10s cho AI phân tích |
| `MOB-VideoDue` | Lịch quay đến hạn | `GET` | `/api/video-schedules/due` | Lấy danh sách các Box quá hạn / cần quay trong ngày |
| `MOB-Alerts` | Quản lý Cảnh báo | `GET` | `/api/alerts` | Lấy danh sách cảnh báo theo độ ưu tiên |
| | | `PATCH` | `/api/alerts/{id}` | Xác nhận (Acknowledge) hoặc Xử lý (Resolve) cảnh báo |
| `MOB-WQ` | Chất lượng nước | `GET` | `/api/water-quality/latest` | Lấy dữ liệu 4 cảm biến realtime (Nhiệt độ, pH, DO, Độ mặn) |
| `MOB-CrabQuick` | Ghi nhận Cua nhanh | `POST` | `/api/crabs` | Thêm mới Cua vào Box |
| | | `POST` | `/api/allocations` | Chuyển vị trí Cua giữa các Box |
| `MOB-MoltConfirm` | Manual Inspection | `POST` | `/api/inspections` | Lưu kết quả kiểm tra thủ công (Mềm vỏ, phản xạ, double line) |
| `MOB-AiFeedback` | AI Feedback | `POST` | `/api/ai/feedback` | Gửi phản hồi ĐÚNG/SAI cho kết quả AI |
| `MOB-RecoAct` | AI Recommendation | `PATCH` | `/api/recommendations/{id}` | Ghi nhận quyết định Thu hoạch / Tiếp tục nuôi / Điều trị |
| `MOB-OpsLog` | Ghi nhật ký vận hành | `POST` | `/api/operation-logs` | Ghi nhận Cho ăn, Thay nước, Canxi, Muối, Lọc... |
| `MOB-HarvestQuick` | Thu hoạch nhanh | `POST` | `/api/harvest-lines` | Tạo dòng thu hoạch Cua lột tại hiện trường |
| `MOB-QuickSale` | Bán nhanh Cua lột | `POST` | `/api/sales-orders` | Tạo đơn hàng xuất bán Cua lột tươi |
| `MOB-TraceScan` | Quét QR Truy xuất | `GET` | `/api/traceability/{id}` | Lấy timeline lịch sử con cua cho khách hàng công khai |
| `MOB-NotifSettings` | Cài đặt Thông báo | `PATCH` | `/api/users/me/notifications` | Cấu hình nhận thông báo Push & liên kết Telegram |
