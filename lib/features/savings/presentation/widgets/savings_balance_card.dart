import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/utils/formatters.dart';

class SavingsBalanceCard extends StatefulWidget {
  final double totalSavings;
  final double availableToWithdraw;
  final double securedSavings;
  final VoidCallback onWithdrawTap;
  final VoidCallback onContributeTap;

  const SavingsBalanceCard({
    super.key,
    required this.totalSavings,
    required this.availableToWithdraw,
    required this.securedSavings,
    required this.onWithdrawTap,
    required this.onContributeTap,
  });

  @override
  State<SavingsBalanceCard> createState() => _SavingsBalanceCardState();
}

class _SavingsBalanceCardState extends State<SavingsBalanceCard> {
  bool _hideBalances = true;

  @override
  Widget build(BuildContext context) {
    const onBrand = Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spacingL),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Label + Privacy Toggle
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
                    'TOTAL SAVINGS BALANCE',
                    style: TextStyle(
                      color: onBrand.withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _hideBalances = !_hideBalances;
                  });
                },
                icon: Icon(
                  _hideBalances ? AppIcons.eyeOff.outline : AppIcons.eye.outline,
                  color: onBrand.withValues(alpha: 0.85),
                  size: AppSizes.iconM - 2,
                ),
                tooltip: _hideBalances ? 'Show Balances' : 'Hide Balances',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main prominent figure
          Text(
            _hideBalances
                ? 'ETB •••••••••'
                : Formatters.money(widget.totalSavings),
            style: const TextStyle(
              color: onBrand,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 20),

          // Divider
          Container(
            height: 1,
            color: onBrand.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 16),

          // Sub-metrics breakdown
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Available to Withdraw',
                      style: TextStyle(
                        color: onBrand.withValues(alpha: 0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hideBalances
                          ? '••••••'
                          : Formatters.money(widget.availableToWithdraw),
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: onBrand.withValues(alpha: 0.15),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Secured for Loans',
                      style: TextStyle(
                        color: onBrand.withValues(alpha: 0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hideBalances
                          ? '••••••'
                          : Formatters.money(widget.securedSavings),
                      style: const TextStyle(
                        color: onBrand,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onContributeTap,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Save Money',
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
              const SizedBox(width: AppSizes.spacingM),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.availableToWithdraw > 0
                      ? widget.onWithdrawTap
                      : null,
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                  label: const Text(
                    'Withdraw',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onBrand,
                    disabledForegroundColor: onBrand.withValues(alpha: 0.38),
                    side: BorderSide(
                      color: widget.availableToWithdraw > 0
                          ? onBrand.withValues(alpha: 0.6)
                          : onBrand.withValues(alpha: 0.24),
                    ),
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
