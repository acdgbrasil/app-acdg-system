import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/di/auth_providers.dart';

/// The root UI shell of the application.
class AppView extends ConsumerWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure AuthViewModel is initialized (restore session called)
    final authInit = ref.watch(authInitializationProvider);

    return authInit.when(
      loading: () => const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator()))),
      error: (err, stack) => MaterialApp(home: Scaffold(body: Center(child: Text('Auth Error: $err')))),
      data: (_) {
        final router = ref.watch(appRouterProvider).router;
        return MaterialApp.router(
          title: 'ACDG System',
          debugShowCheckedModeBanner: false,
          theme: AcdgTheme.light,
          routerConfig: router,
        );
      },
    );
  }
}
