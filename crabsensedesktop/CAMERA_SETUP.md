# Cấu hình Camera cho CrabFarmMonitorDesktop

## Tổng quan

Ứng dụng đã được cấu hình sẵn để hiển thị **2 camera ESP32-CAM** với IP tĩnh, cả 2 đều sử dụng MJPEG stream.

### Camera 1

- **IP**: `10.122.95.47`
- **Stream URL**: `http://10.122.95.47/stream`
- **Snapshot URL**: `http://10.122.95.47/capture`
- **Khu vực**: Khu A
- **ID**: `cam1`

### Camera 2

- **IP**: `10.122.95.227`
- **Stream URL**: `http://10.122.95.227/stream`
- **Snapshot URL**: `http://10.122.95.227/capture`
- **Khu vực**: Khu B
- **ID**: `cam2`

## Kiến trúc

### 1. Cấu hình môi trường (`.env`)

```env
# Camera 1
CAMERA_1_IP=10.122.95.47
CAMERA_1_STREAM_URL=
CAMERA_1_SNAPSHOT_URL=

# Camera 2
CAMERA_2_IP=10.122.95.227
CAMERA_2_STREAM_URL=
CAMERA_2_HTML_PAGE=false
CAMERA_2_SNAPSHOT_ONLY=false
```

### 2. Config Class (`lib/config/app_env.dart`)

**Camera 1:**

- `camera1Ip` - IP của camera 1
- `camera1StreamUrl` - URL stream camera 1 (MJPEG): `http://{IP}/stream`
- `camera1SnapshotFallbackUrl` - URL snapshot khi stream lỗi: `http://{IP}/capture`

**Camera 2:**

- `camera2Ip` - IP của camera 2
- `camera2StreamUrl` - URL stream camera 2 (MJPEG): `http://{IP}/stream`
- `camera2SnapshotFallbackUrl` - URL snapshot khi stream lỗi: `http://{IP}/capture`
- `camera2SnapshotOnly` - Chỉ dùng snapshot (không stream)
- `camera2HtmlPage` - Bật HTML page mode (mặc định: false)

### 3. Data Layer (`lib/data/mock_camera_ai_data.dart`)

Định nghĩa 3 camera feeds:

- **Camera 1** (cam1): Khu A - Online
- **Camera 2** (cam2): Khu B - Online
- **Camera 3** (cam3): Khu C - Lag (camera dự phòng)

### 4. Player Component (`lib/widgets/camera/camera_stream_player.dart`)

Hỗ trợ 3 chế độ phát:

- **MJPEG over HTTP**: Cho camera stream thông thường (`/stream`) ← **Camera 1 & 2 dùng mode này**
- **HTML Page Mode**: Cho camera phát HTML tại root `/` (tắt mặc định)
- **Media Kit**: Cho RTSP/RTMP streams

### 5. UI Integration

- `lib/screens/camera/camera_ai_page.dart` - Trang chính hiển thị camera
- `lib/widgets/camera/camera_ai_widgets.dart` - Các widget camera
- `lib/widgets/camera/mjpeg_http_player.dart` - Player cho MJPEG stream

## Cách hoạt động

### Camera 1 & Camera 2 (Cùng MJPEG Stream Mode)

```
ESP32-CAM (10.122.95.47 hoặc 10.122.95.227)
    ↓ /stream endpoint
MjpegHttpPlayer
    ↓ Hiển thị MJPEG stream liên tục
Flutter UI
```

Cả 2 camera đều:

- Phát MJPEG stream tại `/stream`
- Cung cấp snapshot tại `/capture`
- Hiển thị mượt mà, liên tục (~30 FPS)

## Kiểm tra kết nối

### Kiểm tra Camera 1

```powershell
# Test stream endpoint
curl http://10.122.95.47/stream

# Test snapshot endpoint
curl http://10.122.95.47/capture -o test_cam1.jpg

# Mở trong browser
start http://10.122.95.47
```

### Kiểm tra Camera 2

```powershell
# Test stream endpoint
curl http://10.122.95.227/stream

# Test snapshot endpoint
curl http://10.122.95.227/capture -o test_cam2.jpg

# Mở trong browser
start http://10.122.95.227
```

