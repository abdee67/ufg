import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/utils/formatters.dart';

class SavingsBalanceCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final onGradient = ColorConstants.onBrand;
    final onGradientSoft = onGradient.withValues(alpha: 0.7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spacingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstants.navGradientStart,
            ColorConstants.navGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.navyBlue.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    AppIcons.savings.outline,
                    color: onGradientSoft,
                    size: AppSizes.iconS - 2,
                  ),
                  const SizedBox(width: AppSizes.spacingXs),
                  Text(
                    'TOTAL SAVINGS',
                    style: TextStyle(
                      color: onGradientSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingS),
          Text(
            Formatters.money(totalSavings),
            style: TextStyle(
              color: onGradient,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSizes.spacingL),
          Container(
            padding: const EdgeInsets.all(AppSizes.spacingS + 2),
            decoration: BoxDecoration(
              color: onGradient.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              border: Border.all(color: onGradient.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            AppIcons.check.outline,
                            color: onGradientSoft,
                            size: 14,
                          ),
                          const SizedBox(width: AppSizes.spacingXxs),
                          Expanded(
                            child: Text(
                              'Available to Withdraw',
                              style: TextStyle(
                                color: onGradientSoft,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spacingXxs),
                      Text(
                        Formatters.money(availableToWithdraw),
                        style: TextStyle(
                          color: onGradient,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: onGradient.withValues(alpha: 0.25),
                ),
                const SizedBox(width: AppSizes.spacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            AppIcons.lock.outline,
                            color: onGradientSoft,
                            size: 14,
                          ),
                          const SizedBox(width: AppSizes.spacingXxs),
                          Expanded(
                            child: Text(
                              'Secured for Loans',
                              style: TextStyle(
                                color: onGradientSoft,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spacingXxs),
                      Text(
                        Formatters.money(securedSavings),
                        style: TextStyle(
                          color: onGradient,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacingL),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onContributeTap,
                  icon: Icon(
                    AppIcons.moneySend.outline,
                    size: AppSizes.iconS - 2,
                  ),
                  label: const Text(
                    'Save Money',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: onGradient,
                    foregroundColor: ColorConstants.navyBlue,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.spacingS,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusChip + 6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacingS),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: availableToWithdraw > 0 ? onWithdrawTap : null,
                  icon: Icon(
                    AppIcons.arrowUp.outline,
                    size: AppSizes.iconS - 2,
                  ),
                  label: const Text(
                    'Withdraw',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onGradient,
                    disabledForegroundColor: onGradient.withValues(alpha: 0.38),
                    side: BorderSide(
                      color: availableToWithdraw > 0
                          ? onGradient.withValues(alpha: 0.7)
                          : onGradient.withValues(alpha: 0.24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.spacingS,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusChip + 6,
                      ),
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
