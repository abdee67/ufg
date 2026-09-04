import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';

class GreetingHeader extends StatefulWidget {
  const GreetingHeader({super.key});

  @override
  State<GreetingHeader> createState() => _GreetingHeaderState();
}

class _GreetingHeaderState extends State<GreetingHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onGradient = ColorConstants.onBrand;
    final chipColor = onGradient.withValues(alpha: 0.15);
    final chipBorder = onGradient.withValues(alpha: 0.25);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.spacingXl),
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
                    color: ColorConstants.navyBlue.withValues(alpha: 0.3),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacingS,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: chipColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: chipBorder, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getTimeIcon(),
                              color: onGradient,
                              size: AppSizes.iconXs,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Good ${_getTimeGreeting()}!',
                              style: TextStyle(
                                color: onGradient,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: chipColor,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusChip,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(
                            AppIcons.refresh.outline,
                            color: onGradient,
                            size: AppSizes.iconS,
                          ),
                          splashRadius: 20,
                          tooltip: 'Refresh',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingXl),
                  Text(
                    'Unity Finance',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: onGradient,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacingS,
                      vertical: AppSizes.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: chipColor,
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusCard,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppIcons.savings.outline,
                          color: onGradient,
                          size: AppSizes.iconXs,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Save. Borrow. Grow together.',
                          style: TextStyle(
                            fontSize: 14,
                            color: onGradient,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  Row(
                    children: [
                      _QuickStat(
                        icon: AppIcons.verified.outline,
                        label: 'Active Members',
                        value: '100+',
                      ),
                      const SizedBox(width: AppSizes.spacingS),
                      _QuickStat(
                        icon: AppIcons.trendUp.outline,
                        label: 'Total Savings',
                        value: 'ETB 1M+',
                      ),
                      const SizedBox(width: AppSizes.spacingS),
                      _QuickStat(
                        icon: AppIcons.members.outline,
                        label: 'Loans Disbursed',
                        value: '500+',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  IconData _getTimeIcon() {
    final hour = DateTime.now().hour;
    if (hour < 17) return AppIcons.sun.outline;
    return AppIcons.moon.outline;
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final onGradient = ColorConstants.onBrand;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacingS),
        decoration: BoxDecoration(
          color: onGradient.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(
            color: onGradient.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: onGradient, size: AppSizes.iconXs),
            const SizedBox(height: AppSizes.spacingXs),
            Text(
              value,
              style: TextStyle(
                color: onGradient,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: onGradient.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}