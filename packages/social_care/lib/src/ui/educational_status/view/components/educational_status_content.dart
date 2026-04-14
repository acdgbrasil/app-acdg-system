import 'package:flutter/material.dart';

import '../../constants/educational_status_l10n.dart';
import '../../view_models/educational_status_view_model.dart';
import 'educational_status_add_button.dart';
import 'educational_status_empty_state.dart';
import 'educational_status_occurrence_card.dart';
import 'educational_status_profile_card.dart';
import 'educational_status_section_title.dart';

class EducationalStatusContent extends StatelessWidget {
  const EducationalStatusContent({super.key, required this.viewModel});
  final EducationalStatusViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EducationalStatusSectionTitle(
              text: EducationalStatusL10n.sectionProfiles,
            ),
            const SizedBox(height: 16),
            if (viewModel.memberProfiles.isEmpty)
              const EducationalStatusEmptyState(
                text: EducationalStatusL10n.noProfiles,
              ),
            for (int i = 0; i < viewModel.memberProfiles.length; i++) ...[
              EducationalStatusProfileCard(
                profile: viewModel.memberProfiles[i],
                familyMembers: viewModel.familyMembers,
                educationLevelLookup: viewModel.educationLevelLookup,
                onMemberChanged: (v) => viewModel.updateProfileMember(i, v),
                onEducationLevelChanged: (v) =>
                    viewModel.updateProfileEducationLevel(i, v),
                onToggleCanReadWrite: () =>
                    viewModel.toggleProfileCanReadWrite(i),
                onToggleAttendsSchool: () =>
                    viewModel.toggleProfileAttendsSchool(i),
                onRemove: () => viewModel.removeProfile(i),
              ),
              const SizedBox(height: 12),
            ],
            EducationalStatusAddButton(
              label: EducationalStatusL10n.addProfile,
              onTap: viewModel.addProfile,
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),
            const EducationalStatusSectionTitle(
              text: EducationalStatusL10n.sectionOccurrences,
            ),
            const SizedBox(height: 16),
            if (viewModel.programOccurrences.isEmpty)
              const EducationalStatusEmptyState(
                text: EducationalStatusL10n.noOccurrences,
              ),
            for (int i = 0; i < viewModel.programOccurrences.length; i++) ...[
              EducationalStatusOccurrenceCard(
                occurrence: viewModel.programOccurrences[i],
                familyMembers: viewModel.familyMembers,
                effectLookup: viewModel.effectLookup,
                onMemberChanged: (v) => viewModel.updateOccurrenceMember(i, v),
                onDateChanged: (v) => viewModel.updateOccurrenceDate(i, v),
                onEffectChanged: (v) => viewModel.updateOccurrenceEffect(i, v),
                onToggleSuspension: () =>
                    viewModel.toggleOccurrenceSuspension(i),
                onRemove: () => viewModel.removeOccurrence(i),
              ),
              const SizedBox(height: 12),
            ],
            EducationalStatusAddButton(
              label: EducationalStatusL10n.addOccurrence,
              onTap: viewModel.addOccurrence,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
