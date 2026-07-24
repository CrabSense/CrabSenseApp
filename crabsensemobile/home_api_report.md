# 🏠 Báo Cáo Kiếm Tra API Trang Chủ (Home Command Center) — CrabSense

**Ngày kiểm tra:** 23/07/2026  
**Dự án:** CrabSense Smart Aquaculture Platform  
**Thư mục Backend đối chiếu:** `d:\CrabSense\CrabSenseBE` (`CrabSenseBE.Api`)  
**Backend Base URL:** `http://103.69.96.143:5080/api`  

---

## 📌 1. Tổng Quan Trang Chủ (Farm Command Center)

Màn hình Trang chủ (Home Screen) đóng vai trò là Trung tâm điều khiển toàn bộ trang trại nuôi cua lột thông minh. Trang bao gồm **9 khối thông tin (Widget Sections)** chính:

1. **Home Header & Farm Switcher:** Chào mừng cán bộ vận hành, thông báo chưa đọc, chuyển đổi trang trại.
2. **Farm Overview Hero Card:** Tổng quan số lượng Box, số lượng Cua, Box đang hoạt động, Cảnh báo mở, % IoT Online.
3. **Farm Health Score (Điểm Sức Khỏe Trang Trại):** Điểm đánh giá tổng hợp 0-100%, phân loại Excellent/Good/Warning/Critical.
4. **AI Recommendation Card (Khuyến Nghị AI):** Gợi ý hành động thông minh từ AI (ví dụ: thu hoạch cua lột trong 6h).
5. **Quick Actions Grid (Thao Tác Nhanh):** Quét mã QR, thêm lứa cua, tạo phiếu thu hoạch, ghi nhật ký.
6. **Top Alerts Summary (Cảnh Báo Nổi Bật):** Danh sách các cảnh báo môi trường / thiết bị cần xử lý gấp.
7. **Water Quality Overview (Môi Trường Nước Realtime):** Nhiệt độ, pH, DO (Oxy hòa tan), Độ mặn (Salinity).
8. **Today Tasks (Công Việc Trong Ngày):** Danh sách nhiệm vụ cho ăn, kiểm tra lột, thay nước.
9. **Device Status & Recent Activity:** Thống kê trạng thái thiết bị ESP32/Camera/Bơm/Van & Nhật ký hoạt động gần đây.

---

## 📊 2. Bảng Đối Chiếu API Yêu Cầu vs Thực Tế Backend (`CrabSenseBE`)

| STT | Khối chức năng trên Trang Chủ | Endpoint Mobile Cần Gọi | Endpoint Backend Đối Chiếu | Trạng Thái Backend (`CrabSenseBE`) | Đánh Giá & Hướng Xử Lý |
| :---: | :--- | :--- | :--- | :---: | :--- |
| **1** | **Thông tin Người dùng & Trang trại** | `GET /api/auth/me`<br>`GET /api/farming-areas` | `GET /api/auth/me`<br>`GET /api/farming-areas` | ✅ **Đã có sẵn** | Đã sẵn sàng ghép nối dữ liệu thật |
| **2** | **Farm Overview (Hero Summary)** | `GET /api/dashboard/overview` | `GET /api/dashboard/overview` | ⚠️ **Mới là Stub** | Controller `DashboardController.cs` mới trả về `{ success = true, data = new object() }`. Mobile có thể tạm tính tổng từ `/api/boxes`, `/api/crabs`, `/api/alerts`. |
| **3** | **Farm Health Score (Điểm Sức Khỏe)** | `GET /api/dashboard/metrics` | *Chưa có Endpoint* | ❌ **Thiếu Backend** | Cần Backend bổ sung logic tính toán điểm sức khỏe tổng hợp (Nước + Cua + Thiết bị). |
| **4** | **Khuyến Nghị AI (AI Recommendation)** | `GET /api/ai/recommendations` | `GET /api/ai/recommendations` | ⚠️ **Mới là Stub** | Controller `AiController.cs` mới trả về `Array.Empty<object>()`. Cần bổ sung dữ liệu gợi ý lột vỏ. |
| **5** | **Cảnh Báo Nổi Bật (Top Alerts)** | `GET /api/alerts?activeOnly=true` | `GET /api/alerts` | ✅ **Đã có sẵn** | Controller `AlertsController.cs` đã hỗ trợ lấy cảnh báo active. |
| **6** | **Chất Lượng Nước Realtime** | `GET /api/iot/live`<br>`GET /api/sensors` | `GET /api/iot/live`<br>`GET /api/sensors` | ✅ **Đã có sẵn** | Controller `IotController.cs` & `SensorsController.cs` đã sẵn sàng snapshot realtime. |
| **7** | **Công Việc Trong Ngày (Today Tasks)** | `GET /api/operations/today` | *Chưa có Endpoint* | ❌ **Thiếu Backend** | Cần Backend bổ sung API trả về danh sách lịch công việc vận hành. |
| **8** | **Trạng Thái Thiết Bị (Device Status)** | `GET /api/devices`<br>`POST /api/alerts/check-disconnects` | `GET /api/devices`<br>`POST /api/alerts/check-disconnects` | ✅ **Đã có sẵn** | Controller `DevicesController.cs` đã trả về danh sách thiết bị ESP32 & kiểm tra mất kết nối. |
| **9** | **Nhật Ký Hoạt Động Gần Đây** | `GET /api/operations/recent` | *Chưa có Endpoint* | ❌ **Thiếu Backend** | Cần Backend tạo `OperationsController.cs` ghi nhật ký vận hành. |

