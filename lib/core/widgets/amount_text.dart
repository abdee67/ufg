import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_text_styles.dart';
import 'package:ufg/core/utils/formatters.dart';

class AmountText extends StatelessWidget {
  const AmountText({
    super.key,
    required this.amount,
    this.label,
    this.signed = false,
    this.style,
    this.labelStyle,
  });

  final num amount;
  final String? label;
  final bool signed;
  final TextStyle? style;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final formatted = signed
        ? Formatters.signedMoney(amount)
        : Formatters.money(amount);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              label!,
              style:
                  labelStyle ?? Theme.of(context).textTheme.labelSmall,
            ),
          ),
        Text(
          formatted,
          style: style ?? AppTextStyles.amountMedium(context),
        ),
      ],
    );
  }
}