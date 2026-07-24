import 'package:crabsensemobile/features/authentication/data/models/user_model.dart';
import 'package:crabsensemobile/features/authentication/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel', () {
    final tUserModel = UserModel(
      id: '123',
      email: 'test@example.com',
      name: 'Test User',
      role: UserRole.fieldOperator,
      assignedFarmIds: const ['farm1', 'farm2'],
      photoUrl: 'https://example.com/photo.jpg',
      createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      lastLoginAt: DateTime.parse('2024-01-15T12:00:00.000Z'),
    );

    final tUserJson = {
      'id': '123',
      'email': 'test@example.com',
      'name': 'Test User',
      'role': 'fieldOperator',
      'assignedFarmIds': ['farm1', 'farm2'],
      'photoUrl': 'https://example.com/photo.jpg',
      'createdAt': '2024-01-01T00:00:00.000Z',
      'lastLoginAt': '2024-01-15T12:00:00.000Z',
    };

    test('should be a subclass of User entity', () {
      // assert
      expect(tUserModel, isA<User>());
    });

    group('fromJson', () {
      test('should return a valid UserModel from JSON', () {
        // act
        final result = UserModel.fromJson(tUserJson);

        // assert
        expect(result, equals(tUserModel));
      });

      test('should parse DateTime fields correctly', () {
        // act
        final result = UserModel.fromJson(tUserJson);

        // assert
        expect(result.createdAt, isA<DateTime>());
        expect(result.lastLoginAt, isA<DateTime>());
      });

      test('should parse UserRole enum correctly', () {
        // act
        final result = UserModel.fromJson(tUserJson);

        // assert
        expect(result.role, UserRole.fieldOperator);
      });

      test('should handle null photoUrl', () {
        // arrange
        final jsonWithoutPhoto = Map<String, dynamic>.from(tUserJson);
        jsonWithoutPhoto['photoUrl'] = null;

        // act
        final result = UserModel.fromJson(jsonWithoutPhoto);

        // assert
        expect(result.photoUrl, isNull);
      });

      test('should handle null lastLoginAt', () {
        // arrange
        final jsonWithoutLastLogin = Map<String, dynamic>.from(tUserJson);
        jsonWithoutLastLogin['lastLoginAt'] = null;

        // act
        final result = UserModel.fromJson(jsonWithoutLastLogin);

        // assert
        expect(result.lastLoginAt, isNull);
      });
    });

    group('toJson', () {
      test('should return a JSON map containing proper data', () {
        // act
        final result = tUserModel.toJson();

        // assert
        expect(result, equals(tUserJson));
      });

      test('should format DateTime to ISO 8601 string', () {
        // act
        final result = tUserModel.toJson();

        // assert
        expect(result['createdAt'], isA<String>());
        expect(result['lastLoginAt'], isA<String>());
      });

      test('should convert UserRole enum to string', () {
        // act
        final result = tUserModel.toJson();

        // assert
        expect(result['role'], 'fieldOperator');
      });
    });

    group('fromEntity', () {
      test('should create UserModel from User entity', () {
        // arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          name: 'Test User',
          role: UserRole.fieldOperator,
          assignedFarmIds: const ['farm1', 'farm2'],
          photoUrl: 'https://example.com/photo.jpg',
          createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
          lastLoginAt: DateTime.parse('2024-01-15T12:00:00.000Z'),
        );

        // act
        final result = UserModel.fromEntity(user);

        // assert
        expect(result.id, user.id);
        expect(result.email, user.email);
        expect(result.name, user.name);
        expect(result.role, user.role);
      });
    });

    group('toEntity', () {
      test('should return a User entity', () {
        // act
        final result = tUserModel.toEntity();

        // assert
        expect(result, isA<User>());
        expect(result.id, tUserModel.id);
        expect(result.email, tUserModel.email);
        expect(result.name, tUserModel.name);
        expect(result.role, tUserModel.role);
      });
    });

    group('copyWith', () {
      test('should return a copy with updated fields', () {
        // act
        final result = tUserModel.copyWith(name: 'Updated Name', email: 'updated@example.com');

        // assert
        expect(result.name, 'Updated Name');
        expect(result.email, 'updated@example.com');
        expect(result.id, tUserModel.id);
        expect(result.role, tUserModel.role);
      });

      test('should preserve original values when no updates', () {
        // act
        final result = tUserModel.copyWith();

        // assert
        expect(result, equals(tUserModel));
      });
    });
  });

  group('AuthResponse', () {
    final tUserModel = UserModel(
      id: '123',
      email: 'test@example.com',
      name: 'Test User',
      role: UserRole.fieldOperator,
      assignedFarmIds: const ['farm1'],
      createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
    );

    final tAuthResponse = AuthResponse(
      user: tUserModel,
      accessToken: 'access_token_123',
      refreshToken: 'refresh_token_456',
      accessTokenExpiresAt: DateTime.parse('2024-01-01T01:00:00.000Z'),
      refreshTokenExpiresAt: DateTime.parse('2024-01-08T00:00:00.000Z'),
    );

    final tAuthJson = {
      'user': {
        'id': '123',
        'email': 'test@example.com',
        'name': 'Test User',
        'role': 'fieldOperator',
        'assignedFarmIds': ['farm1'],
        'photoUrl': null,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'lastLoginAt': null,
      },
      'access_token': 'access_token_123',
      'refresh_token': 'refresh_token_456',
    };

    test('should parse AuthResponse from JSON', () {
      // act
      final result = AuthResponse.fromJson(tAuthJson);

      // assert
      expect(result.user.id, tUserModel.id);
      expect(result.accessToken, 'access_token_123');
      expect(result.refreshToken, 'refresh_token_456');
    });

    test('should convert AuthResponse to JSON', () {
      // act
      final result = tAuthResponse.toJson();

      // assert
      expect(result['access_token'], 'access_token_123');
      expect(result['refresh_token'], 'refresh_token_456');
      expect(result['user'], isA<Map<String, dynamic>>());
    });

    test('should use snake_case for token fields in JSON', () {
      // act
      final result = tAuthResponse.toJson();

      // assert
      expect(result.containsKey('access_token'), isTrue);
      expect(result.containsKey('refresh_token'), isTrue);
    });
  });
}
