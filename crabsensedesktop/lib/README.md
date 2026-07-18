# CrabSense Desktop - Cấu trúc thư mục

## Tổng quan
Ứng dụng Flutter Desktop cho hệ thống giám sát chất lượng nước CrabSense.

## Cấu trúc thư mục

```
lib/
├── main.dart                 # Entry point của ứng dụng
├── models/                   # Data models
│   └── water_quality_data.dart
├── screens/                  # Màn hình UI
│   ├── home_screen.dart
│   └── data_monitoring_screen.dart
├── services/                 # Business logic & API calls
│   └── api_service.dart
├── utils/                    # Utilities & helpers
│   ├── constants.dart
│   └── helpers.dart
└── widgets/                  # Reusable UI components
    ├── custom_button.dart
    └── data_card.dart
```

## Các thành phần chính

### Models
- `WaterQualityData`: Model cho dữ liệu chất lượng nước (nhiệt độ, pH, oxy hòa tan, độ mặn)

### Screens
- `HomeScreen`: Màn hình chính của ứng dụng
- `DataMonitoringScreen`: Màn hình giám sát dữ liệu thời gian thực

### Services
- `ApiService`: Service để gọi API và xử lý dữ liệu từ backend

### Widgets
- `CustomButton`: Button tùy chỉnh với icon
- `DataCard`: Card hiển thị thông tin chất lượng nước

### Utils
- `Constants`: Các hằng số, ngưỡng, màu sắc
- `Helpers`: Các hàm tiện ích (format datetime, số, kiểm tra ngưỡng)

## Dependencies chính

- `http`: Gọi REST API
- `provider`: State management
- `intl`: Format ngày tháng, số
- `fl_chart`: Vẽ biểu đồ
- `shared_preferences`: Lưu trữ local

## Cách chạy

```bash
# Cài đặt dependencies
flutter pub get

# Chạy ứng dụng trên Windows
flutter run -d windows

# Chạy ứng dụng trên macOS
flutter run -d macos

# Chạy ứng dụng trên Linux
flutter run -d linux
```

## Build ứng dụng

```bash
# Build cho Windows
flutter build windows

# Build cho macOS
flutter build macos

# Build cho Linux
flutter build linux
```

## Cấu hình API

Chỉnh sửa `lib/utils/constants.dart` để cập nhật URL API:

```dart
static const String apiBaseUrl = 'http://localhost:5000';
```

## Ngưỡng chất lượng nước

Được định nghĩa trong `lib/utils/constants.dart`:
- Nhiệt độ: 20-32°C
- pH: 7.0-8.5
- Oxy hòa tan: 5-10 mg/L
- Độ mặn: 10-25 ppt
