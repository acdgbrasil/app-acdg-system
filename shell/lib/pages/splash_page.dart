import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Splash screen shown while auth state is being resolved.
///
/// GoRouter's global redirect handles navigation once
/// [AuthViewModel] emits Authenticated or Unauthenticated.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcdgColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Conecta Raros',
              style: AcdgTypography.displayMedium.copyWith(
                color: AcdgColors.primary,
              ),
            ),
            const SizedBox(height: AcdgSpacing.xl),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
