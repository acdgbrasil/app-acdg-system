import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class StreetInput extends StatelessWidget {
  final String? errorText;
  final TextEditingController streetController;

  const StreetInput({
    super.key,
    this.errorText,
    required this.streetController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: streetController,
      builder: (context, child) {
        return TextFormField(
          controller: streetController,
          keyboardType: TextInputType.streetAddress,
          decoration: InputDecoration(
            label: const Text(
              ReferencePersonLn10.streetLabel,
              style: TextStyle(color: Colors.black),
            ),
            hintText: ReferencePersonLn10.streetPlaceholder,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
