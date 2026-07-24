import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crabsensemobile/features/water_quality/presentation/models/farm_filter_model.dart';
import 'package:crabsensemobile/features/water_quality/presentation/widgets/farm_pond_filter_widget.dart';

// ── Test fixtures ──────────────────────────────────────────────────────────

const _pond1 = PondOption(id: 'pond_a', name: 'Pond A');
const _pond2 = PondOption(id: 'pond_b', name: 'Pond B');

const _farm1 = FarmOption(id: 'farm_1', name: 'Farm One', ponds: [_pond1, _pond2]);
const _farm2 = FarmOption(id: 'farm_2', name: 'Farm Two');

const _farms = [_farm1, _farm2];

// ── Helpers ────────────────────────────────────────────────────────────────

/// Wraps [FarmPondFilterWidget] in the minimal scaffold required by
/// Flutter widget tests (Material + Directionality).
Widget _buildWidget({
  required String selectedFarmId,
  required void Function(String, String?) onSelectionChanged,
  String? selectedPondId,
  bool isLoading = false,
}) => MaterialApp(
  home: Scaffold(
    body: FarmPondFilterWidget(
      farms: _farms,
      selectedFarmId: selectedFarmId,
      selectedPondId: selectedPondId,
      isLoading: isLoading,
      onSelectionChanged: onSelectionChanged,
    ),
  ),
);

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('FarmPondFilterWidget', () {
    // ── Farm dropdown renders farm options ─────────────────────────────────

    testWidgets('renders farm dropdown with provided farm names', (tester) async {
      await tester.pumpWidget(
        _buildWidget(selectedFarmId: 'farm_1', onSelectionChanged: (_, _) {}),
      );

      // The selected farm label is visible at rest (no need to open dropdown).
      expect(find.text('Farm One'), findsOneWidget);
    });

    // ── Pond dropdown renders "All Ponds" as first option ──────────────────

    testWidgets('renders "All Ponds" as the first pond option when no pond is selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildWidget(selectedFarmId: 'farm_1', onSelectionChanged: (_, _) {}),
      );

      // Open the pond dropdown by tapping it.
      // There are two DropdownButton widgets; the second is the pond one.
      final dropdownButtons = find.byType(DropdownButton<String?>);
      await tester.tap(dropdownButtons.first);
      await tester.pumpAndSettle();

      // "All Ponds" must appear in the opened dropdown menu.
      expect(find.text('All Ponds'), findsWidgets);
    });

    // ── Farm change: calls callback with new farmId and null pondId ────────

    testWidgets('tapping a farm option calls onSelectionChanged with new farmId and '
        'null pondId', (tester) async {
      String? capturedFarm;
      String? capturedPond;

      await tester.pumpWidget(
        _buildWidget(
          selectedFarmId: 'farm_1',
          selectedPondId: 'pond_a',
          onSelectionChanged: (farmId, pondId) {
            capturedFarm = farmId;
            capturedPond = pondId;
          },
        ),
      );

      // Open the farm dropdown (first DropdownButton<String>).
      final farmDropdown = find.byType(DropdownButton<String>);
      await tester.tap(farmDropdown.first);
      await tester.pumpAndSettle();

      // Tap "Farm Two".
      await tester.tap(find.text('Farm Two').last);
      await tester.pumpAndSettle();

      expect(capturedFarm, 'farm_2');
      expect(capturedPond, isNull);
    });

    // ── Pond change: calls callback with current farmId and new pondId ─────

    testWidgets('tapping a pond option calls onSelectionChanged with current farmId '
        'and the selected pondId', (tester) async {
      String? capturedFarm;
      String? capturedPond;

      await tester.pumpWidget(
        _buildWidget(
          selectedFarmId: 'farm_1',
          onSelectionChanged: (farmId, pondId) {
            capturedFarm = farmId;
            capturedPond = pondId;
          },
        ),
      );

      // Open the pond dropdown.
      final pondDropdown = find.byType(DropdownButton<String?>);
      await tester.tap(pondDropdown.first);
      await tester.pumpAndSettle();

      // Tap "Pond A".
      await tester.tap(find.text('Pond A').last);
      await tester.pumpAndSettle();

      expect(capturedFarm, 'farm_1');
      expect(capturedPond, 'pond_a');
    });

    // ── isLoading: dropdowns are disabled ─────────────────────────────────

    testWidgets('dropdowns are disabled when isLoading is true', (tester) async {
      var callbackInvoked = false;

      await tester.pumpWidget(
        _buildWidget(
          selectedFarmId: 'farm_1',
          isLoading: true,
          onSelectionChanged: (_, _) {
            callbackInvoked = true;
          },
        ),
      );

      // Attempt to open the farm dropdown — it should be disabled.
      final farmDropdown = find.byType(DropdownButton<String>);
      await tester.tap(farmDropdown.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Attempt to open the pond dropdown — it should also be disabled.
      final pondDropdown = find.byType(DropdownButton<String?>);
      await tester.tap(pondDropdown.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Neither dropdown should have triggered the callback.
      expect(callbackInvoked, isFalse);
    });
  });
}
