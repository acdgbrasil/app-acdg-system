import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class IsShelterInput extends StatelessWidget {
  final ValueNotifier<bool?> isShelterNotifier;
  final String? errorText;

  const IsShelterInput({super.key, required this.isShelterNotifier, this.errorText});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool?>(
      valueListenable: isShelterNotifier,
      builder: (context, currentValue, _) {
        return FormField<bool>(
          initialValue: currentValue,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          builder: (FormFieldState<bool> fieldState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    text: ReferencePersonLn10.isShelterLabel,
                    style: TextStyle(color: Colors.black, fontSize: 16),
                    children: [
                      TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                RadioListTile<bool>(
                  title: const Text(ReferencePersonLn10.radioYes),
                  value: true,
                  groupValue: currentValue,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    isShelterNotifier.value = val;
                    fieldState.didChange(val);
                  },
                ),
                RadioListTile<bool>(
                  title: const Text(ReferencePersonLn10.radioNo),
                  value: false,
                  groupValue: currentValue,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    isShelterNotifier.value = val;
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
