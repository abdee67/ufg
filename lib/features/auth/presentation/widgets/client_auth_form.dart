import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ufg/core/widgets/primary_button.dart';

class CustomerAuthForm extends StatelessWidget {
  final List<Widget> children;
  final VoidCallback onSubmit;
  final bool loading;

  const CustomerAuthForm({
    super.key,
    required this.children,
    required this.onSubmit,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...children,
        const SizedBox(height: 20),
        loading
            ? SpinKitWave(
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              )
            : PrimaryButton(label: 'Continue', onPressed: onSubmit),
      ],
    );
  }
}
