import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

class FetchHomeData extends HomeEvent {
  final bool refresh;

  const FetchHomeData({this.refresh = false});

  @override
  List<Object> get props => [refresh];
}
class SearchQueryChanged extends HomeEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object> get props => [query];
}

class ClearSearch extends HomeEvent {
  const ClearSearch();
}