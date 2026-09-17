import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/core/config/supabase_config.dart';
import 'package:ufg/features/home/data/models/search_result_model.dart';
import 'package:ufg/features/home/domain/entities/search_result.dart';

abstract class HomeRemoteDataSource {
  Future<List<SearchResultModel>> search(String query);
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  SupabaseClient get _client => SupabaseConfig.client;

  @override
  Future<List<SearchResultModel>> search(String query) async {
    final results = <SearchResultModel>[];
    final searchTerm = '%${query.trim()}%';

    try {
      // 1. Search Loans
      final loansResponse = await _client
          .from('loans')
          .select('id, loan_number, principal')
          .ilike('loan_number', searchTerm)
          .limit(5);

      for (var item in loansResponse) {
        results.add(SearchResultModel(
          id: item['id'],
          title: item['loan_number'],
          subtitle: 'Loan - ETB ${item['principal']}',
          type: SearchResultType.loan,
          metadata: item,
        ));
      }

      // 2. Search Transactions
      final txResponse = await _client
          .from('transactions')
          .select('id, reference_number, description, amount')
          .or('reference_number.ilike.$searchTerm,description.ilike.$searchTerm')
          .limit(5);

      for (var item in txResponse) {
        results.add(SearchResultModel(
          id: item['id'],
          title: item['reference_number'],
          subtitle: '${item['description'] ?? 'Transaction'} - ETB ${item['amount']}',
          type: SearchResultType.transaction,
          metadata: item,
        ));
      }

      // 3. Search Profiles/Members
      final profilesResponse = await _client
          .from('profiles')
          .select('id, full_name, phone')
          .ilike('full_name', searchTerm)
          .limit(5);

      for (var item in profilesResponse) {
        results.add(SearchResultModel(
          id: item['id'],
          title: item['full_name'],
          subtitle: 'Member - ${item['phone'] ?? ''}',
          type: SearchResultType.member,
          metadata: item,
        ));
      }

      return results;
    } catch (e) {
      // In a real app, wrap in a custom exception
      throw Exception('Search failed: $e');
    }
  }
}
