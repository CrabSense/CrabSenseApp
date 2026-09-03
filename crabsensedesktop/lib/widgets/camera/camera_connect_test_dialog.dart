import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/camera_device.dart';
import '../../theme/dashboard_theme.dart';
import '../../utils/camera_connect_test.dart';

Future<void> showCameraConnectTestDialog(
  BuildContext context, {
  String? streamUrl,
  String? ipAddress,
  String? title,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _CameraConnectTestDialog(
      streamUrl: streamUrl,
      ipAddress: ipAddress,
      title: title,
    ),
  );
}

void showCameraConnectTestForDevice(BuildContext context, CameraDevice cam) {
  showCameraConnectTestDialog(
    context,
    streamUrl: cam.streamUrl,
    ipAddress: cam.ipAddress,
    title: '${cam.cameraCode} — ${cam.name}',
  );
}

class CameraConnectTestIconButton extends StatelessWidget {
  const CameraConnectTestIconButton({
    super.key,
    required this.streamUrl,
    required this.ipAddress,
    this.tooltip = 'Test kết nối',
    this.cameraLabel,
  });

  final String? streamUrl;
  final String? ipAddress;
  final String? tooltip;
  final String? cameraLabel;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => showCameraConnectTestDialog(
        context,
        streamUrl: streamUrl,
        ipAddress: ipAddress,
        title: cameraLabel,
      ),
      tooltip: tooltip,
      icon: const Icon(Icons.lan_outlined),
    );
  }
}

class _CameraConnectTestDialog extends StatefulWidget {
  const _CameraConnectTestDialog({
    this.streamUrl,
    this.ipAddress,
    this.title,
  });

  final String? streamUrl;
  final String? ipAddress;
  final String? title;

  @override
  State<_CameraConnectTestDialog> createState() => _CameraConnectTestDialogState();
}

class _CameraConnectTestDialogState extends State<_CameraConnectTestDialog> {
  CameraConnectTestResult? _result;
  var _running = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _running = true;
      _result = null;
    });
    final result = await runCameraConnectTest(
      streamUrl: widget.streamUrl,
      ipAddress: widget.ipAddress,
    );
    if (mounted) {
      setState(() {
        _result = result;
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final overallOk = result?.success == true;

    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Row(
        children: [
          Icon(
            _running
                ? Icons.hourglass_top
                : overallOk
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
            color: _running
                ? DashboardColors.cyan
                : overallOk
                    ? DashboardColors.seaGreen
                    : DashboardColors.risk,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.title ?? 'Test kết nối camera',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: _running
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: DashboardColors.cyan,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Đang thử /capture rồi /stream…',
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (result?.error != null) ...[
                      Text(
                        result!.error!,
                        style: GoogleFonts.notoSans(color: DashboardColors.risk),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (result != null && result.tests.isEmpty && result.error == null)
                      Text(
                        'Không có URL để kiểm tra',
                        style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
                      ),
                    for (final t in result?.tests ?? const <CameraEndpointTest>[])
                      _TestRow(test: t),
                    const SizedBox(height: 8),
                    Text(
                      'ESP32 thường chỉ 1 kết nối — đóng tab browser đang mở /stream trước khi test.',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _running ? null : () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        FilledButton.icon(
          onPressed: _running ? null : _run,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Thử lại'),
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.cyan),
        ),
      ],
    );
  }
}

class _TestRow extends StatelessWidget {
  const _TestRow({required this.test});

  final CameraEndpointTest test;

  @override
  Widget build(BuildContext context) {
    final color = test.ok ? DashboardColors.seaGreen : DashboardColors.risk;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DashboardColors.darkNavy,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: test.ok
                ? DashboardColors.seaGreen.withValues(alpha: 0.4)
                : DashboardColors.risk.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  test.ok ? Icons.check : Icons.close,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  test.label,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${test.ms} ms',
                  style: GoogleFonts.robotoMono(
                    color: DashboardColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              test.url,
              style: GoogleFonts.robotoMono(
                color: DashboardColors.cyan,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              test.detail,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
