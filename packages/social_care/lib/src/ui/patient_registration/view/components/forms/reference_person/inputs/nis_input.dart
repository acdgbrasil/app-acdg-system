import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class NisInput extends StatelessWidget {
  final String? errorText;
  final String? Function(String?)? validator;
  final TextEditingController nisController;

  const NisInput({
    super.key,
    this.errorText,
    this.validator,
    required this.nisController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: nisController,
      builder: (context, child) {
        return TextFormField(
          controller: nisController,
          validator: validator,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          decoration: InputDecoration(
            label: const Text(
              ReferencePersonLn10.nisLabel,
              style: TextStyle(color: Colors.black),
            ),
            hintText: ReferencePersonLn10.nisPlaceholder,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
