import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/utils/formatters.dart';
import 'package:ufg/features/loans/domain/entities/loan_entity.dart';
import 'package:ufg/features/loans/presentation/widgets/loan_status_chip.dart';

class LoanSummaryCard extends StatefulWidget {
  final LoanEntity loan;
  final VoidCallback? onRepayTap;
  final VoidCallback? onDetailsTap;

  const LoanSummaryCard({
    super.key,
    required this.loan,
    this.onRepayTap,
    this.onDetailsTap,
  });

  @override
  State<LoanSummaryCard> createState() => _LoanSummaryCardState();
}

class _LoanSummaryCardState extends State<LoanSummaryCard> {
  bool _hideBalances = true;

  @override
  Widget build(BuildContext context) {
    const onBrand = Colors.white;
    final loan = widget.loan;
    final progress = loan.repaymentProgress;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Slate 900
            Color(0xFF1E293B), // Slate 800
            Color(0xFF134E4A), // Deep Emerald Teal
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Label + Privacy Toggle + Status Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: ColorConstants.brandGreen.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF34D399),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ACTIVE LOAN',
                    style: TextStyle(
                      color: onBrand.withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _hideBalances = !_hideBalances;
                      });
                    },
                    icon: Icon(
                      _hideBalances
                          ? AppIcons.eyeOff.outline
                          : AppIcons.eye.outline,
                      color: onBrand.withValues(alpha: 0.85),
                      size: AppSizes.iconM - 2,
                    ),
                    tooltip: _hideBalances ? 'Show Balances' : 'Hide Balances',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  LoanStatusChip.fromLoanStatus(loan.status),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            'Remaining Outstanding Balance',
            style: TextStyle(
              color: onBrand.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),

          // Main prominent figure
          Text(
            _hideBalances
                ? 'ETB •••••••••'
                : Formatters.money(loan.outstandingBase),
            style: const TextStyle(
              color: onBrand,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 16),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _hideBalances
                        ? 'Paid: ••••'
                        : 'Paid: ${Formatters.money(loan.totalPaid)}',
                    style: TextStyle(
                      color: onBrand.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}% Repaid',
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: onBrand.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    ColorConstants.brandGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Details info box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: onBrand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              border: Border.all(color: onBrand.withValues(alpha: 0.14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan Number',
                      style: TextStyle(
                        color: onBrand.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loan.loanNumber,
                      style: const TextStyle(
                        color: onBrand,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (loan.maturityDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Maturity Date',
                        style: TextStyle(
                          color: onBrand.withValues(alpha: 0.65),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy').format(loan.maturityDate!),
                        style: const TextStyle(
                          color: onBrand,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onRepayTap,
                  icon: const Icon(Icons.payment_rounded, size: 18),
                  label: const Text(
                    'Repay Loan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.brandGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusButton),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacingS),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onDetailsTap,
                  icon: Icon(AppIcons.document.outline, size: 18),
                  label: const Text(
                    'Schedule',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onBrand,
                    side: BorderSide(color: onBrand.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusButton),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
