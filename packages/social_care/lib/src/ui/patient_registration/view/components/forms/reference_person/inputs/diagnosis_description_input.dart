import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class DiagnosisDescriptionInput extends StatelessWidget {
  final String? errorText;
  final String? Function(String?)? validator;
  final TextEditingController descriptionController;

  const DiagnosisDescriptionInput({
    super.key,
    this.errorText,
    this.validator,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: descriptionController,
      builder: (context, child) {
        return TextFormField(
          controller: descriptionController,
          validator: validator,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            label: RichText(
              text: const TextSpan(
                text: ReferencePersonLn10.descriptionLabel,
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ],
              ),
            ),
            hintText: ReferencePersonLn10.descriptionPlaceholder,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
