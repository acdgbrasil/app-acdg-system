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
                RadioListTile<Gender>(
                  title: const Text(ReferencePersonLn10.genderOptionMale),
                  value: Gender.masculino,
                  groupValue: currentGender,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    genderNotifier.value = val;
                    state.didChange(val);
                  },
                ),
                RadioListTile<Gender>(
                  title: const Text(ReferencePersonLn10.genderOptionFemale),
                  value: Gender.feminino,
                  groupValue: currentGender,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    genderNotifier.value = val;
                    state.didChange(val);
                  },
                ),
                RadioListTile<Gender>(
                  title: const Text(ReferencePersonLn10.genderOptionOther),
                  value: Gender.outro,
                  groupValue: currentGender,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    genderNotifier.value = val;
                    state.didChange(val);
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
