import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class LastNameInput extends StatelessWidget {
  final String? errorText;
  final String? Function(String?)? validator;
  final TextEditingController lastNameController;

  const LastNameInput({super.key, this.errorText, this.validator, required this.lastNameController});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: lastNameController, builder: (context, child) {
      return TextFormField(
        controller: lastNameController,
        validator: validator,
        keyboardType: TextInputType.name,
        decoration: InputDecoration(
          label: RichText(text: const TextSpan(
            text: ReferencePersonLn10.lastNameLabel,
            style: TextStyle(color: Colors.black),
            children: <TextSpan>[ TextSpan(text: ' *', style: TextStyle(color: Colors.red)) ]
          )),
          hintText: ReferencePersonLn10.lastNamePlaceholder,
          errorText: errorText,
        ),
      );
    });
  }
}
