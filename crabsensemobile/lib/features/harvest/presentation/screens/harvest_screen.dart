import 'dart:convert';

import 'package:crabsensemobile/core/platform/io_export.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/local_file_image.dart';
import '../../../../app/theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../home/presentation/widgets/crab_hologram_painter.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/entities/harvest.dart';
import '../bloc/harvest_bloc.dart';
import '../bloc/harvest_event.dart';
import '../bloc/harvest_state.dart';

/// Screen for recording harvest data in CrabSense.
///
/// Captures harvest metrics including box ID, total weight, crab count,
/// quality grade, harvest date, photos, and optional notes.
///
/// Requirements: 11.1–11.10
class HarvestScreen extends StatelessWidget {
  const HarvestScreen({
    this.initialBoxId,
    this.initialFarmId,
    this.initialCrabId,
    this.initialBoxGuid,
    this.initialWeightBefore,
    this.initialLengthBefore,
    this.initialWidthBefore,
    this.operatorId,
    this.operatorName,
    this.userRole,
    super.key,
  });

  /// Optional box ID to pre-fill when navigating from box details context.
  final String? initialBoxId;

  /// Optional farm ID to pre-fill.
  final String? initialFarmId;

  final String? initialCrabId;
  final String? initialBoxGuid;
  final double? initialWeightBefore;
  final double? initialLengthBefore;
  final double? initialWidthBefore;

  /// Operator ID (if null, resolved from AuthBloc).
  final String? operatorId;

  /// Operator name (if null, resolved from AuthBloc).
  final String? operatorName;

  /// User role (if null, resolved from AuthBloc).
  final UserRole? userRole;

  @override
  Widget build(BuildContext context) {
    String resolvedOpId = operatorId ?? 'op-user';
    String resolvedOpName = operatorName ?? 'Field Operator';
    UserRole? resolvedRole = userRole;

    try {
      final authState = context.watch<AuthBloc>().state;
      if (authState is Authenticated) {
        resolvedOpId = authState.user.id;
        resolvedOpName = authState.user.fullName;
        resolvedRole ??= authState.user.role;
      }
    } catch (_) {
      // Handled in isolated widget testing environments
    }

    return BlocProvider<HarvestBloc>(
      create: (_) {
        final bloc = sl<HarvestBloc>()
          ..add(LoadHarvestForm(
            boxId: initialBoxId,
            farmId: initialFarmId,
            crabId: initialCrabId,
            boxGuid: initialBoxGuid,
            weightBefore: initialWeightBefore,
            lengthBefore: initialLengthBefore,
            widthBefore: initialWidthBefore,
          ));
        _resolveFarmCode(bloc, initialFarmId, initialBoxId);
        return bloc;
      },
      child: _HarvestView(
        operatorId: resolvedOpId,
        operatorName: resolvedOpName,
        userRole: resolvedRole,
      ),
    );
  }
}

Future<void> _resolveFarmCode(
  HarvestBloc bloc,
  String? farmId,
  String? boxId,
) async {
  try {
    final api = sl<ApiClient>();
    var farm = (farmId ?? '').trim();
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$',
    );
    final emptyGuid = farm.replaceAll('0', '').replaceAll('-', '').isEmpty;
    if ((farm.isEmpty || emptyGuid) &&
        boxId != null &&
        uuid.hasMatch(boxId)) {
      final res = await api.get<dynamic>(ApiConstants.boxDetails(boxId));
      final decoded = jsonDecode(jsonEncode(res.data));
      dynamic raw = decoded;
      if (decoded is Map) {
        raw = decoded['data'] ?? decoded['Data'] ?? decoded;
      }
      if (raw is Map) {
        farm = (raw['farmId'] ??
                raw['FarmId'] ??
                raw['farmingAreaId'] ??
                raw['FarmingAreaId'] ??
                '')
            .toString()
            .trim();
      }
    }
    if (!uuid.hasMatch(farm) || farm.replaceAll('0', '').replaceAll('-', '').isEmpty) {
      if (farm.isNotEmpty) {
        bloc.add(HarvestFarmIdChanged(farmId: farm));
      }
      return;
    }
    final res = await api.get<dynamic>(ApiConstants.farmDetails(farm));
    final decoded = jsonDecode(jsonEncode(res.data));
    dynamic raw = decoded;
    if (decoded is Map) raw = decoded['data'] ?? decoded['Data'] ?? decoded;
    if (raw is Map) {
      final code = (raw['code'] ?? raw['Code'])?.toString().trim();
      final name = (raw['name'] ?? raw['Name'])?.toString().trim();
      farm = (code != null && code.isNotEmpty) ? code : (name ?? farm);
    }
    if (farm.isNotEmpty) {
      bloc.add(HarvestFarmIdChanged(farmId: farm));
    }
  } catch (_) {}
}

