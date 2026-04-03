import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/di/auth_providers.dart';
import '../atoms/app_logo.dart';
import '../molecules/login_form_feedback.dart';
import '../molecules/login_submit_button.dart';

/// The login screen of the application.
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(authViewModelProvider);
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
                  const AcdgText(
                    'ACDG System',
                    variant: AcdgTextVariant.displayLarge,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  const AcdgText(
                    'Plataforma de cuidado e defesa de pacientes\ncom doenças genéticas raras',
                    variant: AcdgTextVariant.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  LoginFormFeedback(viewModel: viewModel),
                  LoginSubmitButton(viewModel: viewModel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
