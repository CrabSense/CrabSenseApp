import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';

class AlertSearchBar extends StatefulWidget {
  const AlertSearchBar({
    required this.initialValue,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<AlertSearchBar> createState() => _AlertSearchBarState();
}

class _AlertSearchBarState extends State<AlertSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant AlertSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text &&
        widget.initialValue != oldWidget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Tìm cảnh báo, Box hoặc thiết bị',
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Colors.white54,
        ),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _controller.clear();
                  widget.onClear();
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white54,
                ),
              ),
        filled: true,
        fillColor: kHomeNavyLift,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kHomeBorderBlue),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kHomeBorderBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kHomeCyan),
        ),
      ),
    );
  }
}
