import 'dart:io';

import 'package:flutter/material.dart';

import '../../config/app_env.dart';

/// Loads a crab photo through the authenticated API proxy.
/// S3 objects are private (`PublicRead: false`); raw HTTPS URLs return 403.
class CrabAuthImage extends StatelessWidget {
  const CrabAuthImage({
    super.key,
    required this.crabId,
    required this.index,
    required this.token,
    this.fallbackUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.error,
  });

  final String crabId;
  final int index;
  final String token;
  final String? fallbackUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? error;

  static String proxyUrl(String crabId, int index) =>
      '${AppEnv.cloudApiUrl}/api/crabs/$crabId/photos/$index';

  @override
  Widget build(BuildContext context) {
    final local = _localFile(fallbackUrl);
    if (local != null) {
      return Image.file(
        local,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => error ?? const SizedBox.shrink(),
      );
    }

    return Image.network(
      proxyUrl(crabId, index),
      width: width,
      height: height,
      fit: fit,
      headers: token.isEmpty ? null : {'Authorization': 'Bearer $token'},
      errorBuilder: (_, __, ___) {
        final raw = fallbackUrl?.trim() ?? '';
        if (raw.startsWith('http://') || raw.startsWith('https://')) {
          return Image.network(
            raw,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => error ?? const SizedBox.shrink(),
          );
        }
        return error ?? const SizedBox.shrink();
      },
    );
  }

  static File? _localFile(String? url) {
    final raw = url?.trim() ?? '';
    if (raw.isEmpty) return null;
    if (raw.startsWith('file:')) {
      try {
        return File(Uri.parse(raw).toFilePath());
      } catch (_) {
        return null;
      }
    }
    if (!raw.startsWith('http://') &&
        !raw.startsWith('https://') &&
        File(raw).existsSync()) {
      return File(raw);
    }
    return null;
  }
}
