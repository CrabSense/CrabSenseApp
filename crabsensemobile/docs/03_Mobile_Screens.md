# CrabSense Mobile - Detailed Screen Specifications & Workflow Mapping

> Tài liệu thiết kế chi tiết 17 màn hình cho ứng dụng CrabSense / CrabGuardian Mobile dành cho Nhân viên vận hành (Operator) và Quản lý (Sales/Manager).

---

## 📋 Bảng Tổng Quan 17 Màn Hình (Master Screen Table)

| Platform | Screen ID | Module | Screen Name | Stack / Navigation | Description & Task | UI Elements & Controls | Flow / Action | Role | API Endpoint | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| **Mobile** | `MOB-Login` | Auth | Đăng nhập | Auth stack | Operator / User đăng nhập trên điện thoại. | Logo; Email/Username & Password fields; Login button; Google Login; Biometric (Vân tay/FaceID); Error text banner | Login → Home | All | `POST /api/auth/login`<br>`POST /api/auth/google` | **P0** |
| **Mobile** | `MOB-Home` | Ops | Home Operator | Bottom tab Home | Tổng quan công việc cần làm hôm nay tại ao. | Greeting; Task cards (Alerts count, Video due, Pre-molt reco, Softshell sẵn); Quick actions (Scan QR, Ops log, Capture); Pull-to-refresh | Tap task → screen | Op / Manager | `GET /api/dashboard/overview` | **P0** |
| **Mobile** | `MOB-ScanQR` | Ops | Quét QR Box | Camera | Định danh Box trước mọi thao tác hiện trường. | Camera viewfinder; Overlay khung QR; Torch toggle; Manual code input fallback; Success haptic → Box context sheet | Scan → BoxStatus | Op | `GET /api/box-qr/scan` | **P0** |
| **Mobile** | `MOB-BoxStatus` | Farm | Trạng thái Box | After scan | Xem nhanh trạng thái Box sau khi quét: Cua, WQ, Alert. | Box header; Crab count list; Mini WQ gauge; Alert chips; Action row (Video / Inspect / Ops / Harvest / Sale) | Navigate actions | Op / Manager | `GET /api/boxes/{id}` | **P0** |
| **Mobile** | `MOB-CaptureVideo` | AI Decision | Quay Video 5-10s | Camera record | Thu video cho AI phân tích sau khi đã scan Box. | Timer 5–10s; Record button; Video preview; Upload progress; Retry queue nếu offline; Box code badge | Record → Upload | Op | `POST /api/videos` | **P0** |
| **Mobile** | `MOB-VideoDue` | AI Decision | Lịch quay đến hạn | Tab AI / List | Nhắc danh sách Box chưa quay đủ lần trong ngày. | List overdue boxes; Due time; Tap → Scan+Capture; Empty state "Xong việc hôm nay" | Start capture | Op | `GET /api/video-schedules/due` | **P0** |
| **Mobile** | `MOB-Alerts` | System | Quản lý Cảnh báo | Bottom tab Alerts | Nhận Push Notification & xử lý cảnh báo tại hiện trường. | Push permission dialog; Alert list; Detail bottom sheet; Nút Resolve / Acknowledge; Deep link Box | Resolve alert | Op / Manager | `GET /api/alerts`<br>`PATCH /api/alerts/{id}` | **P0** |
| **Mobile** | `MOB-WQ` | IoT | Chất lượng nước | Bottom tab WQ | Xem dữ liệu cảm biến nước realtime theo Zone / Box. | Picker Zone / Pond / Box; Gauge list (Nhiệt độ, pH, DO, Độ mặn); Last seen timestamp; Status color (OK/Warn/Danger) | Change target | Op / Manager | `GET /api/water-quality/latest` | **P1** |
| **Mobile** | `MOB-CrabQuick` | Farm | Ghi nhận Cua nhanh | Modal / Sheet | Thêm mới hoặc chuyển Cua giữa các Box ngay tại ao. | Box context badge; Fields crab_code, weight, status; Submit button; Transfer mode (from_box → to_box) | Save crab / Transfer | Op | `POST /api/crabs`<br>`POST /api/allocations` | **P0** |
| **Mobile** | `MOB-MoltConfirm` | AI Decision | Manual Inspection | Form checklist | Checklist thủ công sau khi có kết quả video/AI: Mềm, Phản xạ, Double line, Đã lột. | AI label banner; 4 checkboxes (Softshell, Reflex, Double line, Molted); Final label picker; Note field; Photo upload; Nút "AI sai → Feedback" | Save inspection | Op | `POST /api/inspections` | **P0** |
| **Mobile** | `MOB-AiFeedback` | AI Decision | AI Feedback | Form / Sheet | Phản hồi kết quả AI Đúng / Sai nhanh trên điện thoại. | Detection summary card; Big buttons Correct / Wrong; Picker nhãn đúng nếu chọn Wrong; Submit feedback | Submit feedback | Op | `POST /api/ai/feedback` | **P0** |
| **Mobile** | `MOB-RecoAct` | AI Decision | AI Recommendation | Action sheet | Nhận đề xuất Harvest / Continue / Treat và ghi nhận outcome. | Recommendation card (Action, Confidence score, Reason); Action buttons (Harvest / Continue / Treat); Outcome feedback | Act + Outcome | Op / Manager | `PATCH /api/recommendations/{id}` | **P0** |
| **Mobile** | `MOB-OpsLog` | Farm | Ghi thao tác vận hành | Form / Tab Farm | Ghi nhận Cho ăn / Thay nước / Canxi / Muối / Vệ sinh / Điều trị. | Chip selection op_type; Scope Box/Zone; Qty + Unit + Material; Before/After photos optional; Note; Save offline queue | Save log | Op | `POST /api/operation-logs` | **P0** |
| **Mobile** | `MOB-HarvestQuick` | Harvest | Thu hoạch nhanh | Form / Tab Farm | Tạo dòng thu hoạch Cua lột ngay tại hiện trường. | Scan Box ID; Weight input (kg); Softshell toggle; Add to voucher list; Confirm harvest | Add harvest line | Op / Manager | `POST /api/harvest-lines` | **P0** |
| **Mobile** | `MOB-QuickSale` | Sales | Bán nhanh Cua lột | Form / Tab More | Bán Cua lột tươi tại chỗ (trong cửa sổ softshell). | Customer picker / Quick add; Softshell list sẵn sàng; Quantity & Price input; Confirm order; Cash payment method | Create order + Pay | Sales / Manager | `POST /api/sales-orders` | **P1** |
| **Mobile** | `MOB-TraceScan` | Trace | Quét QR Truy xuất | Scanner / Public | Tra cứu nguồn gốc & lịch sử nuôi cấy sản phẩm Cua. | Camera scanner; Simplified timeline result (Trang trại, Ngày lột, Kiểm định chất lượng) | View chain timeline | All / Public | `GET /api/traceability/{id}` | **P1** |
| **Mobile** | `MOB-NotifSettings` | System | Cài đặt Thông báo | Settings / More | Bật/tắt Push Notification và liên kết Telegram cá nhân. | Toggles Push Notifications; Telegram Deep Link button; Test notification trigger | Save preferences | Op / Manager | `PATCH /api/users/me/notifications` | **P2** |

