import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/entities/loan_product_entity.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class GetActiveOutsiderLoanProduct {
  final LoanRepository repository;
  GetActiveOutsiderLoanProduct(this.repository);

  Future<Either<Failures, LoanProductEntity>> call() =>
      repository.getActiveOutsiderLoanProduct();
}
