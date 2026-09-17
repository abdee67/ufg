import 'package:ufg/features/home/domain/entities/search_result.dart';

class SearchResultModel extends SearchResult {
  const SearchResultModel({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.type,
    super.metadata,
  });

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      type: SearchResultType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => SearchResultType.transaction,
      ),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}
