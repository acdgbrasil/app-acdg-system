import 'package:flutter/material.dart';
import 'package:social_care/src/constants/brazilian_states.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class StateInput extends StatelessWidget {
  final ValueNotifier<String?> stateNotifier;
  final String? errorText;

  const StateInput({super.key, required this.stateNotifier, this.errorText});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: stateNotifier,
      builder: (context, currentState, _) {
        return DropdownButtonFormField<String>(
          value: currentState,
          decoration: InputDecoration(
            label: RichText(
              text: const TextSpan(
                text: ReferencePersonLn10.stateLabel,
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            hintText: ReferencePersonLn10.statePlaceholder,
            errorText: errorText,
          ),
          items: BrazilianStates.abbreviations.map((uf) {
            return DropdownMenuItem<String>(
              value: uf,
              child: Text('$uf — ${BrazilianStates.names[uf]}'),
            );
          }).toList(),
          onChanged: (newValue) => stateNotifier.value = newValue,
        );
      },
    );
  }
}