---

## 🎨 Chi Tiết Cụ Thể Thành Phần UI & Workflow Từng Màn Hình

### 1. `MOB-Login` (Đăng nhập)
- **Mục đích**: Xác thực người dùng, lưu JWT token trong `FlutterSecureStorage`.
- **Thành phần UI**:
  - `AppLogo` thương hiệu CrabSense.
  - `TextFormField` Tài khoản / Email (`owner`, `staff`, `sysadmin` hoặc email).
  - `TextFormField` Mật khẩu hỗ trợ ẩn/hiện password.
  - `ElevatedButton` "Đăng nhập".
  - `OutlinedButton` "Đăng nhập bằng Google".
  - Nút biểu tượng Biometric (Vân tay / FaceID) để đăng nhập nhanh.
  - Banner hiển thị thông báo lỗi khi nhập sai credential.

### 2. `MOB-Home` (Operator Dashboard)
- **Mục đích**: Trung tâm điều khiển hiển thị toàn bộ công việc trong ngày tại ao.
- **Thành phần UI**:
  - Greeting widget chào tên Operator & Tên trang trại.
  - Task Cards métrix: Số lượng Cảnh báo active, Số Video đến hạn quay, Đề xuất sắp lột (Pre-molt), Cua lột sẵn sàng (Softshell ready).
  - Quick Actions Row: Quét QR (`MOB-ScanQR`), Quay Video (`MOB-CaptureVideo`), Ghi nhật ký vận hành (`MOB-OpsLog`).
  - Pull-to-refresh cập nhật dữ liệu tự động.

