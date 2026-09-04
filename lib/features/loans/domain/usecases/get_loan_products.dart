import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/loans/domain/entities/loan_product_entity.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';

class GetLoanProducts {
  final LoanRepository repository;

  GetLoanProducts(this.repository);

  Future<Either<Failures, List<LoanProductEntity>>> call() async {
    return await repository.getLoanProducts();
  }
}
