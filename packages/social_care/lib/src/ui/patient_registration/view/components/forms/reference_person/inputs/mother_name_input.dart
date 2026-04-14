import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class MotherNameInput extends StatelessWidget {
  final String? errorText;
  final String? Function(String?)? validator;
  final TextEditingController motherNameController;

  const MotherNameInput({
    super.key,
    this.errorText,
    this.validator,
    required this.motherNameController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: motherNameController,
      builder: (context, child) {
        return TextFormField(
          controller: motherNameController,
          validator: validator,
          keyboardType: TextInputType.name,
          decoration: InputDecoration(
            label: RichText(
              text: const TextSpan(
                text: ReferencePersonLn10.motherNameLabel,
                style: TextStyle(color: Colors.black),
                children: <TextSpan>[
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ],
              ),
            ),
            hintText: ReferencePersonLn10.motherNamePlaceholder,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
