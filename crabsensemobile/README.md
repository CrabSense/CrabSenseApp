# CrabSense Mobile

Ứng dụng Flutter Mobile (Android & iOS) cho hệ thống giám sát chất lượng nước CrabSense.

## Tính năng

- ✅ Giám sát dữ liệu thời gian thực trên thiết bị di động
- ✅ Dashboard tổng quan với thông số nhanh
- ✅ Biểu đồ trực quan dữ liệu theo thời gian
- ✅ Thông báo cảnh báo ngay lập tức
- ✅ Giao diện tối ưu cho màn hình nhỏ
- ✅ Pull-to-refresh để cập nhật dữ liệu
- ✅ Bottom navigation dễ sử dụng
- ✅ Hỗ trợ Android và iOS

## Yêu cầu hệ thống

- Flutter SDK >= 3.12.2
- Dart SDK >= 3.12.2
- Android Studio / Xcode (cho phát triển)
- Android 5.0+ / iOS 12.0+

## Cài đặt

1. Di chuyển vào thư mục project:
```bash
cd d:\CrabSense\CrabSenseApp\crabsensemobile
```

2. Cài đặt dependencies:
```bash
flutter pub get
```

3. Cấu hình API endpoint trong `lib/utils/constants.dart`:
```dart
static const String apiBaseUrl = 'http://your-server-ip:5000';
```

## Chạy ứng dụng

### Android
```bash
flutter run -d android
```

### iOS
```bash
flutter run -d ios
```

### Chạy trên emulator/simulator
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

## Build ứng dụng

### Android APK
```bash
flutter build apk --release
```
File APK: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (cho Google Play)
```bash
flutter build appbundle --release
```
File AAB: `build/app/outputs/bundle/release/app-release.aab`

### iOS
```bash
flutter build ios --release
```

## Cấu trúc dự án

```
lib/
├── main.dart                 # Entry point với orientation và system UI config
├── models/                   # Data models
│   └── water_quality_data.dart
├── screens/                  # UI screens
│   ├── splash_screen.dart
│   ├── main_navigation_screen.dart
│   ├── home_screen.dart
│   ├── monitoring_screen.dart
│   ├── chart_screen.dart
│   └── settings_screen.dart
├── services/                 # API services
│   └── api_service.dart
├── utils/                    # Utilities
│   ├── constants.dart
│   └── helpers.dart
└── widgets/                  # Reusable widgets
    ├── app_logo.dart
    └── data_card_mobile.dart
```

## Tính năng Mobile đặc biệt

### Bottom Navigation
4 tab chính:
- **Trang chủ**: Dashboard tổng quan
- **Giám sát**: Dữ liệu chi tiết real-time
- **Biểu đồ**: Phân tích theo thời gian
- **Cài đặt**: Cấu hình ứng dụng

### Orientation Lock
Ứng dụng bị khóa ở chế độ portrait (dọc) để tối ưu trải nghiệm.

### Pull to Refresh
Kéo xuống để làm mới dữ liệu trên màn hình giám sát.

### Responsive Design
Giao diện tự động điều chỉnh theo kích thước màn hình.

## Logo & Assets

- Thư mục: `assets/images/`
- Xem hướng dẫn chi tiết trong `assets/images/README.md`
- Logo fallback đẹp mắt nếu chưa có logo thực tế

## Ngưỡng chất lượng nước

- **Nhiệt độ**: 20-32°C
- **pH**: 7.0-8.5
- **Oxy hòa tan**: 5-10 mg/L
- **Độ mặn**: 10-25 ppt

## Dependencies chính

- `http`: REST API client
- `provider`: State management
- `intl`: Date/time formatting
- `fl_chart`: Charts and graphs
- `shared_preferences`: Local storage
- `pull_to_refresh`: Pull to refresh widget
- `geolocator`: Location services
- `permission_handler`: Permission management

## Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Ứng dụng cần truy cập vị trí để hiển thị dữ liệu gần bạn</string>
```

## Testing trên thiết bị thật

### Android
1. Bật Developer Options và USB Debugging trên điện thoại
2. Kết nối điện thoại qua USB
3. Chạy `flutter devices` để kiểm tra
4. Chạy `flutter run`

### iOS
1. Kết nối iPhone qua USB
2. Tin tưởng máy tính trên iPhone
3. Mở Xcode và cấu hình signing
4. Chạy `flutter run`

## Troubleshooting

### Lỗi "Could not resolve dependencies"
```bash
flutter pub cache repair
flutter clean
flutter pub get
```

### Lỗi kết nối API
- Kiểm tra địa chỉ IP server trong `constants.dart`
- Đảm bảo điện thoại và server cùng mạng
- Kiểm tra firewall

### Hot reload không hoạt động
```bash
flutter run --no-fast-start
```

## Phát triển tiếp

- [ ] Tích hợp push notifications
- [ ] Offline mode với local database
- [ ] Export dữ liệu ra PDF/Excel
- [ ] Dark mode hoàn chỉnh
- [ ] Multi-language support
- [ ] Biometric authentication

## Hỗ trợ

Để biết thêm thông tin, vui lòng liên hệ team CrabSense.

## License

Copyright © 2024 CrabSense Team
