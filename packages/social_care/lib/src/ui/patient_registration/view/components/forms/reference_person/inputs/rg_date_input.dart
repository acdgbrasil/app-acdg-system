import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class RgDateInput extends StatelessWidget {
  final String? errorText;
  final String? Function(String?)? validator;
  final TextEditingController rgDateController;

  const RgDateInput({
    super.key,
    this.errorText,
    this.validator,
    required this.rgDateController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: rgDateController,
      builder: (context, child) {
        return TextFormField(
          controller: rgDateController,
          validator: validator,
          keyboardType: TextInputType.number,
          inputFormatters: AppMasks.date,
          decoration: InputDecoration(
            label: const Text(
              ReferencePersonLn10.rgDateLabel,
              style: TextStyle(color: Colors.black),
            ),
            hintText: ReferencePersonLn10.rgDatePlaceholder,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
