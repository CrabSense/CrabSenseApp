# Assets - Images

Thư mục chứa các hình ảnh và logo của ứng dụng CrabSense Desktop.

## Cấu trúc

```
assets/images/
├── logo.png              # Logo chính (512x512)
├── logo_small.png        # Logo nhỏ (128x128)
├── logo_icon.png         # Icon (64x64)
└── splash_logo.png       # Logo cho splash screen (1024x1024)
```

## Yêu cầu

- **Logo chính**: 512x512px, PNG với background trong suốt
- **Logo nhỏ**: 128x128px, dùng cho header/toolbar
- **Icon**: 64x64px, dùng cho các nút và menu
- **Splash logo**: 1024x1024px, dùng cho màn hình khởi động

## Hướng dẫn thêm logo

1. Đặt file logo.png vào thư mục này
2. Logo nên có:
   - Format: PNG với alpha channel (trong suốt)
   - Tỉ lệ: 1:1 (vuông)
   - Chất lượng: High resolution
   - Nội dung: Logo CrabSense, có thể bao gồm hình tôm/nước

## Logo mặc định

Hiện tại đang sử dụng icon mặc định của Flutter. 
Vui lòng thêm logo thực tế của CrabSense vào thư mục này.

## Cách sử dụng trong code

```dart
// Sử dụng logo trong UI
Image.asset(
  'assets/images/logo.png',
  width: 100,
  height: 100,
)
```
