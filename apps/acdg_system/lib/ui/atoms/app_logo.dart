import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 80});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16), // Múltiplo de 8
      ),
      child: Icon(Icons.favorite, color: AppColors.textOnDark, size: size / 2),
    );
  }
}
