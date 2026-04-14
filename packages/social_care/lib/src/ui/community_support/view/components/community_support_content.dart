import 'package:flutter/material.dart';

import '../../constants/community_support_l10n.dart';
import '../../view_models/community_support_view_model.dart';
import 'community_support_section_title.dart';
import 'community_support_toggle_row.dart';

class CommunitySupportContent extends StatefulWidget {
  const CommunitySupportContent({super.key, required this.viewModel});

  final CommunitySupportViewModel viewModel;

  @override
  State<CommunitySupportContent> createState() =>
      _CommunitySupportContentState();
}

class _CommunitySupportContentState extends State<CommunitySupportContent> {
  late final TextEditingController _conflictsController;

  CommunitySupportViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _conflictsController = TextEditingController(text: vm.familyConflicts)
      ..addListener(() => vm.updateFamilyConflicts(_conflictsController.text));
    vm.addListener(_syncController);
  }

  void _syncController() {
    if (_conflictsController.text != vm.familyConflicts) {
      _conflictsController.text = vm.familyConflicts;
    }
  }

  @override
  void dispose() {
    vm.removeListener(_syncController);
    _conflictsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CommunitySupportSectionTitle(
              text: CommunitySupportL10n.sectionSupport,
            ),
            const SizedBox(height: 16),
            CommunitySupportToggleRow(
              label: CommunitySupportL10n.hasRelativeSupportLabel,
              value: vm.hasRelativeSupport,
              onToggle: vm.toggleRelativeSupport,
            ),
            const SizedBox(height: 8),
            CommunitySupportToggleRow(
              label: CommunitySupportL10n.hasNeighborSupportLabel,
              value: vm.hasNeighborSupport,
              onToggle: vm.toggleNeighborSupport,
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),

            const CommunitySupportSectionTitle(
              text: CommunitySupportL10n.sectionConflicts,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _conflictsController,
              maxLines: 5,
              maxLength: 300,
              decoration: InputDecoration(
                labelText: CommunitySupportL10n.familyConflictsLabel,
                hintText: CommunitySupportL10n.familyConflictsHint,
                alignLabelWithHint: true,
                counterText: '${vm.conflictsRemaining} caracteres restantes',
              ),
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),

            const CommunitySupportSectionTitle(
              text: CommunitySupportL10n.sectionParticipation,
            ),
            const SizedBox(height: 16),
            CommunitySupportToggleRow(
              label: CommunitySupportL10n.patientParticipatesLabel,
              value: vm.patientParticipatesInGroups,
              onToggle: vm.togglePatientParticipates,
            ),
            const SizedBox(height: 8),
            CommunitySupportToggleRow(
              label: CommunitySupportL10n.familyParticipatesLabel,
              value: vm.familyParticipatesInGroups,
              onToggle: vm.toggleFamilyParticipates,
            ),
            const SizedBox(height: 8),
            CommunitySupportToggleRow(
              label: CommunitySupportL10n.hasLeisureAccessLabel,
              value: vm.patientHasAccessToLeisure,
              onToggle: vm.toggleLeisureAccess,
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),

            const CommunitySupportSectionTitle(
              text: CommunitySupportL10n.sectionDiscrimination,
            ),
            const SizedBox(height: 16),
            CommunitySupportToggleRow(
              label: CommunitySupportL10n.facesDiscriminationLabel,
              value: vm.facesDiscrimination,
              onToggle: vm.toggleDiscrimination,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
