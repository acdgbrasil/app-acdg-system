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
        _CidCallout(
          onApply: () => formState.applyQuickCid(
            0,
            'Z03.9',
            ReferencePersonLn10.cidZ039Description,
          ),
        ),
        const SizedBox(height: 8),
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

/// Callout card suggesting CID Z03.9 for patients without a closed diagnosis.
class _CidCallout extends StatelessWidget {
  final VoidCallback onApply;

  const _CidCallout({required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4F8448).withValues(alpha: 0.07),
        border: Border.all(
          color: const Color(0xFF4F8448).withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 12, top: 2),
            child: Icon(Icons.lightbulb_outline, color: Color(0xFF4F8448), size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  ReferencePersonLn10.cidCalloutTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF4F8448),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  ReferencePersonLn10.cidCalloutText,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onApply,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Z03.9',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: Color(0xFF4F8448),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          ReferencePersonLn10.cidCalloutChipLabel,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
