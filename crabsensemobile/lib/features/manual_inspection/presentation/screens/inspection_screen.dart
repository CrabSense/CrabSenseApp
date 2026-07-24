// ignore_for_file: lines_longer_than_80_chars
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/di/injection.dart';
import '../../../box/domain/entities/box_enums.dart';
import '../../../video_capture/domain/entities/ai_detection.dart';
import '../../../video_capture/domain/usecases/get_ai_results_usecase.dart';
import '../../domain/usecases/submit_feedback_use_case.dart';
import '../../domain/usecases/submit_inspection_use_case.dart';
import '../../domain/repositories/inspection_repository.dart';
import '../bloc/bloc.dart';

/// Manual inspection form screen.
///
/// Allows a Field Operator to fill in molting status, health condition,
/// weight, notes, and photos. When navigated from the AI results screen
/// the detected results are shown at the top for comparison.
///
/// Route: `/box/:id/inspect` (optional query param `videoId`)
///
/// Requirements: 7.1-7.10
class InspectionScreen extends StatelessWidget {
  const InspectionScreen({
    required this.boxId,
    required this.operatorId,
    required this.operatorName,
    this.videoId,
    super.key,
  });

  /// Box identifier this inspection is for.
  final String boxId;

  /// Operator user ID for attribution (Requirement 7.9).
  final String operatorId;

  /// Operator display name for attribution.
  final String operatorName;

  /// Optional video ID — when set, AI results are loaded for comparison.
  final String? videoId;

  @override
  Widget build(BuildContext context) => BlocProvider<InspectionBloc>(
    create: (_) => InspectionBloc(
      submitInspection: sl<SubmitInspectionUseCase>(),
      submitFeedback: sl<SubmitFeedbackUseCase>(),
      repository: sl<InspectionRepository>(),
      logger: sl<Logger>(),
      getAiResults: sl<GetAIResultsUseCase>(),
    )..add(LoadInspectionContext(boxId: boxId, videoId: videoId)),
    child: _InspectionView(boxId: boxId, operatorId: operatorId, operatorName: operatorName),
  );
}

// ---------------------------------------------------------------------------
// Main view
// ---------------------------------------------------------------------------

class _InspectionView extends StatelessWidget {
  const _InspectionView({
    required this.boxId,
    required this.operatorId,
    required this.operatorName,
  });

  final String boxId;
  final String operatorId;
  final String operatorName;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CrabSenseColors.background,
    appBar: AppBar(
      title: const Text('Manual Inspection'),
      backgroundColor: CrabSenseColors.surface,
      foregroundColor: CrabSenseColors.textPrimary,
    ),
    body: BlocConsumer<InspectionBloc, InspectionState>(
      listener: _onStateChange,
      builder: _buildBody,
    ),
  );

  void _onStateChange(BuildContext context, InspectionState state) {
    if (state is InspectionFormState) {
      if (state.isSubmitted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspection submitted successfully'),
            backgroundColor: CrabSenseColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) context.go(RoutePaths.boxDetails(boxId));
        });
      }
      if (state.submissionError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.submissionError!),
            backgroundColor: CrabSenseColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (state.aiFeedbackError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.aiFeedbackError!),
            backgroundColor: CrabSenseColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildBody(BuildContext context, InspectionState state) {
    if (state is InspectionInitial) {
      return const Center(child: CircularProgressIndicator(color: CrabSenseColors.primary));
    }
    if (state is InspectionFormState) {
      return _InspectionForm(
        boxId: boxId,
        operatorId: operatorId,
        operatorName: operatorName,
        state: state,
      );
    }
    return const Center(child: CircularProgressIndicator(color: CrabSenseColors.primary));
  }
}

// ---------------------------------------------------------------------------
// Form widget
// ---------------------------------------------------------------------------

class _InspectionForm extends StatefulWidget {
  const _InspectionForm({
    required this.boxId,
    required this.operatorId,
    required this.operatorName,
    required this.state,
  });

  final String boxId;
  final String operatorId;
  final String operatorName;
  final InspectionFormState state;

  @override
  State<_InspectionForm> createState() => _InspectionFormState();
}

class _InspectionFormState extends State<_InspectionForm> {
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  bool _weightInitialized = false;
  bool _notesInitialized = false;

  @override
  void initState() {
    super.initState();
    _weightController.text = widget.state.weightText;
    _notesController.text = widget.state.notes;
    _weightInitialized = true;
    _notesInitialized = true;
  }

