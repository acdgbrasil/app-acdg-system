import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class CityInput extends StatelessWidget {
  final String? errorText;
  final String? Function(String?)? validator;
  final TextEditingController cityController;

  const CityInput({
    super.key,
    this.errorText,
    this.validator,
    required this.cityController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cityController,
      builder: (context, child) {
        return TextFormField(
          controller: cityController,
          validator: validator,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            label: RichText(
              text: const TextSpan(
                text: ReferencePersonLn10.cityLabel,
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            hintText: ReferencePersonLn10.cityPlaceholder,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
