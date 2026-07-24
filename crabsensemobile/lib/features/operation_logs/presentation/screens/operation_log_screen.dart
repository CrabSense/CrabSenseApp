// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/operation_log.dart';
import '../../domain/entities/operation_type.dart';
import '../../domain/usecases/create_operation_log_usecase.dart';
import '../../domain/usecases/update_operation_log_usecase.dart';
import '../bloc/operation_bloc.dart';
import '../bloc/operation_event.dart';
import '../bloc/operation_state.dart';

import '../../../authentication/domain/entities/user.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';

/// Screen for creating or editing an operation log.
///
/// Navigates from the dashboard or box-detail screen.
/// Pass [existingLog] to open in edit mode.
///
/// Requirements: 10.1–10.10
class OperationLogScreen extends StatelessWidget {
  const OperationLogScreen({
    required this.operatorId,
    required this.operatorName,
    this.userRole,
    this.existingLog,
    this.initialBoxId,
    super.key,
  });

  /// Authenticated operator's user ID.
  final String operatorId;

  /// Authenticated operator's display name.
  final String operatorName;

  /// Authenticated operator's user role (optional, resolved from AuthBloc if null).
  final UserRole? userRole;

  /// When non-null the form is opened in edit mode.
  final OperationLog? existingLog;

  /// Prefill box id when creating from Boxes quick actions.
  final String? initialBoxId;

