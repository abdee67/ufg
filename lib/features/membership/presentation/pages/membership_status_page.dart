import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
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
            icon: const Icon(Icons.refresh_rounded),
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
              ),
            );
          } else if (state is MembershipOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.primary,
              ),
            );
            _refreshStatus();
          }
        },
        builder: (context, state) {
          if (state is MembershipLoading && state is! MembershipStatusLoaded) {
            return const Center(child: CircularProgressIndicator());
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

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Unable to load membership status.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _refreshStatus,
                  child: const Text('Retry'),
                ),
              ],
            ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding,
        vertical: 24,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
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
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Icon(Icons.verified_rounded, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  member.memberNumber,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Membership Date',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy').format(member.membershipDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.greenAccent),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.dashboard_rounded),
              label: const Text('Go to Member Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => context.go(AppRoutes.homeScreen),
            ),
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
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Application Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Application #${application.applicationNumber}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _statusBadge(status, colorScheme),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Submitted on: ${DateFormat('dd MMM yyyy, hh:mm a').format(application.submittedAt)}',
                  style: theme.textTheme.bodySmall,
                ),
                if (isRejected && application.rejectionReason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.error),
                    ),
                    child: Text(
                      'Rejection reason: ${application.rejectionReason}',
                      style: TextStyle(color: colorScheme.error, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Process Timeline
          Text(
            'Application Process',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

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

          const SizedBox(height: 32),

          if (isRejected || isCancelled) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.membershipApply),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Submit New Application'),
              ),
            ),
          ] else if (!isApproved) ...[
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancel Application'),
                style: TextButton.styleFrom(foregroundColor: colorScheme.error),
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Membership Application',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You are currently a Non-Member. Apply now to unlock savings accounts and loan features.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.membershipApply),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply for Membership'),
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
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case MembershipApplicationStatus.approved:
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green;
        label = 'Approved';
        break;
      case MembershipApplicationStatus.underReview:
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue;
        label = 'Under Review';
        break;
      case MembershipApplicationStatus.rejected:
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red;
        label = 'Rejected';
        break;
      case MembershipApplicationStatus.cancelled:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey;
        label = 'Cancelled';
        break;
      case MembershipApplicationStatus.draft:
        bg = Colors.purple.withValues(alpha: 0.15);
        fg = Colors.purple;
        label = 'Draft';
        break;
      case MembershipApplicationStatus.submitted:
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange;
        label = 'Submitted';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
        ? Colors.green
        : (isActive ? colorScheme.primary : Colors.grey.shade400);

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
                      ? Icons.check
                      : (isActive ? Icons.sync : Icons.circle_outlined),
                  size: 16,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? Colors.green : Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall,
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
