import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/app_env.dart';

/// Loads a crab photo through the authenticated API proxy.
/// S3 objects are private (`PublicRead: false`); raw HTTPS URLs return 403.
///
/// Flutter Windows `Image.network` often drops `Authorization` headers, so this
/// widget fetches bytes with `http` and paints `Image.memory`.
class CrabAuthImage extends StatefulWidget {
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
  State<CrabAuthImage> createState() => _CrabAuthImageState();
}

class _CrabAuthImageState extends State<CrabAuthImage> {
  static final _cache = <String, Uint8List>{};

  Uint8List? _bytes;
  var _loading = true;
  var _failed = false;
  int _gen = 0;

  String get _cacheKey =>
      '${widget.crabId}|${widget.index}|${widget.fallbackUrl ?? ''}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CrabAuthImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.crabId != widget.crabId ||
        oldWidget.index != widget.index ||
        oldWidget.token != widget.token ||
        oldWidget.fallbackUrl != widget.fallbackUrl) {
      _load();
    }
  }

  Future<void> _load() async {
    final gen = ++_gen;
    final local = _localFile(widget.fallbackUrl);
    if (local != null) {
      if (!mounted || gen != _gen) return;
      setState(() {
        _bytes = null;
        _loading = false;
        _failed = false;
      });
      return;
    }

    final cached = _cache[_cacheKey];
    if (cached != null) {
      setState(() {
        _bytes = cached;
        _loading = false;
        _failed = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _failed = false;
      _bytes = null;
    });

    Uint8List? bytes;
    if (widget.crabId.trim().isNotEmpty) {
      bytes = await _getBytes(CrabAuthImage.proxyUrl(widget.crabId, widget.index));
    }
    if (bytes == null) {
      final raw = widget.fallbackUrl?.trim() ?? '';
      if (raw.startsWith('http://') || raw.startsWith('https://')) {
        bytes = await _getBytes(raw);
      }
    }

    if (!mounted || gen != _gen) return;
    if (bytes != null) {
      if (_cache.length > 80) _cache.clear();
      _cache[_cacheKey] = bytes;
    }
    setState(() {
      _bytes = bytes;
      _loading = false;
      _failed = bytes == null;
    });
  }

  Future<Uint8List?> _getBytes(String url) async {
    try {
      final token = widget.token.trim();
      final headers = <String, String>{
        'Accept': 'image/*,application/octet-stream',
        if (token.isNotEmpty)
          'Authorization': token.toLowerCase().startsWith('bearer ')
              ? token
              : 'Bearer $token',
      };
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      if (res.bodyBytes.isEmpty) return null;
      final ct = (res.headers['content-type'] ?? '').toLowerCase();
      if (ct.contains('application/json') || ct.contains('text/html')) {
        return null;
      }
      return res.bodyBytes;
    } catch (_) {
      return null;
    }
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

  @override
  Widget build(BuildContext context) {
    final local = _localFile(widget.fallbackUrl);
    if (local != null) {
      return Image.file(
        local,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => widget.error ?? const SizedBox.shrink(),
      );
    }

    if (_loading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_failed || _bytes == null) {
      return widget.error ?? const SizedBox.shrink();
    }

    return Image.memory(
      _bytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => widget.error ?? const SizedBox.shrink(),
    );
  }
}
