import 'package:flutter/material.dart';
import 'package:social_care/src/constants/brazilian_states.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class RgUfInput extends StatelessWidget {
  final ValueNotifier<String?> rgUfNotifier;
  final String? errorText;

  const RgUfInput({super.key, required this.rgUfNotifier, this.errorText});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: rgUfNotifier,
      builder: (context, currentUf, _) {
        return DropdownButtonFormField<String>(
          value: currentUf,
          decoration: InputDecoration(
            label: const Text(
              ReferencePersonLn10.rgUfLabel,
              style: TextStyle(color: Colors.black),
            ),
            hintText: ReferencePersonLn10.rgUfPlaceholder,
            errorText: errorText,
          ),
          items: BrazilianStates.abbreviations.map((uf) {
            return DropdownMenuItem<String>(
              value: uf,
              child: Text('$uf — ${BrazilianStates.names[uf]}'),
            );
          }).toList(),
          onChanged: (newValue) => rgUfNotifier.value = newValue,
        );
      },
    );
  }
}
