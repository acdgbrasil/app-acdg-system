import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../auth/auth_view_model.dart';

/// Login page — entry point for unauthenticated users.
///
/// Triggers the Zitadel OIDC PKCE flow via [AuthViewModel].
/// Displays error feedback when login fails.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcdgColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(AcdgSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo / Title
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AcdgColors.primary,
                      borderRadius: AcdgRadius.borderLg,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: AcdgColors.onPrimary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: AcdgSpacing.lg),
                  Text(
                    'Conecta Raros',
                    style: AcdgTypography.displayMedium.copyWith(
                      color: AcdgColors.primary,
                    ),
                  ),
                  const SizedBox(height: AcdgSpacing.sm),
                  Text(
                    'Plataforma de cuidado e defesa de pacientes\ncom doencas geneticas raras',
                    style: AcdgTypography.bodyMedium.copyWith(
                      color: AcdgColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AcdgSpacing.xxl),

                  // Error message
                  ValueListenableBuilder<AuthStatus>(
                    valueListenable: viewModel.status,
                    builder: (context, status, _) {
                      if (status is! AuthError) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AcdgSpacing.md),
                        child: Container(
                          padding: const EdgeInsets.all(AcdgSpacing.md),
                          decoration: BoxDecoration(
                            color: AcdgColors.error.withValues(alpha: 0.1),
                            borderRadius: AcdgRadius.borderMd,
                            border: Border.all(color: AcdgColors.error),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AcdgColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: AcdgSpacing.sm),
                              Expanded(
                                child: Text(
                                  status.message,
                                  style: AcdgTypography.bodySmall.copyWith(
                                    color: AcdgColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Login button
                  ValueListenableBuilder<bool>(
                    valueListenable: viewModel.busy,
                    builder: (context, busy, _) {
                      return AcdgButton(
                        label: 'Entrar com ACDG',
                        icon: Icons.login,
                        isLoading: busy,
                        isExpanded: true,
                        size: AcdgButtonSize.large,
                        onPressed: busy ? null : viewModel.login,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
