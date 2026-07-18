# Assets - Images (Mobile)

Thư mục chứa các hình ảnh và logo của ứng dụng CrabSense Mobile.

## Cấu trúc

```
assets/images/
├── logo.png              # Logo chính (512x512)
├── logo_small.png        # Logo nhỏ (128x128)
├── logo_icon.png         # Icon (64x64)
└── splash_logo.png       # Logo cho splash screen (1024x1024)
```

## Yêu cầu cho Mobile

- **Logo chính**: 512x512px, PNG với background trong suốt
- **Logo nhỏ**: 128x128px, dùng cho header/appbar
- **Icon**: 64x64px, dùng cho các nút
- **Splash logo**: 1024x1024px, dùng cho màn hình khởi động
- **App Icon**: Các kích thước cho iOS và Android (xem Android/iOS launcher icons)

## Launcher Icons (App Icon)

### Android
Đặt file trong: `android/app/src/main/res/`
- `mipmap-mdpi/ic_launcher.png` (48x48)
- `mipmap-hdpi/ic_launcher.png` (72x72)
- `mipmap-xhdpi/ic_launcher.png` (96x96)
- `mipmap-xxhdpi/ic_launcher.png` (144x144)
- `mipmap-xxxhdpi/ic_launcher.png` (192x192)

### iOS
Đặt file trong: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Nhiều kích thước khác nhau từ 20x20 đến 1024x1024

## Logo mặc định

Hiện tại đang sử dụng icon mặc định.
Vui lòng thêm logo thực tế của CrabSense.

## Cách sử dụng

```dart
Image.asset('assets/images/logo.png', width: 100, height: 100)
```
