import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../core/di/injection.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
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
    this.operatorId,
    this.operatorName,
    this.userRole,
    super.key,
  });

  /// Optional box ID to pre-fill when navigating from box details context.
  final String? initialBoxId;

  /// Optional farm ID to pre-fill.
  final String? initialFarmId;

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
      create: (_) => sl<HarvestBloc>()
        ..add(LoadHarvestForm(boxId: initialBoxId, farmId: initialFarmId)),
      child: _HarvestView(
        operatorId: resolvedOpId,
        operatorName: resolvedOpName,
        userRole: resolvedRole,
      ),
    );
  }
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
      backgroundColor: CrabSenseColors.background,
      appBar: AppBar(
        title: const Text(
          'Record Harvest',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: CrabSenseColors.surface,
        foregroundColor: CrabSenseColors.textPrimary,
        elevation: 0,
      ),
      body: BlocConsumer<HarvestBloc, HarvestState>(
        listener: (context, state) {
          if (state is HarvestFormState) {
            if (state.isSubmitted) {
              final message = state.isOffline
                  ? 'Harvest recorded offline and queued for sync.'
                  : 'Harvest record submitted successfully!';
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
              child: CircularProgressIndicator(color: CrabSenseColors.primary),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Box & Location'),
                const SizedBox(height: 8),
                _buildBoxAndFarmInputs(context, state),
                const SizedBox(height: 20),

                _buildSectionHeader('Harvest Metrics'),
                const SizedBox(height: 8),
                _buildMetricsInputs(context, state),
                const SizedBox(height: 12),
                _buildAverageWeightCard(state),
                const SizedBox(height: 20),

                _buildSectionHeader('Quality Assessment'),
                const SizedBox(height: 8),
                _buildQualityGradeSelector(context, state),
                const SizedBox(height: 20),

                _buildSectionHeader('Harvest Date & Time'),
                const SizedBox(height: 8),
                _buildDatePickerButton(context, state),
                const SizedBox(height: 20),

                _buildSectionHeader('Photo Documentation'),
                const SizedBox(height: 8),
                _PhotoSection(state: state),
                const SizedBox(height: 20),

                _buildSectionHeader('Notes & Observations'),
                const SizedBox(height: 8),
                _buildNotesInput(context, state),
                const SizedBox(height: 28),

                _SubmitButton(
                  state: state,
                  operatorId: operatorId,
                  operatorName: operatorName,
                  userRole: userRole,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: CrabSenseColors.primary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildBoxAndFarmInputs(BuildContext context, HarvestFormState state) {
    return Column(
      children: [
        TextFormField(
          initialValue: state.boxId,
          style: const TextStyle(color: CrabSenseColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Box ID *',
            hintText: 'e.g. BOX-101',
            prefixIcon: const Icon(Icons.grid_view_rounded, color: CrabSenseColors.primary),
            filled: true,
            fillColor: CrabSenseColors.surface,
            errorText: state.boxIdError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CrabSenseColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CrabSenseColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CrabSenseColors.primary, width: 2),
            ),
          ),
          onChanged: (val) =>
              context.read<HarvestBloc>().add(HarvestBoxIdChanged(boxId: val)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: state.farmId,
          style: const TextStyle(color: CrabSenseColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Farm ID',
            hintText: 'e.g. FARM-01',
            prefixIcon: const Icon(Icons.agriculture_rounded, color: CrabSenseColors.primary),
            filled: true,
            fillColor: CrabSenseColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CrabSenseColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CrabSenseColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CrabSenseColors.primary, width: 2),
            ),
          ),
          onChanged: (val) =>
              context.read<HarvestBloc>().add(HarvestFarmIdChanged(farmId: val)),
        ),
      ],
    );
  }

  Widget _buildMetricsInputs(BuildContext context, HarvestFormState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            initialValue: state.totalWeightText,
            style: const TextStyle(color: CrabSenseColors.textPrimary),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              labelText: 'Total Weight *',
              hintText: '0.00',
              suffixText: 'kg',
              prefixIcon: const Icon(Icons.scale_rounded, color: CrabSenseColors.primary),
              filled: true,
              fillColor: CrabSenseColors.surface,
              errorText: state.weightError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CrabSenseColors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CrabSenseColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CrabSenseColors.primary, width: 2),
              ),
            ),
            onChanged: (val) =>
                context.read<HarvestBloc>().add(HarvestWeightChanged(weightText: val)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            initialValue: state.crabCountText,
            style: const TextStyle(color: CrabSenseColors.textPrimary),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Crab Count *',
              hintText: '0',
              suffixText: 'crabs',
              prefixIcon: const Icon(Icons.format_list_numbered_rounded, color: CrabSenseColors.primary),
              filled: true,
              fillColor: CrabSenseColors.surface,
              errorText: state.crabCountError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CrabSenseColors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CrabSenseColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CrabSenseColors.primary, width: 2),
              ),
            ),
            onChanged: (val) =>
                context.read<HarvestBloc>().add(HarvestCrabCountChanged(crabCountText: val)),
          ),
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
        color: CrabSenseColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CrabSenseColors.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.functions_rounded, color: CrabSenseColors.textSecondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Avg Weight per Crab',
                style: TextStyle(color: CrabSenseColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          Text(
            avgWeight > 0 ? '${avgWeight.toStringAsFixed(2)} kg / crab' : '-- kg / crab',
            style: const TextStyle(
              color: CrabSenseColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
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
                          ? CrabSenseColors.primary.withValues(alpha: 0.2)
                          : CrabSenseColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? CrabSenseColors.primary
                            : CrabSenseColors.outline,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          grade.displayName,
                          style: TextStyle(
                            color: isSelected
                                ? CrabSenseColors.primary
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
                                ? CrabSenseColors.primary.withValues(alpha: 0.8)
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
        return 'Premium';
      case QualityGrade.gradeB:
        return 'Standard';
      case QualityGrade.gradeC:
        return 'Low / Soft';
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
                  primary: CrabSenseColors.primary,
                  onPrimary: CrabSenseColors.background,
                  surface: CrabSenseColors.surface,
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
                    primary: CrabSenseColors.primary,
                    onPrimary: CrabSenseColors.background,
                    surface: CrabSenseColors.surface,
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
          color: CrabSenseColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: state.dateError != null
                ? CrabSenseColors.error
                : CrabSenseColors.outline,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: CrabSenseColors.primary, size: 20),
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
      decoration: InputDecoration(
        hintText: 'Optional harvest notes, crab condition, or remarks...',
        filled: true,
        fillColor: CrabSenseColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CrabSenseColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CrabSenseColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CrabSenseColors.primary, width: 2),
        ),
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
      backgroundColor: CrabSenseColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: CrabSenseColors.primary),
                title: const Text('Take Photo', style: TextStyle(color: CrabSenseColors.textPrimary)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickPhoto(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: CrabSenseColors.primary),
                title: const Text('Choose from Gallery', style: TextStyle(color: CrabSenseColors.textPrimary)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickPhoto(context, ImageSource.gallery);
                },
              ),
            ],
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
                    color: CrabSenseColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CrabSenseColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          color: CrabSenseColors.primary, size: 24),
                      SizedBox(height: 4),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                            color: CrabSenseColors.primary, fontSize: 10),
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
            child: Image.file(
              File(path),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: CrabSenseColors.surfaceVariant,
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
          backgroundColor: CrabSenseColors.primary,
          foregroundColor: CrabSenseColors.background,
          disabledBackgroundColor: CrabSenseColors.surfaceVariant,
          disabledForegroundColor: CrabSenseColors.textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: state.isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: CrabSenseColors.background,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Record Harvest',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
