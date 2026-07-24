# Features Module

This directory contains all feature modules following Clean Architecture principles.

## Clean Architecture Structure

Each feature module follows this structure:

```
feature_name/
  ├── data/              # Data layer
  │   ├── models/        # DTOs and data models (JSON serialization)
  │   ├── repositories/  # Repository implementations
  │   └── datasources/   # Remote and local data sources
  ├── domain/            # Business logic layer
  │   ├── entities/      # Pure business objects
  │   ├── repositories/  # Repository interfaces
  │   └── usecases/      # Business use cases
  └── presentation/      # UI layer
      ├── screens/       # Full-page screen widgets
      ├── widgets/       # Feature-specific widgets
      ├── bloc/          # BLoC/Cubit state management
      └── models/        # Presentation models (ViewModels)
```

## Current Features

- `authentication/` - User login, biometric auth, session management
- `dashboard/` - Farm overview, metrics, quick actions
- `qr_scanner/` - QR code scanning for box identification
- `box_management/` - Box details, crab inventory, operations
- `video_capture/` - Video recording for AI analysis
- `ai_analysis/` - AI detection results and recommendations
- `manual_inspection/` - Manual verification and feedback
- `water_quality/` - Real-time IoT sensor monitoring
- `alerts/` - Alert management and notifications
- `operation_logs/` - Farm operation recording
- `harvest/` - Harvest data recording
- `sales/` - Sales transaction management
- `crab_records/` - Crab inventory management
- `traceability/` - Product journey tracking
- `profile/` - User profile and settings
- `offline_sync/` - Offline data synchronization
- `permissions/` - Role-based access control
- `notifications/` - Push notification handling
- `video_schedule/` - Video capture scheduling

## Key Principles

- Each feature is independent and self-contained
- Dependencies flow inward: Presentation → Domain ← Data
- Domain layer has no external dependencies
- Use dependency injection for loose coupling
