import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/intake_info_form_state.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_error_banner.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_section_title.dart';

import 'inputs/service_reason_input.dart';

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
    const _IngressOption('espontaneo', ReferencePersonLn10.ingressEspontaneo),
    const _IngressOption('busca_ativa', ReferencePersonLn10.ingressBuscaAtiva),
    const _IngressOption('enc_saude', ReferencePersonLn10.ingressEncSaude),
    const _IngressOption('enc_judiciario', ReferencePersonLn10.ingressEncJudiciario),
    const _IngressOption('enc_conselho', ReferencePersonLn10.ingressEncConselho),
    const _IngressOption('enc_educacao', ReferencePersonLn10.ingressEncEducacao),
    const _IngressOption('enc_setoriais', ReferencePersonLn10.ingressEncSetoriais),
    const _IngressOption('enc_psb', ReferencePersonLn10.ingressEncPsb),
    const _IngressOption('enc_pse', ReferencePersonLn10.ingressEncPse),
    const _IngressOption('enc_sgd', ReferencePersonLn10.ingressEncSgd),
    const _IngressOption('outros', ReferencePersonLn10.ingressOutros),
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
                  Expanded(child: _buildIngressColumn()),
                  const SizedBox(width: 60),
                  Expanded(child: _buildRightColumn()),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIngressColumn(),
                const SizedBox(height: 28),
                _buildRightColumn(),
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
                      errorText: showErrors ? formState.serviceReasonError : null,
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

  Widget _buildIngressColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RegistrationSectionTitle(ReferencePersonLn10.sectionIngressType),
        ValueListenableBuilder<String?>(
          valueListenable: formState.ingressType,
          builder: (context, selected, _) {
            return Column(
              children: [
                for (final opt in _ingressOptions)
                  RadioListTile<String>(
                    title: Text(opt.label, style: const TextStyle(fontSize: 14)),
                    value: opt.key,
                    groupValue: selected,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (val) => formState.ingressType.value = val,
                  ),
              ],
            );
          },
        ),
        if (showErrors && formState.ingressTypeError != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              formState.ingressTypeError!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RegistrationSectionTitle(ReferencePersonLn10.sectionReferralDetails),
        TextField(
          controller: formState.originName,
          decoration: const InputDecoration(
            labelText: ReferencePersonLn10.originNameLabel,
            hintText: ReferencePersonLn10.originNamePlaceholder,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: formState.originContact,
          decoration: const InputDecoration(
            labelText: ReferencePersonLn10.originContactLabel,
            hintText: ReferencePersonLn10.originContactPlaceholder,
          ),
        ),
        const SizedBox(height: 28),
        const RegistrationSectionTitle(ReferencePersonLn10.sectionSocialPrograms),
        Text(
          ReferencePersonLn10.socialProgramsHint,
          style: TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 14),
        ValueListenableBuilder<Set<String>>(
          valueListenable: formState.selectedPrograms,
          builder: (context, selected, _) {
            return Column(
              children: [
                for (final prog in _programOptions)
                  CheckboxListTile(
                    title: Text(prog, style: const TextStyle(fontSize: 15)),
                    value: selected.contains(prog),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (_) => formState.toggleProgram(prog),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _IngressOption {
  const _IngressOption(this.key, this.label);
  final String key;
  final String label;
}
