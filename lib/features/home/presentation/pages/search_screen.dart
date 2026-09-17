import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/app_card.dart';
import 'package:ufg/core/widgets/empty_state.dart';
import 'package:ufg/core/widgets/loading_indicator.dart';
import 'package:ufg/features/home/domain/entities/search_result.dart';
import 'package:ufg/features/home/presentation/bloc/home_bloc.dart';
import 'package:ufg/features/home/presentation/bloc/home_event.dart';
import 'package:ufg/features/home/presentation/bloc/home_state.dart';

import '../../../../core/constants/app_routes.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search savings, loans, or transactions...',
            border: InputBorder.none,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          style: theme.textTheme.bodyLarge,
          onChanged: (query) {
            context.read<HomeBloc>().add(SearchQueryChanged(query));
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              _searchController.clear();
              context.read<HomeBloc>().add(ClearSearch());
            },
            icon: Icon(AppIcons.close.outline),
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is SearchInitial) {
            return const Center(
              child: EmptyState(
                title: 'Start Searching',
                subtitle: 'Enter keywords to find loans, savings or members',
              ),
            );
          }

          if (state is SearchLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (state is SearchFailure) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }

          if (state is SearchSuccess) {
            if (state.results.isEmpty) {
              return const Center(
                child: EmptyState(
                  title: 'No results found',
                  subtitle: 'We couldn\'t find anything matching your search',
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppSizes.spacingM),
              itemCount: state.results.length,
              itemBuilder: (context, index) {
                final result = state.results[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.spacingS),
                  child: SearchResultTile(result: result),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class SearchResultTile extends StatelessWidget {
  final SearchResult result;

  const SearchResultTile({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    IconData getIcon() {
      switch (result.type) {
        case SearchResultType.loan:
          return AppIcons.loans.outline;
        case SearchResultType.savings:
          return AppIcons.savings.outline;
        case SearchResultType.member:
          return AppIcons.user.outline;
        case SearchResultType.transaction:
          return AppIcons.receiptItem.outline;
      }
    }

    Color getColor() {
      switch (result.type) {
        case SearchResultType.loan:
          return Colors.blue;
        case SearchResultType.savings:
          return Colors.green;
        case SearchResultType.member:
          return Colors.purple;
        case SearchResultType.transaction:
          return Colors.orange;
      }
    }

    return AppCard(
      onTap: () {
        switch (result.type) {
          case SearchResultType.loan:
            context.push(AppRoutes.loanDetail.replaceFirst(':id', result.id));
            break;
          case SearchResultType.savings:
          case SearchResultType.transaction:
            context.push(AppRoutes.savingsHistory);
            break;
          case SearchResultType.member:
            // Could navigate to a member profile if implemented
            break;
        }
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.spacingS),
            decoration: BoxDecoration(
              color: getColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Icon(getIcon(), color: getColor()),
          ),
          const SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  result.subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            AppIcons.forward.outline,
            size: AppSizes.iconS,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
