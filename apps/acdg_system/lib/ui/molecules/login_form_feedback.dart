import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import '../view_models/auth_view_model.dart';

/// A molecule that displays error feedback for the login process.
class LoginFormFeedback extends StatelessWidget {
  const LoginFormFeedback({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final status = viewModel.status;
        if (status is! AuthError) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.error),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.message,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
