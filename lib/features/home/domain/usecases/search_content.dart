import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/home/domain/entities/search_result.dart';
import 'package:ufg/features/home/domain/repositories/home_repository.dart';

class SearchContent {
  final HomeRepository repository;

  SearchContent(this.repository);

  Future<Either<Failures, List<SearchResult>>> call(String query) async {
    if (query.trim().isEmpty) return const Right([]);
    return repository.search(query);
  }
}
