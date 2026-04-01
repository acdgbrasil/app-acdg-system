import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/specificities_form_state.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_section_title.dart';

/// Step 5 — Social specificities (single selection radio with conditional text).
class StepSpecificitiesContent extends StatelessWidget {
  final SpecificitiesFormState formState;
  final ValueNotifier<List<LookupItem>> identityTypeLookup;
  final bool showErrors;

  const StepSpecificitiesContent({
    super.key,
    required this.formState,
    required this.identityTypeLookup,
    this.showErrors = false,
  });

  static const _options = [
    _SpecOption('cigana', ReferencePersonLn10.specCigana),
    _SpecOption('quilombola', ReferencePersonLn10.specQuilombola),
    _SpecOption('ribeirinha', ReferencePersonLn10.specRibeirinha),
    _SpecOption('situacao_rua', ReferencePersonLn10.specHomeless),
    _SpecOption('indigena_aldeia', ReferencePersonLn10.specIndigenousVillage),
    _SpecOption('indigena_fora', ReferencePersonLn10.specIndigenousOutside),
    _SpecOption('outras', ReferencePersonLn10.specOther),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ReferencePersonLn10.specLegend,
          style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 20),
        const RegistrationSectionTitle(ReferencePersonLn10.sectionSpecificities),
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
                      Expanded(child: _buildColumn(
                        ReferencePersonLn10.specFamilyType,
                        _options.sublist(0, 4),
                        selected,
                      )),
                      const SizedBox(width: 60),
                      Expanded(child: _buildColumn(
                        ReferencePersonLn10.specIndigenousOther,
                        _options.sublist(4),
                        selected,
                      )),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildColumn(
                      ReferencePersonLn10.specFamilyType,
                      _options.sublist(0, 4),
                      selected,
                    ),
                    const SizedBox(height: 28),
                    _buildColumn(
                      ReferencePersonLn10.specIndigenousOther,
                      _options.sublist(4),
                      selected,
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

  Widget _buildColumn(String title, List<_SpecOption> options, String? selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.5,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 14),
        for (final opt in options) ...[
          RadioListTile<String>(
            title: Text(opt.label, style: const TextStyle(fontSize: 15)),
            value: opt.key,
            groupValue: selected,
            contentPadding: EdgeInsets.zero,
            dense: true,
            onChanged: (val) => formState.selectIdentity(val),
          ),
          if (SpecificitiesFormState.keysRequiringDescription.contains(opt.key) &&
              selected == opt.key)
            Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 8),
              child: TextField(
                controller: formState.identityDescription,
                decoration: InputDecoration(
                  hintText: opt.key == 'outras'
                      ? ReferencePersonLn10.specOtherPlaceholder
                      : ReferencePersonLn10.specDescriptionPlaceholder,
                  isDense: true,
                  contentPadding: const EdgeInsets.only(bottom: 5),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _SpecOption {
  const _SpecOption(this.key, this.label);
  final String key;
  final String label;
}
