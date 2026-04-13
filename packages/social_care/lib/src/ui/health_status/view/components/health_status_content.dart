import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/health_status_l10n.dart';
import '../../view_models/health_status_view_model.dart';

class HealthStatusContent extends StatelessWidget {
  const HealthStatusContent({super.key, required this.viewModel});

  final HealthStatusViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeficienciesSection(),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),
            _buildGestatingSection(),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),
            _buildCareNeedsSection(),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),
            _buildFoodInsecuritySection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Section: Deficiencias ───────────────────────────────────

  Widget _buildDeficienciesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(HealthStatusL10n.sectionDeficiencies),
        const SizedBox(height: 16),
        if (viewModel.deficiencies.isEmpty)
          _emptyState(HealthStatusL10n.noDeficiencies),
        for (int i = 0; i < viewModel.deficiencies.length; i++) ...[
          _buildDeficiencyCard(i),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        _addButton(
          label: HealthStatusL10n.addDeficiency,
          onTap: viewModel.addDeficiency,
        ),
      ],
    );
  }

  Widget _buildDeficiencyCard(int index) {
    final row = viewModel.deficiencies[index];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _memberDropdown(
                  label: HealthStatusL10n.deficiencyMemberLabel,
                  value: row.memberId,
                  onChanged: (id) =>
                      viewModel.updateDeficiencyMember(index, id),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _lookupDropdown(
                  label: HealthStatusL10n.deficiencyTypeLabel,
                  value: row.deficiencyTypeId,
                  items: viewModel.deficiencyTypeLookup,
                  onChanged: (id) =>
                      viewModel.updateDeficiencyType(index, id),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _toggleRow(
            label: HealthStatusL10n.deficiencyNeedsConstantCareLabel,
            value: row.needsConstantCare,
            onToggle: () => viewModel.toggleDeficiencyConstantCare(index),
          ),
          if (row.needsConstantCare) ...[
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(
                text: row.responsibleCaregiverName,
              ),
              decoration: const InputDecoration(
                labelText: HealthStatusL10n.deficiencyResponsibleLabel,
                hintText: HealthStatusL10n.deficiencyResponsibleHint,
              ),
              onChanged: (value) =>
                  viewModel.updateDeficiencyResponsible(index, value),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => viewModel.removeDeficiency(index),
              icon: const Icon(Icons.remove_circle_outline,
                  size: 16, color: AppColors.danger),
              label: const Text(
                HealthStatusL10n.removeDeficiency,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  color: AppColors.danger,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section: Gestantes ──────────────────────────────────────

  Widget _buildGestatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(HealthStatusL10n.sectionGestating),
        const SizedBox(height: 16),
        if (viewModel.gestatingMembers.isEmpty)
          _emptyState(HealthStatusL10n.noGestating),
        for (int i = 0; i < viewModel.gestatingMembers.length; i++) ...[
          _buildGestatingCard(i),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        _addButton(
          label: HealthStatusL10n.addGestating,
          onTap: viewModel.addGestating,
        ),
      ],
    );
  }

  Widget _buildGestatingCard(int index) {
    final row = viewModel.gestatingMembers[index];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _memberDropdown(
                  label: HealthStatusL10n.gestatingMemberLabel,
                  value: row.memberId,
                  onChanged: (id) =>
                      viewModel.updateGestatingMember(index, id),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 160,
                child: TextField(
                  controller: TextEditingController(
                    text: row.monthsGestation.toString(),
                  ),
                  decoration: const InputDecoration(
                    labelText: HealthStatusL10n.gestatingMonthsLabel,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (text) {
                    final parsed = int.tryParse(text);
                    if (parsed != null) {
                      viewModel.updateGestatingMonths(index, parsed);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _toggleRow(
            label: HealthStatusL10n.gestatingPrenatalLabel,
            value: row.startedPrenatalCare,
            onToggle: () => viewModel.toggleGestatingPrenatal(index),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => viewModel.removeGestating(index),
              icon: const Icon(Icons.remove_circle_outline,
                  size: 16, color: AppColors.danger),
              label: const Text(
                HealthStatusL10n.removeGestating,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  color: AppColors.danger,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section: Necessidade de cuidados ────────────────────────

  Widget _buildCareNeedsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(HealthStatusL10n.sectionCareNeeds),
        const SizedBox(height: 16),
        if (viewModel.constantCareNeeds.isEmpty)
          _emptyState(HealthStatusL10n.noCareNeeds),
        for (int i = 0; i < viewModel.constantCareNeeds.length; i++) ...[
          Row(
            children: [
              Expanded(
                child: _memberDropdown(
                  label: HealthStatusL10n.careNeedsMemberLabel,
                  value: viewModel.constantCareNeeds[i].isEmpty
                      ? null
                      : viewModel.constantCareNeeds[i],
                  onChanged: (id) =>
                      viewModel.updateCareNeedMember(i, id),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => viewModel.removeCareNeed(i),
                icon: const Icon(Icons.remove_circle_outline,
                    size: 20, color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        _addButton(
          label: HealthStatusL10n.addCareNeed,
          onTap: viewModel.addCareNeed,
        ),
      ],
    );
  }

  // ── Section: Inseguranca alimentar ──────────────────────────

  Widget _buildFoodInsecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(HealthStatusL10n.sectionFoodInsecurity),
        const SizedBox(height: 16),
        _toggleRow(
          label: HealthStatusL10n.foodInsecurityLabel,
          value: viewModel.foodInsecurity,
          onToggle: viewModel.toggleFoodInsecurity,
        ),
      ],
    );
  }

  // ── Shared widgets ─────────────────────────────────────────

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'Satoshi',
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: AppColors.textPrimary,
    ),
  );

  Widget _emptyState(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 14,
        color: AppColors.textPrimary.withValues(alpha: 0.5),
        fontStyle: FontStyle.italic,
      ),
    ),
  );

  Widget _addButton({required String label, required VoidCallback onTap}) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 14,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _memberDropdown({
    required String label,
    required String? value,
    required void Function(String) onChanged,
  }) {
    // Deduplicate members by id and validate value exists
    final seen = <String>{};
    final uniqueMembers = viewModel.familyMembers
        .where((m) => seen.add(m.id))
        .toList();
    final validValue = value != null && uniqueMembers.any((m) => m.id == value)
        ? value
        : null;
    return DropdownButtonFormField<String>(
      value: validValue,
      decoration: InputDecoration(labelText: label),
      items: uniqueMembers
          .map((m) => DropdownMenuItem(value: m.id, child: Text(m.label)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _lookupDropdown({
    required String label,
    required String? value,
    required List items,
    required void Function(String) onChanged,
  }) {
    final validValue = value != null && items.any((item) => item.id == value)
        ? value
        : null;
    return DropdownButtonFormField<String>(
      value: validValue,
      decoration: InputDecoration(labelText: label),
      items: items
          .map<DropdownMenuItem<String>>(
            (item) => DropdownMenuItem(
              value: item.id as String,
              child: Text(item.descricao as String),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

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
