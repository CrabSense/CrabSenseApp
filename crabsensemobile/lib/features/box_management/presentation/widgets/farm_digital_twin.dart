import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/models/boxes_models.dart';

/// Farm Digital Twin — schematic layout of boxes by area (pan / zoom).
class FarmDigitalTwin extends StatefulWidget {
  const FarmDigitalTwin({
    required this.boxes,
    required this.selectedBoxId,
    required this.onBoxSelected,
    super.key,
  });

  final List<BoxSummary> boxes;
  final String? selectedBoxId;
  final ValueChanged<BoxSummary> onBoxSelected;

  @override
  State<FarmDigitalTwin> createState() => _FarmDigitalTwinState();
}

class _FarmDigitalTwinState extends State<FarmDigitalTwin> {
  final TransformationController _controller = TransformationController();
  String? _areaFilter;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fitAll() {
    _controller.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final areas = widget.boxes.map((b) => b.location.areaName).toSet().toList()
      ..sort();
    final visible = _areaFilter == null
        ? widget.boxes
        : widget.boxes
              .where((b) => b.location.areaName == _areaFilter)
              .toList();

    double maxX = 8, maxY = 6;
    for (final b in visible) {
      if (b.location.gridX > maxX) maxX = b.location.gridX;
      if (b.location.gridY > maxY) maxY = b.location.gridY;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _AreaChip(
                      label: 'Tất cả khu',
                      selected: _areaFilter == null,
                      onTap: () => setState(() => _areaFilter = null),
                    ),
                    ...areas.map(
                      (a) => _AreaChip(
                        label: a,
                        selected: _areaFilter == a,
                        onTap: () => setState(() => _areaFilter = a),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Fit all',
              onPressed: _fitAll,
              icon: const Icon(
                Icons.fit_screen_rounded,
                color: kHomeBlueLight,
              ),
            ),
            IconButton(
              tooltip: 'Reset view',
              onPressed: _fitAll,
              icon: const Icon(
                Icons.refresh_rounded,
                color: kHomeBlueLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: kHomeBlue.withValues(alpha: 0.14),
                  blurRadius: 14,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: 0.6,
                maxScale: 3.5,
                boundaryMargin: const EdgeInsets.all(80),
                child: SizedBox(
                  width: (maxX + 2) * 72,
                  height: (maxY + 2) * 72,
                  child: CustomPaint(
                    painter: _FarmGridPainter(areas: areas),
                    child: Stack(
                      children: visible.map((box) {
                        final selected = box.id == widget.selectedBoxId;
                        return Positioned(
                          left: box.location.gridX * 72,
                          top: box.location.gridY * 72,
                          child: _BoxNode(
                            box: box,
                            selected: selected,
                            onTap: () => widget.onBoxSelected(box),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const _MapLegend(),
      ],
    );
  }
}

class _BoxNode extends StatelessWidget {
  const _BoxNode({
    required this.box,
    required this.selected,
    required this.onTap,
  });

  final BoxSummary box;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? kHomeBlue : box.status.color;
    return Semantics(
      label: box.semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color, width: selected ? 2.4 : 1.2),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: kHomeBlue.withValues(alpha: 0.45),
                      blurRadius: 14,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(box.status.icon, size: 14, color: color),
              const SizedBox(height: 2),
              Text(
                box.code.length > 7 ? box.code.substring(0, 7) : box.code,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${box.healthScore.score}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (box.alerts.hasAlerts ||
                  box.aiRecommendation.hasRecommendation)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (box.alerts.hasAlerts)
                      const Icon(
                        Icons.priority_high_rounded,
                        size: 10,
                        color: kHomeOrange,
                      ),
                    if (box.aiRecommendation.hasRecommendation)
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 10,
                        color: kHomePurple,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmGridPainter extends CustomPainter {
  _FarmGridPainter({required this.areas});

  final List<String> areas;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kHomeBorderBlue.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 72) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 72) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FarmGridPainter oldDelegate) => false;
}

class _AreaChip extends StatelessWidget {
  const _AreaChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: kHomeBlue.withValues(alpha: 0.25),
        labelStyle: TextStyle(
          color: selected
              ? kHomeBlueLight
              : Colors.white.withValues(alpha: 0.55),
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        backgroundColor: kHomeNavyDeep.withValues(alpha: 0.75),
        side: BorderSide(
          color: selected
              ? kHomeBlue.withValues(alpha: 0.8)
              : kHomeBorderBlue.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _legend(kHomeGreen, 'Ổn định'),
        _legend(kHomeOrange, 'Cảnh báo'),
        _legend(Colors.redAccent, 'Nghiêm trọng'),
        _legend(Colors.white54, 'Offline'),
        _legend(kHomeBlue, 'Đang chọn'),
      ],
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
