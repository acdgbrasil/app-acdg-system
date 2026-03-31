import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/address_form_state.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_error_banner.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_form_grid.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_section_title.dart';

import 'inputs/cep_input.dart';
import 'inputs/city_input.dart';
import 'inputs/complement_input.dart';
import 'inputs/is_shelter_input.dart';
import 'inputs/neighborhood_input.dart';
import 'inputs/number_input.dart';
import 'inputs/residence_location_input.dart';
import 'inputs/state_input.dart';
import 'inputs/street_input.dart';

class StepAddressContent extends StatelessWidget {
  final AddressFormState formState;
  final bool showErrors;

  const StepAddressContent({
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
        IsShelterInput(
          isShelterNotifier: formState.isShelter,
          errorText: showErrors ? formState.isShelterError : null,
        ),
        const SizedBox(height: 24),
        ResidenceLocationInput(
          residenceLocationNotifier: formState.residenceLocation,
          errorText: showErrors ? formState.residenceLocationError : null,
        ),
        const SizedBox(height: 32),
        const RegistrationSectionTitle(ReferencePersonLn10.sectionAddress),
        RegistrationFormGrid(
          children: [
            CepInput(
              cepController: formState.cep,
              errorText: showErrors ? formState.cepError : null,
            ),
            StreetInput(
              streetController: formState.street,
            ),
            NumberInput(
              numberController: formState.number,
            ),
            ComplementInput(
              complementController: formState.complement,
            ),
            NeighborhoodInput(
              neighborhoodController: formState.neighborhood,
            ),
            StateInput(
              stateNotifier: formState.state,
              errorText: showErrors ? formState.stateError : null,
            ),
            CityInput(
              cityController: formState.city,
              errorText: showErrors ? formState.cityError : null,
            ),
          ],
        ),
      ],
    );
  }
}
