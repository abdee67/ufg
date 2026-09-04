import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/app_card.dart';
import 'package:ufg/core/widgets/error_state.dart';
import 'package:ufg/core/widgets/loading_indicator.dart';
import 'package:ufg/core/widgets/primary_button.dart';
import 'package:ufg/core/widgets/status_chip.dart';
import 'package:ufg/features/membership/domain/entities/member_entity.dart';
import 'package:ufg/features/membership/domain/entities/membership_application_entity.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_bloc.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_event.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_state.dart';

class MembershipStatusPage extends StatefulWidget {
  const MembershipStatusPage({super.key});

  @override
  State<MembershipStatusPage> createState() => _MembershipStatusPageState();
}

class _MembershipStatusPageState extends State<MembershipStatusPage> {
  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  void _refreshStatus() {
    context.read<MembershipBloc>().add(LoadMembershipStatusRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Membership Status'),
        actions: [
          IconButton(
            icon: Icon(AppIcons.refresh.outline, size: AppSizes.iconM),
            onPressed: _refreshStatus,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocConsumer<MembershipBloc, MembershipState>(
        listener: (context, state) {
          if (state is MembershipFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is MembershipOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _refreshStatus();
          }
        },
        builder: (context, state) {
          if (state is MembershipLoading && state is! MembershipStatusLoaded) {
            return ListView(
              physics: AlwaysScrollableScrollPhysics(),
              children: [SizedBox(height: 120), LoadingIndicator()],
            );
          }

          if (state is MembershipStatusLoaded) {
            if (state.isActiveMember) {
              return _buildApprovedMemberView(
                state.member!,
                theme,
                colorScheme,
              );
            }

            if (state.application != null) {
              return _buildApplicationStatusView(
                state.application!,
                theme,
                colorScheme,
              );
            }

            return _buildNoApplicationView(theme, colorScheme);
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ErrorState(
                message: 'Unable to load membership status.',
                onRetry: _refreshStatus,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildApprovedMemberView(
    MemberEntity member,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final onGradient = ColorConstants.onBrand;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding,
        vertical: AppSizes.spacingXl,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.spacingXl),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  ColorConstants.navGradientStart,
                  ColorConstants.navGradientEnd,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.navyBlue.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACTIVE MEMBER',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: onGradient.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Icon(
                      AppIcons.verified.outline,
                      color: onGradient,
                      size: AppSizes.iconM,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingL),
                Text(
                  member.memberNumber,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: onGradient,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Membership Date',
                          style: TextStyle(
                            color: onGradient.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'dd MMM yyyy',
                          ).format(member.membershipDate),
                          style: TextStyle(
                            color: onGradient,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: AppSizes.spacingXxs,
                      ),
                      decoration: BoxDecoration(
                        color: onGradient.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        border: Border.all(
                          color: onGradient.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.check.outline,
                            color: onGradient,
                            size: AppSizes.iconXs - 2,
                          ),
                          const SizedBox(width: AppSizes.spacingXxs),
                          Text(
                            'Active',
                            style: TextStyle(
                              color: onGradient,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacingXxl),
          PrimaryButton(
            label: 'Go to Member Dashboard',
            icon: AppIcons.home.outline,
            onPressed: () => context.go(AppRoutes.homeScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationStatusView(
    MembershipApplicationEntity application,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final status = application.status;
    final isRejected = status == MembershipApplicationStatus.rejected;
    final isCancelled = status == MembershipApplicationStatus.cancelled;
    final isApproved = status == MembershipApplicationStatus.approved;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding,
        vertical: AppSizes.spacingL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: AppSizes.spacingL,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isApproved
                            ? 'Application Approved'
                            : (isRejected || isCancelled
                                ? 'Application Closed'
                                : 'Application Under Review'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _statusBadge(status, colorScheme),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingS),
                Text(
                  'Submitted on: ${DateFormat('dd MMM yyyy, hh:mm a').format(application.submittedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (isRejected && application.rejectionReason != null) ...[
                  const SizedBox(height: AppSizes.spacingS),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.spacingS),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusChip),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          AppIcons.warning.outline,
                          color: colorScheme.error,
                          size: AppSizes.iconS - 2,
                        ),
                        const SizedBox(width: AppSizes.spacingXs),
                        Expanded(
                          child: Text(
                            'Rejection reason: ${application.rejectionReason}',
                            style: TextStyle(
                              color: colorScheme.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacingXl),
          Text(
            'Application Process',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          _timelineStep(
            title: '1. Application & KYC Submitted',
            subtitle:
                'Your profile and Fayda identity document have been received.',
            isDone: true,
            isActive: false,
            colorScheme: colorScheme,
            theme: theme,
          ),
          _timelineStep(
            title: '2. Under Review & Verification',
            subtitle:
                'Unity Finance authorized staff are verifying your identity document.',
            isDone: isApproved,
            isActive: status == MembershipApplicationStatus.submitted ||
                status == MembershipApplicationStatus.underReview,
            colorScheme: colorScheme,
            theme: theme,
          ),
          _timelineStep(
            title: '3. Member Account Activation',
            subtitle:
                'Atomic activation of membership and financial capabilities.',
            isDone: isApproved,
            isActive: false,
            colorScheme: colorScheme,
            theme: theme,
            isLast: true,
          ),
          const SizedBox(height: AppSizes.spacingXxl),
          if (isRejected || isCancelled) ...[
            PrimaryButton(
              label: 'Submit New Application',
              onPressed: () => context.go(AppRoutes.membershipApply),
            ),
          ] else if (!isApproved) ...[
            Center(
              child: TextButton.icon(
                icon: Icon(
                  AppIcons.close.outline,
                  size: AppSizes.iconS - 2,
                ),
                label: const Text('Cancel Application'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
                onPressed: () {
                  context.read<MembershipBloc>().add(
                    CancelMembershipApplicationRequested(
                      applicationId: application.id,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoApplicationView(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingXl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.loans.outline,
                size: 32,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingM),
            Text(
              'No Active Membership Application',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingXs),
            Text(
              'You are currently a Non-Member. Apply now to unlock savings accounts and loan features.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingXl),
            PrimaryButton(
              label: 'Apply for Membership',
              width: 240,
              onPressed: () => context.go(AppRoutes.membershipApply),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(
    MembershipApplicationStatus status,
    ColorScheme colorScheme,
  ) {
    final (StatusTone tone, String label, IconData icon) = switch (status) {
      MembershipApplicationStatus.approved => (
        StatusTone.success,
        'Approved',
        AppIcons.check.outline,
      ),
      MembershipApplicationStatus.underReview => (
        StatusTone.info,
        'Under Review',
        AppIcons.history.outline,
      ),
      MembershipApplicationStatus.rejected => (
        StatusTone.error,
        'Rejected',
        AppIcons.close.outline,
      ),
      MembershipApplicationStatus.cancelled => (
        StatusTone.neutral,
        'Cancelled',
        AppIcons.close.outline,
      ),
      MembershipApplicationStatus.draft => (
        StatusTone.neutral,
        'Draft',
        AppIcons.edit.outline,
      ),
      MembershipApplicationStatus.submitted => (
        StatusTone.warning,
        'Submitted',
        AppIcons.calendar.outline,
      ),
    };

    return StatusChip(label: label, tone: tone, icon: icon);
  }

  Widget _timelineStep({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    required ColorScheme colorScheme,
    required ThemeData theme,
    bool isLast = false,
  }) {
    Color iconBg = isDone
        ? ColorConstants.success
        : (isActive
            ? colorScheme.primary
            : colorScheme.onSurface.withValues(alpha: 0.25));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDone
                      ? AppIcons.check.outline
                      : (isActive
                          ? AppIcons.refresh.outline
                          : AppIcons.info.outline),
                  size: AppSizes.iconXs,
                  color: ColorConstants.onBrand,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone
                        ? ColorConstants.success
                        : theme.dividerColor,
                    margin: const EdgeInsets.symmetric(
                      vertical: AppSizes.spacingXxs,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spacingXl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isActive ? colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingXxs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}