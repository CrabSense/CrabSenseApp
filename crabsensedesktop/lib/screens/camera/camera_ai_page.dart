import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_camera_ai_data.dart';
import '../../models/camera_ai.dart';
import '../../services/camera_ai_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/camera/camera_ai_widgets.dart';
import '../../widgets/dashboard/glass_card.dart';

class CameraAiPage extends StatefulWidget {
  const CameraAiPage({super.key, required this.service});

  final CameraAiService service;

  @override
  State<CameraAiPage> createState() => _CameraAiPageState();
}

class _CameraAiPageState extends State<CameraAiPage> {
  @override
  void initState() {
    super.initState();
    widget.service.reloadCameras();
    widget.service.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final primary = service.primaryCamera;
    final showAll = service.cameraTab == 'Tất cả camera';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Camera AI Monitor',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Giám sát hình ảnh realtime và phát hiện bất thường bằng AI',
            style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 20),
          _CameraTabs(
            selected: service.cameraTab,
            onSelect: service.setCameraTab,
          ),
          const SizedBox(height: 20),
          _FilterBar(service: service),
          const SizedBox(height: 20),
          if (showAll)
            _AllCamerasGrid(service: service)
          else
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth > 1000;
                if (wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            flex: 3,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CameraLiveFeed(camera: primary),
                                const SizedBox(height: 12),
                                _CameraMeta(camera: primary),
                                const SizedBox(height: 16),
                                CameraThumbnailStrip(
                                  cameras: service.thumbnailCameras,
                                  onSelect: (cam) {
                                    final tab = switch (cam.id) {
                                      'cam1' => 'Camera 1',
                                      'cam2' => 'Camera 2',
                                      'cam3' => 'Camera 3',
                                      _ => 'Camera 1',
                                    };
                                    service.setCameraTab(tab);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            flex: 2,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AiDetectionPanel(counts: service.detectionCounts),
                                const SizedBox(height: 16),
                                CrabAssistantCameraCard(
                                  insight: service.aiInsight,
                                  recommendation: service.aiRecommendation,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CameraLiveFeed(camera: primary),
                    const SizedBox(height: 12),
                    _CameraMeta(camera: primary),
                    const SizedBox(height: 16),
                    AiDetectionPanel(counts: service.detectionCounts),
                    const SizedBox(height: 16),
                    CrabAssistantCameraCard(
                      insight: service.aiInsight,
                      recommendation: service.aiRecommendation,
                    ),
                    const SizedBox(height: 16),
                    CameraThumbnailStrip(
                      cameras: service.thumbnailCameras,
                      onSelect: (cam) {
                        final tab = switch (cam.id) {
                          'cam1' => 'Camera 1',
                          'cam2' => 'Camera 2',
                          'cam3' => 'Camera 3',
                          _ => 'Camera 1',
                        };
                        service.setCameraTab(tab);
                      },
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 24),
          AiEventsTable(
            events: service.filteredEvents,
            service: service,
          ),
        ],
      ),
    );
  }
}

class _CameraTabs extends StatelessWidget {
  const _CameraTabs({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: MockCameraAiData.cameraTabs.map((tab) {
        final active = tab == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 24),
          child: InkWell(
            onTap: () => onSelect(tab),
            child: Column(
              children: [
                Text(
                  tab,
                  style: GoogleFonts.notoSans(
                    color: active ? DashboardColors.textPrimary : DashboardColors.textMuted,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 2,
                  width: 80,
                  color: active ? DashboardColors.purple : Colors.transparent,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CameraMeta extends StatelessWidget {
  const _CameraMeta({required this.camera});

  final CameraFeed camera;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _metaChip(camera.status.label, camera.status.color),
        const SizedBox(width: 12),
        Text(
          'FPS: ${camera.fps}',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
        ),
        const SizedBox(width: 12),
        Text(
          'Cập nhật: ${camera.lastUpdateSeconds} giây trước',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _metaChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSans(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.service});

  final CameraAiService service;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _dropdown('Camera', MockCameraAiData.cameraFilterOptions, service.setCameraFilter),
          _dropdown('Phát hiện', MockCameraAiData.typeFilterOptions, service.setTypeFilter),
          _dropdown('Mức độ', MockCameraAiData.levelFilterOptions, service.setLevelFilter),
          _dropdown('Trạng thái', MockCameraAiData.statusFilterOptions, service.setStatusFilter),
        ],
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, ValueChanged<String> onChanged) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
        initialValue: items.first,
        dropdownColor: DashboardColors.card,
        style: GoogleFonts.notoSans(fontSize: 12, color: DashboardColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 11),
          filled: true,
          fillColor: DashboardColors.darkNavy,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _AllCamerasGrid extends StatelessWidget {
  const _AllCamerasGrid({required this.service});

  final CameraAiService service;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 900 ? 3 : 1;
            final w = (c.maxWidth - 12 * (cols - 1)) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: service.cameras.map((cam) {
                return SizedBox(
                  width: w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cam.name} - ${cam.area}',
                        style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      CameraLiveFeed(
                        camera: cam,
                        onTap: () {
                          final tab = switch (cam.id) {
                            'cam1' => 'Camera 1',
                            'cam2' => 'Camera 2',
                            'cam3' => 'Camera 3',
                            _ => 'Camera 1',
                          };
                          service.setCameraTab(tab);
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 16),
        AiDetectionPanel(counts: service.detectionCounts),
        const SizedBox(height: 16),
        CrabAssistantCameraCard(
          insight: service.aiInsight,
          recommendation: service.aiRecommendation,
        ),
      ],
    );
  }
}