---

## 🟢 3. Danh Sách API Trang Chủ ĐÃ CÓ VÀ SẴN SÀNG Trong Backend

Dưới đây là các API chính thức đang hoạt động trong `CrabSenseBE.Api`:

1. **`GET /api/auth/me`** (`AuthController.cs`)
   - Lấy tên cán bộ vận hành, vai trò, avatar và danh sách trang trại được phân quyền.
2. **`GET /api/farming-areas`** (`FarmingController.cs`)
   - Lấy danh sách các khu vực nuôi thuộc trang trại hiện tại.
3. **`GET /api/boxes`** (`FarmingController.cs`)
   - Lấy danh sách Box nuôi để tính tổng số Box và Box đang nuôi (`activeBoxes`).
4. **`GET /api/crabs`** (`FarmingController.cs`)
   - Lấy danh sách cua đang nuôi để tính tổng số lượng cua trong trang trại.
5. **`GET /api/alerts?activeOnly=true`** (`AlertControllers.cs`)
   - Lấy các cảnh báo khẩn cấp (nhiệt độ cao, pH bất thường, oxy giảm, thiết bị mất kết nối).
6. **`GET /api/iot/live`** (`IotController.cs`)
   - Lấy dữ liệu cảm biến chất lượng nước realtime mới nhất (pH, Nhiệt độ, Oxy hòa tan, Độ mặn).
7. **`GET /api/sensors`** (`IotController.cs`)
   - Danh sách cảm biến môi trường đang đo đạc.
8. **`GET /api/devices`** (`IotController.cs`)
   - Danh sách thiết bị IoT (ESP32, Camera, Máy bơm, Van tự động).

---

## 🚨 4. Danh Sách API Trang Chủ THIẾU Hoặc Mới Là STUB Phía Backend

### 4.1. Các API Mới Là Stub (Trả Về Dữ Liệu Rỗng `{}`):
1. **`GET /api/dashboard/overview`** (`SkeletonControllers.cs` line 76)
   - **Hiện tại:** Trả về `{ success = true, data = new object() }`.
   - **Yêu cầu:** Backend cần tổng hợp trả về object chứa: `totalBoxes`, `totalCrabs`, `activeBoxes`, `openAlerts`, `iotOnlinePercentage`.
2. **`GET /api/ai/recommendations`** (`SkeletonControllers.cs` line 108)
   - **Hiện tại:** Trả về `{ success = true, data = [] }`.
   - **Yêu cầu:** Backend/AI Module trả về các khuyến nghị vận hành (ví dụ: Box B01-12 cua chuẩn bị lột vỏ trong 4-6 giờ tới).

### 4.2. Các API Chưa Có (Thiếu Endpoint):
1. **`GET /api/dashboard/metrics`**
   - **Chức năng:** Trả về Điểm sức khỏe trang trại `FarmHealthScore` (0-100), chỉ số nước, chỉ số cua, chỉ số thiết bị và so sánh % so với ngày hôm qua.
2. **`GET /api/operations`** hoặc **`GET /api/operations/recent`**
   - **Chức năng:** Trả về danh sách Công việc trong ngày (`Today Tasks`) và Nhật ký hoạt động gần đây (`Recent Activity`).
3. **`GET /api/videos/schedule`**
   - **Chức năng:** Danh sách lịch quay video/chụp ảnh từ camera AI tự động trong ngày.

---

## 💡 5. Đề Xuất Kế Hoạch Đấu Nối Cho Mobile & Backend

1. **Giải pháp Tạm thời cho Mobile App (`lib/features/home/data/repositories/home_repository_impl.dart`):**
   - Kết hợp các API đã sẵn sàng: Gọi `GET /api/auth/me`, `GET /api/farming-areas`, `GET /api/boxes`, `GET /api/crabs`, `GET /api/alerts`, `GET /api/iot/live` và `GET /api/devices`.
   - Dùng Mock Data địa phương cho 2 khối chưa có API backend: **Farm Health Score** và **Today Tasks / Recent Operations**.

2. **Yêu cầu Đội ngũ Backend (`CrabSenseBE`):**
   - Hoàn thiện dữ liệu thực tế cho `GET /api/dashboard/overview` để Mobile không phải tự gọi lẻ 5 API riêng biệt.
   - Bổ sung logic AI Recommendation tại `GET /api/ai/recommendations`.
   - Xây dựng `OperationsController.cs` để hỗ trợ ghi nhận và truy vấn lịch làm việc/nhật ký vận hành.
