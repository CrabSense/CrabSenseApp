import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../core/di/injection.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../domain/entities/sale.dart';
import '../bloc/sales_bloc.dart';
import '../bloc/sales_event.dart';
import '../bloc/sales_state.dart';

/// Screen for recording quick sales transactions directly from the field.
///
/// Features:
/// - Buyer information fields: name (required), contact (optional)
/// - Product details: quantity in kg, unit price (auto-calculates total amount)
/// - Payment method dropdown: Cash, Bank Transfer, Credit
/// - Sale date & time picker
/// - Optional transaction notes
/// - Offline-first queue & synchronization indication
/// - Enforces sales role permission check
///
/// Requirements: 12.1-12.10
class SalesScreen extends StatelessWidget {
  const SalesScreen({
    this.initialFarmId,
    this.operatorId,
    this.operatorName,
    this.userRole,
    super.key,
  });

  /// Optional farm ID context.
  final String? initialFarmId;

  /// Operator ID (resolved from AuthBloc if null).
  final String? operatorId;

  /// Operator name (resolved from AuthBloc if null).
  final String? operatorName;

  /// User role (resolved from AuthBloc if null).
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
      // Isolated widget test fallback
    }

    return BlocProvider<SalesBloc>(
      create: (_) => sl<SalesBloc>()..add(LoadSalesForm(farmId: initialFarmId)),
      child: _SalesView(
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

class _SalesView extends StatelessWidget {
  const _SalesView({
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
        title: const Row(
          children: [
            Icon(Icons.point_of_sale_rounded, color: CrabSenseColors.primary),
            SizedBox(width: 8),
            Text(
              'Record Quick Sale',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: CrabSenseColors.textPrimary,
        elevation: 0,
      ),
      body: BlocConsumer<SalesBloc, SalesState>(
        listener: (context, state) {
          if (state is SalesFormState) {
            if (state.isSubmitted) {
              final message = state.isOffline
                  ? 'Sale recorded offline and queued for sync.'
                  : 'Sale transaction recorded successfully!';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: state.isOffline
                      ? CrabSenseColors.warning
                      : CrabSenseColors.success,
                ),
              );
              Navigator.of(context).pop(state.createdSale);
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
          if (state is! SalesFormState) {
            return const Center(
              child: CircularProgressIndicator(color: CrabSenseColors.primary),
            );
          }

          final hasPermission = userRole == null || userRole!.canManageSales;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!hasPermission) ...[
                  _buildPermissionBanner(),
                  const SizedBox(height: 16),
                ],
                _buildHeaderBanner(),
                const SizedBox(height: 20),

                _buildSectionHeader('Buyer Information'),
                const SizedBox(height: 8),
                _buildBuyerInputs(context, state),
                const SizedBox(height: 20),

                _buildSectionHeader('Product Details & Pricing'),
                const SizedBox(height: 8),
                _buildProductDetailsInputs(context, state),
                const SizedBox(height: 12),
                _buildTotalAmountCard(state),
                const SizedBox(height: 20),

                _buildSectionHeader('Payment & Schedule'),
                const SizedBox(height: 8),
                _buildPaymentMethodDropdown(context, state),
                const SizedBox(height: 12),
                _buildSaleDatePickerButton(context, state),
                const SizedBox(height: 20),

                _buildSectionHeader('Notes & Comments'),
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

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CrabSenseColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CrabSenseColors.outline),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: CrabSenseColors.primary, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Record quick crab sales directly from the field. Total revenue is calculated automatically based on quantity and unit price.',
              style: TextStyle(
                color: CrabSenseColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CrabSenseColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CrabSenseColors.error.withOpacity(0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: CrabSenseColors.error, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sales management permissions required. Sales recording is restricted to Sales representatives, Farm Managers, and Administrators.',
              style: TextStyle(
                color: CrabSenseColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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

  Widget _buildBuyerInputs(BuildContext context, SalesFormState state) {
    return Column(
      children: [
        TextFormField(
          initialValue: state.buyerName,
          style: const TextStyle(color: CrabSenseColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Buyer Name *',
            hintText: 'e.g. Ocean Catch Seafood Co.',
            prefixIcon: const Icon(Icons.person_outline_rounded, color: CrabSenseColors.primary),
            filled: true,
            fillColor: const Color(0xFFFFFFFF),
            errorText: state.buyerNameError,
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
          onChanged: (val) => context
              .read<SalesBloc>()
              .add(SalesBuyerNameChanged(buyerName: val)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: state.buyerContact,
          style: const TextStyle(color: CrabSenseColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Buyer Contact (Optional)',
            hintText: 'Phone number or email address',
            prefixIcon: const Icon(Icons.contact_phone_outlined, color: CrabSenseColors.primary),
            filled: true,
            fillColor: const Color(0xFFFFFFFF),
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
          onChanged: (val) => context
              .read<SalesBloc>()
              .add(SalesBuyerContactChanged(buyerContact: val)),
        ),
      ],
    );
  }

  Widget _buildProductDetailsInputs(BuildContext context, SalesFormState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            initialValue: state.quantityText,
            style: const TextStyle(color: CrabSenseColors.textPrimary),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.\,]?\d*')),
            ],
            decoration: InputDecoration(
              labelText: 'Quantity (kg) *',
              hintText: '0.0',
              prefixIcon: const Icon(Icons.scale_rounded, color: CrabSenseColors.primary),
              filled: true,
              fillColor: const Color(0xFFFFFFFF),
              errorText: state.quantityError,
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
            onChanged: (val) => context
                .read<SalesBloc>()
                .add(SalesQuantityChanged(quantityText: val)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            initialValue: state.unitPriceText,
            style: const TextStyle(color: CrabSenseColors.textPrimary),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.\,]?\d*')),
            ],
            decoration: InputDecoration(
              labelText: 'Unit Price (\$) *',
              hintText: '0.00',
              prefixIcon: const Icon(Icons.attach_money_rounded, color: CrabSenseColors.primary),
              filled: true,
              fillColor: const Color(0xFFFFFFFF),
              errorText: state.unitPriceError,
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
            onChanged: (val) => context
                .read<SalesBloc>()
                .add(SalesUnitPriceChanged(unitPriceText: val)),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalAmountCard(SalesFormState state) {
    final total = state.totalAmount;
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: CrabSenseColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CrabSenseColors.primary.withOpacity(0.6), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  color: CrabSenseColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Auto-calculated (Qty × Unit Price)',
                style: TextStyle(
                  color: CrabSenseColors.textDisabled,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          Text(
            formatter.format(total),
            style: const TextStyle(
              color: CrabSenseColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodDropdown(BuildContext context, SalesFormState state) {
    return DropdownButtonFormField<PaymentMethod>(
      value: state.paymentMethod,
      dropdownColor: const Color(0xFFFFFFFF),
      style: const TextStyle(color: CrabSenseColors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Payment Method *',
        prefixIcon: const Icon(Icons.payment_rounded, color: CrabSenseColors.primary),
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
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
      items: PaymentMethod.values.map((method) {
        IconData methodIcon;
        switch (method) {
          case PaymentMethod.cash:
            methodIcon = Icons.payments_outlined;
            break;
          case PaymentMethod.bankTransfer:
            methodIcon = Icons.account_balance_outlined;
            break;
          case PaymentMethod.credit:
            methodIcon = Icons.credit_card_outlined;
            break;
        }
        return DropdownMenuItem<PaymentMethod>(
          value: method,
          child: Row(
            children: [
              Icon(methodIcon, color: CrabSenseColors.textSecondary, size: 20),
              const SizedBox(width: 10),
              Text(method.displayName),
            ],
          ),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          context.read<SalesBloc>().add(SalesPaymentMethodChanged(paymentMethod: val));
        }
      },
    );
  }

  Widget _buildSaleDatePickerButton(BuildContext context, SalesFormState state) {
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
    final formattedDate = dateFormat.format(state.saleDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: state.saleDate,
              firstDate: now.subtract(const Duration(days: 365)),
              lastDate: now.add(const Duration(minutes: 5)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: CrabSenseColors.primary,
                      onPrimary: const Color(0xFFF5F7FA),
                      surface: const Color(0xFFFFFFFF),
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
                initialTime: TimeOfDay.fromDateTime(state.saleDate),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: CrabSenseColors.primary,
                        onPrimary: const Color(0xFFF5F7FA),
                        surface: const Color(0xFFFFFFFF),
                        onSurface: CrabSenseColors.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (pickedTime != null && context.mounted) {
                final newDateTime = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
                context.read<SalesBloc>().add(SalesDateChanged(saleDate: newDateTime));
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: state.dateError != null
                    ? CrabSenseColors.error
                    : CrabSenseColors.outline,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: CrabSenseColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sale Date & Time *',
                        style: TextStyle(
                          color: CrabSenseColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: CrabSenseColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: CrabSenseColors.textSecondary),
              ],
            ),
          ),
        ),
        if (state.dateError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              state.dateError!,
              style: const TextStyle(color: CrabSenseColors.error, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotesInput(BuildContext context, SalesFormState state) {
    return TextFormField(
      initialValue: state.notes,
      maxLines: 3,
      style: const TextStyle(color: CrabSenseColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Add optional notes, delivery terms, or buyer details...',
        hintStyle: const TextStyle(color: CrabSenseColors.textDisabled),
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
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
          context.read<SalesBloc>().add(SalesNotesChanged(notes: val)),
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

  final SalesFormState state;
  final String operatorId;
  final String operatorName;
  final UserRole? userRole;

  @override
  Widget build(BuildContext context) {
    final hasPermission = userRole == null || userRole!.canManageSales;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (!hasPermission || state.isSubmitting)
            ? null
            : () {
                context.read<SalesBloc>().add(
                      SubmitSale(
                        operatorId: operatorId,
                        operatorName: operatorName,
                        userRole: userRole,
                      ),
                    );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: CrabSenseColors.primary,
          foregroundColor: const Color(0xFFF5F7FA),
          disabledBackgroundColor: CrabSenseColors.surfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        child: state.isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: const Color(0xFFF5F7FA),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Record Quick Sale',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
