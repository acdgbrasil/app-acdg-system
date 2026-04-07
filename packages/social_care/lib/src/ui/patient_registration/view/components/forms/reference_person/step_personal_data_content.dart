import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/personal_data_form_state.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_error_banner.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_form_grid.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_section_title.dart';

import 'inputs/first_name_input.dart';
import 'inputs/gender_input.dart';
import 'inputs/last_name_input.dart';
import 'inputs/mother_name_input.dart';
import 'inputs/nationality_input.dart';
import 'inputs/phone_number_input.dart';
import 'inputs/social_name_input.dart';

class StepPersonalDataContent extends StatelessWidget {
  final PersonalDataFormState formState;
  final bool showErrors;

  const StepPersonalDataContent({
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
        const RegistrationSectionTitle(
          ReferencePersonLn10.identificationSectionTitle,
        ),
        RegistrationFormGrid(
          children: [
            FirstNameInput(
              firstNameController: formState.firstName,
              errorText: showErrors ? formState.firstNameError : null,
              validator: formState.firstNameValidator,
            ),
            LastNameInput(
              lastNameController: formState.lastName,
              errorText: showErrors ? formState.lastNameError : null,
              validator: formState.lastNameValidator,
            ),
            SocialNameInput(
              socialNameController: formState.socialName,
              errorText: showErrors ? formState.socialNameError : null,
              validator: formState.socialNameValidator,
            ),
            MotherNameInput(
              motherNameController: formState.motherName,
              errorText: showErrors ? formState.motherNameError : null,
              validator: formState.motherNameValidator,
            ),
            NationalityInput(
              nationalityNotifier: formState.nationality,
              validator: formState.nationalityValidator,
            ),
            GenderInput(
              genderNotifier: formState.gender,
              validator: formState.genderValidator,
            ),
            PhoneNumberInput(
              phoneNumberController: formState.phoneNumber,
              errorText: showErrors ? formState.phoneNumberError : null,
              validator: formState.phoneNumberValidator,
            ),
          ],
        ),
      ],
    );
  }
}
