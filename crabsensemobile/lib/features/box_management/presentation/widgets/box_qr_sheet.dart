import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../home/presentation/widgets/home_palette.dart';

Future<void> showBoxQrSheet(
  BuildContext context, {
  required String boxId,
  required String boxCode,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _BoxQrSheet(boxId: boxId, boxCode: boxCode),
  );
}

class _BoxQrSheet extends StatefulWidget {
  const _BoxQrSheet({required this.boxId, required this.boxCode});

  final String boxId;
  final String boxCode;

  @override
  State<_BoxQrSheet> createState() => _BoxQrSheetState();
}

class _BoxQrSheetState extends State<_BoxQrSheet> {
  bool _loading = true;
  String? _error;
  Uint8List? _pngBytes;
  String? _qrCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = sl<ApiClient>();
      try {
        await api.dio.post(ApiConstants.boxQr(widget.boxId));
      } catch (_) {}

      try {
        final meta = await api.dio.get(ApiConstants.boxQr(widget.boxId));
        final body = meta.data;
        if (body is Map) {
          final data = body['data'] is Map ? body['data'] as Map : body;
          _qrCode = (data['code'] ?? data['qrCode'] ?? data['rawValue'])
              ?.toString();
        }
      } catch (_) {}

      final img = await api.dio.get<List<int>>(
        ApiConstants.boxQrImage(widget.boxId),
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = img.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Không tải được ảnh QR');
      }
      _pngBytes = Uint8List.fromList(bytes);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: kHomeSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kHomeBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: kHomeBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'QR hộp ${widget.boxCode}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: kHomePrimaryDark,
            ),
          ),
          if (_qrCode != null && _qrCode!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _qrCode!,
              style: const TextStyle(fontSize: 12, color: kHomeTextSub),
            ),
          ],
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: kHomePrimary),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: kHomeDanger),
                  ),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _load, child: const Text('Thử lại')),
                ],
              ),
            )
          else if (_pngBytes != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kHomeBorder),
              ),
              child: Image.memory(
                _pngBytes!,
                width: 220,
                height: 220,
                fit: BoxFit.contain,
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Chụp màn hình để in tem dán hộp.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: kHomeTextHint),
          ),
        ],
      ),
    );
  }
}
