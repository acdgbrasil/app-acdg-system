import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/specificities_form_state.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_section_title.dart';
import 'specificity_column.dart';

/// Step 5 — Social specificities (single selection radio with conditional text).
class StepSpecificitiesContent extends StatelessWidget {
  final SpecificitiesFormState formState;
  final List<LookupItem> identityTypeLookup;
  final bool showErrors;

  const StepSpecificitiesContent({
    super.key,
    required this.formState,
    required this.identityTypeLookup,
    this.showErrors = false,
  });

  static const _options = [
    SpecOption('cigana', ReferencePersonLn10.specCigana),
    SpecOption('quilombola', ReferencePersonLn10.specQuilombola),
    SpecOption('ribeirinha', ReferencePersonLn10.specRibeirinha),
    SpecOption('situacao_rua', ReferencePersonLn10.specHomeless),
    SpecOption('indigena_aldeia', ReferencePersonLn10.specIndigenousVillage),
    SpecOption('indigena_fora', ReferencePersonLn10.specIndigenousOutside),
    SpecOption('outras', ReferencePersonLn10.specOther),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ReferencePersonLn10.specLegend,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 20),
        const RegistrationSectionTitle(
          ReferencePersonLn10.sectionSpecificities,
        ),
        ValueListenableBuilder<String?>(
          valueListenable: formState.selectedIdentity,
          builder: (context, selected, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SpecificityColumn(
                          title: ReferencePersonLn10.specFamilyType,
                          options: _options.sublist(0, 4),
                          selected: selected,
                          onSelected: formState.selectIdentity,
                          descriptionController: formState.identityDescription,
                          keysRequiringDescription:
                              SpecificitiesFormState.keysRequiringDescription,
                        ),
                      ),
                      const SizedBox(width: 60),
                      Expanded(
                        child: SpecificityColumn(
                          title: ReferencePersonLn10.specIndigenousOther,
                          options: _options.sublist(4),
                          selected: selected,
                          onSelected: formState.selectIdentity,
                          descriptionController: formState.identityDescription,
                          keysRequiringDescription:
                              SpecificitiesFormState.keysRequiringDescription,
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SpecificityColumn(
                      title: ReferencePersonLn10.specFamilyType,
                      options: _options.sublist(0, 4),
                      selected: selected,
                      onSelected: formState.selectIdentity,
                      descriptionController: formState.identityDescription,
                      keysRequiringDescription:
                          SpecificitiesFormState.keysRequiringDescription,
                    ),
                    const SizedBox(height: 28),
                    SpecificityColumn(
                      title: ReferencePersonLn10.specIndigenousOther,
                      options: _options.sublist(4),
                      selected: selected,
                      onSelected: formState.selectIdentity,
                      descriptionController: formState.identityDescription,
                      keysRequiringDescription:
                          SpecificitiesFormState.keysRequiringDescription,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}