### 3. `MOB-ScanQR` (Quét QR Box)
- **Mục đích**: Định danh Hộp nuôi Cua (Box) cực nhanh trước mọi thao tác hiện trường (<500ms).
- **Thành phần UI**:
  - Khung ngắm Camera Viewfinder toàn màn hình.
  - Khung Overlay giới hạn vùng quét QR.
  - Nút bật/tắt Đèn Flash (Torch toggle).
  - Ô nhập mã Box thủ công fallback khi mã QR bị mờ/hỏng.
  - Haptic feedback (rung nhẹ) khi quét thành công -> Mở `MOB-BoxStatus`.

### 4. `MOB-BoxStatus` (Trạng thái Box)
- **Mục đích**: Hiển thị toàn bộ thông tin tình trạng của 1 Box vừa quét.
- **Thành phần UI**:
  - Header thông tin mã Box, Vị trí (Khu / Ao / Hàng).
  - Danh sách Cua trong Box (Mã cua, Trọng lượng, Ngày vào hộp).
  - Thẻ thông số môi trường mini (WQ: Nhiệt độ, pH, DO).
  - Alert chips hiển thị các cảnh báo chưa xử lý liên quan đến Box.
  - Action Row thao tác nhanh: Quay Video, Manual Inspect, Ghi nhật ký, Thu hoạch, Bán nhanh.

### 5. `MOB-CaptureVideo` (Quay Video AI 5–10s)
- **Mục đích**: Thu thập video chất lượng cao cho mô hình AI nhận diện trạng thái lột xác.
- **Thành phần UI**:
  - Badge hiển thị mã Box đang quay.
  - Đồng hồ đếm ngược 5–10s (Recording Timer).
  - Nút bấm Bắt đầu / Dừng quay.
  - Màn hình Preview video vừa quay.
  - Thanh tiến trình Nén & Upload video (`video_compress`).
  - Hàng chờ đẩy lên server khi mất kết nối mạng (Offline Retry Queue).

### 6. `MOB-VideoDue` (Lịch quay đến hạn)
- **Mục đích**: Nhắc nhở danh sách các Box chưa quay đủ số lần video trong ngày.
- **Thành phần UI**:
  - Danh sách các Box quá hạn hoặc đến hạn quay.
  - Thời gian dự kiến quay tiếp theo.
  - Chạm vào từng item -> Chuyển thẳng đến màn hình Camera Quét QR & Quay Video.
  - Màn hình Empty State đẹp mắt khi đã hoàn thành toàn bộ lịch quay trong ngày ("Xong việc hôm nay!").

### 7. `MOB-Alerts` (Quản lý Cảnh báo)
- **Mục đích**: Theo dõi & xử lý các sự cố môi trường hoặc bất thường của Cua.
- **Thành phần UI**:
  - Dialog xin quyền Push Notification khi truy cập lần đầu.
  - Danh sách Cảnh báo phân loại màu sắc: Đỏ (Emergency), Vàng (Warning), Xanh (Info).
  - Bottom Sheet hiển thị chi tiết nguyên nhân & hướng khắc phục.
  - Nút hành động: Xác nhận (Acknowledge) & Xử lý xong (Resolve).
  - Deep link chuyển trực tiếp đến Box liên quan.

### 8. `MOB-WQ` (Chất lượng nước IoT)
- **Mục đích**: Giám sát thông số môi trường theo thời gian thực từ cảm biến IoT.
- **Thành phần UI**:
  - Bộ lọc Picker chọn Trang trại / Ao / Zone.
  - Đồng hồ Gauge hiển thị 4 chỉ số chính: Nhiệt độ (°C), pH, Oxy hòa tan DO (mg/L), Độ mặn (ppt).
  - Thời gian cập nhật gần nhất (Last seen timestamp).
  - Mã màu trực quan: Xanh (Đạt chuẩn), Vàng (Cảnh báo), Đỏ (Nguy hiểm).

### 9. `MOB-CrabQuick` (Ghi nhận Cua nhanh)
- **Mục đích**: Cập nhật biến động Cua tại ao (Thêm mới, Cập nhật trọng lượng, Chuyển hộp).
- **Thành phần UI**:
  - Badge gắn ngữ cảnh Box hiện tại.
  - Ô nhập Mã Cua (`crab_code`), Trọng lượng (`weight_gram`), Tình trạng sức khỏe.
  - Chế độ Chuyển hộp (Transfer Mode): Chọn Box nguồn -> Box đích.
  - Nút Lưu thông tin & Đồng bộ Offline.

