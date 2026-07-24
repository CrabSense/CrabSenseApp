// ignore_for_file: unused_local_variable, dead_code

/// Example usage of the dependency injection system
///
/// This file demonstrates how to use the GetIt service locator
/// to access dependencies throughout the application.
///
/// NOTE: This file is for documentation purposes only and should not
/// be included in the production build.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import 'injection.dart';

/// Example 1: Accessing dependencies in a screen widget
class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Example: Access logger directly (use sparingly)
    sl<Logger>().d('ExampleScreen built');

    // Example: Provide a BLoC to the widget tree
    // BLoCs are registered as factories, so each BlocProvider
    // gets a fresh instance
    return BlocProvider(
      // Get a fresh BLoC instance from the service locator
      // Uncomment when AuthBloc is implemented:
      // create: (context) => sl<AuthBloc>(),
      create: (context) => throw UnimplementedError('AuthBloc not yet implemented'),
      child: Scaffold(
        appBar: AppBar(title: const Text('Example')),
        body: const ExampleContent(),
      ),
    );
  }
}

/// Example 2: Using BLoC in widget
class ExampleContent extends StatelessWidget {
  const ExampleContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the BLoC provided above
    // Uncomment when AuthBloc is implemented:
    // final authBloc = context.read<AuthBloc>();

    return const Center(child: Text('Example content'));
  }
}

/// Example 3: Repository implementation with injected dependencies
///
/// This shows how repositories receive their dependencies through
/// constructor injection, with the actual instances provided by GetIt.
class ExampleRepositoryImpl {
  ExampleRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });
  // Dependencies are passed through constructor
  final dynamic remoteDataSource;
  final dynamic localDataSource;
  final dynamic networkInfo;

  // Implementation methods would go here
}

/// Example 4: How the repository would be registered in injection.dart
///
/// This is what you would add to the init() function:
///
/// ```dart
/// // Data Sources
/// sl.registerLazySingleton<ExampleRemoteDataSource>(
///   () => ExampleRemoteDataSourceImpl(dio: sl()),
/// );
///
/// sl.registerLazySingleton<ExampleLocalDataSource>(
///   () => ExampleLocalDataSourceImpl(hive: sl()),
/// );
///
/// // Repository - GetIt automatically injects dependencies by calling sl()
/// sl.registerLazySingleton<ExampleRepository>(
///   () => ExampleRepositoryImpl(
///     remoteDataSource: sl(),  // GetIt resolves to ExampleRemoteDataSource
///     localDataSource: sl(),   // GetIt resolves to ExampleLocalDataSource
///     networkInfo: sl(),       // GetIt resolves to NetworkInfo
///   ),
/// );
///
/// // Use Case
/// sl.registerLazySingleton(() => GetExampleDataUseCase(sl()));
///
/// // BLoC (as factory for fresh instances)
/// sl.registerFactory(
///   () => ExampleBloc(getExampleData: sl()),
/// );
/// ```

/// Example 5: Use Case with injected repository
class ExampleUseCase {
  ExampleUseCase(this.repository);
  final dynamic repository;

  // Use case logic would go here
  // Future<Either<Failure, Data>> call(Params params) async {
  //   return await repository.getData(params);
  // }
}

/// Example 6: BLoC with injected use cases
class ExampleBloc {
  ExampleBloc({required this.getDataUseCase, required this.createDataUseCase});
  final dynamic getDataUseCase;
  final dynamic createDataUseCase;

  // BLoC event handlers would go here
}

/// Example 7: Accessing core utilities directly
void exampleLogging() {
  // Access logger instance
  final logger = sl<Logger>();

  logger.d('Debug message');
  logger.i('Info message');
  logger.w('Warning message');
  logger.e('Error message');
}

/// Example 8: Accessing HTTP client for API calls
Future<void> exampleApiCall() async {
  // Access Dio instance (not recommended - use repositories instead)
  // final dio = sl<Dio>();
  // final response = await dio.get('/endpoint');

  // Better approach: Use repository pattern
  // final repository = sl<ExampleRepository>();
  // final result = await repository.getData();
}

/// Example 9: Multiple BLoC providers in a screen
class ExampleMultiBlocScreen extends StatelessWidget {
  const ExampleMultiBlocScreen({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: const [
      // Each BlocProvider gets a fresh instance from the factory
      // Uncomment when BLoCs are implemented:
      // BlocProvider(create: (context) => sl<DashboardBloc>()),
      // BlocProvider(create: (context) => sl<AlertBloc>()),
      // BlocProvider(create: (context) => sl<WaterQualityBloc>()),
    ],
    child: Scaffold(
      appBar: AppBar(title: const Text('Multi-BLoC Example')),
      body: const Center(child: Text('Content')),
    ),
  );
}

/// Example 10: Testing with dependency injection
/// 
/// In your test files:
/// 
/// ```dart
/// void main() {
///   setUpAll(() async {
///     // Initialize the service locator
///     await di.init();
///     
///     // Allow reassigning dependencies for mocking
///     sl.allowReassignment = true;
///     
///     // Replace real dependencies with mocks
///     sl.registerLazySingleton<AuthRepository>(
///       () => MockAuthRepository(),
///     );
///   });
///   
///   tearDownAll(() async {
///     // Reset the service locator after tests
///     await di.reset();
///   });
///   
///   test('example test', () {
///     final repository = sl<AuthRepository>();
///     // Test with mocked repository
///   });
/// }
/// ```

/// Common Patterns Summary:
/// 
/// 1. **Singleton Services**: Use `registerLazySingleton` for services that
///    should exist as single instances (repositories, data sources, utilities)
/// 
/// 2. **Factory BLoCs**: Use `registerFactory` for BLoCs to get fresh instances
///    per screen
/// 
/// 3. **Constructor Injection**: Pass dependencies through constructors,
///    resolve them using `sl()` in the registration
/// 
/// 4. **BlocProvider**: Use with `sl<BlocType>()` to provide BLoC to widget tree
/// 
/// 5. **Direct Access**: Only use `sl<Type>()` directly for utilities like
///    Logger, avoid for business logic
/// 
/// 6. **Testing**: Override registrations with mocks using `allowReassignment`
