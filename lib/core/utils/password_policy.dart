class PasswordPolicy {
  PasswordPolicy._();

  static const _blockedPasswords = {
    '12345678',
    '00000000',
    'password',
    'qwertyui',
  };

  static String? validationMessage(String value, {String? phone}) {
    if (value.length < 8) return 'Use at least 8 characters';

    final normalized = value.trim().toLowerCase();
    if (_blockedPasswords.contains(normalized)) {
      return 'Choose a less predictable password';
    }

    final phoneDigits = phone?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (phoneDigits.length >= 8 && value.contains(phoneDigits)) {
      return 'Do not use your phone number as your password';
    }
    return null;
  }
}
