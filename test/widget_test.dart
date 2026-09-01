import 'package:flutter_test/flutter_test.dart';
import 'package:ufg/core/constants/app_routes.dart';

void main() {
  test('AppRoutes defines critical paths', () {
    expect(AppRoutes.loginScreen, '/login');
    expect(AppRoutes.signupScreen, '/signup');
    expect(AppRoutes.homeScreen, '/home');
    expect(AppRoutes.membershipApply, '/membership/apply');
    expect(AppRoutes.membershipStatus, '/membership/status');
  });
}
