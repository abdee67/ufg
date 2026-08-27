// If your Supabase auth supports updating metadata:
import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/auth/domain/repositories/auth_repository.dart';

import '../entities/customer_entity.dart';

class UpdateCustomerProfile {
  final AuthRepository repo;
  UpdateCustomerProfile(this.repo);

  Future<Either<Failures, void>> call(CustomerEntity updatedData) {
    return repo.updateCustomerProfile(updatedData);
  }
}
