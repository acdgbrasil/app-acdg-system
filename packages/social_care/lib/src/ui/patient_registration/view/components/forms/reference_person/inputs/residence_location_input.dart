import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class ResidenceLocationInput extends StatelessWidget {
  final ValueNotifier<String?> residenceLocationNotifier;
  final String? errorText;

  const ResidenceLocationInput({super.key, required this.residenceLocationNotifier, this.errorText});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: residenceLocationNotifier,
      builder: (context, currentValue, _) {
        return FormField<String>(
          initialValue: currentValue,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          builder: (FormFieldState<String> fieldState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    text: ReferencePersonLn10.residenceLocationLabel,
                    style: TextStyle(color: Colors.black, fontSize: 16),
                    children: [
                      TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text(ReferencePersonLn10.radioUrban),
                  value: 'urbano',
                  groupValue: currentValue,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    residenceLocationNotifier.value = val;
                    fieldState.didChange(val);
                  },
                ),
                RadioListTile<String>(
                  title: const Text(ReferencePersonLn10.radioRural),
                  value: 'rural',
                  groupValue: currentValue,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    residenceLocationNotifier.value = val;
                    fieldState.didChange(val);
                  },
                ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8),
                    child: Text(
                      errorText!,
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
