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
  });

  final List<FarmOption> farms;
  final String selectedFarmId;
  final String? selectedPondId;
  final bool isLoading;
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
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: kHomeBlue.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: _FilterDropdown<String>(
                  label: 'Khu nuôi',
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
          ),
        ),
      );
}

class _DropdownEntry<T> {
  const _DropdownEntry(this.value, this.label);

  final T value;
  final String label;
}

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
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: kHomeBlueLight.withValues(alpha: 0.85),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedOpacity(
            opacity: isLoading ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: kHomeNavyDeep.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: kHomeBorderBlue.withValues(alpha: 0.4),
                ),
              ),
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: kHomeBlueLight,
                ),
                dropdownColor: kHomeNavy,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
      );
}