  @override
  Widget build(BuildContext context) {
    UserRole? effectiveRole = userRole;
    if (effectiveRole == null) {
      try {
        final authState = context.watch<AuthBloc>().state;
        if (authState is Authenticated) {
          effectiveRole = authState.user.role;
        }
      } catch (_) {
        // AuthBloc not in context during isolated widget tests
      }
    }

    return BlocProvider<OperationBloc>(
      create: (_) => OperationBloc(
        createOperationLog: sl<CreateOperationLogUseCase>(),
        updateOperationLog: sl<UpdateOperationLogUseCase>(),
      )..add(LoadOperationForm(existingLog: existingLog, initialBoxId: initialBoxId)),
      child: _OperationLogView(
        operatorId: operatorId,
        operatorName: operatorName,
        userRole: effectiveRole,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View
// ─────────────────────────────────────────────────────────────────────────────

class _OperationLogView extends StatelessWidget {
  const _OperationLogView({
    required this.operatorId,
    required this.operatorName,
    this.userRole,
  });

  final String operatorId;
  final String operatorName;
  final UserRole? userRole;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CrabSenseColors.background,
    appBar: AppBar(
      title: const Text('Operation Log'),
      backgroundColor: CrabSenseColors.surface,
      foregroundColor: CrabSenseColors.textPrimary,
    ),
    body: BlocConsumer<OperationBloc, OperationState>(
      listener: _onStateChange,
      builder: _buildBody,
    ),
  );

  void _onStateChange(BuildContext context, OperationState state) {
    if (state is OperationFormState) {
      if (state.isSubmitted && !state.isSubmitting) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.isOffline
                  ? 'Saved offline. Will sync when online.'
                  : 'Operation log saved successfully.',
            ),
            backgroundColor: CrabSenseColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) context.pop();
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
    }
  }

  Widget _buildBody(BuildContext context, OperationState state) {
    if (state is OperationInitial) {
      return const Center(child: CircularProgressIndicator(color: CrabSenseColors.primary));
    }
    if (state is OperationFormState) {
      return _OperationLogForm(
        operatorId: operatorId,
        operatorName: operatorName,
        userRole: userRole,
        state: state,
      );
    }
    if (state is OperationError) {
      return _ErrorBody(message: state.message);
    }
    return const Center(child: CircularProgressIndicator(color: CrabSenseColors.primary));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error body
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: CrabSenseColors.error, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: CrabSenseColors.textPrimary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(onPressed: () => context.pop(), child: const Text('Go Back')),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Permission banner
// ─────────────────────────────────────────────────────────────────────────────

class _PermissionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: CrabSenseColors.error.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: CrabSenseColors.error.withValues(alpha: 0.4)),
    ),
    child: const Row(
      children: [
        Icon(Icons.lock_outline_rounded, color: CrabSenseColors.error, size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Permission Denied: Requires Field Operator role or higher to record operations.',
            style: TextStyle(color: CrabSenseColors.error, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Form
// ─────────────────────────────────────────────────────────────────────────────

class _OperationLogForm extends StatefulWidget {
  const _OperationLogForm({
    required this.operatorId,
    required this.operatorName,
    required this.state,
    this.userRole,
  });

  final String operatorId;
  final String operatorName;
  final UserRole? userRole;
  final OperationFormState state;

  @override
  State<_OperationLogForm> createState() => _OperationLogFormState();
}

class _OperationLogFormState extends State<_OperationLogForm> {
  final _boxController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _notesController = TextEditingController();
  final _timestampController = TextEditingController();

  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _syncControllers(widget.state);
    _initialised = true;
  }

  @override
  void didUpdateWidget(_OperationLogForm old) {
    super.didUpdateWidget(old);
    if (!_initialised) return;
    final s = widget.state;
    if (s.rawBoxInput != _boxController.text) {
      _boxController.text = s.rawBoxInput;
    }
    if (s.quantityText != _quantityController.text) {
      _quantityController.text = s.quantityText;
    }
    if (s.unit != _unitController.text) {
      _unitController.text = s.unit;
    }
    if (s.notes != _notesController.text) {
      _notesController.text = s.notes;
    }
    final formatted = _dateFmt.format(s.timestamp);
    if (formatted != _timestampController.text) {
      _timestampController.text = formatted;
    }
  }

  void _syncControllers(OperationFormState s) {
    _boxController.text = s.rawBoxInput;
    _quantityController.text = s.quantityText;
    _unitController.text = s.unit;
    _notesController.text = s.notes;
    _timestampController.text = _dateFmt.format(s.timestamp);
  }

  @override
  void dispose() {
    _boxController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    _timestampController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final s = widget.state;
    final date = await showDatePicker(
      context: context,
      initialDate: s.timestamp,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(s.timestamp),
    );
    if (time == null || !context.mounted) return;

    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    context.read<OperationBloc>().add(OperationTimestampChanged(timestamp: combined));
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final hasPermission =
        widget.userRole == null || widget.userRole!.canPerformFieldOperations;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 0. Permission banner
          if (!hasPermission) ...[
            _PermissionBanner(),
            const SizedBox(height: 16),
          ],

          // 1. Offline banner
          if (state.isOffline) ...[_OfflineBanner(), const SizedBox(height: 16)],

          // 2. Operation type
          const _SectionLabel(label: 'Operation Type *'),
          const SizedBox(height: 8),
          _GlassCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DropdownButtonFormField<OperationType>(
                initialValue: state.selectedType,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                dropdownColor: CrabSenseColors.surface,
                style: const TextStyle(color: CrabSenseColors.textPrimary),
                items: OperationType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          t.displayName,
                          style: const TextStyle(color: CrabSenseColors.textPrimary),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    context.read<OperationBloc>().add(OperationTypeChanged(type: value));
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Box ID(s)
          const _SectionLabel(label: 'Box ID(s) *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _boxController,
            style: const TextStyle(color: CrabSenseColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. BOX-001, BOX-002',
              errorText: state.boxIdsError,
            ),
            onChanged: (value) =>
                context.read<OperationBloc>().add(OperationBoxIdsChanged(rawInput: value)),
          ),
          const SizedBox(height: 16),

          // 4. Timestamp
          const _SectionLabel(label: 'Date & Time *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _timestampController,
            readOnly: true,
            style: const TextStyle(color: CrabSenseColors.textPrimary),
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.calendar_today_outlined, color: CrabSenseColors.primary),
            ),
            onTap: () => _pickDateTime(context),
          ),
          const SizedBox(height: 16),

          // 5 & 6. Quantity + Unit (conditional)
          if (state.showQuantityField) ...[
            const _SectionLabel(label: 'Quantity (optional)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    style: const TextStyle(color: CrabSenseColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. 5.5',
                      errorText: state.quantityError,
                    ),
                    onChanged: (value) =>
                        context.read<OperationBloc>().add(OperationQuantityChanged(value: value)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _unitController,
                    style: const TextStyle(color: CrabSenseColors.textPrimary),
                    decoration: const InputDecoration(hintText: 'kg / L'),
                    onChanged: (value) =>
                        context.read<OperationBloc>().add(OperationUnitChanged(unit: value)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // 7. Notes
          const _SectionLabel(label: 'Notes (optional)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            maxLines: 4,
            style: const TextStyle(color: CrabSenseColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Add any observations or notes...',
              alignLabelWithHint: true,
            ),
            onChanged: (value) =>
                context.read<OperationBloc>().add(OperationNotesChanged(notes: value)),
          ),
          const SizedBox(height: 16),

          // 8. Photo attachments
          const _SectionLabel(label: 'Photos (optional, max 5)'),
          const SizedBox(height: 8),
          _PhotoSection(photoPaths: state.photoPaths, atLimit: state.photosAtLimit),
          const SizedBox(height: 24),

          // 9. Submit button
          _SubmitButton(
            state: state,
            operatorId: widget.operatorId,
            operatorName: widget.operatorName,
            userRole: widget.userRole,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Glass card
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Offline banner
// ─────────────────────────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: CrabSenseColors.warning.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: CrabSenseColors.warning.withValues(alpha: 0.4)),
    ),
    child: const Row(
      children: [
        Icon(Icons.wifi_off_rounded, color: CrabSenseColors.warning, size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            "You're offline. Log will be saved and synced when connection is restored.",
            style: TextStyle(color: CrabSenseColors.warning, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo section
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({required this.photoPaths, required this.atLimit});

  final List<String> photoPaths;
  final bool atLimit;

  Future<void> _pickPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null && context.mounted) {
      context.read<OperationBloc>().add(AddOperationPhoto(photoPath: picked.path));
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 96,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        ...photoPaths.asMap().entries.map(
          (entry) => _PhotoThumbnail(path: entry.value, index: entry.key),
        ),
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
            onTap: () => context.read<OperationBloc>().add(RemoveOperationPhoto(index: index)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Submit button
// ─────────────────────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.state,
    required this.operatorId,
    required this.operatorName,
    this.userRole,
  });

  final OperationFormState state;
  final String operatorId;
  final String operatorName;
  final UserRole? userRole;

  @override
  Widget build(BuildContext context) {
    final hasPermission =
        userRole == null || userRole!.canPerformFieldOperations;
    final canSubmit = state.canSubmit && hasPermission;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Tooltip(
        message: !hasPermission
            ? 'Requires Field Operator role or higher'
            : '',
        child: ElevatedButton(
          onPressed: canSubmit
              ? () => context.read<OperationBloc>().add(
                    SubmitOperationLog(
                      operatorId: operatorId,
                      operatorName: operatorName,
                      userRole: userRole,
                    ),
                  )
              : null,
          child: state.isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                )
              : const Text(
                  'Save Operation Log',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}
