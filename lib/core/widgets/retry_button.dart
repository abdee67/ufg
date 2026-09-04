import 'package:flutter/material.dart';
import 'package:ufg/core/widgets/error_state.dart';

class RetryButton extends StatelessWidget {
  const RetryButton({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorState(message: message, onRetry: onRetry);
  }
}