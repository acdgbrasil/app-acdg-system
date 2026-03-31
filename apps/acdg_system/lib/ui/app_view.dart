import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/di/dependency_manager.dart';

/// The root UI shell of the application.
class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AppDependencyManager, RouterConfig<Object>>(
      selector: (_, deps) => deps.appRouter.router,
      builder: (context, router, _) {
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
