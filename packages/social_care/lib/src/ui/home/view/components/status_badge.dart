import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/ui/home/constants/home_ln10.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  bool get _isActive => status == HomeLn10.statusActive;

  @override
  Widget build(BuildContext context) {
    final color = _isActive ? AppColors.primary : AppColors.danger;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          status,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}
