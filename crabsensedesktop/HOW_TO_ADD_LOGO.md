# Hướng dẫn thêm Logo vào CrabSense Desktop

## 📋 Yêu cầu Logo

### 1. Định dạng và kích thước

Cần chuẩn bị các file logo với kích thước khác nhau:

| File | Kích thước | Mục đích |
|------|-----------|----------|
| `logo.png` | 512x512px | Logo chính, hiển thị ở màn hình chính |
| `logo_small.png` | 128x128px | Logo nhỏ cho toolbar/header |
| `logo_icon.png` | 64x64px | Icon cho menu và nút |
| `splash_logo.png` | 1024x1024px | Logo cho splash screen |

### 2. Đặc điểm kỹ thuật

- **Format**: PNG với alpha channel (nền trong suốt)
- **Tỉ lệ**: 1:1 (hình vuông)
- **Màu sắc**: Phù hợp với theme xanh dương của ứng dụng
- **Nội dung**: Logo CrabSense (có thể bao gồm hình tôm, nước, sóng)

## 📁 Cách thêm Logo

### Bước 1: Chuẩn bị file logo

1. Thiết kế logo theo yêu cầu trên
2. Export logo thành các file PNG với kích thước khác nhau
3. Đặt tên file chính xác: `logo.png`, `logo_small.png`, `logo_icon.png`

### Bước 2: Copy file vào thư mục assets

```bash
# Copy các file logo vào thư mục assets/images/
copy logo.png d:\CrabSense\CrabSenseApp\crabsensedesktop\assets\images\
copy logo_small.png d:\CrabSense\CrabSenseApp\crabsensedesktop\assets\images\
copy logo_icon.png d:\CrabSense\CrabSenseApp\crabsensedesktop\assets\images\
```

### Bước 3: Xác nhận cấu hình

File `pubspec.yaml` đã được cấu hình sẵn:

```yaml
flutter:
  assets:
    - assets/images/
    - assets/images/logo.png
    - assets/images/logo_small.png
    - assets/images/logo_icon.png
```

### Bước 4: Chạy lại ứng dụng

```bash
# Dọn dẹp và rebuild
flutter clean
flutter pub get
flutter run -d windows
```

## 🎨 Logo sẽ xuất hiện ở đâu?

### 1. AppBar (Thanh tiêu đề)
- Logo nhỏ 32x32px ở góc trái
- Hiển thị trên tất cả các màn hình

### 2. Home Screen (Màn hình chính)
- Logo lớn 150x150px ở giữa màn hình
- Có animation zoom nhẹ

### 3. Splash Screen (Màn hình khởi động)
- Logo 180x180px với animation fade + scale
- Hiển thị khi mở ứng dụng

### 4. Data Monitoring Screen
- Logo nhỏ ở AppBar

## 🔧 Tùy chỉnh Logo

### Thay đổi kích thước logo

Trong file `lib/screens/home_screen.dart`:

```dart
// Thay đổi kích thước logo chính
const AnimatedAppLogo(size: 150), // Đổi 150 thành số khác
```

### Thêm logo vào màn hình mới

```dart
import '../widgets/app_logo.dart';

// Sử dụng logo đơn giản
AppLogo(size: 100)

// Logo với text
AppLogo(size: 100, showText: true)

// Logo cho AppBar
AppBarLogo()

// Logo với animation
AnimatedAppLogo(size: 120)
```

## 🖼️ Logo mặc định (Fallback)

Nếu không có file logo, ứng dụng sẽ tự động hiển thị:
- Icon nước (water icon) với gradient xanh dương
- Icon tôm nhỏ ở góc dưới phải
- Thiết kế đẹp mắt và phù hợp với theme

## 📱 Thay đổi App Icon (Tùy chọn)

### Windows
File icon: `windows/runner/resources/app_icon.ico`

```bash
# Tạo file .ico từ logo.png (cần tool chuyển đổi)
# Đặt file vào: windows/runner/resources/app_icon.ico
# Rebuild ứng dụng
flutter build windows
```

### macOS
Thư mục: `macos/Runner/Assets.xcassets/AppIcon.appiconset/`

### Linux
File: `linux/runner/resources/app_icon.png`

## ✅ Checklist

- [ ] Chuẩn bị file logo.png (512x512px)
- [ ] Copy file vào thư mục assets/images/
- [ ] Chạy `flutter pub get`
- [ ] Test ứng dụng: `flutter run -d windows`
- [ ] Kiểm tra logo hiển thị đúng trên tất cả màn hình
- [ ] (Tùy chọn) Thay đổi app icon cho Windows/macOS/Linux

## 🎯 Gợi ý thiết kế Logo

### Ý tưởng 1: Tôm + Nước
- Hình tôm stylized ở trung tâm
- Sóng nước/giọt nước ở phía dưới
- Màu gradient xanh dương -> xanh lam

### Ý tưởng 2: Giọt nước + Data
- Giọt nước lớn
- Biểu đồ/chart nhỏ bên trong
- Màu xanh chủ đạo

### Ý tưởng 3: Chữ C stylized
- Chữ C của CrabSense
- Kết hợp hình dạng tôm
- Minimalist, hiện đại

## 📞 Hỗ trợ

Nếu gặp vấn đề khi thêm logo, vui lòng kiểm tra:
1. Đường dẫn file có đúng không
2. Tên file có chính xác không (phân biệt hoa/thường)
3. File có định dạng PNG không
4. Đã chạy `flutter pub get` chưa
