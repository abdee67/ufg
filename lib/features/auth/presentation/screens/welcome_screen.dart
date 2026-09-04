import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_images.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Smart Savings',
      description: 'Build your financial future\nwith structured monthly savings',
      image: 'assets/images/onboarding1.png',
      color: ColorConstants.brandGreen,
    ),
    OnboardingPage(
      title: 'Flexible Lending',
      description: 'Access member loans with\ncompetitive rates when you need it',
      image: 'assets/images/onboarding2.png',
      color: ColorConstants.navyBlue,
    ),
    OnboardingPage(
      title: 'Community Growth',
      description: 'Join a trusted network of\nmembers growing together financially',
      image: 'assets/images/onboarding3.png',
      color: ColorConstants.brandGreen,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) {
      context.go(AppRoutes.loginScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(color: theme.scaffoldBackgroundColor),
          Column(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingXl,
                    vertical: AppSizes.spacingM,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Hero(
                        tag: 'app-logo',
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.primaryColor,
                              width: 2,
                            ),
                          ),
                          child: Image.asset(
                            AllImages().logo,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                            .animate()
                            .scale(delay: 300.ms)
                            .move(
                              duration: 300.ms,
                              curve: Curves.easeInOut,
                              begin: const Offset(0, 30),
                            ),
                      ),
                      if (_currentPage < _pages.length - 1)
                        TextButton(
                          onPressed: _skipToEnd,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: _pages[_currentPage].color,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ).animate().fadeIn(delay: 500.ms),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index], index);
                  },
                ),
              ),
              _buildBottomNavigation(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, int index) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(flex: 3, child: _buildImageWidget(page.image, page.color)),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                if (_currentPage == index)
                  AnimatedTextKit(
                    key: ValueKey(page.title),
                    animatedTexts: [
                      TyperAnimatedText(
                        page.title,
                        textStyle: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: page.color,
                          height: 1.2,
                        ),
                        speed: const Duration(milliseconds: 100),
                        curve: Curves.easeOut,
                      ),
                    ],
                    isRepeatingAnimation: true,
                    repeatForever: true,
                    displayFullTextOnTap: true,
                    pause: Duration.zero,
                  )
                else
                  Text(
                    page.title,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: page.color,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: AppSizes.spacingM),
                Text(
                  page.description,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String assetPath, Color color) {
    return Container(
      margin: const EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusSheet),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusSheet),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSheet),
              ),
              child: Icon(
                AppIcons.image.outline,
                size: 64,
                color: color,
              ),
            );
          },
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack)
        .move(
          duration: 600.ms,
          curve: Curves.easeInOut,
          begin: const Offset(0, 30),
        );
  }

  Widget _buildBottomNavigation() {
    final isLast = _currentPage == _pages.length - 1;

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingXl),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingXxs,
                ),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentPage == index
                      ? _pages[_currentPage].color
                      : _pages[_currentPage].color.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingXxl),
          PrimaryButton(
            label: isLast ? 'Get Started' : 'Next',
            onPressed: _nextPage,
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
  });
}