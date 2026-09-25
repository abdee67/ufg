/// Converts supported member phone input to the canonical E.164 form used by
/// Supabase Auth and the profile mirror.
class PhoneNormalizer {
  PhoneNormalizer._();

  static const _e164Pattern = r'^\+[1-9]\d{7,14}$';

  /// Ethiopia is the current primary market. International callers must enter
  /// their number with a leading `+` (or `00`) and a country code.
  static String? normalize(String value) {
    var compact = value.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (compact.isEmpty) return null;

    if (compact.startsWith('00')) {
      compact = '+${compact.substring(2)}';
    } else if (compact.startsWith('0')) {
      compact = '+251${compact.substring(1)}';
    } else if (compact.startsWith('251')) {
      compact = '+$compact';
    }

    return RegExp(_e164Pattern).hasMatch(compact) ? compact : null;
  }
}
