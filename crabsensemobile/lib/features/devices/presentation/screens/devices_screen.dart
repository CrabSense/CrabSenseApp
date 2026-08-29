import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../home/presentation/widgets/crab_hologram_painter.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../data/models/iot_device.dart';
import '../providers/devices_provider.dart';

/// Danh sách thiết bị IoT — GET /api/devices.
class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key, this.initialType});

  /// Optional type hint from profile (esp32, camera, …).
  final String? initialType;

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  bool _appliedInitial = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_appliedInitial || widget.initialType == null) return;
      _appliedInitial = true;
      final t = widget.initialType!.toLowerCase();
      final mapped = switch (t) {
        'esp32' || 'esp' || 'gateway' => DevicesTypeFilter.esp,
        'camera' || 'cam' => DevicesTypeFilter.camera,
        'sensor' => DevicesTypeFilter.sensor,
        'pump' => DevicesTypeFilter.pump,
        'valve' => DevicesTypeFilter.valve,
        _ => DevicesTypeFilter.all,
      };
      if (mapped != DevicesTypeFilter.all) {
        ref.read(devicesStateProvider.notifier).setTypeFilter(mapped);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(devicesStateProvider);
    final notifier = ref.read(devicesStateProvider.notifier);

    return Scaffold(
      backgroundColor: kHomeBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CrabHologramPainter(
                  color: kHomeBlueLight.withValues(alpha: 0.05),
                  trayExtent: 32,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: kHomeBlueLight,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'THIẾT BỊ & IOT',
                          style: TextStyle(
                            color: kHomePrimaryDark,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Làm mới',
                        onPressed: () => notifier.load(),
                        icon: const Icon(Icons.refresh_rounded, color: kHomeCyan),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: homeCardDecoration(radius: 16, glowAlpha: 0.12),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        const HomeCrabWatermark(alpha: 0.05, trayExtent: 20),
                        Row(
                          children: [
                            _StatChip(
                              label: 'Tổng',
                              value: '${state.devices.length}',
                              color: kHomeBlueLight,
                            ),
                            const SizedBox(width: 10),
                            _StatChip(
                              label: 'Online',
                              value: '${state.onlineCount}',
                              color: kHomeGreen,
                            ),
                            const SizedBox(width: 10),
                            _StatChip(
                              label: 'Offline',
                              value: '${state.offlineCount}',
                              color: kHomeOrange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _FilterChip(
                        label: 'Tất cả',
                        selected: state.filter == DevicesFilter.all,
                        onTap: () => notifier.setFilter(DevicesFilter.all),
                      ),
                      _FilterChip(
                        label: 'Online',
                        selected: state.filter == DevicesFilter.online,
                        onTap: () => notifier.setFilter(DevicesFilter.online),
                      ),
                      _FilterChip(
                        label: 'Offline',
                        selected: state.filter == DevicesFilter.offline,
                        onTap: () => notifier.setFilter(DevicesFilter.offline),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'ESP32',
                        selected: state.typeFilter == DevicesTypeFilter.esp,
                        onTap: () => notifier.setTypeFilter(
                          state.typeFilter == DevicesTypeFilter.esp
                              ? DevicesTypeFilter.all
                              : DevicesTypeFilter.esp,
                        ),
                      ),
                      _FilterChip(
                        label: 'Camera',
                        selected: state.typeFilter == DevicesTypeFilter.camera,
                        onTap: () => notifier.setTypeFilter(
                          state.typeFilter == DevicesTypeFilter.camera
                              ? DevicesTypeFilter.all
                              : DevicesTypeFilter.camera,
                        ),
                      ),
                      _FilterChip(
                        label: 'Cảm biến',
                        selected: state.typeFilter == DevicesTypeFilter.sensor,
                        onTap: () => notifier.setTypeFilter(
                          state.typeFilter == DevicesTypeFilter.sensor
                              ? DevicesTypeFilter.all
                              : DevicesTypeFilter.sensor,
                        ),
                      ),
                      _FilterChip(
                        label: 'Bơm',
                        selected: state.typeFilter == DevicesTypeFilter.pump,
                        onTap: () => notifier.setTypeFilter(
                          state.typeFilter == DevicesTypeFilter.pump
                              ? DevicesTypeFilter.all
                              : DevicesTypeFilter.pump,
                        ),
                      ),
                      _FilterChip(
                        label: 'Van',
                        selected: state.typeFilter == DevicesTypeFilter.valve,
                        onTap: () => notifier.setTypeFilter(
                          state.typeFilter == DevicesTypeFilter.valve
                              ? DevicesTypeFilter.all
                              : DevicesTypeFilter.valve,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: _buildBody(context, ref, state)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, DevicesState state) {
    if (state.isLoading && state.devices.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kHomeCyan));
    }
    if (state.error != null && state.devices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: kHomeOrange, size: 40),
              const SizedBox(height: 12),
              Text(
                'Không tải được thiết bị',
                style: TextStyle(
                  color: const Color(0xFF5A7184),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF5A7184),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(devicesStateProvider.notifier).load(),
                style: FilledButton.styleFrom(
                  backgroundColor: kHomeCyan,
                  foregroundColor: kHomeBg,
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final items = state.filtered;
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Không có thiết bị phù hợp bộ lọc',
          style: TextStyle(color: const Color(0xFF5A7184)),
        ),
      );
    }

    return RefreshIndicator(
      color: kHomeCyan,
      backgroundColor: kHomeSurface,
      onRefresh: () => ref.read(devicesStateProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final d = items[i];
          return _DeviceCard(
            device: d,
            onTap: () => _showDetail(context, ref, d),
          );
        },
      ),
    );
  }

  Future<void> _showDetail(
    BuildContext context,
    WidgetRef ref,
    IotDevice device,
  ) async {
    IotDevice detail = device;
    try {
      detail = await ref.read(devicesRepositoryProvider).getDevice(device.id);
    } catch (_) {}

    if (!context.mounted) return;
    final fmt = DateFormat('HH:mm dd/MM/yyyy');

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kHomeSurface, kHomeBg, kHomeBg],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.5)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              const HomeCrabWatermark(alpha: 0.05, trayExtent: 28),
              SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: kHomeCyan.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Text(
                        detail.deviceCode,
                        style: const TextStyle(
                          color: kHomeTextMain,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Badge(
                            label: detail.typeLabel,
                            color: kHomeBlueLight,
                          ),
                          _Badge(
                            label: detail.statusLabelVi,
                            color: detail.isOnline ? kHomeGreen : kHomeOrange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DetailRow('Loại', detail.deviceType.isEmpty ? '—' : detail.deviceType),
                      _DetailRow(
                        'Firmware',
                        detail.firmwareVersion?.isNotEmpty == true
                            ? detail.firmwareVersion!
                            : '—',
                      ),
                      _DetailRow(
                        'Pin',
                        detail.batteryLevel != null
                            ? '${detail.batteryLevel!.toStringAsFixed(0)}%'
                            : '—',
                      ),
                      _DetailRow(
                        'RSSI',
                        detail.rssiDbm != null
                            ? '${detail.rssiDbm!.toStringAsFixed(0)} dBm'
                            : '—',
                      ),
                      _DetailRow('Số cảm biến', '${detail.sensorCount}'),
                      _DetailRow(
                        'Last seen',
                        detail.lastSeenAt != null
                            ? fmt.format(detail.lastSeenAt!.toLocal())
                            : '—',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: FilledButton.styleFrom(
                            backgroundColor: kHomeCyan,
                            foregroundColor: kHomeBg,
                          ),
                          child: const Text(
                            'Đóng',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF5A7184),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        onSelected: (_) => onTap(),
        label: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        selectedColor: kHomeBlue.withValues(alpha: 0.45),
        backgroundColor: kHomeBg.withValues(alpha: 0.72),
        side: BorderSide(
          color: selected
              ? kHomeCyan.withValues(alpha: 0.8)
              : kHomeBorderBlue.withValues(alpha: 0.45),
        ),
        showCheckmark: false,
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device, required this.onTap});

  final IotDevice device;
  final VoidCallback onTap;

  IconData get _icon {
    final t = device.deviceType.toLowerCase();
    if (t.contains('cam')) return Icons.videocam_rounded;
    if (t.contains('sensor')) return Icons.sensors_rounded;
    if (t.contains('pump') || t.contains('bơm')) return Icons.water_drop_rounded;
    if (t.contains('valve') || t.contains('van')) return Icons.tune_rounded;
    return Icons.memory_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final online = device.isOnline;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: homeCardDecoration(
            radius: 16,
            glowAlpha: online ? 0.14 : 0.08,
            accent: online ? kHomeGreen : kHomeOrange,
          ),
          child: Stack(
            children: [
              const HomeCrabWatermark(alpha: 0.04, trayExtent: 20),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (online ? kHomeCyan : kHomeOrange)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (online ? kHomeCyan : kHomeOrange)
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(
                        _icon,
                        color: online ? kHomeCyan : kHomeOrange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.deviceCode,
                            style: const TextStyle(
                              color: kHomeTextMain,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            device.typeLabel,
                            style: TextStyle(
                              color: const Color(0xFF5A7184),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                device.statusLabelVi,
                                style: TextStyle(
                                  color: online ? kHomeGreen : kHomeOrange,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              if (device.sensorCount > 0)
                                Text(
                                  '${device.sensorCount} sensor',
                                  style: TextStyle(
                                    color: const Color(0xFF5A7184),
                                    fontSize: 11,
                                  ),
                                ),
                              if (device.lastSeenAt != null)
                                Text(
                                  'Seen ${DateFormat('HH:mm dd/MM').format(device.lastSeenAt!.toLocal())}',
                                  style: TextStyle(
                                    color: const Color(0xFF5A7184),
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: const Color(0xFF5A7184),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF5A7184),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
