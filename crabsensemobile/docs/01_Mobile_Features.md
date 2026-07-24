# Mobile Features & Screen Mapping (FR)

> Danh sách các chức năng và màn hình cho ứng dụng Mobile của hệ thống CrabSense / CrabGuardian.

| Feature ID | Module | Feature | Mô tả | Screen ID | Role | API Endpoint | Priority |
|:---|:---|:---|:---|:---|:---|:---|:---:|
| MF-000 | Auth | Mobile Login | Operator / User đăng nhập trên điện thoại. | `MOB-Login` | All | `POST /api/auth/login`<br>`POST /api/auth/google` | **P0** |
| MF-001 | Dashboard | Home Dashboard | Hiển thị tổng quan công việc hôm nay, cảnh báo và thao tác nhanh. | `MOB-Home` | Op / Manager | `GET /api/dashboard/overview` | **P0** |
| MF-002 | Box Management | Scan QR Box | Quét QR để định danh Box trước khi thao tác. | `MOB-ScanQR` | Op | `GET /api/box-qr/scan` | **P0** |
| MF-003 | Box Management | View Box Status | Xem thông tin Box, cua, chất lượng nước và cảnh báo. | `MOB-BoxStatus` | Op / Manager | `GET /api/boxes/{id}` | **P0** |
| MF-004 | AI Decision | Capture Video | Quay video 5–10 giây phục vụ AI phân tích. | `MOB-CaptureVideo` | Op | `POST /api/videos` | **P0** |
| MF-005 | AI Decision | Video Due Schedule | Danh sách Box cần quay video trong ngày. | `MOB-VideoDue` | Op | `GET /api/video-schedules/due` | **P0** |
| MF-006 | Alert | Alert Management | Xem, nhận và xử lý cảnh báo. | `MOB-Alerts` | Op / Manager | `GET /api/alerts`<br>`PATCH /api/alerts/{id}` | **P0** |
| MF-007 | IoT | Water Quality Monitoring | Theo dõi dữ liệu cảm biến môi trường theo thời gian thực. | `MOB-WQ` | Op / Manager | `GET /api/water-quality/latest` | **P1** |
| MF-008 | Crab Management | Quick Crab Record | Thêm mới hoặc chuyển cua giữa các Box. | `MOB-CrabQuick` | Op | `POST /api/crabs`<br>`POST /api/allocations` | **P0** |
| MF-009 | AI Decision | Manual Inspection | Xác nhận kết quả AI bằng kiểm tra thủ công. | `MOB-MoltConfirm` | Op | `POST /api/inspections` | **P0** |
| MF-010 | AI Decision | AI Feedback | Gửi phản hồi đúng/sai cho AI. | `MOB-AiFeedback` | Op | `POST /api/ai/feedback` | **P0** |
| MF-011 | AI Decision | AI Recommendation | Nhận đề xuất Harvest / Continue / Treat từ AI. | `MOB-RecoAct` | Op / Manager | `PATCH /api/recommendations/{id}` | **P0** |
| MF-012 | Farm Operation | Operation Log | Ghi nhận các thao tác như cho ăn, thay nước, bổ sung khoáng... | `MOB-OpsLog` | Op | `POST /api/operation-logs` | **P0** |
| MF-013 | Harvest | Quick Harvest | Ghi nhận thu hoạch tại hiện trường. | `MOB-HarvestQuick` | Op / Manager | `POST /api/harvest-lines` | **P0** |
| MF-014 | Sales | Quick Sale | Bán nhanh cua lột tại ao. | `MOB-QuickSale` | Sales / Op | `POST /api/sales-orders` | **P1** |
| MF-015 | Traceability | Product Traceability | Quét QR để truy xuất nguồn gốc sản phẩm. | `MOB-TraceScan` | All / Public | `GET /api/traceability/{id}` | **P1** |
| MF-016 | System | Notification Settings | Quản lý Push Notification và Telegram. | `MOB-NotifSettings` | Op / Manager | `PATCH /api/users/me/notifications` | **P2** |

---

# Total Statistics

| Metric | Count |
|:---|---:|
| Phân hệ (Modules) | **8** |
| Chức năng (Features) | **17** |
| Màn hình (Screens) | **17** |
| Ưu tiên P0 | **13** |
| Ưu tiên P1 | **3** |
| Ưu tiên P2 | **1** |