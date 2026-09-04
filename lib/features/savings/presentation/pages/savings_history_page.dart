import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/empty_state.dart';
import 'package:ufg/core/widgets/error_state.dart';
import 'package:ufg/core/widgets/loading_indicator.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_bloc.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_event.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_state.dart';
import 'package:ufg/features/savings/presentation/widgets/savings_transaction_tile.dart';

class SavingsHistoryPage extends StatefulWidget {
  const SavingsHistoryPage({super.key});

  @override
  State<SavingsHistoryPage> createState() => _SavingsHistoryPageState();
}

class _SavingsHistoryPageState extends State<SavingsHistoryPage> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    context.read<SavingsBloc>().add(LoadSavingsHistoryRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Savings History'),
        leading: IconButton(
          icon: Icon(AppIcons.back.outline, size: AppSizes.iconM),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadHistory(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingL,
                vertical: AppSizes.spacingS,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterTab(
                      label: 'All Transactions',
                      isSelected: _selectedFilter == 'all',
                      onTap: () => setState(() => _selectedFilter = 'all'),
                    ),
                    const SizedBox(width: AppSizes.spacingXs),
                    _FilterTab(
                      label: 'Contributions',
                      isSelected: _selectedFilter == 'contribution',
                      onTap: () =>
                          setState(() => _selectedFilter = 'contribution'),
                    ),
                    const SizedBox(width: AppSizes.spacingXs),
                    _FilterTab(
                      label: 'Withdrawals',
                      isSelected: _selectedFilter == 'withdrawal',
                      onTap: () =>
                          setState(() => _selectedFilter = 'withdrawal'),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<SavingsBloc, SavingsState>(
                builder: (context, state) {
                  if (state is SavingsLoading) {
                    return  ListView(
                      physics: AlwaysScrollableScrollPhysics(),
                      children: [SizedBox(height: 120), LoadingIndicator()],
                    );
                  }

                  if (state is SavingsHistoryLoaded) {
                    final allItems = state.history;
                    final filteredItems = _selectedFilter == 'all'
                        ? allItems
                        : allItems
                            .where((item) =>
                                item.itemType.toLowerCase() == _selectedFilter)
                            .toList();

                    if (filteredItems.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: AppSizes.spacingHero),
                          EmptyState(
                            title: 'No transactions found',
                            subtitle:
                                'Your contribution and withdrawal history will appear here.',
                            icon: AppIcons.history.outline,
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spacingL,
                        vertical: AppSizes.spacingXs,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return SavingsTransactionTile(
                          item: filteredItems[index],
                        );
                      },
                    );
                  }

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      ErrorState(
                        message: 'Failed to load transaction history.',
                        onRetry: _loadHistory,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingS + 2,
          vertical: AppSizes.spacingXs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? ColorConstants.onBrand
                : theme.textTheme.bodyMedium?.color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}