### 10. `MOB-MoltConfirm` (Manual Inspection)
- **Mục đích**: Kiểm tra thủ công đối soát với kết quả nhận diện của AI.
- **Thành phần UI**:
  - Banner hiển thị kết quả dự đoán của AI (VD: AI đoán *Softshell - 88%*).
  - 4 Ô Checkbox kiểm tra thực tế: [ ] Mềm vỏ, [ ] Phản xạ tốt, [ ] Thấy đường đôi (Double line), [ ] Đã lột xong.
  - Dropdown chọn Nhãn kết luận cuối cùng (Hard shell / Soft shell / Pre-molt / Post-molt).
  - Ô nhập Ghi chú & Nút chụp ảnh thực tế.
  - Nút "AI phát hiện Sai -> Gửi Feedback".

### 11. `MOB-AiFeedback` (AI Feedback)
- **Mục đích**: Gửi phản hồi đánh giá mô hình AI phục vụ Retrain Model.
- **Thành phần UI**:
  - Thẻ tóm tắt kết quả phát hiện của AI và video liên quan.
  - 2 Nút lớn nổi bật: **ĐÚNG (Correct)** và **SAI (Wrong)**.
  - Chọn Nhãn chính xác thực tế nếu bấm chọn SAI.
  - Nút Gửi phản hồi.

### 12. `MOB-RecoAct` (AI Recommendation)
- **Mục đích**: Nhận khuyến nghị hành động thông minh từ hệ thống AI (Thu hoạch / Tiếp tục nuôi / Điều trị).
- **Thành phần UI**:
  - Thẻ Recommendation: Hành động đề xuất, Độ tin cậy (%), Lý do phân tích.
  - 3 Nút quyết định: **Thu hoạch (Harvest)** | **Nuôi tiếp (Continue)** | **Điều trị (Treat)**.
  - Form ghi nhận Outcome sau khi thực hiện quyết định.

### 13. `MOB-OpsLog` (Nhật ký Vận hành)
- **Mục đích**: Nhập nhanh công việc chăm sóc ao nuôi tại chỗ.
- **Thành phần UI**:
  - Filter Chips chọn loại thao tác: Cho ăn, Thay nước, Chích Ca/Khoáng, Tạt muối, Vệ sinh, Lọc nước, Điều trị bệnh.
  - Chọn Phạm vi tác động: Toàn Ao / Danh sách Box cụ thể.
  - Ô nhập Số lượng + Đơn vị + Vật tư/Hóa chất sử dụng.
  - Nút chụp ảnh Trước / Sau thao tác (Optional).
  - Lưu vào Hàng chờ Offline Queue nếu không có kết nối mạng.

### 14. `MOB-HarvestQuick` (Thu hoạch nhanh)
- **Mục đích**: Lập phiếu thu hoạch Cua lột tại hiện trường trong khoảng thời gian "vàng".
- **Thành phần UI**:
  - Quét mã Box thu hoạch.
  - Ô nhập Trọng lượng cua thu hoạch (kg).
  - Công tắc Toggle phân loại Cua lột (Softshell) / Cua thịt.
  - Thêm dòng vào Phiếu thu hoạch (Voucher list).
  - Nút Chốt phiếu thu hoạch.

### 15. `MOB-QuickSale` (Bán nhanh Cua lột)
- **Mục đích**: Xuất bán Cua lột tươi trực tiếp cho thương lái ngay sau thu hoạch.
- **Thành phần UI**:
  - Picker chọn Thương lái / Thêm nhanh Khách hàng mới.
  - Danh sách Cua lột sẵn sàng bán.
  - Ô nhập Số lượng (kg) & Đơn giá (VNĐ).
  - Chọn Phương thức thanh toán: Tiền mặt (Cash) / Chuyển khoản (Transfer).
  - Nút Xác nhận đơn hàng & Tạo hóa đơn.

### 16. `MOB-TraceScan` (Quét QR Truy xuất Nguồn gốc)
- **Mục đích**: Tra cứu minh bạch toàn bộ nhật ký nuôi cấy sản phẩm Cua.
- **Thành phần UI**:
  - Camera scanner quét mã QR dán trên bao bì sản phẩm.
  - Timeline tóm tắt rút gọn: Nguồn gốc con giống -> Quá trình lột xác -> Lịch sử kiểm định -> Ngày thu hoạch & Đóng gói.

### 17. `MOB-NotifSettings` (Cài đặt Thông báo)
- **Mục đích**: Cấu hình nhận cảnh báo khẩn cấp qua ứng dụng và Telegram.
- **Thành phần UI**:
  - Công tắc Toggles bật/tắt Push Notification theo cấp độ (Khẩn cấp, Cảnh báo, Thông tin).
  - Nút liên kết tài khoản Telegram cá nhân (Telegram Deep Link).
  - Nút gửi Thông báo thử nghiệm (Test Notification).