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
  Widget build(BuildContext context) {
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('blob:') ||
        path.startsWith('data:')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }
    return SizedBox(
      width: width,
      height: height,
      child: errorBuilder?.call(
            context,
            Exception('local files not previewed on web'),
            StackTrace.empty,
          ) ??
          const Icon(Icons.image_outlined),
    );
  }
}
