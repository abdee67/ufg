import 'package:equatable/equatable.dart';

enum SearchResultType {
  loan,
  savings,
  member,
  transaction,
}

class SearchResult extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final SearchResultType type;
  final Map<String, dynamic> metadata;

  const SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [id, title, subtitle, type, metadata];
}
