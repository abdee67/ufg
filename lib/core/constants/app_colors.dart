import 'package:flutter/material.dart';

Color hexToColor(String hex) {
  assert(
    RegExp(r'^#([0-9a-fA-F]{6})|([0-9a-fA-F]{8})$').hasMatch(hex),
    'hex color must be #rrggbb or #rrggbbaa',
  );

  return Color(
    int.parse(hex.substring(1), radix: 16) +
        (hex.length == 7 ? 0xff000000 : 0x00000000),
  );
}

class ColorConstants {
  static Color lightScaffoldBackgroundColor = hexToColor('#F9F9F9');
  static Color darkScaffoldBackgroundColor = hexToColor('#2F2E2E');
  static Color secondaryAppColor = hexToColor('#5E92F3');
  static Color secondaryDarkAppColor = Colors.white;
  static const paper = Color(0xFFFFF8F2);
  static const surface = Colors.white;
  static const ink = Color(0xFF2E2420);
  static const black = Color(0xFF000000);
  static const muted = Color(0xFF78665F);
  static const clay = Color(0xFF9F624F);
  static const burgundy = Color(0xFF72175B);
  static const rose = Color(0xFFE9B7A6);
  static const field = Color(0xFFFFF1EA);
  static const border = Color(0xFFF0D6C9);
  static const peach = Color(0xFFFFE5D2);
  static const blush = Color(0xFFF4DDD1);
  static const sage = Color(0xFF70866D);
  static const successSurface = Color(0xFFEAF0E5);
  static const error = Color(0xFF9B3A32);
}
