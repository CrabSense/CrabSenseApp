# Mobile Bottom Navigation Structure

## Tổng quan

| Bottom Tab | Mục đích | Screen ID |
|------------|----------|-----------|
| 🏠 Home | Dashboard & Công việc hôm nay | `MOB-Home` |
| 📦 Box | Quản lý Box & thao tác với cua | `MOB-ScanQR`, `MOB-BoxStatus`, `MOB-CrabQuick`, `MOB-MoltConfirm`, `MOB-AiFeedback` |
| 🤖 AI | AI Decision & Video | `MOB-CaptureVideo`, `MOB-VideoDue`, `MOB-RecoAct` |
| 🌊 Farm | Vận hành ao & IoT | `MOB-WQ`, `MOB-OpsLog`, `MOB-HarvestQuick` |
| ☰ More | Chức năng khác | `MOB-Alerts`, `MOB-QuickSale`, `MOB-TraceScan`, `MOB-NotifSettings` |

---

# Tab 1 - 🏠 Home

## Mục đích
Hiển thị tổng quan các công việc cần làm trong ngày.

### Screen

| Screen ID | Screen Name |
|-----------|-------------|
| `MOB-Home` | Home Operator Dashboard |

### Quick Actions

- Scan QR
- Capture Video
- Operation Log

---

# Tab 2 - 📦 Box

## Mục đích
Toàn bộ quy trình thao tác với một Box sau khi quét QR.

### Screens

| Screen ID | Screen Name |
|-----------|-------------|
| `MOB-ScanQR` | Scan QR Box |
| `MOB-BoxStatus` | Box Status |
| `MOB-CrabQuick` | Quick Crab Record |
| `MOB-MoltConfirm` | Manual Inspection |
| `MOB-AiFeedback` | AI Feedback |

### Navigation

```text
Box
│
├── Scan QR
│
└── Box Status
      │
      ├── Quick Crab Record
      ├── Manual Inspection
      ├── AI Feedback
      ├── Capture Video
      ├── Harvest
      └── Quick Sale
```

---

# Tab 3 - 🤖 AI

## Mục đích

Quản lý Video AI và các quyết định từ AI.

### Screens

| Screen ID | Screen Name |
|-----------|-------------|
| `MOB-VideoDue` | Video Due |
| `MOB-CaptureVideo` | Capture Video |
| `MOB-RecoAct` | AI Recommendation |

### Navigation

```text
AI
│
├── Video Due
│
├── Capture Video
│
└── AI Recommendation
```

---

# Tab 4 - 🌊 Farm

## Mục đích

Theo dõi môi trường và ghi nhận vận hành.

### Screens

| Screen ID | Screen Name |
|-----------|-------------|
| `MOB-WQ` | Water Quality |
| `MOB-OpsLog` | Operation Log |
| `MOB-HarvestQuick` | Quick Harvest |

### Navigation

```text
Farm
│
├── Water Quality
│
├── Operation Log
│
└── Quick Harvest
```

---

# Tab 5 - ☰ More

## Mục đích

Các chức năng phụ trợ và cài đặt.

### Screens

| Screen ID | Screen Name |
|-----------|-------------|
| `MOB-Alerts` | Alerts |
| `MOB-QuickSale` | Quick Sale |
| `MOB-TraceScan` | Traceability Scan |
| `MOB-NotifSettings` | Notification Settings |

### Navigation

```text
More
│
├── Alerts
├── Quick Sale
├── Traceability
└── Notification Settings
```

---

# Main Navigation Flow

```text
Home
 │
 ├── Scan QR
 │      │
 │      ▼
 │  Box Status
 │      │
 │      ├── Capture Video
 │      ├── Manual Inspection
 │      ├── AI Feedback
 │      ├── Operation Log
 │      ├── Harvest
 │      └── Quick Sale
 │
 ├── Alerts
 │
 ├── Video Due
 │      │
 │      ▼
 │   Scan QR
 │
 └── Water Quality
```

---

# Screen Distribution

| Module | Number of Screens | Screen IDs |
|---------|------------------|------------|
| Home | 1 | `MOB-Home` |
| Box | 5 | `MOB-ScanQR`, `MOB-BoxStatus`, `MOB-CrabQuick`, `MOB-MoltConfirm`, `MOB-AiFeedback` |
| AI | 3 | `MOB-CaptureVideo`, `MOB-VideoDue`, `MOB-RecoAct` |
| Farm | 3 | `MOB-WQ`, `MOB-OpsLog`, `MOB-HarvestQuick` |
| More | 4 | `MOB-Alerts`, `MOB-QuickSale`, `MOB-TraceScan`, `MOB-NotifSettings` |

---

# Tổng kết

- **Bottom Tabs:** 5
- **Tổng số Screen:** 16
- **Thiết kế tối ưu cho thao tác ngoài hiện trường**
- **Quy trình chính:** Scan QR → Box Status → AI → Harvest/Sale → Operation Log