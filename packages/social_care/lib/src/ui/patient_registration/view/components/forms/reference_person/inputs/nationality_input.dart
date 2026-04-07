import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/models/enums/nationality.dart';

final class NationalityInput extends StatelessWidget {
  final ValueNotifier<Nationality?> nationalityNotifier;
  final String? Function(Nationality?)? validator;

  const NationalityInput({
    super.key,
    required this.nationalityNotifier,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Nationality?>(
      valueListenable: nationalityNotifier,
      builder: (context, currentNationality, _) {
        return DropdownButtonFormField<Nationality>(
          initialValue: currentNationality,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            label: RichText(
              text: const TextSpan(
                text: ReferencePersonLn10.nationalityLabel,
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            hintText: ReferencePersonLn10.nationalityPlaceholder,
          ),
          items: Nationality.values.map((nationality) {
            return DropdownMenuItem<Nationality>(
              value: nationality,
              child: Text(_getDisplayLabel(nationality)),
            );
          }).toList(),
          onChanged: (newValue) => nationalityNotifier.value = newValue,
        );
      },
    );
  }

  String _getDisplayLabel(Nationality value) {
    return switch (value) {
      Nationality.brasileira => ReferencePersonLn10.nationalityOptionBrasilian,
      Nationality.estrangeira => ReferencePersonLn10.nationalityOptionForeigner,
      Nationality.nacionalizado =>
        ReferencePersonLn10.nationalityOptionNationalized,
    };
  }
}
