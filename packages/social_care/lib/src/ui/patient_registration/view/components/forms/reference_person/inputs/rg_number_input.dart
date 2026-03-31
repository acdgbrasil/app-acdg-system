import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class RgNumberInput extends StatelessWidget {
  final String? errorText;
  final String? Function(String?)? validator;
  final TextEditingController rgNumberController;

  const RgNumberInput({super.key, this.errorText, this.validator, required this.rgNumberController});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: rgNumberController,
      builder: (context, child) {
        return TextFormField(
          controller: rgNumberController,
          validator: validator,
          keyboardType: TextInputType.text,
          inputFormatters: AppMasks.rg,
          decoration: InputDecoration(
            label: const Text(
              ReferencePersonLn10.rgNumberLabel,
              style: TextStyle(color: Colors.black),
            ),
            hintText: ReferencePersonLn10.rgNumberPlaceholder,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
