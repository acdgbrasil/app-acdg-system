import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class BirthDateInput extends StatelessWidget {
  final String? errorText;
  final String? Function(String?)? validator;
  final TextEditingController birthDateController;

  const BirthDateInput({super.key, this.errorText, this.validator, required this.birthDateController});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: birthDateController,
      builder: (context, child) {
        return TextFormField(
          controller: birthDateController,
          validator: validator,
          keyboardType: TextInputType.number,
          inputFormatters: AppMasks.date,
          decoration: InputDecoration(
            label: RichText(text: const TextSpan(
              text: ReferencePersonLn10.birthDateLabel,
              style: TextStyle(color: Colors.black),
              children: <TextSpan>[ TextSpan(text: ' *', style: TextStyle(color: Colors.red)) ],
            )),
            hintText: ReferencePersonLn10.birthDatePlaceholder,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