## Cách sử dụng trong ứng dụng

1. **Khởi động ứng dụng**:

   ```powershell
   cd d:\CN8\PRM392\CrabFarmMonitorDesktop
   flutter run -d windows
   ```

2. **Truy cập Camera AI page** từ menu bên trái

3. **Chuyển đổi giữa các camera**:
   - Tab "Camera 1" - Xem camera 1 (10.122.95.47)
   - Tab "Camera 2" - Xem camera 2 (10.122.95.227)
   - Tab "Camera 3" - Xem camera 3
   - Tab "Tất cả camera" - Xem grid tất cả

4. **Tính năng**:
   - Live stream MJPEG từ camera (mượt, liên tục)
   - AI bounding box overlay
   - Thông tin camera (FPS, độ phân giải, IP)
   - Danh sách sự kiện AI phát hiện
   - Thống kê phát hiện theo loại
   - Gợi ý từ AI

## Troubleshooting

### Camera không hiển thị

1. Kiểm tra camera đã khởi động và kết nối WiFi
2. Ping IP camera từ máy tính:
   ```powershell
   ping 10.122.95.47
   ping 10.122.95.227
   ```
3. Mở browser test URL stream:
   ```
   http://10.122.95.47/stream
   http://10.122.95.227/stream
   ```
4. Kiểm tra file `.env` đúng IP và `CAMERA_2_HTML_PAGE=false`

### Camera stream bị giật/lag

- Kiểm tra băng thông mạng WiFi
- Giảm độ phân giải camera (FRAMESIZE_QVGA thay vì VGA)
- Tăng `jpeg_quality` trong code ESP32 (12 → 15)
- Kiểm tra nhiều thiết bị cùng kết nối WiFi

### Camera 2 không stream như Camera 1

- Đảm bảo `.env` có `CAMERA_2_HTML_PAGE=false`
- Hot restart ứng dụng Flutter: nhấn `R` trong terminal
- Hoặc stop và chạy lại: `flutter run -d windows`

## Code ESP32-CAM

Hai folder ESP32-CAM hoàn toàn giống nhau về chức năng:

- `ESP32-CAM_WebServer` - Camera 1 (10.122.95.47)
- `ESP32-CAM_WebServer2` - Camera 2 (10.122.95.227)

Cả hai đều:

- Kết nối WiFi "Khanh" / "khanhui0"
- Cấu hình IP tĩnh
- Phát MJPEG stream tại `/stream`
- Cung cấp snapshot tại `/capture`
- Web interface tại `/`

### Endpoint URLs

**Camera 1:**

```
http://10.122.95.47/         → Web UI
http://10.122.95.47/stream   → MJPEG stream
http://10.122.95.47/capture  → Single JPEG snapshot
```

**Camera 2:**

```
http://10.122.95.227/        → Web UI
http://10.122.95.227/stream  → MJPEG stream
http://10.122.95.227/capture → Single JPEG snapshot
```

## So sánh cấu hình Camera 1 vs Camera 2

| Tính năng    | Camera 1        | Camera 2        |
| ------------ | --------------- | --------------- |
| IP           | 10.122.95.47    | 10.122.95.227   |
| Stream URL   | `/stream`       | `/stream`       |
| Snapshot URL | `/capture`      | `/capture`      |
| Mode         | MJPEG Stream    | MJPEG Stream    |
| Player       | MjpegHttpPlayer | MjpegHttpPlayer |
| FPS          | ~30             | ~30             |
| Băng thông   | Cao             | Cao             |
| Độ trễ       | Thấp            | Thấp            |

**Kết luận:** Cả 2 camera hoạt động giống hệt nhau! ✅

## Kết luận

✅ **Camera 1** và **Camera 2** đã được cấu hình GIỐNG NHAU  
✅ Cả 2 đều dùng **MJPEG stream** tại `/stream`  
✅ Code Flutter tự động phát stream mượt mà  
✅ Chỉ cần flash code lên ESP32-CAM và chạy ứng dụng  
✅ UI tự động hiển thị và chuyển đổi giữa 2 camera
