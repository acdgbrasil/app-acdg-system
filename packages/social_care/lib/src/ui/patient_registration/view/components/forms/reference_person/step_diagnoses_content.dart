import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/diagnoses_form_state.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_error_banner.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_section_title.dart';

import 'diagnosis_card.dart';

class StepDiagnosesContent extends StatelessWidget {
  final DiagnosesFormState formState;
  final bool showErrors;

  const StepDiagnosesContent({
    super.key,
    required this.formState,
    this.showErrors = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showErrors)
          RegistrationErrorBanner(errors: formState.validationErrors),
        const RegistrationSectionTitle(ReferencePersonLn10.sectionDiagnoses),
        ValueListenableBuilder<List<DiagnosisEntryState>>(
          valueListenable: formState.entries,
          builder: (context, entries, _) {
            return Column(
              children: [
                for (var i = 0; i < entries.length; i++)
                  DiagnosisCard(
                    entry: entries[i],
                    index: i,
                    showErrors: showErrors,
                    onRemove: i > 0 ? () => formState.removeEntry(i) : null,
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: formState.addEntry,
                    icon: const Icon(Icons.add),
                    label: const Text(ReferencePersonLn10.addDiagnosisBtn),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
