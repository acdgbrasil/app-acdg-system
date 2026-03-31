import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/models/enums/gender.dart';

final class GenderInput extends StatelessWidget {
  final ValueNotifier<Gender?> genderNotifier;
  final String? Function(Gender?)? validator;

  const GenderInput({
    super.key,
    required this.genderNotifier,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<Gender>(
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      initialValue: genderNotifier.value,
      builder: (FormFieldState<Gender> state) {
        return ValueListenableBuilder<Gender?>(
          valueListenable: genderNotifier,
          builder: (context, currentGender, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    text: ReferencePersonLn10.genderLabel,
                    style: TextStyle(color: Colors.black, fontSize: 16),
                    children: [
                      TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Masculino'),
                  value: currentGender == Gender.masculino,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (checked) {
                    final newValue = checked == true ? Gender.masculino : null;
                    genderNotifier.value = newValue;
                    state.didChange(newValue);
                  },
                ),
                CheckboxListTile(
                  title: const Text('Feminino'),
                  value: currentGender == Gender.feminino,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (checked) {
                    final newValue = checked == true ? Gender.feminino : null;
                    genderNotifier.value = newValue;
                    state.didChange(newValue);
                  },
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
