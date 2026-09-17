import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/home/domain/entities/search_result.dart';

abstract class HomeRepository {
  Future<Either<Failures, List<SearchResult>>> search(String query);
}
