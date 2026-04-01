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
          housingSituationNotifier: formState.housingSituation,
          errorText: showErrors ? formState.housingSituationError : null,
          onHomelessSelected: formState.clearAddressFields,
        ),
        const SizedBox(height: 24),
        ResidenceLocationInput(
          residenceLocationNotifier: formState.residenceLocation,
          errorText: showErrors ? formState.residenceLocationError : null,
        ),
        const SizedBox(height: 32),
        const RegistrationSectionTitle(ReferencePersonLn10.sectionAddress),
        ValueListenableBuilder<HousingSituation?>(
          valueListenable: formState.housingSituation,
          builder: (context, situation, _) {
            final disabled = formState.areAddressFieldsDisabled;
            return RegistrationFormGrid(
              children: [
                IgnorePointer(
                  ignoring: disabled,
                  child: Opacity(
                    opacity: disabled ? 0.3 : 1.0,
                    child: CepInput(
                      cepController: formState.cep,
                      errorText: showErrors ? formState.cepError : null,
                    ),
                  ),
                ),
                IgnorePointer(
                  ignoring: disabled,
                  child: Opacity(
                    opacity: disabled ? 0.3 : 1.0,
                    child: StreetInput(
                      streetController: formState.street,
                    ),
                  ),
                ),
                IgnorePointer(
                  ignoring: disabled,
                  child: Opacity(
                    opacity: disabled ? 0.3 : 1.0,
                    child: NumberInput(
                      numberController: formState.number,
                    ),
                  ),
                ),
                IgnorePointer(
                  ignoring: disabled,
                  child: Opacity(
                    opacity: disabled ? 0.3 : 1.0,
                    child: ComplementInput(
                      complementController: formState.complement,
                    ),
                  ),
                ),
                IgnorePointer(
                  ignoring: disabled,
                  child: Opacity(
                    opacity: disabled ? 0.3 : 1.0,
                    child: NeighborhoodInput(
                      neighborhoodController: formState.neighborhood,
                    ),
                  ),
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
            );
          },
        ),
      ],
    );
  }
}
