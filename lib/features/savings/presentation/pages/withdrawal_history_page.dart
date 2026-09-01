import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_routes.dart';
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
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
                ),
              );
              _loadRequests();
            } else if (state is SavingsFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is SavingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is WithdrawalRequestsLoaded) {
              final requests = state.requests;

              if (requests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 64,
                        color: theme.hintColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No withdrawal requests yet.',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.push(AppRoutes.savingsWithdraw),
                        child: const Text('Request Withdrawal'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return WithdrawalRequestCard(
                    request: req,
                    onCancelTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cancel Request?'),
                          content: const Text(
                            'Are you sure you want to cancel this withdrawal request?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('No, Keep'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.read<SavingsBloc>().add(
                                      CancelWithdrawalRequested(
                                        withdrawalRequestId: req.id,
                                      ),
                                    );
                              },
                              child: const Text('Yes, Cancel'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            }

            return Center(
              child: ElevatedButton(
                onPressed: _loadRequests,
                child: const Text('Reload Requests'),
              ),
            );
          },
        ),
      ),
    );
  }
}
