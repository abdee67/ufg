class AppRoutes {
  static const String initialRoute = '/';
  static const String onboardingScreen = '/onboarding';
  static const String loginScreen = '/login';
  static const String signupScreen = '/signup';
  static const String forgotPasswordScreen = '/forgot-password';
  static const String resetPasswordScreen = '/reset-password';
  static const String homeScreen = '/home';
  static const String searchScreen = '/search';
  static const String locationScreen = '/location';
  static const String chat = '/chat';
  static const String payment = '/payment';
  static const String paymentSuccess = '/payment-success';
  static const String profile = '/profile';
  static const String notification = '/notification';
  static const String settings = '/settings';
  static const String help = '/help';
  static const String about = '/about';
  static const String privacyPolicy = '/privacy-policy';
  static const String membershipApply = '/membership/apply';
  static const String membershipStatus = '/membership/status';
  static const String membershipPayment = '/membership/payment';

  // Savings Feature Routes
  static const String savings = '/savings';
  static const String savingsObligations = '/savings/obligations';
  static const String savingsHistory = '/savings/history';
  static const String savingsWithdraw = '/savings/withdraw';
  static const String savingsWithdrawals = '/savings/withdrawals';
  static const String savingsPayment = '/savings/payment';

  // Loan Feature Routes
  static const String loans = '/loans';
  static const String loanApply = '/loans/apply';
  static const String loanApplicationStatus = '/loans/application/:id';
  static const String loanDetail = '/loans/detail/:id';
  static const String loanRepay = '/loans/repay/:id';
  static const String loanGuarantors = '/loans/guarantors';
  static const String loanExtension = '/loans/extension/:id';
  static const String outsiderLoanApply = '/outsider-loan/apply';

  static const String logout = '/logout';
}
