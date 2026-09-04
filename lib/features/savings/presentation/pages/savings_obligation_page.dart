import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/empty_state.dart';
import 'package:ufg/core/widgets/error_state.dart';
import 'package:ufg/core/widgets/loading_indicator.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_bloc.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_event.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_state.dart';
import 'package:ufg/features/savings/presentation/widgets/monthly_obligation_card.dart';

class SavingsObligationPage extends StatefulWidget {
  const SavingsObligationPage({super.key});

  @override
  State<SavingsObligationPage> createState() => _SavingsObligationPageState();
}

class _SavingsObligationPageState extends State<SavingsObligationPage> {
  @override
  void initState() {
    super.initState();
    _loadObligations();
  }

  void _loadObligations() {
    context.read<SavingsBloc>().add(LoadSavingsObligationsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Monthly Obligations'),
        leading: IconButton(
          icon: Icon(AppIcons.back.outline, size: AppSizes.iconM),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadObligations(),
        child: BlocBuilder<SavingsBloc, SavingsState>(
          builder: (context, state) {
            if (state is SavingsLoading) {
              return ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [SizedBox(height: 120), LoadingIndicator()],
              );
            }

            if (state is SavingsObligationsLoaded) {
              final obligations = state.obligations;

              if (obligations.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: AppSizes.spacingHero),
                    EmptyState(
                      title: 'No obligations yet',
                      subtitle:
                          'Your monthly saving obligations will appear here once they are created.',
                      // icon: AppIcons.calendar.outline,
                    ),
                  ],
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingL,
                  vertical: AppSizes.spacingM,
                ),
                itemCount: obligations.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSizes.spacingS + 2),
                itemBuilder: (context, index) {
                  final obligation = obligations[index];
                  return MonthlyObligationCard(
                    obligation: obligation,
                    onPayTap: () => context.push(
                      AppRoutes.savingsPayment,
                      extra: obligation,
                    ),
                  );
                },
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                ErrorState(
                  message: 'Failed to load your obligations.',
                  onRetry: _loadObligations,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
