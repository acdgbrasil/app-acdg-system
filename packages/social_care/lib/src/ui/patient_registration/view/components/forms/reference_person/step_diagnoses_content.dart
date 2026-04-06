import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/diagnoses_form_state.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_error_banner.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_section_title.dart';

import 'cid_callout.dart';
import 'diagnosis_card.dart';

class StepDiagnosesContent extends StatelessWidget {
  final ValueNotifier<List<DiagnosisEntryState>> entries;
  final List<String> validationErrors;
  final VoidCallback onApplyQuickCid;
  final VoidCallback onAddEntry;
  final void Function(int index) onRemoveEntry;
  final bool showErrors;

  const StepDiagnosesContent({
    super.key,
    required this.entries,
    required this.validationErrors,
    required this.onApplyQuickCid,
    required this.onAddEntry,
    required this.onRemoveEntry,
    this.showErrors = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showErrors) RegistrationErrorBanner(errors: validationErrors),
        CidCallout(onApply: onApplyQuickCid),
        const SizedBox(height: 8),
        const RegistrationSectionTitle(ReferencePersonLn10.sectionDiagnoses),
        ValueListenableBuilder<List<DiagnosisEntryState>>(
          valueListenable: entries,
          builder: (context, entryList, _) {
            return Column(
              children: [
                for (var i = 0; i < entryList.length; i++)
                  DiagnosisCard(
                    entry: entryList[i],
                    index: i,
                    showErrors: showErrors,
                    onRemove: i > 0 ? () => onRemoveEntry(i) : null,
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onAddEntry,
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
