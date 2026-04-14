import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/di/auth_providers.dart';
import '../atoms/app_logo.dart';
import '../molecules/login_form_feedback.dart';
import '../molecules/login_submit_button.dart';

/// The login screen — "Confident Identity" pattern.
///
/// A clean gateway that establishes trust before redirecting to the
/// external OIDC provider (Zitadel). Shows product identity, a single
/// CTA, redirect notice, environment badge, and support link.
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  static const _appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  bool get _isProduction => _appEnv == 'production';

  String get _envLabel => switch (_appEnv) {
    'production' => '',
    'staging' || 'hml' => 'HOMOLOGAÇÃO',
    _ => 'DESENVOLVIMENTO',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Login card ──
                Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 48,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.elevationXs,
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                      BoxShadow(
                        color: AppColors.elevationSm,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      const AppLogo(size: 72),
                      const SizedBox(height: 20),

                      // Product name
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: const Text(
                          'Conecta Raros',
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.w700,
                            fontSize: 56,
                            height: 1.0,
                            letterSpacing: -1.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Short functional descriptor
                      AcdgText(
                        'Gestão de cuidado social',
                        variant: AcdgTextVariant.bodyLarge,
                        color: AppColors.textMuted,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Error feedback (hidden unless auth failed)
                      LoginFormFeedback(viewModel: viewModel),

                      // Login button
                      LoginSubmitButton(viewModel: viewModel),
                      const SizedBox(height: 16),

                      // Redirect notice
                      AcdgText(
                        'Você será redirecionado para o\nserviço de autenticação da ACDG.',
                        variant: AcdgTextVariant.caption,
                        color: AppColors.textMuted,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Beta notice ──
                Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.science_outlined,
                          size: 18,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Esta aplicação está em fase Beta. '
                          'Caso encontre algum erro, entre em contato com a equipe da ACDG. '
                          'Novas versões com melhorias são lançadas toda quinta-feira.',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Support link ──
                TextButton(
                  onPressed: () {
                    // TODO: open support channel (WhatsApp or email)
                  },
                  child: AcdgText(
                    'Precisa de ajuda? Fale com o suporte',
                    variant: AcdgTextVariant.caption,
                    color: AppColors.textMuted,
                  ),
                ),

                // ── Environment badge (non-production only) ──
                if (!_isProduction) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: AcdgText(
                      _envLabel,
                      variant: AcdgTextVariant.caption,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
