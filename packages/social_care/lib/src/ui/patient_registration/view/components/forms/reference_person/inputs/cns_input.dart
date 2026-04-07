import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class CnsInput extends StatelessWidget {
  final String? errorText;
  final String? Function(String?)? validator;
  final TextEditingController cnsController;

  const CnsInput({
    super.key,
    this.errorText,
    this.validator,
    required this.cnsController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cnsController,
      builder: (context, child) {
        return TextFormField(
          controller: cnsController,
          validator: validator,
          keyboardType: TextInputType.number,
          inputFormatters: AppMasks.cns,
          decoration: InputDecoration(
            label: const Text(
              ReferencePersonLn10.cnsLabel,
              style: TextStyle(color: Colors.black),
            ),
            hintText: ReferencePersonLn10.cnsPlaceholder,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
