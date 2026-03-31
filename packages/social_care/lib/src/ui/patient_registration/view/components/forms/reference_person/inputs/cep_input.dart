import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class CepInput extends StatelessWidget {
  final String? errorText;
  final String? Function(String?)? validator;
  final TextEditingController cepController;

  const CepInput({super.key, this.errorText, this.validator, required this.cepController});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cepController,
      builder: (context, child) {
        return TextFormField(
          controller: cepController,
          validator: validator,
          keyboardType: TextInputType.number,
          inputFormatters: AppMasks.cep,
          decoration: InputDecoration(
            label: const Text(
              ReferencePersonLn10.cepLabel,
              style: TextStyle(color: Colors.black),
            ),
            hintText: ReferencePersonLn10.cepPlaceholder,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
