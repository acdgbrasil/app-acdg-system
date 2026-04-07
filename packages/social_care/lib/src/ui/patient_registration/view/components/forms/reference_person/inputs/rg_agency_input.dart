import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class RgAgencyInput extends StatelessWidget {
  final String? errorText;
  final String? Function(String?)? validator;
  final TextEditingController rgAgencyController;

  const RgAgencyInput({
    super.key,
    this.errorText,
    this.validator,
    required this.rgAgencyController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: rgAgencyController,
      builder: (context, child) {
        return TextFormField(
          controller: rgAgencyController,
          validator: validator,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            label: const Text(
              ReferencePersonLn10.rgAgencyLabel,
              style: TextStyle(color: Colors.black),
            ),
            hintText: ReferencePersonLn10.rgAgencyPlaceholder,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
