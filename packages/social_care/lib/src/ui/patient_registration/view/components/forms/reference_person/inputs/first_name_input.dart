import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class FirstNameInput extends StatelessWidget {
  final String? errorText;
  final String? Function(String?)? validator;
  final TextEditingController firstNameController;

  const FirstNameInput({
    super.key,
    this.errorText,
    this.validator,
    required this.firstNameController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: firstNameController,
      builder: (context, child) {
        return TextFormField(
          controller: firstNameController,
          validator: validator,
          keyboardType: TextInputType.name,
          decoration: InputDecoration(
            label: RichText(
              text: const TextSpan(
                text: ReferencePersonLn10.firstNameLabel,
                style: TextStyle(color: Colors.black),
                children: <TextSpan>[
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            errorText: errorText,
          ),
        );
      },
    );
  }
}
