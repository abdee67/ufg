import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle amountLarge(BuildContext context) =>
      Theme.of(context).textTheme.displayMedium!.copyWith(
        letterSpacing: -0.5,
      );

  static TextStyle amountMedium(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.25,
      );

  static TextStyle sectionTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.w700,
      );

  static TextStyle caption(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall!;

  static TextStyle fieldLabel(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall!.copyWith(
        fontWeight: FontWeight.w600,
      );
}