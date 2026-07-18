# Hướng dẫn thêm Logo vào CrabSense Mobile

## 📱 Đặc biệt cho Mobile

Logo mobile cần nhiều kích thước hơn desktop để hỗ trợ các độ phân giải màn hình khác nhau.

## 📋 Yêu cầu Logo

### 1. Logo trong ứng dụng

| File | Kích thước | Mục đích |
|------|-----------|----------|
| `logo.png` | 512x512px | Logo chính, hiển thị trong app |
| `logo_small.png` | 128x128px | Logo nhỏ cho AppBar |
| `logo_icon.png` | 64x64px | Icon nhỏ |
| `splash_logo.png` | 1024x1024px | Logo cho splash screen |

### 2. App Icons (Launcher Icons)

#### Android
File trong: `android/app/src/main/res/`

| Thư mục | Kích thước |
|---------|-----------|
| `mipmap-mdpi/` | 48x48px |
| `mipmap-hdpi/` | 72x72px |
| `mipmap-xhdpi/` | 96x96px |
| `mipmap-xxhdpi/` | 144x144px |
| `mipmap-xxxhdpi/` | 192x192px |

#### iOS
File trong: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

Các kích thước: 20x20, 29x29, 40x40, 60x60, 76x76, 83.5x83.5, 1024x1024

## 🔧 Cách thêm Logo nhanh với Flutter Launcher Icons

### Bước 1: Thêm dependency

Thêm vào `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo.png"
  adaptive_icon_background: "#2196F3"
  adaptive_icon_foreground: "assets/images/logo.png"
```

### Bước 2: Generate icons

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

Công cụ sẽ tự động tạo tất cả các kích thước cần thiết!

## 📁 Cách thêm Logo thủ công

### 1. Logo trong ứng dụng

```bash
# Copy logo vào thư mục assets
copy logo.png d:\CrabSense\CrabSenseApp\crabsensemobile\assets\images\
```

### 2. Android Launcher Icon

```bash
# Copy các file icon vào thư mục tương ứng
copy ic_launcher_48.png android\app\src\main\res\mipmap-mdpi\ic_launcher.png
copy ic_launcher_72.png android\app\src\main\res\mipmap-hdpi\ic_launcher.png
copy ic_launcher_96.png android\app\src\main\res\mipmap-xhdpi\ic_launcher.png
copy ic_launcher_144.png android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png
copy ic_launcher_192.png android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png
```

### 3. iOS Launcher Icon

1. Mở Xcode
2. Mở file `ios/Runner.xcworkspace`
3. Chọn `Runner` > `Assets.xcassets` > `AppIcon`
4. Kéo thả các file icon theo kích thước tương ứng

## 🎨 Logo xuất hiện ở đâu?

### 1. Splash Screen
- Logo 120x120px với animation
- Hiển thị khi mở ứng dụng
- File: `lib/screens/splash_screen.dart`

### 2. Home Screen
- Logo 50x50px trên AppBar gradient
- File: `lib/screens/home_screen.dart`

### 3. Settings Screen
- Logo 80x80px ở phần thông tin app
- File: `lib/screens/settings_screen.dart`

### 4. App Icon (Home Screen của điện thoại)
- Icon người dùng tap để mở app
- Android: Các thư mục `mipmap-*`
- iOS: `AppIcon.appiconset`

## ✨ Logo mặc định

Nếu không có file logo, app sẽ hiển thị:
- Gradient xanh dương đẹp mắt
- Icon nước ở giữa
- Icon tôm nhỏ ở góc
- Tự động tối ưu cho mobile

## 🛠️ Tool hỗ trợ tạo Icon

### 1. App Icon Generator (Online)
- https://appicon.co/
- https://makeappicon.com/
- Upload logo 1024x1024px
- Download tất cả kích thước

### 2. Android Asset Studio
- https://romannurik.github.io/AndroidAssetStudio/
- Tạo adaptive icons cho Android

### 3. Adobe Illustrator / Figma
- Design và export nhiều kích thước cùng lúc

## 📱 Test Logo

### Android
```bash
flutter run -d android
```

### iOS
```bash
flutter run -d ios
```

### Check App Icon
1. Build và install app
2. Kiểm tra icon trên home screen
3. Test trên nhiều thiết bị khác nhau

## ⚠️ Lưu ý quan trọng

### Android Adaptive Icons
Android 8.0+ hỗ trợ adaptive icons:
- **Foreground**: Logo (108x108dp safe zone)
- **Background**: Màu nền hoặc pattern
- Giúp logo hiển thị đẹp trên nhiều launcher

### iOS Safe Area
- Logo nên để trên 80% diện tích giữa
- 20% viền ngoài có thể bị cắt

### Format
- Sử dụng PNG với alpha channel
- Tránh dùng text quá nhỏ
- Logo nên đơn giản, dễ nhận diện

## 🎯 Checklist

- [ ] Chuẩn bị logo.png (512x512px)
- [ ] Copy vào `assets/images/`
- [ ] Cài đặt `flutter_launcher_icons`
- [ ] Generate launcher icons
- [ ] Test trên Android
- [ ] Test trên iOS
- [ ] Check splash screen
- [ ] Check app icon trên home screen

## 💡 Gợi ý thiết kế cho Mobile

### Màu sắc
- Sử dụng màu tương phản cao
- Tránh dùng màu quá nhạt
- Test trên cả nền sáng và tối

### Độ phức tạp
- Logo càng đơn giản càng tốt
- Dễ nhận diện ở kích thước nhỏ
- Không quá nhiều chi tiết

### Adaptive
- Design logo vừa đẹp trên nền tròn, vuông, và squircle
- Test trên nhiều launcher khác nhau (Android)

## 🚀 Quick Start

```bash
# 1. Copy logo
copy your_logo.png assets\images\logo.png

# 2. Generate launcher icons
flutter pub run flutter_launcher_icons

# 3. Run app
flutter run

# 4. Check result
# Logo sẽ xuất hiện trong app và trên home screen!
```

## 📞 Hỗ trợ

Nếu gặp vấn đề:
1. Chạy `flutter clean`
2. Xóa folder `build/`
3. Chạy lại `flutter pub get`
4. Rebuild app

Vẫn lỗi? Kiểm tra:
- File path có đúng không
- Format file có phải PNG không
- Kích thước có đúng không
- Permissions trên folder
