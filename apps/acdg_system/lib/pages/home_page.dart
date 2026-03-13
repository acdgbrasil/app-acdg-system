import 'package:acdg_system/ui/view_models/auth_view_model.dart';
import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/molecules/user_menu_button.dart';
import '../ui/organisms/home_content.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ACDG System'),
        actions: [
          ValueListenableBuilder<AuthUser?>(
            valueListenable: viewModel.user,
            builder: (context, user, _) {
              if (user == null) return const SizedBox.shrink();
              return UserMenuButton(
                user: user,
                onLogout: viewModel.logout.execute,
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<AuthUser?>(
        valueListenable: viewModel.user,
        builder: (context, user, _) {
          if (user == null) return const SizedBox.shrink();
          return HomeContent(user: user);
        },
      ),
    );
  }
}
