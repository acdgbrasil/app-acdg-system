import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/documents_form_state.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_error_banner.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_form_grid.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_section_title.dart';

import 'inputs/birth_date_input.dart';
import 'inputs/cns_input.dart';
import 'inputs/cpf_input.dart';
import 'inputs/nis_input.dart';
import 'inputs/rg_agency_input.dart';
import 'inputs/rg_date_input.dart';
import 'inputs/rg_number_input.dart';
import 'inputs/rg_uf_input.dart';

class StepDocumentsContent extends StatelessWidget {
  final DocumentsFormState formState;
  final bool showErrors;

  const StepDocumentsContent({
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
        const RegistrationSectionTitle(ReferencePersonLn10.sectionDocuments),
        RegistrationFormGrid(
          children: [
            CpfInput(
              cpfController: formState.cpf,
              errorText: showErrors ? formState.cpfError : null,
            ),
            NisInput(
              nisController: formState.nis,
              errorText: showErrors ? formState.nisError : null,
            ),
            CnsInput(
              cnsController: formState.cnsNumber,
              errorText: showErrors ? formState.cnsError : null,
            ),
          ],
        ),
        const SizedBox(height: 32),
        const RegistrationSectionTitle(ReferencePersonLn10.sectionRg),
        RegistrationFormGrid(
          children: [
            RgNumberInput(
              rgNumberController: formState.rgNumber,
              errorText: showErrors ? formState.rgNumberError : null,
            ),
            RgUfInput(
              rgUfNotifier: formState.rgUf,
              errorText: showErrors ? formState.rgUfError : null,
            ),
            RgAgencyInput(
              rgAgencyController: formState.rgAgency,
              errorText: showErrors ? formState.rgAgencyError : null,
            ),
            RgDateInput(
              rgDateController: formState.rgDate,
              errorText: showErrors ? formState.rgDateError : null,
            ),
          ],
        ),
        const SizedBox(height: 32),
        const RegistrationSectionTitle(ReferencePersonLn10.sectionBirth),
        BirthDateInput(
          birthDateController: formState.birthDate,
          errorText: showErrors ? formState.birthDateError : null,
        ),
      ],
    );
  }
}
