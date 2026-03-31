import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../view_models/auth_view_model.dart';

/// A molecule representing the login button with loading state.
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
            icon: busy ? null : Icons.login,
            label: busy ? 'Entrando...' : 'Entrar com ACDG',
          ),
        );
      },
    );
  }
}
