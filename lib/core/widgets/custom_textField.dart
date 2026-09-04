import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_sizes.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.controller,
    required this.label,
    this.icon,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.obscureText = false,
    this.maxLines = 1,
    this.suffixIcon,
    this.errorText,
    this.hintText,
    this.enabled = true,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final String label;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool obscureText;
  final int maxLines;
  final Widget? suffixIcon;
  final String? errorText;
  final String? hintText;
  final bool enabled;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: icon != null
            ? Icon(icon, color: colorScheme.onSurface.withValues(alpha: 0.6))
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: colorScheme.surface,
        errorText: errorText,
        border: _border(theme),
        enabledBorder: _border(theme),
        focusedBorder: _border(theme, colorScheme.primary),
        errorBorder: _border(theme, colorScheme.error),
        focusedErrorBorder: _border(theme, colorScheme.error),
      ),
      validator: validator,
      onChanged: onChanged,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      enabled: enabled,
      autofillHints: autofillHints,
    );
  }

  OutlineInputBorder _border(ThemeData theme, [Color color = Colors.transparent]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusField),
        borderSide: BorderSide(color: color, width: 1.4),
      );
}