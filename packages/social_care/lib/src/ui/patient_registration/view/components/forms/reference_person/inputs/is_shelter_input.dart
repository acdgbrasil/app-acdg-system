import 'package:design_system/design_system.dart';
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
            AcdgRadioGroup<HousingSituation>(
              value: currentValue,
              onChanged: (HousingSituation? val) {
                housingSituationNotifier.value = val;
                if (val == HousingSituation.homeless) {
                  onHomelessSelected?.call();
                }
              },
              options: const [
                AcdgRadioOption(
                  value: HousingSituation.shelter,
                  label: ReferencePersonLn10.isShelterOptionYes,
                ),
                AcdgRadioOption(
                  value: HousingSituation.regular,
                  label: ReferencePersonLn10.isShelterOptionNo,
                ),
                AcdgRadioOption(
                  value: HousingSituation.homeless,
                  label: ReferencePersonLn10.isShelterOptionHomeless,
                ),
              ],
              errorText: errorText,
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
          ],
        );
      },
    );
  }
}
