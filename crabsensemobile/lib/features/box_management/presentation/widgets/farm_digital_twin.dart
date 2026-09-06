import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/models/boxes_models.dart';

/// Farm Digital Twin — sơ đồ hộp theo khu (pan / zoom), full-bleed trong viewport.
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
  Size? _viewport;

  static const double _cell = 76;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fitAll() {
    final vp = _viewport;
    if (vp == null || vp.width <= 0 || vp.height <= 0) {
      _controller.value = Matrix4.identity();
      return;
    }

    final visible = _visibleBoxes();
    var maxX = 4.0;
    var maxY = 4.0;
    for (final b in visible) {
      maxX = math.max(maxX, b.location.gridX);
      maxY = math.max(maxY, b.location.gridY);
    }
    final contentW = math.max((maxX + 2.5) * _cell, vp.width);
    final contentH = math.max((maxY + 2.5) * _cell, vp.height);

    final scale = math.min(
      1.0,
      math.min(vp.width / contentW, vp.height / contentH) * 0.92,
    );
    final dx = (vp.width - contentW * scale) / 2;
    final dy = (vp.height - contentH * scale) / 2;
    _controller.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  List<BoxSummary> _visibleBoxes() {
    if (_areaFilter == null) return widget.boxes;
    return widget.boxes
        .where((b) => b.location.areaName == _areaFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final areas = widget.boxes.map((b) => b.location.areaName).toSet().toList()
      ..sort();
    final visible = _visibleBoxes();

    var maxX = 4.0;
    var maxY = 4.0;
    for (final b in visible) {
      maxX = math.max(maxX, b.location.gridX);
      maxY = math.max(maxY, b.location.gridY);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
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
              IconButton(
                tooltip: 'Vừa khung',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: _fitAll,
                icon: const Icon(
                  Icons.fit_screen_rounded,
                  color: const Color(0xFF27AE60), size: 20,
                ),
              ),
              IconButton(
                tooltip: 'Reset',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () {
                  _controller.value = Matrix4.identity();
                  WidgetsBinding.instance.addPostFrameCallback((_) => _fitAll());
                },
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: const Color(0xFF27AE60), size: 20,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFDDE4EB),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x142ECC71),
                  blurRadius: 14,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final vp = Size(constraints.maxWidth, constraints.maxHeight);
                  if (_viewport != vp) {
                    _viewport = vp;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _fitAll();
                    });
                  }

                  // Canvas ≥ viewport → không còn “đường cắt” dọc bên phải.
                  final contentW =
                      math.max((maxX + 2.5) * _cell, constraints.maxWidth);
                  final contentH =
                      math.max((maxY + 2.5) * _cell, constraints.maxHeight);

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      InteractiveViewer(
                        transformationController: _controller,
                        minScale: 0.45,
                        maxScale: 3.5,
                        constrained: false,
                        boundaryMargin: const EdgeInsets.all(120),
                        child: SizedBox(
                          width: contentW,
                          height: contentH,
                          child: CustomPaint(
                            painter: const _FarmGridPainter(cell: _cell),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                for (final box in visible)
                                  Positioned(
                                    left: box.location.gridX * _cell,
                                    top: box.location.gridY * _cell,
                                    child: _BoxNode(
                                      box: box,
                                      selected:
                                          box.id == widget.selectedBoxId,
                                      onTap: () =>
                                          widget.onBoxSelected(box),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Legend overlay — không chiếm chiều cao Expanded, tránh cắt map.
                      const Positioned(
                        left: 10,
                        right: 118,
                        bottom: 10,
                        child: _MapLegend(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color, width: selected ? 2.4 : 1.2),
            boxShadow: [
              BoxShadow(
                color: (selected ? kHomeBlue : color).withValues(alpha: 0.35),
                blurRadius: selected ? 14 : 8,
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(box.status.icon, size: 14, color: color),
                const SizedBox(height: 2),
                Text(
                  box.code.length > 8 ? box.code.substring(0, 8) : box.code,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${box.healthScore.score}',
                  style: TextStyle(
                    color: const Color(0xFF5A7184), fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (box.alerts.hasAlerts ||
                    box.aiRecommendation.hasRecommendation)
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}

class _FarmGridPainter extends CustomPainter {
  const _FarmGridPainter({required this.cell});

  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDDE4EB)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FarmGridPainter oldDelegate) =>
      oldDelegate.cell != cell;
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
        selectedcolor: const Color(0xFFD5F5E3),
        labelStyle: TextStyle(
          color: selected ? const Color(0xFF27AE60) : const Color(0xFF5A7184),
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        backgroundcolor: const Color(0xFFF5F7FA),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(
          color: selected
              ? kHomeBlue.withValues(alpha: 0.8)
              : const Color(0xFFDDE4EB),
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE4EB)),
      ),
      child: const Wrap(
        spacing: 10,
        runSpacing: 6,
        children: [
          _LegendDot(color: kHomeGreen, label: 'Ổn định'),
          _LegendDot(color: kHomeOrange, label: 'Cảnh báo'),
          _LegendDot(color: Colors.redAccent, label: 'Nghiêm trọng'),
          _LegendDot(color: Colors.white54, label: 'Offline'),
          _LegendDot(color: kHomeBlue, label: 'Đang chọn'),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 5),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF5A7184), fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
