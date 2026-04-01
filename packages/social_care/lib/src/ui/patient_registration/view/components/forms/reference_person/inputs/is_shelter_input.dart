import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import '../address_form_state.dart';

final class IsShelterInput extends StatelessWidget {
  final ValueNotifier<HousingSituation?> housingSituationNotifier;
  final String? errorText;
  final VoidCallback? onHomelessSelected;

  const IsShelterInput({
    super.key,
    required this.housingSituationNotifier,
    this.errorText,
    this.onHomelessSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HousingSituation?>(
      valueListenable: housingSituationNotifier,
      builder: (context, currentValue, _) {
        return FormField<HousingSituation>(
          initialValue: currentValue,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          builder: (FormFieldState<HousingSituation> fieldState) {
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
                RadioListTile<HousingSituation>(
                  title: const Text(ReferencePersonLn10.isShelterOptionYes),
                  value: HousingSituation.shelter,
                  groupValue: currentValue,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    housingSituationNotifier.value = val;
                    fieldState.didChange(val);
                  },
                ),
                RadioListTile<HousingSituation>(
                  title: const Text(ReferencePersonLn10.isShelterOptionNo),
                  value: HousingSituation.regular,
                  groupValue: currentValue,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    housingSituationNotifier.value = val;
                    fieldState.didChange(val);
                  },
                ),
                RadioListTile<HousingSituation>(
                  title: const Text(ReferencePersonLn10.isShelterOptionHomeless),
                  value: HousingSituation.homeless,
                  groupValue: currentValue,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    housingSituationNotifier.value = val;
                    fieldState.didChange(val);
                    onHomelessSelected?.call();
                  },
                ),
                if (currentValue == HousingSituation.homeless)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text(
                      ReferencePersonLn10.homelessWarning,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
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
