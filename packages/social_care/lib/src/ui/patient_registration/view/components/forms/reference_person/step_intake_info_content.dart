import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/intake_info_form_state.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_error_banner.dart';

import 'ingress_type_selector.dart';
import 'inputs/service_reason_input.dart';
import 'referral_details_form.dart';
import 'social_programs_selector.dart';

/// Step 6 — Intake info (forma de ingresso).
class StepIntakeInfoContent extends StatelessWidget {
  final IntakeInfoFormState formState;
  final List<LookupItem> ingressTypeLookup;
  final List<LookupItem> socialProgramsLookup;
  final bool showErrors;

  const StepIntakeInfoContent({
    super.key,
    required this.formState,
    required this.ingressTypeLookup,
    required this.socialProgramsLookup,
    this.showErrors = false,
  });

  static final _ingressOptions = [
    const IngressOption('espontaneo', ReferencePersonLn10.ingressEspontaneo),
    const IngressOption('busca_ativa', ReferencePersonLn10.ingressBuscaAtiva),
    const IngressOption('enc_saude', ReferencePersonLn10.ingressEncSaude),
    const IngressOption(
      'enc_judiciario',
      ReferencePersonLn10.ingressEncJudiciario,
    ),
    const IngressOption('enc_conselho', ReferencePersonLn10.ingressEncConselho),
    const IngressOption('enc_educacao', ReferencePersonLn10.ingressEncEducacao),
    const IngressOption(
      'enc_setoriais',
      ReferencePersonLn10.ingressEncSetoriais,
    ),
    const IngressOption('enc_psb', ReferencePersonLn10.ingressEncPsb),
    const IngressOption('enc_pse', ReferencePersonLn10.ingressEncPse),
    const IngressOption('enc_sgd', ReferencePersonLn10.ingressEncSgd),
    const IngressOption('outros', ReferencePersonLn10.ingressOutros),
  ];

  static final _programOptions = [
    ReferencePersonLn10.programBolsaFamilia,
    ReferencePersonLn10.programBpc,
    ReferencePersonLn10.programPeti,
    ReferencePersonLn10.programOutros,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showErrors)
          RegistrationErrorBanner(errors: formState.validationErrors),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: IngressTypeSelector(
                      selectedType: formState.ingressType,
                      options: _ingressOptions,
                      showErrors: showErrors,
                      errorText: formState.ingressTypeError,
                    ),
                  ),
                  const SizedBox(width: 60),
                  Expanded(
                    child: Column(
                      children: [
                        ReferralDetailsForm(
                          originNameController: formState.originName,
                          originContactController: formState.originContact,
                        ),
                        const SizedBox(height: 28),
                        SocialProgramsSelector(
                          selectedPrograms: formState.selectedPrograms,
                          options: _programOptions,
                          onToggle: formState.toggleProgram,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IngressTypeSelector(
                  selectedType: formState.ingressType,
                  options: _ingressOptions,
                  showErrors: showErrors,
                  errorText: formState.ingressTypeError,
                ),
                const SizedBox(height: 28),
                ReferralDetailsForm(
                  originNameController: formState.originName,
                  originContactController: formState.originContact,
                ),
                const SizedBox(height: 28),
                SocialProgramsSelector(
                  selectedPrograms: formState.selectedPrograms,
                  options: _programOptions,
                  onToggle: formState.toggleProgram,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ServiceReasonInput(
                      controller: formState.serviceReason,
                      errorText: showErrors
                          ? formState.serviceReasonError
                          : null,
                    ),
                  ),
                  const SizedBox(width: 60),
                  Expanded(
                    child: TextField(
                      controller: formState.programObservation,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: ReferencePersonLn10.observationsLabel,
                        hintText: ReferencePersonLn10.observationsPlaceholder,
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                ServiceReasonInput(
                  controller: formState.serviceReason,
                  errorText: showErrors ? formState.serviceReasonError : null,
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: formState.programObservation,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: ReferencePersonLn10.observationsLabel,
                    hintText: ReferencePersonLn10.observationsPlaceholder,
                    alignLabelWithHint: true,
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
