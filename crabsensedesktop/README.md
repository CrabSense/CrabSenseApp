# CrabSense Desktop

Ứng dụng Flutter Desktop cho hệ thống giám sát chất lượng nước CrabSense.

## Tính năng

- ✅ Giám sát dữ liệu chất lượng nước thời gian thực
- ✅ Hiển thị nhiệt độ, pH, oxy hòa tan, độ mặn
- ✅ Cảnh báo khi vượt ngưỡng
- ✅ Biểu đồ trực quan
- ✅ Kết nối API backend
- ✅ Hỗ trợ Windows, macOS, Linux

## Yêu cầu hệ thống

- Flutter SDK >= 3.12.2
- Dart SDK >= 3.12.2
- Windows 10/11, macOS 10.14+, hoặc Linux

## Cài đặt

1. Clone repository:
```bash
cd d:\CrabSense\CrabSenseApp\crabsensedesktop
```

2. Cài đặt dependencies:
```bash
flutter pub get
```

3. Cấu hình API endpoint trong `lib/utils/constants.dart`:
```dart
static const String apiBaseUrl = 'http://localhost:5000';
```

## Chạy ứng dụng

### Windows
```bash
flutter run -d windows
```

### macOS
```bash
flutter run -d macos
```

### Linux
```bash
flutter run -d linux
```

## Build ứng dụng

### Windows
```bash
flutter build windows --release
```
File .exe sẽ được tạo trong `build\windows\x64\runner\Release\`

### macOS
```bash
flutter build macos --release
```
File .app sẽ được tạo trong `build/macos/Build/Products/Release/`

### Linux
```bash
flutter build linux --release
```
File binary sẽ được tạo trong `build/linux/x64/release/bundle/`

## Cấu trúc dự án

```
lib/
├── main.dart                 # Entry point
├── models/                   # Data models
│   └── water_quality_data.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── data_monitoring_screen.dart
│   └── splash_screen.dart
├── services/                 # API services
│   └── api_service.dart
├── utils/                    # Utilities
│   ├── constants.dart
│   └── helpers.dart
└── widgets/                  # Reusable widgets
    ├── custom_button.dart
    ├── data_card.dart
    └── app_logo.dart
```

## Logo & Branding

Ứng dụng hỗ trợ logo tùy chỉnh:
- **Thư mục logo**: `assets/images/`
- **File cần thiết**: `logo.png` (512x512px, PNG với nền trong suốt)
- **Hướng dẫn chi tiết**: Xem file `HOW_TO_ADD_LOGO.md`

Nếu chưa có logo, ứng dụng sẽ hiển thị icon mặc định đẹp mắt với gradient xanh dương.

## Ngưỡng chất lượng nước

- **Nhiệt độ**: 20-32°C
- **pH**: 7.0-8.5
- **Oxy hòa tan**: 5-10 mg/L
- **Độ mặn**: 10-25 ppt

## Dependencies chính

- `http`: REST API client
- `provider`: State management
- `intl`: Internationalization
- `fl_chart`: Charts and graphs
- `shared_preferences`: Local storage

## Hỗ trợ

Để biết thêm thông tin, vui lòng liên hệ team CrabSense.

## License

Copyright © 2024 CrabSense Team
