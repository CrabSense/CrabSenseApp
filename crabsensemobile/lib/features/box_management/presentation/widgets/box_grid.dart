import 'package:flutter/material.dart';

import '../../domain/models/boxes_models.dart';
import 'box_card.dart';
import 'box_list_tile.dart';
import 'boxes_skeleton.dart';

class BoxGrid extends StatelessWidget {
  const BoxGrid({
    required this.boxes,
    required this.columns,
    required this.onBoxTap,
    required this.onBoxLongPress,
    required this.onMenuSelected,
    required this.onExplainHealth,
    this.isLoadingMore = false,
    this.onLoadMore,
    super.key,
  });

  final List<BoxSummary> boxes;
  final int columns;
  final ValueChanged<BoxSummary> onBoxTap;
  final ValueChanged<BoxSummary> onBoxLongPress;
  final void Function(BoxSummary box, String action) onMenuSelected;
  final ValueChanged<BoxSummary> onExplainHealth;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
          onLoadMore?.call();
        }
        return false;
      },
      child: GridView.builder(
        padding: EdgeInsets.zero,
        itemCount: boxes.length + (isLoadingMore ? columns : 0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: columns >= 3 ? 0.78 : 0.72,
        ),
        itemBuilder: (context, index) {
          if (index >= boxes.length) {
            return const GridBoxCardSkeleton();
          }
          final box = boxes[index];
          return RepaintBoundary(
            child: BoxCard(
              key: ValueKey(box.id),
              box: box,
              onTap: () => onBoxTap(box),
              onLongPress: () => onBoxLongPress(box),
              onMenuSelected: (action) => onMenuSelected(box, action),
              onExplainHealth: () => onExplainHealth(box),
            ),
          );
        },
      ),
    );
  }
}

class BoxList extends StatelessWidget {
  const BoxList({
    required this.boxes,
    required this.onBoxTap,
    required this.onSwipeAction,
    this.isLoadingMore = false,
    this.onLoadMore,
    super.key,
  });

  final List<BoxSummary> boxes;
  final ValueChanged<BoxSummary> onBoxTap;
  final void Function(BoxSummary box, String action) onSwipeAction;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
          onLoadMore?.call();
        }
        return false;
      },
      child: ListView.separated(
        itemCount: boxes.length + (isLoadingMore ? 2 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= boxes.length) {
            return const ListBoxRowSkeleton();
          }
          final box = boxes[index];
          return RepaintBoundary(
            child: BoxListTileCard(
              key: ValueKey('list-${box.id}'),
              box: box,
              onTap: () => onBoxTap(box),
              onSwipeAction: (action) => onSwipeAction(box, action),
            ),
          );
        },
      ),
    );
  }
}
