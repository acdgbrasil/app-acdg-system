import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class SocialNameInput extends StatelessWidget {
  final String? errorText;
  final String? Function(String?)? validator;
  final TextEditingController socialNameController;

  const SocialNameInput({super.key, this.errorText, this.validator, required this.socialNameController});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: socialNameController, builder: (context, child) {
      return TextFormField(
        controller: socialNameController,
        validator: validator,
        keyboardType: TextInputType.name,
        decoration: InputDecoration(
          label: const Text(
            ReferencePersonLn10.socialNameLabel,
            style: TextStyle(color: Colors.black),
          ),
          hintText: ReferencePersonLn10.socialNamePlaceholder,
          errorText: errorText,
        ),
      );
    });
  }
}
