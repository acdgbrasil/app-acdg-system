import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class CpfInput extends StatelessWidget {
  final String? errorText;
  final String? Function(String?)? validator;
  final TextEditingController cpfController;

  const CpfInput({
    super.key,
    this.errorText,
    this.validator,
    required this.cpfController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cpfController,
      builder: (context, child) {
        return TextFormField(
          controller: cpfController,
          validator: validator,
          keyboardType: TextInputType.number,
          inputFormatters: AppMasks.cpf,
          decoration: InputDecoration(
            label: RichText(
              text: const TextSpan(
                text: ReferencePersonLn10.cpfLabel,
                style: TextStyle(color: Colors.black),
                children: <TextSpan>[
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            hintText: ReferencePersonLn10.cpfPlaceholder,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
