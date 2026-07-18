# CrabSense Mobile - Cấu trúc thư mục

## Tổng quan
Ứng dụng Flutter Mobile (Android & iOS) cho hệ thống giám sát chất lượng nước CrabSense.

## Cấu trúc thư mục

```
lib/
├── main.dart                       # Entry point với config mobile-specific
├── models/                         # Data models
│   └── water_quality_data.dart     # Model dữ liệu chất lượng nước
├── screens/                        # Màn hình UI
│   ├── splash_screen.dart          # Màn hình khởi động
│   ├── main_navigation_screen.dart # Bottom navigation chính
│   ├── home_screen.dart            # Dashboard tổng quan
│   ├── monitoring_screen.dart      # Giám sát real-time
│   ├── chart_screen.dart           # Biểu đồ phân tích
│   └── settings_screen.dart        # Cài đặt
├── services/                       # Business logic & API
│   └── api_service.dart            # REST API client
├── utils/                          # Utilities & helpers
│   ├── constants.dart              # Hằng số, config (mobile-optimized)
│   └── helpers.dart                # Helper functions
└── widgets/                        # Reusable components
    ├── app_logo.dart               # Logo widget với fallback
    └── data_card_mobile.dart       # Card dữ liệu (mobile layout)
```

## Đặc điểm Mobile

### 1. Orientation Lock
```dart
// main.dart
SystemChrome.setPreferredOrientations([
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
]);
```

### 2. Bottom Navigation
4 tabs chính với `NavigationBar`:
- **Home**: Dashboard overview
- **Monitoring**: Real-time data
- **Charts**: Analytics  
- **Settings**: Configuration

### 3. Responsive Widgets
- `DataCardMobile`: Compact layout cho màn hình nhỏ
- Grid 2 cột cho thống kê
- Pull-to-refresh pattern

### 4. Status Bar
```dart
SystemChrome.setSystemUIOverlayStyle(
  SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ),
);
```

## Screens Chi Tiết

### SplashScreen
- Animation fade + scale
- Logo với loading indicator
- Auto-navigate sau 3s

### HomeScreen  
- Sliver AppBar với gradient
- Quick stats grid 2x2
- System status cards
- Quick action buttons

### MonitoringScreen
- List view với data cards
- Pull-to-refresh
- Error handling với retry
- Empty state

### ChartScreen
- Period selector (24h/7d/30d)
- Placeholder charts
- Stats summary per metric

### SettingsScreen
- App info với logo
- Notification toggle
- Dark mode toggle
- Server configuration
- About dialog

## Widgets Tái Sử Dụng

### AppLogo
```dart
AppLogo(size: 80)                    // Simple logo
AppLogo(size: 80, showText: true)   // Logo + text
AppBarLogo()                         // Small logo for AppBar
AnimatedAppLogo(size: 100)          // Animated logo
```

### DataCardMobile
```dart
DataCardMobile(data: waterQualityData)
```
- Compact 2-column layout
- Color-coded status
- Relative timestamp
- Touch-friendly sizing

## Dependencies Đặc Biệt cho Mobile

```yaml
pull_to_refresh: ^2.0.0           # Pull-to-refresh gesture
geolocator: ^11.0.0                # Location services
permission_handler: ^11.2.0        # Runtime permissions
```

## Mobile-Specific Constants

```dart
// constants.dart
static const Color backgroundColor = Color(0xFFF5F5F5);
static const double smallPadding = 8.0;
static const double defaultBorderRadius = 12.0;  // Rounded for mobile
static const double bottomNavHeight = 60.0;
```

## Cách sử dụng

### Run on Android
```bash
flutter run -d android
```

### Run on iOS
```bash
flutter run -d ios
```

### Build APK
```bash
flutter build apk --release
```

### Build iOS
```bash
flutter build ios --release
```

## Testing

### Emulator
```bash
flutter emulators --launch <emulator-id>
flutter run
```

### Real Device
1. Enable USB debugging (Android) / Trust computer (iOS)
2. Connect device
3. `flutter devices`
4. `flutter run`

## Best Practices

### Layout
- Sử dụng `SafeArea` cho notch/status bar
- `MediaQuery` cho responsive
- `ListView` thay vì `Column` cho scroll

### Performance
- `const` constructors khi có thể
- `ListView.builder` cho list dài
- Image caching

### UX
- Loading states rõ ràng
- Error messages dễ hiểu
- Empty states với action
- Pull-to-refresh pattern
- Touch target >= 48dp

## Permissions

### Android
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

### iOS
```xml
<!-- Info.plist -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Cần truy cập vị trí</string>
```

## Future Enhancements

- [ ] Push notifications
- [ ] Offline mode with SQLite
- [ ] Biometric auth
- [ ] Dark theme
- [ ] Export data (PDF/CSV)
- [ ] Multi-language
- [ ] Widget for home screen