// ─────────────────────────────────────────────────────────────────────────────
// Field decoration (đồng bộ phong cách navy + viền xanh của trang home)
// ─────────────────────────────────────────────────────────────────────────────

InputDecoration _fieldDecoration({
  String? label,
  String? hint,
  String? errorText,
  String? suffixText,
  Widget? prefixIcon,
}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: errorText,
    suffixText: suffixText,
    prefixIcon: prefixIcon,
    labelStyle: const TextStyle(color: CrabSenseColors.textSecondary),
    hintStyle: const TextStyle(color: CrabSenseColors.textDisabled, fontSize: 13),
    suffixStyle: const TextStyle(color: CrabSenseColors.textSecondary),
    filled: true,
    fillColor: kHomeBg.withValues(alpha: 0.75),
    enabledBorder: border(kHomeBorderBlue.withValues(alpha: 0.4)),
    focusedBorder: border(kHomeBlue, 1.5),
    errorBorder: border(CrabSenseColors.error.withValues(alpha: 0.6)),
    focusedErrorBorder: border(CrabSenseColors.error),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// View
// ─────────────────────────────────────────────────────────────────────────────

class _HarvestView extends StatelessWidget {
  const _HarvestView({
    required this.operatorId,
    required this.operatorName,
    this.userRole,
  });

  final String operatorId;
  final String operatorName;
  final UserRole? userRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: CrabSenseColors.textPrimary,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kHomeSurface, kHomeBg, kHomeBg],
            ),
            border: Border(
              bottom: BorderSide(
                color: kHomeBorderBlue.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_rounded,
              size: 18,
              color: kHomeBlueLight,
              shadows: [
                Shadow(
                  color: kHomeBlueLight.withValues(alpha: 0.8),
                  blurRadius: 10,
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Text(
              'GHI NHẬN LỘT / THU HOẠCH',
              style: TextStyle(
                color: kHomePrimaryDark,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                fontSize: 14,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<HarvestBloc, HarvestState>(
        listener: (context, state) {
          if (state is HarvestFormState) {
            if (state.isSubmitted) {
              final message = state.keepRaising
                  ? (state.isOffline
                      ? 'Đã lưu nuôi tiếp ngoại tuyến.'
                      : 'Đã ghi nhận lột — cua ở lại hộp nuôi tiếp.')
                  : (state.isOffline
                      ? 'Đã lưu thu hoạch ngoại tuyến, sẽ đồng bộ khi có mạng.'
                      : 'Đã ghi nhận thu hoạch thành công!');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: state.isOffline
                      ? CrabSenseColors.warning
                      : CrabSenseColors.success,
                ),
              );
              Navigator.of(context).pop(state.createdHarvest);
            } else if (state.submissionError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.submissionError!),
                  backgroundColor: CrabSenseColors.error,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is! HarvestFormState) {
            return const Center(
              child: CircularProgressIndicator(color: kHomeBlue),
            );
          }

          return Stack(
            children: [
              // Họa tiết lưới khay nuôi + cua (đồng bộ trang home)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: CrabHologramPainter(
                      color: kHomeBlueLight.withValues(alpha: 0.05),
                      trayExtent: 30,
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('HỘP & VỊ TRÍ'),
                    const SizedBox(height: 8),
                    _buildBoxAndFarmInputs(context, state),
                    if (_beforeLabel(state) != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _beforeLabel(state)!,
                        style: const TextStyle(
                          color: CrabSenseColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    _buildSectionHeader('CHỈ SỐ SAU LỘT (1 CON)'),
                    const SizedBox(height: 8),
                    _buildMetricsInputs(context, state),
                    const SizedBox(height: 20),

                    _buildSectionHeader('ĐÁNH GIÁ CHẤT LƯỢNG'),
                    const SizedBox(height: 8),
                    _buildQualityGradeSelector(context, state),
                    const SizedBox(height: 20),

                    _buildSectionHeader('NGÀY & GIỜ THU HOẠCH'),
                    const SizedBox(height: 8),
                    _buildDatePickerButton(context, state),
                    const SizedBox(height: 20),

                    _buildSectionHeader('HÌNH ẢNH MINH CHỨNG'),
                    const SizedBox(height: 8),
                    _PhotoSection(state: state),
                    const SizedBox(height: 20),

                    _buildSectionHeader('GHI CHÚ & QUAN SÁT'),
                    const SizedBox(height: 8),
                    _buildNotesInput(context, state),
                    const SizedBox(height: 20),

                    _buildSectionHeader('SAU LỘT'),
                    const SizedBox(height: 8),
                    _buildOutcomeSelector(context, state),
                    const SizedBox(height: 16),

                    _SubmitButton(
                      state: state,
                      operatorId: operatorId,
                      operatorName: operatorName,
                      userRole: userRole,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String? _beforeLabel(HarvestFormState state) {
    final parts = <String>[
      if (state.weightBefore != null && state.weightBefore! > 0)
        '${state.weightBefore!.toStringAsFixed(1)} g',
      if (state.lengthBefore != null && state.lengthBefore! > 0)
        'dài ${state.lengthBefore!.toStringAsFixed(1)} mm',
      if (state.widthBefore != null && state.widthBefore! > 0)
        'rộng ${state.widthBefore!.toStringAsFixed(1)} mm',
    ];
    if (parts.isEmpty) return null;
    return 'Trước lột: ${parts.join(' · ')}';
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: kHomePrimaryDark,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildBoxAndFarmInputs(BuildContext context, HarvestFormState state) {
    return Column(
      children: [
        TextFormField(
          initialValue: state.boxId,
          style: const TextStyle(color: CrabSenseColors.textPrimary),
          decoration: _fieldDecoration(
            label: 'Mã hộp *',
            hint: 'VD: BOX-101',
            errorText: state.boxIdError,
            prefixIcon: const Icon(Icons.grid_view_rounded, color: kHomeBlueLight),
          ),
          onChanged: (val) =>
              context.read<HarvestBloc>().add(HarvestBoxIdChanged(boxId: val)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: ValueKey('farm-${state.farmId}'),
          initialValue: state.farmId,
          readOnly: true,
          style: const TextStyle(color: CrabSenseColors.textPrimary),
          decoration: _fieldDecoration(
            label: 'Mã trang trại',
            hint: state.farmId.isEmpty ? 'Đang lấy từ hộp…' : null,
            prefixIcon: const Icon(Icons.agriculture_rounded, color: kHomeBlueLight),
          ),
        ),
      ],
    );
  }

  Widget _buildOutcomeSelector(BuildContext context, HarvestFormState state) {
    Widget chip({
      required bool selected,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: selected
                  ? kHomeBlue.withValues(alpha: 0.18)
                  : kHomeBg.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? kHomeBlue.withValues(alpha: 0.9)
                    : kHomeBorderBlue.withValues(alpha: 0.4),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: kHomePrimaryDark,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CrabSenseColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(
          selected: state.keepRaising,
          title: 'Nuôi tiếp',
          subtitle: 'Cua ở lại hộp',
          onTap: () => context.read<HarvestBloc>().add(
            const HarvestKeepRaisingChanged(keepRaising: true),
          ),
        ),
        const SizedBox(width: 8),
        chip(
          selected: !state.keepRaising,
          title: 'Thu hoạch',
          subtitle: 'Xuất khỏi hộp',
          onTap: () => context.read<HarvestBloc>().add(
            const HarvestKeepRaisingChanged(keepRaising: false),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsInputs(BuildContext context, HarvestFormState state) {
    return Column(
      children: [
        TextFormField(
          initialValue: state.totalWeightText,
          style: const TextStyle(color: CrabSenseColors.textPrimary),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: _fieldDecoration(
            label: 'Cân nặng sau lột *',
            hint: 'VD: 220',
            suffixText: 'g',
            errorText: state.weightError,
            prefixIcon: const Icon(Icons.scale_rounded, color: kHomeBlueLight),
          ),
          onChanged: (val) {
            context.read<HarvestBloc>().add(HarvestWeightChanged(weightText: val));
            context.read<HarvestBloc>().add(
              const HarvestCrabCountChanged(crabCountText: '1'),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: _fieldDecoration(
                  label: 'Dài mai sau lột',
                  hint: 'mm',
                  suffixText: 'mm',
                  prefixIcon: const Icon(Icons.straighten_rounded, color: kHomeBlueLight),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) => context.read<HarvestBloc>().add(
                  HarvestLengthChanged(lengthText: val),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                decoration: _fieldDecoration(
                  label: 'Rộng mai sau lột',
                  hint: 'mm',
                  suffixText: 'mm',
                  prefixIcon: const Icon(Icons.swap_horiz_rounded, color: kHomeBlueLight),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) => context.read<HarvestBloc>().add(
                  HarvestWidthChanged(widthText: val),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAverageWeightCard(HarvestFormState state) {
    final avgWeight = state.averageWeightPerCrab;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kHomeBg.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.functions_rounded, color: CrabSenseColors.textSecondary, size: 20),
              SizedBox(width: 8),
              Text(
                'KL trung bình mỗi con',
                style: TextStyle(color: CrabSenseColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          Text(
            avgWeight > 0 ? '${avgWeight.toStringAsFixed(2)} kg / con' : '-- kg / con',
            style: TextStyle(
              color: kHomePrimaryDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: kHomeBlue.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityGradeSelector(BuildContext context, HarvestFormState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: QualityGrade.values.map((grade) {
            final isSelected = state.qualityGrade == grade;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: InkWell(
                  onTap: () => context
                      .read<HarvestBloc>()
                      .add(HarvestQualityGradeChanged(qualityGrade: grade)),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? kHomeBlue.withValues(alpha: 0.18)
                          : kHomeBg.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? kHomeBlue.withValues(alpha: 0.9)
                            : kHomeBorderBlue.withValues(alpha: 0.4),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: kHomeBlue.withValues(alpha: 0.35),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          grade.displayName,
                          style: TextStyle(
                            color: isSelected
                                ? kHomeBlueLight
                                : CrabSenseColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getGradeDescription(grade),
                          style: TextStyle(
                            color: isSelected
                                ? kHomeBlueLight.withValues(alpha: 0.85)
                                : CrabSenseColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getGradeDescription(QualityGrade grade) {
    switch (grade) {
      case QualityGrade.gradeA:
        return 'Cao cấp';
      case QualityGrade.gradeB:
        return 'Tiêu chuẩn';
      case QualityGrade.gradeC:
        return 'Thấp / Mềm';
    }
  }

  Widget _buildDatePickerButton(BuildContext context, HarvestFormState state) {
    final dateFormat = DateFormat('yyyy-MM-dd  HH:mm');
    final formattedDate = dateFormat.format(state.harvestDate);

    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: state.harvestDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(minutes: 5)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: kHomeBlue,
                  onPrimary: Colors.white,
                  surface: kHomeBg,
                  onSurface: CrabSenseColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedDate != null && context.mounted) {
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(state.harvestDate),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: kHomeBlue,
                    onPrimary: Colors.white,
                    surface: kHomeBg,
                    onSurface: CrabSenseColors.textPrimary,
                  ),
                ),
                child: child!,
              );
            },
          );

          if (pickedTime != null && context.mounted) {
            final combinedDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            context
                .read<HarvestBloc>()
                .add(HarvestDateChanged(harvestDate: combinedDateTime));
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kHomeBg.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: state.dateError != null
                ? CrabSenseColors.error
                : kHomeBorderBlue.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: kHomeBlueLight, size: 20),
                const SizedBox(width: 12),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: CrabSenseColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Icon(Icons.edit_rounded, color: CrabSenseColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesInput(BuildContext context, HarvestFormState state) {
    return TextFormField(
      initialValue: state.notes,
      maxLines: 3,
      style: const TextStyle(color: CrabSenseColors.textPrimary),
      decoration: _fieldDecoration(
        hint: 'Ghi chú thu hoạch, tình trạng cua hoặc nhận xét...',
      ),
      onChanged: (val) =>
          context.read<HarvestBloc>().add(HarvestNotesChanged(notes: val)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo Section
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({required this.state});

  final HarvestFormState state;

  Future<void> _pickPhoto(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (pickedFile != null && context.mounted) {
      context.read<HarvestBloc>().add(AddHarvestPhoto(photoPath: pickedFile.path));
    }
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kHomeSurface, kHomeBg, kHomeBg],
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: kHomeBorderBlue.withValues(alpha: 0.5),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kHomeBorderBlue.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: kHomeBlueLight),
                  title: const Text('Chụp ảnh', style: TextStyle(color: CrabSenseColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickPhoto(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: kHomeBlueLight),
                  title: const Text('Chọn từ thư viện', style: TextStyle(color: CrabSenseColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickPhoto(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 84,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: state.photoPaths.length + (state.photosAtLimit ? 0 : 1),
            itemBuilder: (context, index) {
              if (index < state.photoPaths.length) {
                return _PhotoThumbnail(
                  path: state.photoPaths[index],
                  index: index,
                );
              }

              return InkWell(
                onTap: () => _showSourceSheet(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: kHomeBg.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kHomeBlue.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kHomeBlue.withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          color: kHomeBlueLight, size: 24),
                      SizedBox(height: 4),
                      Text(
                        'Thêm ảnh',
                        style: TextStyle(
                            color: kHomePrimaryDark, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.path, required this.index});

  final String path;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LocalFileImage(
              path: path,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: kHomeSurface,
                child: const Icon(Icons.broken_image_outlined,
                    color: CrabSenseColors.textSecondary),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => context
                  .read<HarvestBloc>()
                  .add(RemoveHarvestPhoto(index: index)),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: CrabSenseColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Submit Button
// ─────────────────────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.state,
    required this.operatorId,
    required this.operatorName,
    this.userRole,
  });

  final HarvestFormState state;
  final String operatorId;
  final String operatorName;
  final UserRole? userRole;

  @override
  Widget build(BuildContext context) {
    final hasPermission =
        userRole == null || userRole!.canPerformFieldOperations;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (!hasPermission || state.isSubmitting)
            ? null
            : () {
                context.read<HarvestBloc>().add(
                      SubmitHarvest(
                        operatorId: operatorId,
                        operatorName: operatorName,
                        userRole: userRole,
                      ),
                    );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: kHomeBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kHomeSurface,
          disabledForegroundColor: CrabSenseColors.textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 6,
          shadowColor: kHomeBlue.withValues(alpha: 0.6),
        ),
        child: state.isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                state.keepRaising ? 'Ghi nhận nuôi tiếp' : 'Ghi nhận thu hoạch',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
