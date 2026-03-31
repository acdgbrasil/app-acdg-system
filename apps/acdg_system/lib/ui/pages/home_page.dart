import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_care_desktop/social_care_desktop.dart';
import '../atoms/sync_indicator.dart';
import '../molecules/user_menu_button.dart';
import '../organisms/home_content.dart';
import '../view_models/auth_view_model.dart';

/// The home screen of the application.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const AcdgText(
          'ACDG System',
          variant: AcdgTextVariant.headingSmall,
          color: AppColors.textPrimary,
        ),
        actions: [
          Consumer<SyncEngine?>(
            builder: (context, syncEngine, _) {
              if (syncEngine == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SyncIndicator(status: syncEngine.status),
              );
            },
          ),
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
