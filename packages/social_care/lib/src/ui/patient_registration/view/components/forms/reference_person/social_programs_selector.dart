import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_section_title.dart';

class SocialProgramsSelector extends StatelessWidget {
  final ValueNotifier<Set<String>> selectedPrograms;
  final List<String> options;
  final ValueChanged<String> onToggle;

  const SocialProgramsSelector({
    super.key,
    required this.selectedPrograms,
    required this.options,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RegistrationSectionTitle(
          ReferencePersonLn10.sectionSocialPrograms,
        ),
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
          valueListenable: selectedPrograms,
          builder: (context, selected, _) {
            return Column(
              children: [
                for (final prog in options)
                  CheckboxListTile(
                    title: Text(prog, style: const TextStyle(fontSize: 15)),
                    value: selected.contains(prog),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (_) => onToggle(prog),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
