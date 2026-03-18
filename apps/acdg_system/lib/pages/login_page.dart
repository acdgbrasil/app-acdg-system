import 'package:acdg_system/ui/view_models/auth_view_model.dart';
import 'package:auth/auth.dart';
import 'package:flutter/material.dart';

import '../ui/atoms/app_logo.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(),
                  const SizedBox(height: 16),
                  Text(
                    'ACDG System',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Plataforma de cuidado e defesa de pacientes\ncom doencas geneticas raras',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _ErrorFeedback(viewModel: viewModel),
                  _LoginButton(viewModel: viewModel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorFeedback extends StatelessWidget {
  const _ErrorFeedback({required this.viewModel});
  final AuthViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<AuthStatus>(
      valueListenable: viewModel.status,
      builder: (context, status, _) {
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

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.viewModel});
  final AuthViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel.login,
      builder: (context, _) {
        final busy = viewModel.login.running;
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: busy ? null : viewModel.login.execute,
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: const Text('Entrar com ACDG'),
          ),
        );
      },
    );
  }
}
