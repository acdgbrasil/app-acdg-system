import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/diagnoses_form_state.dart';

import 'inputs/diagnosis_date_input.dart';
import 'inputs/diagnosis_description_input.dart';
import 'inputs/icd_code_input.dart';

class DiagnosisCard extends StatelessWidget {
  final DiagnosisEntryState entry;
  final int index;
  final bool showErrors;
  final VoidCallback? onRemove;

  const DiagnosisCard({
    super.key,
    required this.entry,
    required this.index,
    this.showErrors = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${ReferencePersonLn10.diagnosisCardTitle} ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.red),
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: 16),
          IcdCodeInput(
            icdCodeController: entry.icdCode,
            errorText: showErrors ? entry.icdCodeError : null,
          ),
          const SizedBox(height: 20),
          DiagnosisDateInput(
            dateController: entry.date,
            errorText: showErrors ? entry.dateError : null,
          ),
          const SizedBox(height: 20),
          DiagnosisDescriptionInput(
            descriptionController: entry.description,
            errorText: showErrors ? entry.descriptionError : null,
          ),
        ],
      ),
    );
  }
}
