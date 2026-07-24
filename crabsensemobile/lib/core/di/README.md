# Dependency Injection (DI) Module

## Overview

This module provides dependency injection setup for the CrabSense Mobile Application using the `get_it` package. It implements the Service Locator pattern to manage dependencies across the entire application following Clean Architecture principles.

## Key Concepts

### Service Locator Pattern
- **Global Access**: Single `GetIt` instance (`sl`) accessible throughout the app
- **Lazy Initialization**: Dependencies are created only when first accessed
- **Singleton Services**: Core services exist as single instances
- **Factory BLoCs**: Fresh BLoC instances created for each screen

### Registration Types

#### 1. Lazy Singleton (`registerLazySingleton`)
Used for services that should exist as a single instance:
- Data sources (remote and local)
- Repositories
- Use cases
- Core utilities (Logger, Network Info)
- External services (Dio, Storage)

```dart
sl.registerLazySingleton<AuthRepository>(
  () => AuthRepositoryImpl(
    remoteDataSource: sl(),
    localDataSource: sl(),
  ),
);
```

#### 2. Factory (`registerFactory`)
Used for BLoCs that need fresh instances per screen:
```dart
sl.registerFactory(
  () => AuthBloc(
    loginUseCase: sl(),
    logoutUseCase: sl(),
  ),
);
```

## Usage

### 1. Initialization
The DI system is initialized once at app startup in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize dependency injection
  await di.init();
  
  runApp(const CrabSenseMobileApp());
}
```

### 2. Accessing Dependencies

#### In BLoC/Cubit
```dart
import '../../../core/di/injection.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuthBloc>(),
      child: // ... your widget tree
    );
  }
}
```

#### In Repository/Use Case
```dart
import '../../core/di/injection.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });
  
  // Dependencies injected via constructor
}
```

#### Direct Access (Use Sparingly)
```dart
import '../../core/di/injection.dart';

// Access logger anywhere
sl<Logger>().d('Debug message');

// Access Dio client
final response = await sl<Dio>().get('/endpoint');
```

## Structure

The `injection.dart` file is organized by feature modules:

```
init() {
  // Core Dependencies (Logger, Network Info)
  
  // External Dependencies (Dio, Connectivity, Storage)
  
  // Shared Services (Notification, Storage, Camera)
  
  // Feature Modules:
  //   - Authentication
  //   - Dashboard
  //   - QR Scanner
  //   - Box Management
  //   - Video Capture & AI Analysis
  //   - Manual Inspection
  //   - Water Quality
  //   - Alerts
  //   - Operation Logs
  //   - Harvest
  //   - Sales
  //   - Offline Sync
  //   ... and more
}
```

## Adding New Dependencies

When implementing a new feature, follow this pattern:

### 1. Data Sources
```dart
// Remote Data Source
sl.registerLazySingleton<MyFeatureRemoteDataSource>(
  () => MyFeatureRemoteDataSourceImpl(dio: sl()),
);

// Local Data Source
sl.registerLazySingleton<MyFeatureLocalDataSource>(
  () => MyFeatureLocalDataSourceImpl(hive: sl()),
);
```

### 2. Repository
```dart
sl.registerLazySingleton<MyFeatureRepository>(
  () => MyFeatureRepositoryImpl(
    remoteDataSource: sl(),
    localDataSource: sl(),
    networkInfo: sl(),
  ),
);
```

### 3. Use Cases
```dart
sl.registerLazySingleton(() => GetMyFeatureDataUseCase(sl()));
sl.registerLazySingleton(() => CreateMyFeatureUseCase(sl()));
```

### 4. BLoC
```dart
sl.registerFactory(
  () => MyFeatureBloc(
    getMyFeatureData: sl(),
    createMyFeature: sl(),
  ),
);
```

### 5. Uncomment Imports
After implementing your feature, uncomment the corresponding import statements at the top of `injection.dart`:

```dart
// Before implementation
// import '../../features/my_feature/data/datasources/my_feature_remote_data_source.dart';

// After implementation
import '../../features/my_feature/data/datasources/my_feature_remote_data_source.dart';
```

## Testing

### Unit Tests
For unit tests, you can mock dependencies:

```dart
import 'package:mockito/mockito.dart';
import 'package:crabsensemobile/core/di/injection.dart';

void main() {
  setUp(() async {
    // Reset service locator before each test
    await reset();
    await init();
    
    // Override with mocks
    sl.allowReassignment = true;
    sl.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
  });
}
```

### Integration Tests
Use the real DI setup but with test configuration:

```dart
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  await di.init();
  
  testWidgets('Login flow', (tester) async {
    await tester.pumpWidget(const CrabSenseMobileApp());
    // ... test code
  });
}
```

## Best Practices

### ✅ Do:
- Register interfaces, not concrete implementations (Dependency Inversion)
- Use lazy singletons for stateless services
- Use factories for stateful components (BLoCs)
- Keep registration order: Core → External → Data Sources → Repositories → Use Cases → BLoCs
- Document each registration with comments
- Group registrations by feature module

### ❌ Don't:
- Don't access `sl<>()` directly in widgets (use BlocProvider instead)
- Don't register mutable state as singletons
- Don't create circular dependencies
- Don't register without type parameters (`sl.register(() => MyClass())` ❌)
- Don't forget to call `await di.init()` before `runApp()`

## Troubleshooting

### Error: "Object/factory with type X is not registered inside GetIt"
**Solution**: Make sure you've:
1. Registered the dependency in `injection.dart`
2. Uncommented the registration code
3. Called `await di.init()` in `main.dart`
4. Used the correct type parameter when accessing: `sl<MyType>()`

### Error: "Bad state: The method 'Xxx' was called on null"
**Solution**: 
- Check if you're trying to access a dependency before `di.init()` completes
- Ensure your dependency chain is complete (no missing dependencies)

### BLoC not updating UI
**Solution**:
- Verify BLoC is registered as `factory`, not `singleton`
- Check if you're creating a new BlocProvider per screen
- Ensure you're using `BlocProvider` correctly

## Architecture Diagram

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│  (Screens, Widgets, BLoCs - Factory)    │
└─────────────────┬───────────────────────┘
                  │ depends on
┌─────────────────▼───────────────────────┐
│            Domain Layer                  │
│  (Use Cases, Entities - Singleton)       │
└─────────────────┬───────────────────────┘
                  │ depends on
┌─────────────────▼───────────────────────┐
│             Data Layer                   │
│  (Repositories, Data Sources - Singleton)│
└─────────────────┬───────────────────────┘
                  │ depends on
┌─────────────────▼───────────────────────┐
│          External Dependencies           │
│  (Dio, Hive, SecureStorage - Singleton)  │
└──────────────────────────────────────────┘
```

## Related Files

- `lib/main.dart` - DI initialization at app startup
- `lib/core/di/injection.dart` - All dependency registrations
- Feature modules - Individual implementations that get registered

## Requirements Coverage

This DI module satisfies the following requirements:
- **Requirement 1.8**: Authentication service initialization
- **Requirements 19.1-19.10**: Permission manager and role-based access control setup
- All other feature requirements through proper dependency registration

## References

- [get_it package documentation](https://pub.dev/packages/get_it)
- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter BLoC pattern](https://bloclibrary.dev/)
