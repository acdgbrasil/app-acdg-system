import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class PhoneNumberInput extends StatelessWidget {
  final String? errorText;
  final String? Function(String?)? validator;
  final TextEditingController phoneNumberController;

  const PhoneNumberInput({
    super.key, 
    this.errorText, 
    this.validator, 
    required this.phoneNumberController
  });

  @override
  Widget build(BuildContext context) {
    final phoneMaskFormatter = PhoneMask();

    return ListenableBuilder(
      listenable: phoneNumberController, 
      builder: (context, child) {
        return TextFormField(
          controller: phoneNumberController,
          validator: validator,
          keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            phoneMaskFormatter,
          ],
          decoration: InputDecoration(
            label: const Text(
              ReferencePersonLn10.phoneNumberLabel,
              style: TextStyle(color: Colors.black),
            ),
            hintText: ReferencePersonLn10.phoneNumberPlaceholder,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
