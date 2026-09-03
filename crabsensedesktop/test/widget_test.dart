import 'package:flutter_test/flutter_test.dart';

import 'package:crab_farm_monitor_desktop/main.dart';

void main() {
  testWidgets('Login screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const CrabFarmMonitorApp());
    expect(find.text('Welcome to CrabFarm'), findsOneWidget);
  });
}
