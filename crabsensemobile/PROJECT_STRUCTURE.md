# CrabSense Mobile - Project Structure

This document describes the directory structure and organization of the CrabSense Mobile application following Clean Architecture principles.

## Root Structure

```
crabsensemobile/
├── android/                    # Android native configuration
├── ios/                        # iOS native configuration (when needed)
├── assets/                     # Static assets
│   ├── images/                 # Image assets and logos
│   └── fonts/                  # Inter font family files
├── lib/                        # Dart/Flutter source code
│   ├── app/                    # Application configuration
│   ├── core/                   # Core utilities and constants
│   ├── features/               # Feature modules (Clean Architecture)
│   └── shared/                 # Shared components and services
├── test/                       # Unit and widget tests
├── pubspec.yaml                # Project dependencies
└── analysis_options.yaml       # Linting configuration
```

## lib/ Directory Structure

### app/
Application-level configuration and setup.

```
app/
├── app.dart                    # Main application widget
├── theme.dart                  # Material Design 3 theme configuration
└── router.dart                 # GoRouter navigation configuration
```

### core/
Shared utilities, constants, and cross-cutting concerns.

```
core/
├── constants/                  # Application constants
├── errors/                     # Custom error/exception classes
├── extensions/                 # Dart extensions
├── network/                    # HTTP client configuration
├── theme/                      # Theme data
└── utils/                      # Helper functions
```

### features/
Feature modules following Clean Architecture with three layers:

```
features/
├── [feature_name]/
│   ├── data/                   # Data Layer
│   │   ├── models/             # DTOs (JSON serialization)
│   │   ├── datasources/        # Remote & local data sources
│   │   └── repositories/       # Repository implementations
│   ├── domain/                 # Business Logic Layer
│   │   ├── entities/           # Pure business objects
│   │   ├── repositories/       # Repository interfaces
│   │   └── usecases/           # Business operations
│   └── presentation/           # UI Layer
│       ├── screens/            # Full-page widgets
│       ├── widgets/            # Feature-specific widgets
│       ├── bloc/               # BLoC state management
│       └── models/             # Presentation models (ViewModels)
```

### Current Features

1. **authentication/** - User login, JWT, biometric authentication
2. **dashboard/** - Farm overview, metrics, quick actions
3. **qr_scanner/** - QR code scanning for box identification
4. **box_management/** - Box details, crab inventory, operations
5. **video_capture/** - Video recording for AI analysis
6. **ai_analysis/** - AI detection results and recommendations
7. **manual_inspection/** - Manual verification and feedback
8. **water_quality/** - Real-time IoT sensor monitoring
9. **alerts/** - Alert management and notifications
10. **operation_logs/** - Farm operation recording
11. **harvest/** - Harvest data recording
12. **sales/** - Sales transaction management
13. **crab_records/** - Crab inventory tracking
14. **traceability/** - Product journey tracking
15. **profile/** - User profile and settings
16. **offline_sync/** - Offline data synchronization
17. **permissions/** - Role-based access control
18. **notifications/** - Push notification handling
19. **video_schedule/** - Video capture scheduling

### shared/
Reusable components, widgets, and services used across features.

```
shared/
├── widgets/                    # Reusable UI components
├── services/                   # Shared services (auth, storage, logging)
├── utils/                      # Shared utility functions
├── models/                     # Common data models
└── theme/                      # Shared theme components
```

## Clean Architecture Layers

### Data Layer (Outer Layer)
- **Responsibility**: Data sources, API clients, local storage
- **Components**: Models (DTOs), Data Sources, Repository Implementations
- **Dependencies**: Can depend on Domain layer
- **Key Files**: `*_model.dart`, `*_remote_datasource.dart`, `*_local_datasource.dart`, `*_repository_impl.dart`

### Domain Layer (Core Layer)
- **Responsibility**: Business logic, use cases, entities
- **Components**: Entities, Repository Interfaces, Use Cases
- **Dependencies**: No external dependencies (pure Dart)
- **Key Files**: `*_entity.dart`, `*_repository.dart`, `*_usecase.dart`

### Presentation Layer (Outer Layer)
- **Responsibility**: UI, state management, user interaction
- **Components**: Screens, Widgets, BLoC/Cubit, View Models
- **Dependencies**: Can depend on Domain layer
- **Key Files**: `*_screen.dart`, `*_widget.dart`, `*_bloc.dart`, `*_state.dart`, `*_event.dart`

## Key Technologies

- **Framework**: Flutter 3.x with Dart 3.x
- **State Management**: flutter_bloc (BLoC pattern)
- **Navigation**: go_router with deep linking
- **Local Storage**: drift (SQLite), hive, flutter_secure_storage
- **Networking**: dio with interceptors
- **Camera/Media**: camera, mobile_scanner, video_compress
- **Push Notifications**: firebase_messaging, flutter_local_notifications
- **Code Generation**: freezed, json_serializable, build_runner

## Naming Conventions

- **Files**: snake_case (`user_profile_screen.dart`)
- **Classes**: PascalCase (`UserProfileScreen`)
- **Variables/Functions**: camelCase (`getUserProfile`)
- **Constants**: camelCase or UPPER_SNAKE_CASE
- **Directories**: snake_case (`water_quality`)

## Guidelines

1. **Feature Independence**: Each feature should be self-contained
2. **Dependency Flow**: Presentation → Domain ← Data
3. **No Cross-Feature Dependencies**: Features should not import from other features
4. **Shared Code**: Use `shared/` for reusable components
5. **State Management**: Use BLoC for complex features, Cubit for simple ones
6. **Testing**: Mirror `lib/` structure in `test/` directory
7. **Code Generation**: Run `flutter pub run build_runner build` after model changes

## Next Steps

After initial setup:
1. Configure Firebase for push notifications
2. Set up Drift database schemas
3. Implement authentication flow
4. Create Material Design 3 theme
5. Set up GoRouter with navigation guards
6. Implement offline sync strategy
