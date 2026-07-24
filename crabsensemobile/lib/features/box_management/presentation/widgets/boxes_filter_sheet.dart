import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/boxes_models.dart';

Future<BoxFilterState?> showBoxesFilterSheet(
  BuildContext context, {
  required BoxFilterState initial,
  required List<String> areas,
  required int Function(BoxFilterState) previewCount,
}) {
  return showModalBottomSheet<BoxFilterState>(
    context: context,
    isScrollControlled: true,
    backgroundColor: CrabSenseColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _FilterSheetBody(
      initial: initial,
      areas: areas,
      previewCount: previewCount,
    ),
  );
}

class _FilterSheetBody extends StatefulWidget {
  const _FilterSheetBody({
    required this.initial,
    required this.areas,
    required this.previewCount,
  });

  final BoxFilterState initial;
  final List<String> areas;
  final int Function(BoxFilterState) previewCount;

  @override
  State<_FilterSheetBody> createState() => _FilterSheetBodyState();
}

class _FilterSheetBodyState extends State<_FilterSheetBody> {
  late BoxFilterState _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
  }

  void _toggleStatus(BoxHealthStatus status) {
    final next = Set<BoxHealthStatus>.from(_filter.statuses);
    if (next.contains(status)) {
      next.remove(status);
    } else {
      next.add(status);
    }
    setState(() => _filter = _filter.copyWith(statuses: next));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final count = widget.previewCount(_filter);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CrabSenseColors.hintText.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bộ lọc nâng cao',
                style: TextStyle(
                  color: CrabSenseColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dự kiến $count kết quả',
                style: const TextStyle(
                  color: CrabSenseColors.hintText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    const _SectionTitle('Khu vực'),
                    Wrap(
                      spacing: 8,
                      children: widget.areas.map((a) {
                        final selected = _filter.areaId == a;
                        return ChoiceChip(
                          label: Text(a),
                          selected: selected,
                          onSelected: (_) => setState(() {
                            _filter = _filter.copyWith(
                              areaId: selected ? '' : a,
                            );
                          }),
                          selectedColor: CrabSenseColors.primary.withValues(
                            alpha: 0.25,
                          ),
                          labelStyle: TextStyle(
                            color: selected
                                ? CrabSenseColors.primary
                                : CrabSenseColors.textSecondary,
                          ),
                          backgroundColor: CrabSenseColors.surface,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const _SectionTitle('Trạng thái'),
                    Wrap(
                      spacing: 8,
                      children: BoxHealthStatus.values.map((s) {
                        final selected = _filter.statuses.contains(s);
                        return FilterChip(
                          label: Text(s.label),
                          selected: selected,
                          onSelected: (_) => _toggleStatus(s),
                          selectedColor: s.color.withValues(alpha: 0.2),
                          checkmarkColor: s.color,
                          labelStyle: TextStyle(
                            color: selected
                                ? s.color
                                : CrabSenseColors.textSecondary,
                          ),
                          backgroundColor: CrabSenseColors.surface,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const _SectionTitle('Health Score'),
                    RangeSlider(
                      values: _filter.healthScoreRange,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      labels: RangeLabels(
                        _filter.healthScoreRange.start.round().toString(),
                        _filter.healthScoreRange.end.round().toString(),
                      ),
                      activeColor: CrabSenseColors.primary,
                      onChanged: (v) => setState(
                        () => _filter = _filter.copyWith(healthScoreRange: v),
                      ),
                    ),
                    const _SectionTitle('AI Confidence'),
                    RangeSlider(
                      values: _filter.aiConfidenceRange,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      labels: RangeLabels(
                        _filter.aiConfidenceRange.start.round().toString(),
                        _filter.aiConfidenceRange.end.round().toString(),
                      ),
                      activeColor: CrabSenseColors.accent,
                      onChanged: (v) => setState(
                        () => _filter = _filter.copyWith(aiConfidenceRange: v),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Có cảnh báo',
                        style: TextStyle(
                          color: CrabSenseColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      value: _filter.hasAlerts == true,
                      activeThumbColor: CrabSenseColors.primary,
                      onChanged: (v) => setState(
                        () => _filter = v
                            ? _filter.copyWith(hasAlerts: true)
                            : _filter.copyWith(clearHasAlerts: true),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Thiết bị Offline',
                        style: TextStyle(
                          color: CrabSenseColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      value: _filter.deviceOffline == true,
                      activeThumbColor: CrabSenseColors.primary,
                      onChanged: (v) => setState(
                        () => _filter = v
                            ? _filter.copyWith(deviceOffline: true)
                            : _filter.copyWith(clearDeviceOffline: true),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Có đề xuất AI',
                        style: TextStyle(
                          color: CrabSenseColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      value: _filter.hasAiRecommendation == true,
                      activeThumbColor: CrabSenseColors.primary,
                      onChanged: (v) => setState(
                        () => _filter = v
                            ? _filter.copyWith(hasAiRecommendation: true)
                            : _filter.copyWith(clearHasAi: true),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Đến lịch kiểm tra nước',
                        style: TextStyle(
                          color: CrabSenseColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      value: _filter.waterTestDue == true,
                      activeThumbColor: CrabSenseColors.primary,
                      onChanged: (v) => setState(
                        () => _filter = v
                            ? _filter.copyWith(waterTestDue: true)
                            : _filter.copyWith(clearWaterDue: true),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Đến lịch quay video',
                        style: TextStyle(
                          color: CrabSenseColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      value: _filter.videoDue == true,
                      activeThumbColor: CrabSenseColors.primary,
                      onChanged: (v) => setState(
                        () => _filter = v
                            ? _filter.copyWith(videoDue: true)
                            : _filter.copyWith(clearVideoDue: true),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Sắp thu hoạch',
                        style: TextStyle(
                          color: CrabSenseColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      value: _filter.nearHarvest == true,
                      activeThumbColor: CrabSenseColors.primary,
                      onChanged: (v) => setState(
                        () => _filter = v
                            ? _filter.copyWith(nearHarvest: true)
                            : _filter.copyWith(clearNearHarvest: true),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _SectionTitle('Sắp xếp'),
                    DropdownButtonFormField<BoxSortOption>(
                      initialValue: _filter.sortOption,
                      dropdownColor: CrabSenseColors.card,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: CrabSenseColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: CrabSenseColors.border,
                          ),
                        ),
                      ),
                      items: BoxSortOption.values
                          .map(
                            (o) => DropdownMenuItem(
                              value: o,
                              child: Text(
                                o.label,
                                style: const TextStyle(
                                  color: CrabSenseColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(
                            () => _filter = _filter.copyWith(sortOption: v),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _filter = BoxFilterState.initial),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CrabSenseColors.textSecondary,
                        side: const BorderSide(color: CrabSenseColors.border),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Đặt lại'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, _filter),
                      style: FilledButton.styleFrom(
                        backgroundColor: CrabSenseColors.primary,
                        foregroundColor: CrabSenseColors.background,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text('Áp dụng ($count)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: CrabSenseColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
