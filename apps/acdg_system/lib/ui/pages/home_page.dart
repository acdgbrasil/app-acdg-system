import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/di/auth_providers.dart';
import '../../logic/di/infrastructure_providers.dart';
import '../atoms/sync_indicator.dart';
import '../molecules/user_menu_button.dart';
import '../organisms/home_content.dart';

/// The home screen of the application.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(authViewModelProvider);
    final syncEngine = ref.watch(syncEngineProvider);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final user = viewModel.user;

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
              if (syncEngine != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SyncIndicator(status: syncEngine.status),
                ),
              if (user != null)
                UserMenuButton(user: user, onLogout: viewModel.logout.execute),
            ],
          ),
          body: user != null
              ? HomeContent(user: user)
              : const SizedBox.shrink(),
        );
      },
    );
  }
}
