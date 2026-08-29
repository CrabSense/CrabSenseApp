import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';

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
    _focusNode = FocusNode()..addListener(() => setState(() {}));
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
          onChanged: (v) {
            widget.onChanged(v);
            setState(() {});
          },
          style: const TextStyle(color: kHomeTextMain, fontSize: 14),
          cursorColor: kHomeBlueLight,
          decoration: InputDecoration(
            hintText: 'Tìm theo tên Box, mã QR hoặc khu vực',
            hintStyle: TextStyle(
              color: const Color(0xFF5A7184),
              fontSize: 13,
            ),
            filled: true,
            fillColor: kHomeBg.withValues(alpha: 0.75),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: kHomeBlueLight,
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
                      color: kHomeBlueLight,
                    ),
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: kHomeBorderBlue.withValues(alpha: 0.4),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: kHomeBorderBlue.withValues(alpha: 0.4),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: kHomeBlue.withValues(alpha: 0.9),
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
                backgroundColor: kHomeBg.withValues(alpha: 0.75),
                side: BorderSide(
                  color: kHomeBorderBlue.withValues(alpha: 0.4),
                ),
                onPressed: () => widget.onRecentSelected?.call(q),
                labelStyle: TextStyle(
                  color: const Color(0xFF5A7184),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
