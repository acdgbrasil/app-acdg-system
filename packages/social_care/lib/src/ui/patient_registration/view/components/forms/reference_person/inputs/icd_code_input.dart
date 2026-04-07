import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class IcdCodeInput extends StatelessWidget {
  final String? errorText;
  final String? Function(String?)? validator;
  final TextEditingController icdCodeController;

  const IcdCodeInput({
    super.key,
    this.errorText,
    this.validator,
    required this.icdCodeController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: icdCodeController,
      builder: (context, child) {
        return TextFormField(
          controller: icdCodeController,
          validator: validator,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            label: RichText(
              text: const TextSpan(
                text: ReferencePersonLn10.icdCodeLabel,
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            hintText: ReferencePersonLn10.icdCodePlaceholder,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
