import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../models/farm_filter_model.dart';

/// Dropdown chọn khu / dãy cho màn chất lượng nước.
class FarmPondFilterWidget extends StatefulWidget {
  const FarmPondFilterWidget({
    required this.farms,
    required this.selectedFarmId,
    required this.onSelectionChanged,
    super.key,
    this.selectedPondId,
    this.isLoading = false,
    this.embedded = false,
  });

  final List<FarmOption> farms;
  final String selectedFarmId;
  final String? selectedPondId;
  final bool isLoading;
  final bool embedded;
  final void Function(String farmId, String? pondId) onSelectionChanged;

  @override
  State<FarmPondFilterWidget> createState() => _FarmPondFilterWidgetState();
}

class _FarmPondFilterWidgetState extends State<FarmPondFilterWidget> {
  List<PondOption> get _currentPonds {
    final match = widget.farms.where((f) => f.id == widget.selectedFarmId);
    return match.isNotEmpty ? match.first.ponds : const [];
  }

  void _onFarmChanged(String? farmId) {
    if (farmId == null || farmId == widget.selectedFarmId) return;
    widget.onSelectionChanged(farmId, null);
  }

  void _onPondChanged(String? pondId) {
    widget.onSelectionChanged(widget.selectedFarmId, pondId);
  }

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Expanded(
          child: _FilterDropdown<String>(
            label: 'Khu nuôi',
            icon: Icons.location_on_rounded,
            value: widget.selectedFarmId,
            items: widget.farms
                .map((f) => _DropdownEntry(f.id, f.name))
                .toList(),
            isLoading: widget.isLoading,
            onChanged: _onFarmChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FilterDropdown<String?>(
            label: 'Dãy / ao',
            icon: Icons.layers_rounded,
            value: widget.selectedPondId,
            items: [
              const _DropdownEntry(null, 'Tất cả'),
              ..._currentPonds.map((p) => _DropdownEntry(p.id, p.name)),
            ],
            isLoading: widget.isLoading,
            onChanged: _onPondChanged,
          ),
        ),
      ],
    );
    if (widget.embedded) return row;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: homeCardDecoration(radius: 22),
      child: row,
    );
  }
}

class _DropdownEntry<T> {
  const _DropdownEntry(this.value, this.label);

  final T value;
  final String label;
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.isLoading,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
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
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8AA396),
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedOpacity(
            opacity: isLoading ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6EE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: const Color(0xFF2F8A4E)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<T>(
                        value: value,
                        isExpanded: true,
                        isDense: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: Color(0xFF2F8A4E),
                        ),
                        dropdownColor: kHomeSurface,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF163A2C),
                        ),
                        onChanged: isLoading ? null : onChanged,
                        items: items
                            .map(
                              (e) => DropdownMenuItem<T>(
                                value: e.value,
                                child: Text(
                                  e.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}
