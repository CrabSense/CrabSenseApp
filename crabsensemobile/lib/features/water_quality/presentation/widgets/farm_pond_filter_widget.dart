import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../models/farm_filter_model.dart';

/// A widget that renders two styled dropdowns for farm and pond selection.
///
/// Displays a Farm selector and a Pond selector side-by-side. When the
/// farm changes, the pond resets to null ("All Ponds"). When the pond
/// changes, the current farmId is preserved and only pondId is updated.
///
/// The dropdowns are disabled while [isLoading] is true to prevent
/// selection changes during a data refresh.
///
/// Callback [onSelectionChanged] fires whenever either selector changes,
/// with the new (farmId, pondId) pair.
///
/// Requirements: 8.9
class FarmPondFilterWidget extends StatefulWidget {
  const FarmPondFilterWidget({
    required this.farms,
    required this.selectedFarmId,
    required this.onSelectionChanged,
    super.key,
    this.selectedPondId,
    this.isLoading = false,
  });

  /// Available farms to display in the farm dropdown.
  final List<FarmOption> farms;

  /// Currently selected farm id.
  final String selectedFarmId;

  /// Currently selected pond id, or null for "All Ponds".
  final String? selectedPondId;

  /// Whether dropdowns should be disabled (e.g. during a refresh).
  final bool isLoading;

  /// Callback fired when the selection changes.
  ///
  /// [farmId] is always non-null; [pondId] is null when "All Ponds"
  /// is selected.
  final void Function(String farmId, String? pondId) onSelectionChanged;

  @override
  State<FarmPondFilterWidget> createState() => _FarmPondFilterWidgetState();
}

class _FarmPondFilterWidgetState extends State<FarmPondFilterWidget> {
  /// Returns the ponds for the currently selected farm, or empty list.
  List<PondOption> get _currentPonds {
    final match = widget.farms.where((f) => f.id == widget.selectedFarmId);
    return match.isNotEmpty ? match.first.ponds : const [];
  }

  void _onFarmChanged(String? farmId) {
    if (farmId == null || farmId == widget.selectedFarmId) return;
    // Reset pond to null when farm changes.
    widget.onSelectionChanged(farmId, null);
  }

  void _onPondChanged(String? pondId) {
    // pondId is null when "All Ponds" is selected.
    widget.onSelectionChanged(widget.selectedFarmId, pondId);
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: CrabSenseColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: CrabSenseColors.primary.withValues(alpha: 0.15)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _FilterDropdown<String>(
              label: 'Farm',
              value: widget.selectedFarmId,
              items: widget.farms.map((f) => _DropdownEntry(f.id, f.name)).toList(),
              isLoading: widget.isLoading,
              onChanged: _onFarmChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FilterDropdown<String?>(
              label: 'Pond',
              value: widget.selectedPondId,
              items: [
                const _DropdownEntry(null, 'All Ponds'),
                ..._currentPonds.map((p) => _DropdownEntry(p.id, p.name)),
              ],
              isLoading: widget.isLoading,
              onChanged: _onPondChanged,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Internal helpers ──────────────────────────────────────────────────────────

/// A lightweight typed pair used to build dropdown items.
class _DropdownEntry<T> {
  const _DropdownEntry(this.value, this.label);

  final T value;
  final String label;
}

/// Styled dropdown selector used for both farm and pond.
///
/// Generics allow [T] to be either [String] (farm) or [String?] (pond).
class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.isLoading,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<_DropdownEntry<T>> items;
  final bool isLoading;
  final void Function(T?) onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: CrabSenseColors.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
      const SizedBox(height: 4),
      _DropdownContainer(
        isLoading: isLoading,
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: CrabSenseColors.textSecondary,
          ),
          dropdownColor: CrabSenseColors.surfaceVariant,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CrabSenseColors.textPrimary,
          ),
          onChanged: isLoading ? null : onChanged,
          items: items
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e.value,
                  child: Text(e.label, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
        ),
      ),
    ],
  );
}

/// Decorative container applied around each dropdown.
class _DropdownContainer extends StatelessWidget {
  const _DropdownContainer({required this.isLoading, required this.child});

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: isLoading ? 0.5 : 1.0,
    duration: const Duration(milliseconds: 200),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CrabSenseColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CrabSenseColors.outline),
      ),
      child: child,
    ),
  );
}
