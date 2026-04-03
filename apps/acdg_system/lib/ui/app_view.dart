import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/di/auth_providers.dart';

/// The root UI shell of the application.
class AppView extends ConsumerWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider).router;

    return MaterialApp.router(
      title: 'ACDG System',
      debugShowCheckedModeBanner: false,
      theme: AcdgTheme.light,
      routerConfig: router,
    );
  }
}
