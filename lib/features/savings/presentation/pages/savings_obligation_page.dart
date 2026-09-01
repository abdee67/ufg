import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_routes.dart';
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadObligations(),
        child: BlocBuilder<SavingsBloc, SavingsState>(
          builder: (context, state) {
            if (state is SavingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SavingsObligationsLoaded) {
              final obligations = state.obligations;

              if (obligations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available_rounded, size: 64, color: theme.hintColor),
                      const SizedBox(height: 16),
                      Text(
                        'No savings obligations found.',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: obligations.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
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

            return Center(
              child: ElevatedButton(
                onPressed: _loadObligations,
                child: const Text('Reload Obligations'),
              ),
            );
          },
        ),
      ),
    );
  }
}
