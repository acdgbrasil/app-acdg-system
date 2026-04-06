import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class AddMemberModalField extends StatelessWidget {
  final String label;
  final bool isRequired;
  final String? error;
  final Widget child;

  const AddMemberModalField({
    super.key,
    required this.label,
    this.isRequired = false,
    this.error,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.background,
              ),
              children: [
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.danger, fontSize: 10),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          child,
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              error!,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 11,
                color: AppColors.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
