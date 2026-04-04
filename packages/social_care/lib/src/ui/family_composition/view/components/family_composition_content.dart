import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../models/family_member_model.dart';
import '../../view_models/family_composition_view_model.dart';
import 'age_profile_panel.dart';
import 'empty_state.dart';
import 'family_composition_specificities.dart';
import 'family_table.dart';

/// The scrollable body content of [FamilyCompositionPage].
///
/// Contains the family table, empty state, specificities panel and age profile.
/// Extracted to enforce 1 Widget = 1 File (SRP).
class FamilyCompositionContent extends StatelessWidget {
  const FamilyCompositionContent({
    super.key,
    required this.viewModel,
    required this.onEdit,
    required this.onRemove,
    required this.onToggleCaregiver,
    required this.onAddMember,
  });

  final FamilyCompositionViewModel viewModel;
  final void Function(FamilyMemberModel member) onEdit;
  final void Function(FamilyMemberModel member) onRemove;
  final void Function(FamilyMemberModel member) onToggleCaregiver;
  final VoidCallback onAddMember;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (viewModel.errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 13,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          FamilyTable(
            members: viewModel.members,
            onToggleDoc: viewModel.toggleDocument,
            onEdit: onEdit,
            onRemove: onRemove,
            onToggleCaregiver: onToggleCaregiver,
          ),
          if (viewModel.isEmpty) ...[
            const SizedBox(height: 16),
            const FamilyEmptyState(),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Divider(color: AppColors.inputLine),
          ),
          LayoutBuilder(builder: (context, c) {
            final spec = FamilyCompositionSpecificities(
              items: viewModel.specificityLookup,
              selectedId: viewModel.selectedSpecificityId,
              onSelected: viewModel.updateSpecificity,
            );
            final age = AgeProfilePanel(ageProfile: viewModel.ageProfile);
            return c.maxWidth > 600
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: spec),
                    const SizedBox(width: 40),
                    Expanded(child: age),
                  ])
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    spec,
                    const SizedBox(height: 28),
                    age,
                  ]);
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
