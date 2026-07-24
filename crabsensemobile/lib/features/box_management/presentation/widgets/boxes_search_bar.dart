import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class BoxesSearchBar extends StatefulWidget {
  const BoxesSearchBar({
    required this.initialQuery,
    required this.onChanged,
    required this.onClear,
    this.recentSearches = const [],
    this.onRecentSelected,
    this.autofocus = false,
    super.key,
  });

  final String initialQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final List<String> recentSearches;
  final ValueChanged<String>? onRecentSelected;
  final bool autofocus;

  @override
  State<BoxesSearchBar> createState() => _BoxesSearchBarState();
}

class _BoxesSearchBarState extends State<BoxesSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant BoxesSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != _controller.text &&
        widget.initialQuery != oldWidget.initialQuery) {
      _controller.text = widget.initialQuery;
      _controller.selection = TextSelection.collapsed(
        offset: widget.initialQuery.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          style: const TextStyle(
            color: CrabSenseColors.textPrimary,
            fontSize: 14,
          ),
          cursorColor: CrabSenseColors.primary,
          decoration: InputDecoration(
            hintText: 'Tìm theo tên Box, mã QR hoặc khu vực',
            hintStyle: const TextStyle(
              color: CrabSenseColors.hintText,
              fontSize: 13,
            ),
            filled: true,
            fillColor: CrabSenseColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: CrabSenseColors.hintText,
            ),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa',
                    onPressed: () {
                      _controller.clear();
                      widget.onClear();
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: CrabSenseColors.hintText,
                    ),
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: CrabSenseColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: CrabSenseColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: CrabSenseColors.primary,
                width: 1.4,
              ),
            ),
          ),
        ),
        if (widget.recentSearches.isNotEmpty && _focusNode.hasFocus) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.recentSearches.take(5).map((q) {
              return ActionChip(
                label: Text(q, style: const TextStyle(fontSize: 11)),
                backgroundColor: CrabSenseColors.container,
                side: const BorderSide(color: CrabSenseColors.border),
                onPressed: () => widget.onRecentSelected?.call(q),
                labelStyle: const TextStyle(
                  color: CrabSenseColors.textSecondary,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
