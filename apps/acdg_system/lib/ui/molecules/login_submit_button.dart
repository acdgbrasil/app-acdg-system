import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../view_models/auth_view_model.dart';

/// Login button with loading state.
///
/// Shows "Entrar" by default, "Redirecionando..." with spinner while
/// the OIDC redirect is in progress.
class LoginSubmitButton extends StatelessWidget {
  const LoginSubmitButton({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel.login,
      builder: (context, _) {
        final busy = viewModel.login.running;

        return SizedBox(
          width: double.infinity,
          child: AcdgPillButton.primary(
            onPressed: busy ? null : viewModel.login.execute,
            icon: busy ? null : Icons.arrow_forward_rounded,
            label: busy ? 'Redirecionando...' : 'Entrar',
          ),
        );
      },
    );
  }
}
