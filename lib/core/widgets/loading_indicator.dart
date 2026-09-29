import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitWave(
        color: Theme.of(context).colorScheme.primary,
        size: 50,
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }
}
