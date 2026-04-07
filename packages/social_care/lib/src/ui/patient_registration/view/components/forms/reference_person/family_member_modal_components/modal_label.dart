import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class ModalLabel extends StatelessWidget {
  final String text;
  final bool isRequired;

  const ModalLabel({super.key, required this.text, this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textOnDark,
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.danger, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }
}
