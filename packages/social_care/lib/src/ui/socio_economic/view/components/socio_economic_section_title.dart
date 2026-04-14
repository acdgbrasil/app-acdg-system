import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class SocioEconomicSectionTitle extends StatelessWidget {
  const SocioEconomicSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Satoshi',
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
    );
  }
}
