import 'package:flutter_test/flutter_test.dart';
import '../lib/models/auth_models.dart';

void main() {
  test('only canonical FarmManager can use desktop', () {
    for (final role in [
      UserRoles.systemAdministrator,
      UserRoles.farmAdministrator,
      UserRoles.farmManager,
      UserRoles.farmStaff,
      'manager', 'operator', 'FarmOwner', 'Staff', '', 'farmmanager',
    ]) {
      expect(UserRoles.canUseDesktop(role), role == UserRoles.farmManager);
    }
  });
  test('missing role cannot authenticate', () {
    final user = AuthUser.fromJson({'id': 'test'});
    expect(UserRoles.canUseDesktop(user.role), false);
  });
}
