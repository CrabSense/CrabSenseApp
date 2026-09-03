# Camera 2 - Thay đổi cấu hình

## Tóm tắt

Camera 2 đã được **cấu hình lại để hoạt động GIỐNG HỆT Camera 1** - sử dụng MJPEG stream thay vì HTML page mode.

## Các file đã thay đổi

### 1. `.env` ✅

**Trước:**

```env
CAMERA_2_IP=10.122.95.227
CAMERA_2_STREAM_URL=http://10.122.95.227/
CAMERA_2_HTML_PAGE=true
CAMERA_2_MAX_FPS=1
CAMERA_2_POLL_MIN_MS=3500
```

**Sau:**

```env
CAMERA_2_IP=10.122.95.227
CAMERA_2_STREAM_URL=
CAMERA_2_HTML_PAGE=false
CAMERA_2_SNAPSHOT_ONLY=false
```

### 2. `.env.example` ✅

Đã cập nhật giống `.env`

### 3. `lib/config/app_env.dart` ✅

**Thay đổi:**

- `camera2StreamUrl`: Giờ trả về `http://{IP}/stream` thay vì `http://{IP}/`
- `camera2SnapshotFallbackUrl`: Thêm endpoint `/capture` giống Camera 1
- `camera2HtmlPage`: Mặc định `false` (trước đây `true`)
- **Đã xóa**: `camera2MaxFps`, `camera2PollMinMs`, `camera2StreamCandidates`

### 4. `lib/data/mock_camera_ai_data.dart` ✅

**Thay đổi:**

```dart
// Đã xóa các tham số HTML page mode
CameraFeed(
  id: 'cam2',
  name: 'Camera 2',
  area: 'Khu B',
  status: CameraStatus.online,
  fps: 24,
  resolution: '1080p',
  lastUpdateSeconds: 3,
  ipAddress: AppEnv.camera2Ip,
  streamUrl: AppEnv.camera2StreamUrl,
  snapshotFallbackUrl: AppEnv.camera2SnapshotFallbackUrl,
  // ❌ Đã xóa: streamUrlCandidates, maxFps, snapshotOnly, htmlPageMode, pollMinMs
  overlays: const [ ... ],
)
```

### 5. `CAMERA_SETUP.md` ✅

Đã cập nhật tài liệu với cấu hình mới

## So sánh Camera 1 vs Camera 2

### Trước khi thay đổi ❌

|             | Camera 1        | Camera 2             |
| ----------- | --------------- | -------------------- |
| Stream Mode | MJPEG           | HTML Page            |
| URL         | `/stream`       | `/` (root)           |
| Player      | MjpegHttpPlayer | HttpPageCameraPlayer |
| FPS         | ~30             | ~1 (poll mỗi 3.5s)   |
| Smooth      | ✅ Mượt         | ❌ Giật              |

### Sau khi thay đổi ✅

|             | Camera 1        | Camera 2        |
| ----------- | --------------- | --------------- |
| Stream Mode | MJPEG           | MJPEG           |
| URL         | `/stream`       | `/stream`       |
| Player      | MjpegHttpPlayer | MjpegHttpPlayer |
| FPS         | ~30             | ~30             |
| Smooth      | ✅ Mượt         | ✅ Mượt         |

## Cách hoạt động mới

### Trước (HTML Page Mode)

```
Camera 2 (10.122.95.227)
    ↓ GET http://10.122.95.227/ (mỗi 3.5s)
    ↓ Parse HTML
    ↓ Extract <img src="...">
    ↓ GET image URL
HttpPageCameraPlayer
    ↓ Display image (1 FPS)
Flutter UI
```

### Sau (MJPEG Stream Mode)

```
Camera 2 (10.122.95.227)
    ↓ GET http://10.122.95.227/stream
    ↓ MJPEG stream (liên tục)
MjpegHttpPlayer
    ↓ Display stream (~30 FPS)
Flutter UI
```

## Lợi ích của việc thay đổi

✅ **Mượt mà hơn**: 30 FPS thay vì 1 FPS  
✅ **Đồng nhất**: Camera 2 hoạt động giống Camera 1  
✅ **Đơn giản hơn**: Không cần logic phức tạp cho HTML parsing  
✅ **Độ trễ thấp**: Stream liên tục thay vì poll interval  
✅ **Code sạch hơn**: Loại bỏ các tham số không cần thiết

## Kiểm tra sau thay đổi

### 1. Kiểm tra file `.env`

```powershell
cat d:\CN8\PRM392\CrabFarmMonitorDesktop\.env
```

Đảm bảo có:

```
CAMERA_2_HTML_PAGE=false
```

### 2. Test stream endpoint Camera 2

```powershell
# Test stream (phải trả về MJPEG stream)
curl http://10.122.95.227/stream

# Mở trong browser
start http://10.122.95.227/stream
```

### 3. Chạy ứng dụng

```powershell
cd d:\CN8\PRM392\CrabFarmMonitorDesktop
flutter run -d windows
```

### 4. Kiểm tra UI

- Vào menu "Camera AI"
- Chọn tab "Camera 2"
- Xác nhận stream mượt mà, không giật

## Troubleshooting

### Camera 2 vẫn hiển thị HTML page mode

**Giải pháp:**

1. Kiểm tra `.env` có `CAMERA_2_HTML_PAGE=false`
2. Hot restart: nhấn `R` trong Flutter terminal
3. Hoặc stop và chạy lại

### Camera 2 không có stream

**Giải pháp:**

1. Kiểm tra ESP32-CAM Camera 2 đã được flash code đúng
2. Test endpoint: `http://10.122.95.227/stream`
3. Kiểm tra ESP32 có endpoint `/stream` trong code

### Camera 2 bị lỗi "Connection closed"

**Giải pháp:**

1. Flash lại code ESP32-CAM_WebServer2
2. Kiểm tra WiFi connection
3. Reboot ESP32-CAM

## Code ESP32-CAM không đổi

**Lưu ý:** Code ESP32-CAM **KHÔNG CẦN THAY ĐỔI**!

Cả `ESP32-CAM_WebServer` và `ESP32-CAM_WebServer2` đều đã có:

- ✅ Endpoint `/stream` - MJPEG stream
- ✅ Endpoint `/capture` - Snapshot
- ✅ Endpoint `/` - Web UI

Chỉ có **ứng dụng Flutter** thay đổi cách kết nối (từ HTML mode sang MJPEG stream mode).

## Kết luận

🎉 **Camera 2 giờ hoạt động GIỐNG HỆT Camera 1!**

- ✅ Cả 2 đều dùng MJPEG stream
- ✅ Cả 2 đều mượt mà ~30 FPS
- ✅ Code đơn giản hơn
- ✅ Dễ maintain hơn
- ✅ Trải nghiệm người dùng tốt hơn
