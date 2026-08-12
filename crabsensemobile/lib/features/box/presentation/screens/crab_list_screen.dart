import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../home/presentation/widgets/crab_hologram_painter.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../data/datasources/box_remote_data_source.dart';
import '../../data/models/crab_model.dart';
import '../../domain/entities/box_enums.dart';
import '../../domain/entities/crab.dart';

/// Danh sách cua trong một hộp nuôi.
class CrabListScreen extends StatefulWidget {
  const CrabListScreen({super.key, required this.boxId, this.boxCode});

  final String boxId;
  final String? boxCode;

  @override
  State<CrabListScreen> createState() => _CrabListScreenState();
}

class _CrabListScreenState extends State<CrabListScreen> {
  late Future<List<CrabModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<CrabModel>> _load() =>
      sl<BoxRemoteDataSource>().getCrabsByBox(widget.boxId);

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.boxCode != null && widget.boxCode!.isNotEmpty
        ? 'CUA · ${widget.boxCode}'
        : 'DANH SÁCH CUA';

    return Scaffold(
      backgroundColor: kHomeNavyDeep,
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
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: kHomeBlueLight,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _refresh,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: kHomeCyan,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<CrabModel>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: kHomeCyan),
                        );
                      }
                      if (snap.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Không tải được danh sách cua.\n${snap.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        );
                      }
                      final crabs = snap.data ?? const [];
                      if (crabs.isEmpty) {
                        return Center(
                          child: Text(
                            'Hộp chưa có cua',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        );
                      }
                      return RefreshIndicator(
                        color: kHomeCyan,
                        backgroundColor: kHomeNavyLift,
                        onRefresh: _refresh,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: crabs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final crab = crabs[i];
                            return _CrabTile(
                              crab: crab,
                              onTap: () => context.push(
                                RoutePaths.crabDetails(
                                  crab.id,
                                  boxId: widget.boxId,
                                ),
                                extra: crab,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CrabTile extends StatelessWidget {
  const _CrabTile({required this.crab, required this.onTap});

  final CrabModel crab;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tag = crab.addedBy.isNotEmpty ? crab.addedBy : crab.id;
    final shortId = crab.id.length > 8 ? crab.id.substring(0, 8) : crab.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: homeCardDecoration(radius: 14, glowAlpha: 0.08),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kHomeCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.set_meal_rounded, color: kHomeCyan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${crab.species.displayName} · ${crab.weight.toStringAsFixed(1)} g',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Chip(
                          label: _moltingVi(crab.moltingStatus),
                          color: kHomeBlueLight,
                        ),
                        _Chip(
                          label: _healthVi(crab.healthStatus),
                          color: _healthColor(crab.healthStatus),
                        ),
                        _Chip(label: '#$shortId', color: kHomeCyan),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _moltingVi(MoltingStatus s) => switch (s) {
      MoltingStatus.preMolt => 'Trước lột',
      MoltingStatus.molting => 'Đang lột',
      MoltingStatus.postMolt => 'Sau lột',
      MoltingStatus.hardShell => 'Vỏ cứng',
    };

String _healthVi(HealthStatus s) => switch (s) {
      HealthStatus.normal => 'Khỏe',
      HealthStatus.disease => 'Bệnh',
      HealthStatus.stress => 'Stress',
      HealthStatus.unknown => 'Không rõ',
    };

Color _healthColor(HealthStatus s) => switch (s) {
      HealthStatus.normal => kHomeGreen,
      HealthStatus.disease => Colors.redAccent,
      HealthStatus.stress => kHomeOrange,
      HealthStatus.unknown => Colors.white54,
    };

String _sourceVi(CrabSource s) => switch (s) {
      CrabSource.farm => 'Nuôi trang trại',
      CrabSource.purchase => 'Mua ngoài',
      CrabSource.transfer => 'Chuyển hộp',
    };

/// Chi tiết một con cua.
class CrabDetailScreen extends StatefulWidget {
  const CrabDetailScreen({
    super.key,
    required this.crabId,
    this.boxId,
    this.initial,
  });

  final String crabId;
  final String? boxId;
  final CrabModel? initial;

  @override
  State<CrabDetailScreen> createState() => _CrabDetailScreenState();
}

class _CrabDetailScreenState extends State<CrabDetailScreen> {
  late Future<CrabModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<CrabModel> _load() async {
    if (widget.initial != null && widget.initial!.id == widget.crabId) {
      // Vẫn refresh nền; hiển thị initial trước qua Future.value rồi? Simple: fetch.
    }
    try {
      return await sl<BoxRemoteDataSource>().getCrabById(widget.crabId);
    } catch (_) {
      if (widget.initial != null) return widget.initial!;
      rethrow;
    }
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm dd/MM/yyyy');

    return Scaffold(
      backgroundColor: kHomeNavyDeep,
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
                          'CHI TIẾT CUA',
                          style: TextStyle(
                            color: kHomeBlueLight,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _refresh,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: kHomeCyan,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<CrabModel>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting &&
                          widget.initial == null) {
                        return const Center(
                          child: CircularProgressIndicator(color: kHomeCyan),
                        );
                      }
                      if (snap.hasError && widget.initial == null) {
                        return Center(
                          child: Text(
                            'Không tải được cua.\n${snap.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        );
                      }
                      final crab = snap.data ?? widget.initial!;
                      final tag =
                          crab.addedBy.isNotEmpty ? crab.addedBy : '—';

                      return RefreshIndicator(
                        color: kHomeCyan,
                        backgroundColor: kHomeNavyLift,
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          children: [
                            Container(
                              decoration: homeCardDecoration(
                                radius: 16,
                                glowAlpha: 0.12,
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.set_meal_rounded,
                                        color: kHomeCyan,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          tag == '—' ? 'Cua' : tag,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ID: ${crab.id}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.45),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: homeCardDecoration(
                                radius: 16,
                                glowAlpha: 0.08,
                              ),
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                              child: Column(
                                children: [
                                  _Row(
                                    icon: Icons.sell_outlined,
                                    label: 'Tag / mã',
                                    value: tag,
                                  ),
                                  _Row(
                                    icon: Icons.category_outlined,
                                    label: 'Giống',
                                    value: crab.species.displayName,
                                  ),
                                  _Row(
                                    icon: Icons.scale_outlined,
                                    label: 'Khối lượng',
                                    value:
                                        '${crab.weight.toStringAsFixed(1)} g',
                                  ),
                                  _Row(
                                    icon: Icons.water_drop_outlined,
                                    label: 'Giai đoạn lột',
                                    value: _moltingVi(crab.moltingStatus),
                                  ),
                                  _Row(
                                    icon: Icons.favorite_outline,
                                    label: 'Sức khỏe',
                                    value: _healthVi(crab.healthStatus),
                                    valueColor: _healthColor(crab.healthStatus),
                                  ),
                                  _Row(
                                    icon: Icons.swap_horiz_rounded,
                                    label: 'Nguồn gốc',
                                    value: _sourceVi(crab.source),
                                  ),
                                  _Row(
                                    icon: Icons.inventory_2_outlined,
                                    label: 'Hộp nuôi',
                                    value: crab.boxId.isNotEmpty
                                        ? crab.boxId
                                        : (widget.boxId ?? '—'),
                                  ),
                                  _Row(
                                    icon: Icons.schedule_rounded,
                                    label: 'Thêm lúc',
                                    value: fmt.format(crab.addedAt),
                                    showDivider: false,
                                  ),
                                ],
                              ),
                            ),
                            if (widget.boxId != null &&
                                widget.boxId!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push(
                                    RoutePaths.boxDetails(widget.boxId!),
                                  ),
                                  icon: const Icon(Icons.grid_view_rounded),
                                  label: const Text('Xem hộp nuôi'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: kHomeCyan,
                                    side: BorderSide(
                                      color: kHomeCyan.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: kHomeCyan, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        color: valueColor ?? Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: kHomeBorderBlue.withValues(alpha: 0.3)),
      ],
    );
  }
}
