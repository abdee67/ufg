import 'package:dartz/dartz.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/home/data/datasources/home_remote_data_source.dart';
import 'package:ufg/features/home/domain/entities/search_result.dart';
import 'package:ufg/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failures, List<SearchResult>>> search(String query) async {
    try {
      final results = await remoteDataSource.search(query);
      return Right(results);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
