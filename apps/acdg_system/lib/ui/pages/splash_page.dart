import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The initial splash screen shown during auth state resolution.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AcdgText(
              'ACDG System',
              variant: AcdgTextVariant.displayLarge,
              color: AppColors.primary,
            ),
            SizedBox(height: AppSpacing.space5),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
