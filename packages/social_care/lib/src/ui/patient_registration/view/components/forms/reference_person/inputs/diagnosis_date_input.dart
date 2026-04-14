import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class DiagnosisDateInput extends StatelessWidget {
  final String? errorText;
  final String? Function(String?)? validator;
  final TextEditingController dateController;

  const DiagnosisDateInput({
    super.key,
    this.errorText,
    this.validator,
    required this.dateController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: dateController,
      builder: (context, child) {
        return TextFormField(
          controller: dateController,
          validator: validator,
          keyboardType: TextInputType.number,
          inputFormatters: AppMasks.date,
          decoration: InputDecoration(
            label: RichText(
              text: const TextSpan(
                text: ReferencePersonLn10.diagnosisDateLabel,
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ],
              ),
            ),
            hintText: ReferencePersonLn10.diagnosisDatePlaceholder,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
