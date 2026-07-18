# CrabSenseApp

> Ứng dụng **Mobile** (Flutter) — thao tác hiện trường: quét QR, quay video, checklist AI, ghi ops, thu hoạch / bán nhanh.

Repo này triển khai **Member 4 (Mobile)** theo workbook (sheet `02_Man_hinh_UI` filter **Platform = Mobile**).

## Vai trò

| Mục | Nội dung (Excel) |
|-----|------------------|
| Module | Video, AI Decision Support, Notify, Quick sale, Ops |
| FR | FR-3.5, FR-4, FR-5, FR-10 (mobile), FR-5B Operation Log |
| Layout | Bottom navigation + camera flows |

## Màn hình Mobile (Excel)

| Mã MH | Tên | Ý nghĩa |
|-------|-----|---------|
| MOB-Login | Đăng nhập | JWT / biometric optional |
| MOB-Home | Home operator | Task: alerts, video due, pre-molt reco, softshell sẵn |
| MOB-ScanQR | Quét QR box | Bắt buộc trước capture / inspect |
| MOB-BoxStatus | Trạng thái box | Cua + WQ + alert + action row |
| MOB-CaptureVideo | Quay 5–10s | Upload video cho AI (offline queue) |
| MOB-VideoDue | Lịch quay đến hạn | Box overdue |
| MOB-Alerts | Cảnh báo | Push + resolve |
| MOB-WQ | Chất lượng nước | Gauge theo zone/box |
| MOB-CrabQuick | Ghi nhận cua nhanh | Thêm/chuyển cua |
| MOB-MoltConfirm | Manual Inspection | Checklist: mềm / phản xạ / double line / đã lột |
| MOB-AiFeedback | AI Feedback | Correct / Wrong |
| MOB-RecoAct | Recommendation | Harvest / Continue / Treat + outcome |
| MOB-OpsLog | Ghi thao tác | feeding, water_change, calcium, salt, clean, filter, treatment |
| MOB-HarvestQuick | Thu hoạch nhanh | Softshell toggle |
| MOB-QuickSale | Bán nhanh | Softshell tại chỗ |
| MOB-TraceScan | Quét QR sản phẩm | Timeline rút gọn |
| MOB-NotifSettings | Cài thông báo | Push / Telegram |

## Luồng chuẩn hiện trường (Excel FR-4 / FR-5)

```
Scan QR box → Capture video 5–10s → AI detection
  → Manual Inspection checklist → Feedback Correct/Wrong
  → Decision recommendation (harvest|continue|treat) → Outcome
```

## Stack đề xuất

- Flutter (Android ưu tiên; iOS optional)
- Camera + QR scanner
- Local queue khi offline → sync API BE

## Liên kết

- API: [CrabSenseBE](https://github.com/CrabSense/CrabSenseBE)
- AI service: [CrabSenseAIWaterQualityAnalysis](https://github.com/CrabSense/CrabSenseAIWaterQualityAnalysis)
- Web: [CrabSenseFE](https://github.com/CrabSense/CrabSenseFE)
