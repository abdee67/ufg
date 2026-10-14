import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_images.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  late final AnimationController _floatController;
  late final Animation<double> _floatOffset;

  late final List<OnboardingPage> _pages = [
    OnboardingPage(
      eyebrow: 'YOUR GOALS, ONE PLAN',
      title: 'Save with\npurpose.',
      description:
          'Build a steady saving habit, follow your progress, and take small steps toward a stronger financial future.',
      color: ColorConstants.brandGreen,
      icon: Icons.savings_outlined,
      insightTitle: 'Small steps add up',
      insightDescription: 'Make progress at your own pace',
    ),
    OnboardingPage(
      eyebrow: 'SUPPORT WHEN IT MATTERS',
      title: 'Borrow with\nconfidence.',
      description:
          'Explore member-focused loans and keep your balances and repayments easier to understand.',
      color: ColorConstants.navyBlue,
      icon: Icons.account_balance_wallet_outlined,
      insightTitle: 'Clarity at every step',
      insightDescription: 'Know what you owe and why',
    ),
    OnboardingPage(
      eyebrow: 'BETTER, TOGETHER',
      title: 'Grow as\none community.',
      description:
          'Stay connected to your SACCO and build a shared future with trust, transparency, and teamwork.',
      color: ColorConstants.brandGreen,
      icon: Icons.groups_2_outlined,
      insightTitle: 'Community comes first',
      insightDescription: 'Progress is better when shared',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatOffset = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    if (_currentPage == page) return;
    setState(() => _currentPage = page);
  }

  void _nextPage() {
    if (_isCompleting) return;

    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);
      if (mounted) context.go(AppRoutes.loginScreen);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCompleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your progress. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers that derive colors from the theme so light/dark mode "just works".
  // ---------------------------------------------------------------------------

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Surface used for cards and chips inside the illustration area.
  Color _cardSurface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// A subtle tint of [base] appropriate for the current brightness.
  Color _subtleTint(BuildContext context, Color base, [double amount = 0.10]) =>
      _isDark(context)
          ? base.withValues(alpha: amount * 0.7)
          : base.withValues(alpha: amount);

  /// Primary text color from the theme.
  Color _primaryText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// Secondary / muted text color from the theme.
  Color _secondaryText(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyLarge?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.6);
  }

  /// Border color that adapts to the brightness.
  Color _borderColor(BuildContext context) => Theme.of(context).dividerColor;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding - 4,
            10,
            AppSizes.screenPadding - 4,
            14,
          ),
          child: Column(
            children: [
              _buildHeader(page),
              const SizedBox(height: AppSizes.spacingXs),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) =>
                      _buildPage(_pages[index], index),
                ),
              ),
              const SizedBox(height: AppSizes.spacingXs),
              _buildBottomNavigation(page),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(OnboardingPage page) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 54,
      child: Row(
        children: [
          Hero(
            tag: 'app-logo',
            child:
                Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage(AllImages.logo),
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 450.ms)
                    .scale(
                      begin: const Offset(0.86, 0.86),
                      curve: Curves.easeOutBack,
                      duration: 500.ms,
                    ),
          ),
          const SizedBox(width: AppSizes.spacingS),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unity Finance Group',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.05,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Saving today. Growing tomorrow.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _currentPage < _pages.length - 1
                ? TextButton(
                    key: const ValueKey('skip'),
                    onPressed: _skipToEnd,
                    style: TextButton.styleFrom(
                      foregroundColor: page.color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: AppSizes.spacingXs,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  )
                : const SizedBox(
                    key: ValueKey('skip-placeholder'),
                    width: AppSizes.spacingS,
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page layout
  // ---------------------------------------------------------------------------

  Widget _buildPage(OnboardingPage page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Column(
        children: [
          Expanded(flex: 6, child: _buildIllustration(page, index)),
          const SizedBox(height: AppSizes.spacingXs),
          Expanded(flex: 5, child: _buildTextContent(page, index)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Illustration container
  // ---------------------------------------------------------------------------

  Widget _buildIllustration(OnboardingPage page, int index) {
    final dark = _isDark(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child:
                Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 7),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusSheet + 2),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: dark
                              ? [
                                  Color.lerp(
                                    page.color,
                                    Colors.black,
                                    0.82,
                                  )!,
                                  _cardSurface(context),
                                  Color.lerp(
                                    page.color,
                                    Colors.black,
                                    0.88,
                                  )!,
                                ]
                              : [
                                  Color.lerp(
                                    page.color,
                                    Colors.white,
                                    0.89,
                                  )!,
                                  _cardSurface(
                                    context,
                                  ).withValues(alpha: 0.94),
                                  Color.lerp(
                                    page.color,
                                    Colors.white,
                                    0.95,
                                  )!,
                                ],
                        ),
                        border: Border.all(
                          color: _borderColor(context),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: page.color.withValues(
                              alpha: dark ? 0.18 : 0.10,
                            ),
                            blurRadius: 28,
                            offset: const Offset(0, 13),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          // Decorative orbs
                          Positioned(
                            top: -42,
                            right: -26,
                            child: _decorativeOrb(
                              size: constraints.maxHeight * 0.56,
                              color: _subtleTint(context, page.color, 0.09),
                            ),
                          ),
                          Positioned(
                            left: -34,
                            bottom: -54,
                            child: _decorativeOrb(
                              size: constraints.maxHeight * 0.48,
                              color: _subtleTint(context, page.color, 0.07),
                            ),
                          ),
                          // Hero artwork
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                30,
                                14,
                                AppSizes.screenPadding,
                              ),
                              child: _buildHeroArtwork(page, index),
                            ),
                          ),
                          // Badge chip
                          Positioned(
                            top: 15,
                            left: 15,
                            child:
                                Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 11,
                                        vertical: AppSizes.spacingXs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _cardSurface(
                                          context,
                                        ).withValues(alpha: 0.92),
                                        borderRadius:
                                            BorderRadius.circular(30),
                                        border: Border.all(
                                          color: _borderColor(context),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.auto_awesome_rounded,
                                            size: 13,
                                            color: page.color,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'MEMBER FIRST',
                                            style: TextStyle(
                                              color: page.color,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .animate(
                                      key: ValueKey(
                                        'badge-${page.title}',
                                      ),
                                    )
                                    .fadeIn(
                                      duration: 420.ms,
                                      delay: 120.ms,
                                    )
                                    .slideX(
                                      begin: -0.08,
                                      end: 0,
                                      curve: Curves.easeOutCubic,
                                    ),
                          ),
                          // Insight card
                          Positioned(
                            right: AppSizes.spacingS,
                            bottom: 13,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 228,
                              ),
                              child: AnimatedBuilder(
                                animation: _floatOffset,
                                builder: (context, child) =>
                                    Transform.translate(
                                      offset: Offset(
                                        0,
                                        _floatOffset.value,
                                      ),
                                      child: child,
                                    ),
                                child: _buildInsightCard(page),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate(key: ValueKey('artwork-${page.title}'))
                    .fadeIn(duration: 560.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      duration: 620.ms,
                      curve: Curves.easeOutBack,
                    )
                    .slideY(
                      begin: 0.04,
                      end: 0,
                      duration: 560.ms,
                      curve: Curves.easeOutCubic,
                    ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Hero artworks (vector-style, no raster assets)
  // ---------------------------------------------------------------------------

  Widget _buildHeroArtwork(OnboardingPage page, int index) {
    switch (index) {
      case 0:
        return _buildSavingsArtwork(page);
      case 1:
        return _buildLoanArtwork(page);
      default:
        return _buildCommunityArtwork(page);
    }
  }

  Widget _buildSavingsArtwork(OnboardingPage page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth * 0.76)
            .clamp(155.0, 245.0)
            .toDouble();
        final cardHeight = (constraints.maxHeight * 0.76)
            .clamp(135.0, 190.0)
            .toDouble();

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Container(
                width: cardWidth,
                height: cardHeight,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _cardSurface(context),
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: _borderColor(context),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _subtleTint(context, page.color),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 31,
                          height: 31,
                          decoration: BoxDecoration(
                            color: _subtleTint(context, page.color),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusChip + 2),
                          ),
                          child: Icon(
                            Icons.savings_rounded,
                            color: page.color,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'SAVINGS WALLET',
                            maxLines: 1,
                            style: TextStyle(
                              color: _secondaryText(context),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.more_horiz_rounded,
                          color: _secondaryText(
                            context,
                          ).withValues(alpha: 0.5),
                          size: 19,
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Text(
                      'Little by little,',
                      style: TextStyle(
                        color: _primaryText(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'you move forward.',
                      style: TextStyle(
                        color: _primaryText(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final bar in [0.36, 0.52, 0.43, 0.72, 0.61, 0.90])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: TweenAnimationBuilder<double>(
                                key: ValueKey('saving-bar-$bar'),
                                tween: Tween(begin: 0.18, end: bar),
                                duration: Duration(
                                  milliseconds: 550 + (bar * 400).round(),
                                ),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) => Container(
                                  height: (cardHeight * 0.18) * value,
                                  decoration: BoxDecoration(
                                    color: Color.lerp(
                                      _subtleTint(
                                        context,
                                        page.color,
                                        0.20,
                                      ),
                                      page.color,
                                      value,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: constraints.maxHeight * 0.09,
              left: constraints.maxWidth * 0.015,
              child: _animatedArtworkChip(
                icon: Icons.trending_up_rounded,
                label: 'Keep growing',
                color: page.color,
                compact: true,
              ),
            ),
            Positioned(
              right: constraints.maxWidth * 0.015,
              bottom: constraints.maxHeight * 0.08,
              child: _animatedArtworkChip(
                icon: Icons.check_circle_rounded,
                label: 'Habit in progress',
                color: const Color(0xFF27845C),
                compact: true,
                reverseFloat: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoanArtwork(OnboardingPage page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth * 0.75)
            .clamp(155.0, 245.0)
            .toDouble();
        final cardHeight = (constraints.maxHeight * 0.76)
            .clamp(135.0, 190.0)
            .toDouble();

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Container(
                width: cardWidth,
                height: cardHeight,
                padding: const EdgeInsets.all(AppSizes.spacingS),
                decoration: BoxDecoration(
                  color: _cardSurface(context),
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: _borderColor(context),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _subtleTint(context, page.color, 0.11),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 37,
                          height: 37,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _subtleTint(context, page.color, 0.16),
                                _subtleTint(context, page.color, 0.06),
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusS),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: page.color,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MEMBER LOAN',
                                style: TextStyle(
                                  color: _secondaryText(context),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Support when it matters',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _primaryText(context),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final lineWidth in [0.92, 0.70, 0.82])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: FractionallySizedBox(
                          widthFactor: lineWidth,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: _isDark(context)
                                  ? _primaryText(
                                      context,
                                    ).withValues(alpha: 0.08)
                                  : const Color(0xFFE9EEF0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spacingXs,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _isDark(context)
                            ? ColorConstants.successSubtleDark
                            : ColorConstants.successSubtle,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusChip + 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: _isDark(context)
                                ? ColorConstants.brandGreen
                                : const Color(0xFF27845C),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Clear and transparent',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _isDark(context)
                                    ? ColorConstants.brandGreen
                                    : const Color(0xFF26734F),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: constraints.maxHeight * 0.08,
              right: constraints.maxWidth * 0.01,
              child: _animatedArtworkChip(
                icon: Icons.shield_outlined,
                label: 'Member first',
                color: page.color,
                compact: true,
              ),
            ),
            Positioned(
              left: constraints.maxWidth * 0.005,
              bottom: constraints.maxHeight * 0.08,
              child: _animatedArtworkChip(
                icon: Icons.handshake_rounded,
                label: 'Here for you',
                color: const Color(0xFF27845C),
                compact: true,
                reverseFloat: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommunityArtwork(OnboardingPage page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final centerSize = (constraints.maxHeight * 0.47)
            .clamp(82.0, 126.0)
            .toDouble();
        final bubbleSize = (constraints.maxHeight * 0.23)
            .clamp(43.0, 62.0)
            .toDouble();

        Widget memberBubble(IconData icon, Color color) {
          return AnimatedBuilder(
            animation: _floatOffset,
            builder: (context, child) => Transform.translate(
              offset: Offset(
                0,
                _floatOffset.value * (color == page.color ? 0.65 : 0.9),
              ),
              child: child,
            ),
            child: Container(
              width: bubbleSize,
              height: bubbleSize,
              decoration: BoxDecoration(
                color: _cardSurface(context),
                shape: BoxShape.circle,
                border: Border.all(color: _borderColor(context), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _subtleTint(context, color, 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: bubbleSize * 0.72,
                  height: bubbleSize * 0.72,
                  decoration: BoxDecoration(
                    color: _subtleTint(context, color, 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: bubbleSize * 0.39, color: color),
                ),
              ),
            ),
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Orbit ring
            Center(
              child: Container(
                width: centerSize * 1.65,
                height: centerSize * 1.65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _subtleTint(context, page.color, 0.13),
                    width: 1.2,
                  ),
                ),
              ),
            ),
            // Center icon
            Center(
              child:
                  Container(
                        width: centerSize,
                        height: centerSize,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              page.color,
                              Color.lerp(page.color, Colors.black, 0.12)!,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: page.color.withValues(alpha: 0.25),
                              blurRadius: 27,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.groups_rounded,
                          size: centerSize * 0.46,
                          color: Colors.white,
                        ),
                      )
                      .animate(key: const ValueKey('community-center'))
                      .scale(
                        begin: const Offset(0.88, 0.88),
                        duration: 650.ms,
                        curve: Curves.easeOutBack,
                      ),
            ),
            // Member bubbles
            Positioned(
              top: constraints.maxHeight * 0.07,
              left: constraints.maxWidth * 0.17,
              child: memberBubble(
                Icons.person_rounded,
                const Color(0xFF3B82A0),
              ),
            ),
            Positioned(
              top: constraints.maxHeight * 0.16,
              right: constraints.maxWidth * 0.12,
              child: memberBubble(
                Icons.person_rounded,
                const Color(0xFFCE9450),
              ),
            ),
            Positioned(
              bottom: constraints.maxHeight * 0.08,
              left: constraints.maxWidth * 0.13,
              child: memberBubble(
                Icons.person_rounded,
                const Color(0xFF27845C),
              ),
            ),
            Positioned(
              bottom: constraints.maxHeight * 0.06,
              right: constraints.maxWidth * 0.17,
              child: memberBubble(
                Icons.person_rounded,
                const Color(0xFF8171BB),
              ),
            ),
            Positioned(
              top: constraints.maxHeight * 0.01,
              right: constraints.maxWidth * 0.40,
              child: _animatedArtworkChip(
                icon: Icons.favorite_rounded,
                label: 'Together',
                color: page.color,
                compact: true,
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Shared artwork widgets
  // ---------------------------------------------------------------------------

  Widget _animatedArtworkChip({
    required IconData icon,
    required String label,
    required Color color,
    bool compact = false,
    bool reverseFloat = false,
  }) {
    return AnimatedBuilder(
          animation: _floatOffset,
          builder: (context, child) => Transform.translate(
            offset:
                Offset(0, _floatOffset.value * (reverseFloat ? -0.8 : 0.8)),
            child: child,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 9 : 11,
              vertical: compact ? 7 : 9,
            ),
            decoration: BoxDecoration(
              color: _cardSurface(context).withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor(context), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: _subtleTint(context, color, 0.12),
                  blurRadius: 17,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: compact ? 14 : 17),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: _primaryText(context),
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 420.ms)
        .scale(
          begin: const Offset(0.90, 0.90),
          duration: 520.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _decorativeOrb({required double size, required Color color}) {
    return Container(
      width: size.clamp(70.0, 250.0).toDouble(),
      height: size.clamp(70.0, 250.0).toDouble(),
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildInsightCard(OnboardingPage page) {
    return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingS,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: _cardSurface(context).withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _borderColor(context), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: _subtleTint(context, page.color, 0.10),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: _subtleTint(context, page.color),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusChip + 3),
                ),
                child: Icon(page.icon, color: page.color, size: 19),
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      page.insightTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      page.insightDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _secondaryText(context),
                        fontWeight: FontWeight.w500,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(key: ValueKey('insight-${page.title}'))
        .fadeIn(duration: 420.ms, delay: 220.ms)
        .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
  }

  // ---------------------------------------------------------------------------
  // Text content
  // ---------------------------------------------------------------------------

  Widget _buildTextContent(OnboardingPage page, int index) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width < 360 ? 29.0 : 33.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Eyebrow
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                page.eyebrow,
                key: ValueKey('eyebrow-$index'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: page.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
            ),
            const SizedBox(height: 9),
            // Title
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.10),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                page.title,
                key: ValueKey('title-${page.title}'),
                textAlign: TextAlign.center,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: titleSize,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.9,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacingS),
            // Description
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              child: Padding(
                key: ValueKey('description-${page.title}'),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  page.description,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 13.5,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom navigation
  // ---------------------------------------------------------------------------

  Widget _buildBottomNavigation(OnboardingPage page) {
    final isLast = _currentPage == _pages.length - 1;
    final pageCount = _pages.length.toString().padLeft(2, '0');
    final currentCount = (_currentPage + 1).toString().padLeft(2, '0');

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Page dots
              Row(
                children: List.generate(_pages.length, (index) {
                  final isActive = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(right: 6),
                    width: isActive ? 26 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isActive
                          ? page.color
                          : _subtleTint(context, page.color, 0.20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }),
              ),
              const Spacer(),
              // Counter
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  '$currentCount / $pageCount',
                  key: ValueKey(currentCount),
                  style: TextStyle(
                    color: _secondaryText(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // CTA button
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight + 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusButton + 1),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    page.color,
                    Color.lerp(page.color, Colors.black, 0.12)!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: page.color.withValues(alpha: 0.24),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isCompleting ? null : _nextPage,
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusButton + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.screenPadding - 5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.15),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: Text(
                            _isCompleting
                                ? 'Getting things ready…'
                                : isLast
                                ? 'Get started'
                                : 'Continue',
                            key: ValueKey(
                              'cta-$_currentPage-$_isCompleting',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.15,
                            ),
                          ),
                        ),
                        Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.17),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusS),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                            ),
                          ),
                          child: _isCompleting
                              ? const Padding(
                                  padding: EdgeInsets.all(9),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isLast
                                      ? Icons.arrow_forward_rounded
                                      : Icons.east_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.10, end: 0),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String eyebrow;
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final String insightTitle;
  final String insightDescription;

  const OnboardingPage({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.insightTitle,
    required this.insightDescription,
  });
}