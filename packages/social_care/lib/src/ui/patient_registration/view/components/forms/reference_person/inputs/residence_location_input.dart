import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

final class ResidenceLocationInput extends StatelessWidget {
  final ValueNotifier<String?> residenceLocationNotifier;
  final String? errorText;

  const ResidenceLocationInput({
    super.key,
    required this.residenceLocationNotifier,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: residenceLocationNotifier,
      builder: (context, currentValue, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                text: ReferencePersonLn10.residenceLocationLabel,
                style: TextStyle(color: Colors.black, fontSize: 16),
                children: [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AcdgRadioGroup<String>(
              value: currentValue,
              onChanged: (String? val) => residenceLocationNotifier.value = val,
              options: const [
                AcdgRadioOption(
                  value: 'urbano',
                  label: ReferencePersonLn10.radioUrban,
                ),
                AcdgRadioOption(
                  value: 'rural',
                  label: ReferencePersonLn10.radioRural,
                ),
              ],
              errorText: errorText,
            ),
          ],
        );
      },
    );
  }
}
