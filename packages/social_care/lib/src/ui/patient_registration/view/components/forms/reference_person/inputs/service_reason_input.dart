import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class ServiceReasonInput extends StatelessWidget {
  final String? errorText;
  final String? Function(String?)? validator;
  final TextEditingController controller;

  const ServiceReasonInput({
    super.key,
    this.errorText,
    this.validator,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return TextFormField(
          controller: controller,
          validator: validator,
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            label: RichText(
              text: const TextSpan(
                text: ReferencePersonLn10.serviceReasonLabel,
                style: TextStyle(color: Colors.black),
                children: <TextSpan>[
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            hintText: ReferencePersonLn10.serviceReasonPlaceholder,
            errorText: errorText,
            alignLabelWithHint: true,
          ),
        );
      },
    );
  }
}
