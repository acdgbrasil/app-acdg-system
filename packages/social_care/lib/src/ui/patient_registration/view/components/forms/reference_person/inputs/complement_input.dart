import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class ComplementInput extends StatelessWidget {
  final String? errorText;
  final TextEditingController complementController;

  const ComplementInput({
    super.key,
    this.errorText,
    required this.complementController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: complementController,
      builder: (context, child) {
        return TextFormField(
          controller: complementController,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            label: const Text(
              ReferencePersonLn10.complementLabel,
              style: TextStyle(color: Colors.black),
            ),
            hintText: ReferencePersonLn10.complementPlaceholder,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
