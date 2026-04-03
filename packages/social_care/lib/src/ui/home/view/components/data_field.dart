import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/ui/home/constants/home_ln10.dart';

class DataField extends StatelessWidget {
  final String label;
  final String? value;

  const DataField({super.key, required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.background.withValues(alpha: 0.5),
            letterSpacing: 0.05 * 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value ?? HomeLn10.emptyValue,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: AppColors.background,
          ),
        ),
      ],
    );
  }
}
