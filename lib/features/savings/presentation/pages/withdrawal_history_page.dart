import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/empty_state.dart';
import 'package:ufg/core/widgets/error_state.dart';
import 'package:ufg/core/widgets/loading_indicator.dart';
import 'package:ufg/core/widgets/primary_button.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_bloc.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_event.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_state.dart';
import 'package:ufg/features/savings/presentation/widgets/withdrawal_request_card.dart';

class WithdrawalHistoryPage extends StatefulWidget {
  const WithdrawalHistoryPage({super.key});

  @override
  State<WithdrawalHistoryPage> createState() => _WithdrawalHistoryPageState();
}

class _WithdrawalHistoryPageState extends State<WithdrawalHistoryPage> {
  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    context.read<SavingsBloc>().add(LoadWithdrawalRequestsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Withdrawal Requests'),
        leading: IconButton(
          icon: Icon(AppIcons.back.outline, size: AppSizes.iconM),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(AppIcons.moneySend.outline, size: AppSizes.iconM),
            tooltip: 'New Request',
            onPressed: () => context.push(AppRoutes.savingsWithdraw),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadRequests(),
        child: BlocConsumer<SavingsBloc, SavingsState>(
          listener: (context, state) {
            if (state is SavingsActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _loadRequests();
            } else if (state is SavingsFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is SavingsLoading) {
              return ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [SizedBox(height: 120), LoadingIndicator()],
              );
            }

            if (state is WithdrawalRequestsLoaded) {
              final requests = state.requests;

              if (requests.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: AppSizes.spacingHero),
                    EmptyState(
                      title: 'No withdrawal requests yet',
                      subtitle:
                          'When you request a withdrawal, its review status will be tracked here.',
                      icon: AppIcons.walletEmpty.outline,
                      action: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacingHero,
                        ),
                        child: PrimaryButton(
                          label: 'Request Withdrawal',
                          onPressed: () =>
                              context.push(AppRoutes.savingsWithdraw),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingL,
                  vertical: AppSizes.spacingM,
                ),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return WithdrawalRequestCard(
                    request: req,
                    onCancelTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cancel withdrawal request?'),
                          content: Text(
                            'This will withdraw your ${req.amount.toStringAsFixed(2)} ETB request from review. You can submit a new request at any time.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Keep request'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: ColorConstants.onBrand,
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.read<SavingsBloc>().add(
                                      CancelWithdrawalRequested(
                                        withdrawalRequestId: req.id,
                                      ),
                                    );
                              },
                              child: const Text('Cancel request'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                ErrorState(
                  message: 'Failed to load withdrawal requests.',
                  onRetry: _loadRequests,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}