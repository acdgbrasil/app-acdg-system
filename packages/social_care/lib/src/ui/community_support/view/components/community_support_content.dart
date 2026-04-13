import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../constants/community_support_l10n.dart';
import '../../view_models/community_support_view_model.dart';

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
            // Section: Rede de apoio
            _sectionTitle(CommunitySupportL10n.sectionSupport),
            const SizedBox(height: 16),
            _toggleRow(
              label: CommunitySupportL10n.hasRelativeSupportLabel,
              value: vm.hasRelativeSupport,
              onToggle: vm.toggleRelativeSupport,
            ),
            const SizedBox(height: 8),
            _toggleRow(
              label: CommunitySupportL10n.hasNeighborSupportLabel,
              value: vm.hasNeighborSupport,
              onToggle: vm.toggleNeighborSupport,
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),

            // Section: Conflitos familiares
            _sectionTitle(CommunitySupportL10n.sectionConflicts),
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

            // Section: Participacao social
            _sectionTitle(CommunitySupportL10n.sectionParticipation),
            const SizedBox(height: 16),
            _toggleRow(
              label: CommunitySupportL10n.patientParticipatesLabel,
              value: vm.patientParticipatesInGroups,
              onToggle: vm.togglePatientParticipates,
            ),
            const SizedBox(height: 8),
            _toggleRow(
              label: CommunitySupportL10n.familyParticipatesLabel,
              value: vm.familyParticipatesInGroups,
              onToggle: vm.toggleFamilyParticipates,
            ),
            const SizedBox(height: 8),
            _toggleRow(
              label: CommunitySupportL10n.hasLeisureAccessLabel,
              value: vm.patientHasAccessToLeisure,
              onToggle: vm.toggleLeisureAccess,
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),

            // Section: Discriminacao
            _sectionTitle(CommunitySupportL10n.sectionDiscrimination),
            const SizedBox(height: 16),
            _toggleRow(
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

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'Satoshi',
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: AppColors.textPrimary,
    ),
  );

  Widget _toggleRow({
    required String label,
    required bool value,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
