import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class NumberInput extends StatelessWidget {
  final String? errorText;
  final TextEditingController numberController;

  const NumberInput({
    super.key,
    this.errorText,
    required this.numberController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: numberController,
      builder: (context, child) {
        return TextFormField(
          controller: numberController,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            label: const Text(
              ReferencePersonLn10.numberLabel,
              style: TextStyle(color: Colors.black),
            ),
            hintText: ReferencePersonLn10.numberPlaceholder,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
