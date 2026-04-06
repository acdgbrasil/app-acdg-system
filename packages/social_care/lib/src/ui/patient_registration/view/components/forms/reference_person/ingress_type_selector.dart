import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_section_title.dart';

class IngressOption {
  const IngressOption(this.key, this.label);
  final String key;
  final String label;
}

class IngressTypeSelector extends StatelessWidget {
  final ValueNotifier<String?> selectedType;
  final List<IngressOption> options;
  final bool showErrors;
  final String? errorText;

  const IngressTypeSelector({
    super.key,
    required this.selectedType,
    required this.options,
    this.showErrors = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RegistrationSectionTitle(ReferencePersonLn10.sectionIngressType),
        ValueListenableBuilder<String?>(
          valueListenable: selectedType,
          builder: (context, selected, _) {
            return AcdgRadioGroup<String>(
              value: selected,
              onChanged: (String? val) => selectedType.value = val,
              isDense: true,
              errorText: showErrors ? errorText : null,
              options: options
                  .map(
                    (opt) => AcdgRadioOption(value: opt.key, label: opt.label),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
