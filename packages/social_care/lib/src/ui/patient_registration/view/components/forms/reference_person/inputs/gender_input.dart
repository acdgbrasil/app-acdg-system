import 'package:design_system/design_system.dart';
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
                AcdgRadioGroup<Gender>(
                  value: currentGender,
                  onChanged: (Gender? val) {
                    genderNotifier.value = val;
                    state.didChange(val);
                  },
                  options: const [
                    AcdgRadioOption(
                      value: Gender.masculino,
                      label: ReferencePersonLn10.genderOptionMale,
                    ),
                    AcdgRadioOption(
                      value: Gender.feminino,
                      label: ReferencePersonLn10.genderOptionFemale,
                    ),
                    AcdgRadioOption(
                      value: Gender.outro,
                      label: ReferencePersonLn10.genderOptionOther,
                    ),
                  ],
                  errorText: state.errorText,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
