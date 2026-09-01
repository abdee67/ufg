import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ufg/core/constants/app_colors.dart';

class ThemeConfig {
  static ThemeData get darkTheme => createTheme(
    brightness: Brightness.dark,
    background: ColorConstants.darkScaffoldBackgroundColor,
    cardBackground: ColorConstants.surfaceDark,
    primaryText: ColorConstants.textPrimaryDark,
    secondaryText: ColorConstants.textSecondaryDark,
    accentColor: ColorConstants.accent,
    divider: ColorConstants.dividerDark,
    buttonBackground: ColorConstants.brandGreen,
    buttonText: Colors.white,
    disabled: ColorConstants.dividerDark,
    error: ColorConstants.error,
  );

  static ThemeData get lightTheme => createTheme(
    brightness: Brightness.light,
    background: ColorConstants.lightScaffoldBackgroundColor,
    cardBackground: ColorConstants.surfaceLight,
    primaryText: ColorConstants.textPrimaryLight,
    secondaryText: ColorConstants.textSecondaryLight,
    accentColor: ColorConstants.accent,
    divider: ColorConstants.dividerLight,
    buttonBackground: ColorConstants.brandGreen,
    buttonText: Colors.white,
    disabled: ColorConstants.dividerLight,
    error: ColorConstants.error,
  );

  static ThemeData createTheme({
    required Brightness brightness,
    required Color background,
    required Color primaryText,
    required Color secondaryText,
    required Color accentColor,
    required Color divider,
    required Color buttonBackground,
    required Color buttonText,
    required Color cardBackground,
    required Color disabled,
    required Color error,
  }) {
    return ThemeData(
      brightness: brightness,
      canvasColor: background,
      cardColor: cardBackground,
      dividerColor: divider,
      dividerTheme: DividerThemeData(color: divider, space: 1, thickness: 1),
      cardTheme: CardThemeData(
        color: cardBackground,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAliasWithSaveLayer,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
          ),
          padding: WidgetStateProperty.all<EdgeInsets>(
            const EdgeInsets.all(16),
          ),
          backgroundColor: WidgetStateProperty.all<Color>(buttonBackground),
          foregroundColor: WidgetStateProperty.all<Color>(buttonText),
        ),
      ),
      primaryColor: accentColor,
      appBarTheme: AppBarThemeData(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: brightness,
        ),
        backgroundColor: cardBackground,
        iconTheme: IconThemeData(color: primaryText),
        toolbarTextStyle: TextTheme(
          bodyLarge: TextStyle(
            color: primaryText,
            fontSize: 18,
          ),
        ).bodyMedium,
        titleTextStyle: TextTheme(
          bodyLarge: TextStyle(
            color: primaryText,
            fontSize: 18,
          ),
        ).titleLarge,
      ),
      iconTheme: IconThemeData(color: primaryText, size: 16.0),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accentColor,
        secondary: ColorConstants.navyBlue,
        surface: cardBackground,
        error: error,
        onPrimary: buttonText,
        onSecondary: buttonText,
        onSurface: primaryText,
        onError: buttonText,
      ),
      buttonTheme: ButtonThemeData(
        textTheme: ButtonTextTheme.primary,
        colorScheme: ColorScheme(
          brightness: brightness,
          primary: accentColor,
          secondary: ColorConstants.navyBlue,
          surface: cardBackground,
          error: error,
          onPrimary: buttonText,
          onSecondary: buttonText,
          onSurface: primaryText,
          onError: buttonText,
        ),
        padding: const EdgeInsets.all(16.0),
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: accentColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        errorStyle: TextStyle(color: error),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16.0,
          color: primaryText.withValues(alpha: 0.5),
        ),
        hintStyle: TextStyle(
          color: secondaryText,
          fontSize: 13.0,
          fontWeight: FontWeight.w300,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: primaryText,
          fontSize: 34.0,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: primaryText,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: secondaryText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: primaryText,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: secondaryText,
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          color: primaryText,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: primaryText,
          fontSize: 12.0,
          fontWeight: FontWeight.w700,
        ),
        bodySmall: TextStyle(
          color: primaryText,
          fontSize: 11.0,
          fontWeight: FontWeight.w300,
        ),
        labelSmall: TextStyle(
          color: secondaryText,
          fontSize: 11.0,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          color: primaryText,
          fontSize: 16.0,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: TextStyle(
          color: secondaryText,
          fontSize: 11.0,
          fontWeight: FontWeight.w500,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accentColor,
        selectionColor: accentColor,
        selectionHandleColor: accentColor,
      ),
    );
  }
}
