import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/custom_app_bar.dart';
import 'package:ufg/core/widgets/error_state.dart';
import 'package:ufg/core/widgets/loading_indicator.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_bloc.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_event.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_state.dart';
import 'package:ufg/features/loans/presentation/widgets/guarantor_request_card.dart';
import 'package:ufg/features/loans/domain/entities/guarantor_request_entity.dart';

class GuarantorRequestsPage extends StatefulWidget {
  const GuarantorRequestsPage({super.key});

  @override
  State<GuarantorRequestsPage> createState() => _GuarantorRequestsPageState();
}

class _GuarantorRequestsPageState extends State<GuarantorRequestsPage> {
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    context.read<LoanBloc>().add(LoadGuarantorRequestsRequested());
  }

  void _confirmResponse(GuarantorRequestEntity request, bool accept) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          accept ? 'Accept Guarantee Request' : 'Decline Guarantee Request',
        ),
        content: Text(
          accept
              ? 'By accepting, you electronically agree to act as guarantor. If the borrower defaults, eligible savings may be utilized. You cannot guarantee another outsider loan while this is active.'
              : 'Are you sure you want to decline this guarantee request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<LoanBloc>().add(
                RespondToGuarantorRequestEvent(
                  guarantorRequestId: request.id,
                  borrowerType: request.borrowerType.name,
                  accept: accept,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accept
                  ? Theme.of(context).primaryColor
                  : ColorConstants.error,
              foregroundColor: Colors.white,
            ),
            child: Text(accept ? 'Confirm Accept' : 'Decline'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Guarantor Requests',
        fallbackRoute: AppRoutes.loans,
        actions: [
          IconButton(
            icon: Icon(AppIcons.refresh.outline, size: AppSizes.iconM),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: BlocConsumer<LoanBloc, LoanState>(
        listener: (context, state) {
          if (state is LoanActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: ColorConstants.success,
              ),
            );
            _refresh();
          } else if (state is LoanFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: ColorConstants.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is LoanLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (state is LoanFailure) {
            return ErrorState(
              title: 'Unable to load guarantor requests',
              message: state.message,
              onRetry: _refresh,
            );
          }

          if (state is GuarantorRequestsLoaded) {
            final requests = state.requests;

            if (requests.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.screenPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        AppIcons.shield.outline,
                        size: 48,
                        color: theme.hintColor,
                      ),
                      const SizedBox(height: AppSizes.spacingM),
                      Text(
                        'No Guarantor Requests',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingS),
                      Text(
                        'When an outsider borrower requests you as their guarantor, the request will appear here for your review.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return GuarantorRequestCard(
                    request: req,
                    onAccept: req.isPending
                        ? () => _confirmResponse(req, true)
                        : null,
                    onReject: req.isPending
                        ? () => _confirmResponse(req, false)
                        : null,
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
