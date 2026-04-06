import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

class FamilyMemberModalHeader extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onClose;

  const FamilyMemberModalHeader({
    super.key,
    required this.isEditing,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            isEditing
                ? ReferencePersonLn10.memberModalEditTitle
                : ReferencePersonLn10.memberModalTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: AppColors.textOnDark,
            ),
          ),
        ),
        GestureDetector(
          onTap: onClose,
          child: const MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Icon(Icons.close, color: AppColors.danger, size: 24),
          ),
        ),
      ],
    );
  }
}