  @override
  void didUpdateWidget(_InspectionForm old) {
    super.didUpdateWidget(old);
    if (_weightInitialized && widget.state.weightText != _weightController.text) {
      _weightController.text = widget.state.weightText;
    }
    if (_notesInitialized && widget.state.notes != _notesController.text) {
      _notesController.text = widget.state.notes;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. AI comparison panel (if context loaded)
          if (state.isLoadingContext) ...[
            _AiContextSkeleton(),
            const SizedBox(height: 16),
          ] else if (state.hasAiContext) ...[
            _AiComparisonPanel(detection: state.aiDetection!),
            const SizedBox(height: 16),
          ],
          // 2. Molting status
          const _SectionLabel(label: 'Molting Status *'),
          const SizedBox(height: 8),
          _MoltingDropdown(current: state.moltingStatus),
          const SizedBox(height: 16),
          // 2b. Checklist 4 tiêu chuẩn
          const _InspectionChecklistWidget(),
          const SizedBox(height: 16),
          // 3. Health condition
          const _SectionLabel(label: 'Health Condition *'),
          const SizedBox(height: 8),
          _HealthDropdown(current: state.healthStatus),
          const SizedBox(height: 16),
          // 4. Weight input
          const _SectionLabel(label: 'Weight (grams) *'),
          const SizedBox(height: 8),
          _WeightInput(controller: _weightController, errorText: state.weightError),
          const SizedBox(height: 16),
          // 5. Notes
          const _SectionLabel(label: 'Notes (optional)'),
          const SizedBox(height: 8),
          _NotesInput(controller: _notesController),
          const SizedBox(height: 16),
          // 6. Photo capture
          const _SectionLabel(label: 'Photos (optional)'),
          const SizedBox(height: 8),
          _PhotoCaptureWidget(photoPaths: state.photoPaths, atLimit: state.photosAtLimit),
          const SizedBox(height: 16),
          // 7. AI feedback (if AI context present)
          if (state.hasAiContext && state.submittedInspectionId != null) ...[
            _AiFeedbackSection(
              state: state,
              videoId: state.aiDetection!.videoId,
              operatorId: widget.operatorId,
            ),
            const SizedBox(height: 16),
          ],
          // 8. Agreement rate display (after submission)
          if (state.isSubmitted && state.agreementRate != null) ...[
            _AgreementRateWidget(agreementRate: state.agreementRate!),
            const SizedBox(height: 16),
          ],
          // 9. Submit button
          _SubmitButton(
            state: state,
            boxId: widget.boxId,
            operatorId: widget.operatorId,
            operatorName: widget.operatorName,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI comparison panel
// ---------------------------------------------------------------------------

class _AiComparisonPanel extends StatelessWidget {
  const _AiComparisonPanel({required this.detection});

  final AIDetection detection;

  Color _moltingColor(MoltingStatus s) {
    switch (s) {
      case MoltingStatus.preMolt:
        return const Color(0xFFFFD54F);
      case MoltingStatus.molting:
        return CrabSenseColors.warning;
      case MoltingStatus.postMolt:
        return CrabSenseColors.success;
      case MoltingStatus.hardShell:
        return CrabSenseColors.primary;
    }
  }

  Color _healthColor(HealthStatus s) {
    switch (s) {
      case HealthStatus.normal:
        return CrabSenseColors.success;
      case HealthStatus.disease:
        return CrabSenseColors.error;
      case HealthStatus.stress:
        return CrabSenseColors.warning;
      case HealthStatus.unknown:
        return CrabSenseColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) => _GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.smart_toy_outlined, color: CrabSenseColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'AI Detection Results (for comparison)',
                style: TextStyle(
                  color: CrabSenseColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusChip(
                label: detection.moltingStatus.displayName,
                color: _moltingColor(detection.moltingStatus),
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: detection.healthStatus.displayName,
                color: _healthColor(detection.healthStatus),
              ),
              const Spacer(),
              Text(
                '${detection.confidencePercent}% confidence',
                style: const TextStyle(color: CrabSenseColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

class _AiContextSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const _GlassCard(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonLine(width: 220, height: 14),
          SizedBox(height: 12),
          Row(
            children: [
              _SkeletonLine(width: 80, height: 24),
              SizedBox(width: 8),
              _SkeletonLine(width: 70, height: 24),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: CrabSenseColors.surfaceVariant,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}

// ---------------------------------------------------------------------------
// Form field widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: CrabSenseColors.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
  );
}

class _MoltingDropdown extends StatelessWidget {
  const _MoltingDropdown({required this.current});

  final MoltingStatus current;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<MoltingStatus>(
    initialValue: current,
    decoration: const InputDecoration(hintText: 'Select molting status'),
    dropdownColor: CrabSenseColors.surface,
    style: const TextStyle(color: CrabSenseColors.textPrimary),
    items: MoltingStatus.values
        .map(
          (s) => DropdownMenuItem(
            value: s,
            child: Text(s.displayName, style: const TextStyle(color: CrabSenseColors.textPrimary)),
          ),
        )
        .toList(),
    onChanged: (value) {
      if (value != null) {
        context.read<InspectionBloc>().add(UpdateMoltingStatus(status: value));
      }
    },
  );
}

class _HealthDropdown extends StatelessWidget {
  const _HealthDropdown({required this.current});

  final HealthStatus current;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<HealthStatus>(
    initialValue: current,
    decoration: const InputDecoration(hintText: 'Select health condition'),
    dropdownColor: CrabSenseColors.surface,
    style: const TextStyle(color: CrabSenseColors.textPrimary),
    items: HealthStatus.values
        .map(
          (s) => DropdownMenuItem(
            value: s,
            child: Text(s.displayName, style: const TextStyle(color: CrabSenseColors.textPrimary)),
          ),
        )
        .toList(),
    onChanged: (value) {
      if (value != null) {
        context.read<InspectionBloc>().add(UpdateHealthStatus(status: value));
      }
    },
  );
}

class _WeightInput extends StatelessWidget {
  const _WeightInput({required this.controller, this.errorText});

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
    style: const TextStyle(color: CrabSenseColors.textPrimary),
    decoration: InputDecoration(
      hintText: 'e.g. 150.5',
      errorText: errorText,
      suffixText: 'g',
      suffixStyle: const TextStyle(color: CrabSenseColors.textSecondary),
    ),
    onChanged: (value) => context.read<InspectionBloc>().add(UpdateWeight(value: value)),
  );
}

class _NotesInput extends StatelessWidget {
  const _NotesInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    maxLines: 4,
    style: const TextStyle(color: CrabSenseColors.textPrimary),
    decoration: const InputDecoration(
      hintText: 'Add any observations or notes...',
      alignLabelWithHint: true,
    ),
    onChanged: (value) => context.read<InspectionBloc>().add(UpdateNotes(notes: value)),
  );
}

// ---------------------------------------------------------------------------
// Photo capture widget
// ---------------------------------------------------------------------------

class _PhotoCaptureWidget extends StatelessWidget {
  const _PhotoCaptureWidget({required this.photoPaths, required this.atLimit});

  final List<String> photoPaths;
  final bool atLimit;

  Future<void> _pickPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null && context.mounted) {
      context.read<InspectionBloc>().add(AddPhoto(photoPath: picked.path));
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 96,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        // Existing photo thumbnails
        ...photoPaths.asMap().entries.map(
          (entry) => _PhotoThumbnail(path: entry.value, index: entry.key),
        ),
        // Add photo button (hidden when at limit)
        if (!atLimit)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _pickPhoto(context),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: CrabSenseColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CrabSenseColors.primary.withValues(alpha: 0.4)),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: CrabSenseColors.primary, size: 24),
                    SizedBox(height: 4),
                    Text(
                      'Add Photo',
                      style: TextStyle(color: CrabSenseColors.primary, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.path, required this.index});

  final String path;
  final int index;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(path),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 80,
              height: 80,
              color: CrabSenseColors.surfaceVariant,
              child: const Icon(Icons.broken_image_outlined, color: CrabSenseColors.textSecondary),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => context.read<InspectionBloc>().add(RemovePhoto(index: index)),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(color: CrabSenseColors.error, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// AI feedback section
// ---------------------------------------------------------------------------

class _AiFeedbackSection extends StatelessWidget {
  const _AiFeedbackSection({required this.state, required this.videoId, required this.operatorId});

  final InspectionFormState state;
  final String videoId;
  final String operatorId;

  @override
  Widget build(BuildContext context) => _GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Was the AI result accurate?',
            style: TextStyle(
              color: CrabSenseColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your feedback helps improve AI accuracy',
            style: TextStyle(color: CrabSenseColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          // Feedback already submitted
          if (state.aiFeedbackSubmitted != null) ...[
            Row(
              children: [
                Icon(
                  state.aiFeedbackSubmitted! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: state.aiFeedbackSubmitted!
                      ? CrabSenseColors.success
                      : CrabSenseColors.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  state.aiFeedbackSubmitted!
                      ? 'You marked this as Correct'
                      : 'You marked this as Incorrect',
                  style: TextStyle(
                    color: state.aiFeedbackSubmitted!
                        ? CrabSenseColors.success
                        : CrabSenseColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ] else if (state.aiFeedbackSubmitting) ...[
            const Center(child: CircularProgressIndicator(color: CrabSenseColors.primary)),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.read<InspectionBloc>().add(
                      SubmitAiFeedback(
                        videoId: videoId,
                        inspectionId: state.submittedInspectionId ?? '',
                        isCorrect: true,
                        operatorId: operatorId,
                      ),
                    ),
                    icon: const Icon(Icons.thumb_up_alt_rounded, size: 16),
                    label: const Text('Correct'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CrabSenseColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.read<InspectionBloc>().add(
                      SubmitAiFeedback(
                        videoId: videoId,
                        inspectionId: state.submittedInspectionId ?? '',
                        isCorrect: false,
                        operatorId: operatorId,
                      ),
                    ),
                    icon: const Icon(Icons.thumb_down_alt_rounded, size: 16),
                    label: const Text('Incorrect'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CrabSenseColors.error,
                      side: const BorderSide(color: CrabSenseColors.error),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Submit button
// ---------------------------------------------------------------------------

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.state,
    required this.boxId,
    required this.operatorId,
    required this.operatorName,
  });

  final InspectionFormState state;
  final String boxId;
  final String operatorId;
  final String operatorName;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: state.canSubmit
          ? () => context.read<InspectionBloc>().add(
              SubmitInspection(boxId: boxId, operatorId: operatorId, operatorName: operatorName),
            )
          : null,
      child: state.isSubmitting
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
            )
          : const Text(
              'Submit Inspection',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Agreement rate widget
// ---------------------------------------------------------------------------

class _AgreementRateWidget extends StatelessWidget {
  const _AgreementRateWidget({required this.agreementRate});

  final double agreementRate;

  @override
  Widget build(BuildContext context) => _GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: CrabSenseColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'AI Agreement Rate',
                style: TextStyle(
                  color: CrabSenseColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: agreementRate,
                  backgroundColor: CrabSenseColors.surfaceVariant,
                  color: CrabSenseColors.success,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(agreementRate * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: CrabSenseColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'How often you and AI agree on detection results',
            style: TextStyle(color: CrabSenseColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Shared glass card
// ---------------------------------------------------------------------------

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: CrabSenseColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: CrabSenseColors.primary.withValues(alpha: 0.2)),
    ),
    child: child,
  );
}

// ---------------------------------------------------------------------------
// 4 Checkboxes Checklist Widget (MOB-MoltConfirm)
// ---------------------------------------------------------------------------

class _InspectionChecklistWidget extends StatefulWidget {
  const _InspectionChecklistWidget();

  @override
  State<_InspectionChecklistWidget> createState() => _InspectionChecklistWidgetState();
}

class _InspectionChecklistWidgetState extends State<_InspectionChecklistWidget> {
  bool _isSoftShell = false;
  bool _hasGoodReflex = true;
  bool _hasDoubleLine = false;
  bool _isMolted = false;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Checklist Hiện Trường (4 Tiêu chí)',
              style: TextStyle(color: CrabSenseColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            CheckboxListTile(
              value: _isSoftShell,
              dense: true,
              activeColor: CrabSenseColors.primary,
              title: const Text('Vỏ mềm (Softshell sẵn sàng)', style: TextStyle(color: Colors.white, fontSize: 12)),
              onChanged: (val) => setState(() => _isSoftShell = val ?? false),
            ),
            CheckboxListTile(
              value: _hasGoodReflex,
              dense: true,
              activeColor: CrabSenseColors.primary,
              title: const Text('Phản xạ tốt (Khỏe mạnh)', style: TextStyle(color: Colors.white, fontSize: 12)),
              onChanged: (val) => setState(() => _hasGoodReflex = val ?? false),
            ),
            CheckboxListTile(
              value: _hasDoubleLine,
              dense: true,
              activeColor: CrabSenseColors.primary,
              title: const Text('Thấy đường đôi (Double line - Sắp lột)', style: TextStyle(color: Colors.white, fontSize: 12)),
              onChanged: (val) => setState(() => _hasDoubleLine = val ?? false),
            ),
            CheckboxListTile(
              value: _isMolted,
              dense: true,
              activeColor: CrabSenseColors.primary,
              title: const Text('Đã lột vỏ xong (Post-molt)', style: TextStyle(color: Colors.white, fontSize: 12)),
              onChanged: (val) => setState(() => _isMolted = val ?? false),
            ),
          ],
        ),
      ),
    );
  }
}
