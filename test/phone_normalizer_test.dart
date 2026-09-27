import 'package:flutter_test/flutter_test.dart';
import 'package:ufg/core/utils/phone_normalizer.dart';
import 'package:ufg/core/utils/password_policy.dart';

void main() {
  group('PhoneNormalizer', () {
    test('normalizes Ethiopian local phone input to E.164', () {
      expect(PhoneNormalizer.normalize('0911 223 344'), '+251911223344');
    });

    test('preserves a valid E.164 number', () {
      expect(PhoneNormalizer.normalize('+251-911-223-344'), '+251911223344');
    });

    test('rejects input without a usable country code', () {
      expect(PhoneNormalizer.normalize('911223344'), isNull);
    });
  });

  group('PasswordPolicy', () {
    test('rejects a known weak password', () {
      expect(
        PasswordPolicy.validationMessage('password'),
        'Choose a less predictable password',
      );
    });
  });
}
