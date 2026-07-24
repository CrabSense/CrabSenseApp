import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../authentication/domain/entities/user.dart';
import '../entities/sale.dart';
import '../repositories/sales_repository.dart';

/// Parameters for [CreateSaleUseCase].
class CreateSaleParams {
  const CreateSaleParams({
    required this.sale,
    this.userRole,
    this.skipInventoryCheck = false,
  });

  /// The sale record to be created.
  final Sale sale;

  /// Role of the user performing the action.
  /// Used for authorization validation (Requirement 12.9, 19.4).
  final UserRole? userRole;

  /// Option to bypass inventory check (default false).
  final bool skipInventoryCheck;
}

/// Use case for creating a quick sale transaction in the CrabSense system.
///
/// Business validation rules enforced:
/// - User must have Sales management permission (Requirement 12.9, 19.4)
/// - Buyer name must not be empty (Requirement 12.2)
/// - Quantity must be a positive number (> 0) (Requirement 12.2)
/// - Unit price must be a positive number (> 0) (Requirement 12.2)
/// - Operator ID & operator name must not be empty
/// - Sale date must not be in the future (Requirement 12.2)
/// - Sale quantity must not exceed available harvested inventory (Requirement 12.4)
/// - Total amount is calculated automatically if zero or unpopulated (Requirement 12.3)
///
/// Requirements: 12.1-12.9, 19.4
class CreateSaleUseCase {
  const CreateSaleUseCase(this._repository);

  final SalesRepository _repository;

  Future<Either<Failure, Sale>> call(CreateSaleParams params) async {
    final sale = params.sale;
    final role = params.userRole;

    // Validate authorization: Sales role, Admin, or Farm Manager required (Requirement 12.9, 19.4)
    if (role != null && !role.canManageSales) {
      return const Left(
        ValidationFailure(
          'Requires Sales role or higher to create sales records.',
          code: 'PERMISSION_DENIED',
        ),
      );
    }

    // Validate required buyer name (Requirement 12.2)
    if (sale.buyerName.trim().isEmpty) {
      return const Left(ValidationFailure.required('Buyer name'));
    }

    // Validate positive quantity (Requirement 12.2)
    if (sale.quantity <= 0) {
      return const Left(
        ValidationFailure(
          'Quantity must be greater than zero.',
          code: 'INVALID_QUANTITY',
        ),
      );
    }

    // Validate positive unit price (Requirement 12.2)
    if (sale.unitPrice <= 0) {
      return const Left(
        ValidationFailure(
          'Unit price must be greater than zero.',
          code: 'INVALID_UNIT_PRICE',
        ),
      );
    }

    // Validate operator identity
    if (sale.operatorId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Operator ID'));
    }

    if (sale.operatorName.trim().isEmpty) {
      return const Left(ValidationFailure.required('Operator name'));
    }

    // Validate sale date not in future (Requirement 12.2)
    if (sale.saleDate.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      return const Left(
        ValidationFailure(
          'Sale date cannot be in the future.',
          code: 'INVALID_DATE',
        ),
      );
    }

    // Validate quantity against available harvested inventory (Requirement 12.4)
    if (!params.skipInventoryCheck) {
      final inventoryResult =
          await _repository.getAvailableHarvestedInventory(farmId: sale.farmId);

      Failure? inventoryError;
      double availableInventory = 0.0;

      inventoryResult.fold(
        (failure) => inventoryError = failure,
        (avail) => availableInventory = avail,
      );

      if (inventoryError != null) {
        return Left(inventoryError!);
      }

      if (sale.quantity > availableInventory) {
        return Left(
          ValidationFailure(
            'Sale quantity (${sale.quantity.toStringAsFixed(1)}) exceeds available harvested inventory (${availableInventory.toStringAsFixed(1)} kg available).',
            code: 'INSUFFICIENT_INVENTORY',
          ),
        );
      }
    }

    // Ensure total amount is calculated automatically (Requirement 12.3)
    final calculatedTotal = sale.calculatedTotal;
    final finalSale = (sale.totalAmount <= 0 || (sale.totalAmount - calculatedTotal).abs() > 0.01)
        ? sale.copyWith(totalAmount: calculatedTotal)
        : sale;

    return _repository.createSale(finalSale);
  }
}
