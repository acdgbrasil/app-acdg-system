import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class ViolationReportSuccessBanner extends StatelessWidget {
  const ViolationReportSuccessBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.primary),
          SizedBox(width: 12),
          Text(
            'Relato registrado com sucesso. Preencha outro ou volte.',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
