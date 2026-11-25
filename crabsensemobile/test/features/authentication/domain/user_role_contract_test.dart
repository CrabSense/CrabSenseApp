import 'package:flutter_test/flutter_test.dart';
import 'package:crabsensemobile/features/authentication/domain/entities/user.dart';

void main() {
  test('canonical BE roles round trip and only Staff can use mobile', () {
    for (final role in UserRole.values.where((r) => r != UserRole.unknown)) {
      expect(UserRole.parse(role.apiValue), role);
      expect(role.canUseMobile, role == UserRole.farmStaff);
    }
  });
  test('missing and legacy roles fail closed', () {
    for (final raw in [null, '', 'admin', 'operator', 'fieldOperator', 'sales', 'viewer', 'FarmOwner', 'Farmstaff', 3]) {
      final role = UserRole.parse(raw);
      expect(role, UserRole.unknown);
      expect(role.canUseMobile, false);
      expect(role.hasWriteAccess, false);
    }
  });
}
