import 'package:crabsensemobile/core/platform/io_export.dart';
import 'package:flutter/material.dart';

class LocalFileImage extends StatelessWidget {
  const LocalFileImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) => Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
}
