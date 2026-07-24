import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/sale.dart';
import '../repositories/sales_repository.dart';

/// Parameters for [GetSalesHistoryUseCase].
class GetSalesHistoryParams {
  const GetSalesHistoryParams({
    this.farmId,
    this.buyerName,
    this.startDate,
    this.endDate,
    this.paymentMethod,
    this.paymentStatus,
    this.page = 1,
    this.pageSize = 50,
  });

  final String? farmId;
  final String? buyerName;
  final DateTime? startDate;
  final DateTime? endDate;
  final PaymentMethod? paymentMethod;
  final PaymentStatus? paymentStatus;
  final int page;
  final int pageSize;
}

/// Use case for retrieving historical sales records with optional filtering parameters.
///
/// Supports filtering by farm, buyer name, date range, payment method, and status (Requirement 12.10).
/// Validates date range constraints and pagination settings.
///
/// Requirements: 12.10
class GetSalesHistoryUseCase {
  const GetSalesHistoryUseCase(this._repository);

  final SalesRepository _repository;

  Future<Either<Failure, List<Sale>>> call(GetSalesHistoryParams params) async {
    // Validate pagination parameters
    if (params.page < 1) {
      return const Left(ValidationFailure('Page number must be at least 1.'));
    }

    if (params.pageSize < 1 || params.pageSize > 200) {
      return const Left(ValidationFailure('Page size must be between 1 and 200.'));
    }

    // Validate date range logic
    if (params.startDate != null &&
        params.endDate != null &&
        params.startDate!.isAfter(params.endDate!)) {
      return const Left(ValidationFailure('Start date cannot be after end date.'));
    }

    return _repository.getSalesHistory(
      farmId: params.farmId,
      buyerName: params.buyerName,
      startDate: params.startDate,
      endDate: params.endDate,
      paymentMethod: params.paymentMethod,
      paymentStatus: params.paymentStatus,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}
