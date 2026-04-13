import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../../constants/educational_status_l10n.dart';
import '../../view_models/educational_status_view_model.dart';

class EducationalStatusContent extends StatelessWidget {
  const EducationalStatusContent({super.key, required this.viewModel});
  final EducationalStatusViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8), child: ListenableBuilder(listenable: viewModel, builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(EducationalStatusL10n.sectionProfiles), const SizedBox(height: 16),
      if (viewModel.memberProfiles.isEmpty) _empty(EducationalStatusL10n.noProfiles),
      for (int i = 0; i < viewModel.memberProfiles.length; i++) ...[_buildProfileCard(i), const SizedBox(height: 12)],
      _addBtn(EducationalStatusL10n.addProfile, viewModel.addProfile),
      const SizedBox(height: 28), const Divider(), const SizedBox(height: 24),
      _title(EducationalStatusL10n.sectionOccurrences), const SizedBox(height: 16),
      if (viewModel.programOccurrences.isEmpty) _empty(EducationalStatusL10n.noOccurrences),
      for (int i = 0; i < viewModel.programOccurrences.length; i++) ...[_buildOccurrenceCard(i), const SizedBox(height: 12)],
      _addBtn(EducationalStatusL10n.addOccurrence, viewModel.addOccurrence),
      const SizedBox(height: 40),
    ])));
  }

  Widget _buildProfileCard(int i) {
    final p = viewModel.memberProfiles[i];
    final seen = <String>{}; final unique = viewModel.familyMembers.where((m) => seen.add(m.id)).toList();
    final validMember = p.memberId != null && unique.any((m) => m.id == p.memberId) ? p.memberId : null;
    final validLevel = p.educationLevelId != null && viewModel.educationLevelLookup.any((l) => l.id == p.educationLevelId) ? p.educationLevelId : null;
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: AppColors.inputLine), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: DropdownButtonFormField<String>(value: validMember, decoration: const InputDecoration(labelText: EducationalStatusL10n.memberLabel), items: unique.map((m) => DropdownMenuItem(value: m.id, child: Text(m.label))).toList(), onChanged: (v) { if (v != null) viewModel.updateProfileMember(i, v); })),
        const SizedBox(width: 16),
        Expanded(child: DropdownButtonFormField<String>(value: validLevel, decoration: const InputDecoration(labelText: EducationalStatusL10n.educationLevelLabel), items: viewModel.educationLevelLookup.map((l) => DropdownMenuItem(value: l.id, child: Text(l.descricao))).toList(), onChanged: (v) { if (v != null) viewModel.updateProfileEducationLevel(i, v); })),
      ]),
      const SizedBox(height: 12),
      _toggle(EducationalStatusL10n.canReadWriteLabel, p.canReadWrite, () => viewModel.toggleProfileCanReadWrite(i)),
      _toggle(EducationalStatusL10n.attendsSchoolLabel, p.attendsSchool, () => viewModel.toggleProfileAttendsSchool(i)),
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => viewModel.removeProfile(i), icon: const Icon(Icons.remove_circle_outline, size: 16, color: AppColors.danger), label: const Text(EducationalStatusL10n.remove, style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, color: AppColors.danger)))),
    ]));
  }

  Widget _buildOccurrenceCard(int i) {
    final o = viewModel.programOccurrences[i];
    final seen = <String>{}; final unique = viewModel.familyMembers.where((m) => seen.add(m.id)).toList();
    final validMember = o.memberId != null && unique.any((m) => m.id == o.memberId) ? o.memberId : null;
    final validEffect = o.effectId != null && viewModel.effectLookup.any((e) => e.id == o.effectId) ? o.effectId : null;
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: AppColors.inputLine), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: DropdownButtonFormField<String>(value: validMember, decoration: const InputDecoration(labelText: EducationalStatusL10n.memberLabel), items: unique.map((m) => DropdownMenuItem(value: m.id, child: Text(m.label))).toList(), onChanged: (v) { if (v != null) viewModel.updateOccurrenceMember(i, v); })),
        const SizedBox(width: 16),
        SizedBox(width: 180, child: TextField(controller: TextEditingController(text: o.date), decoration: const InputDecoration(labelText: EducationalStatusL10n.occurrenceDateLabel), onChanged: (v) => viewModel.updateOccurrenceDate(i, v))),
      ]),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: validEffect, decoration: const InputDecoration(labelText: EducationalStatusL10n.effectLabel), items: viewModel.effectLookup.map((e) => DropdownMenuItem(value: e.id, child: Text(e.descricao))).toList(), onChanged: (v) { if (v != null) viewModel.updateOccurrenceEffect(i, v); }),
      const SizedBox(height: 8),
      _toggle(EducationalStatusL10n.suspensionLabel, o.isSuspensionRequested, () => viewModel.toggleOccurrenceSuspension(i)),
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => viewModel.removeOccurrence(i), icon: const Icon(Icons.remove_circle_outline, size: 16, color: AppColors.danger), label: const Text(EducationalStatusL10n.remove, style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, color: AppColors.danger)))),
    ]));
  }

  Widget _title(String t) => Text(t, style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary));
  Widget _empty(String t) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(t, style: TextStyle(fontFamily: 'Satoshi', fontSize: 14, color: AppColors.textPrimary.withValues(alpha: 0.5), fontStyle: FontStyle.italic)));
  Widget _addBtn(String label, VoidCallback onTap) => TextButton.icon(onPressed: onTap, icon: const Icon(Icons.add, size: 18, color: AppColors.primary), label: Text(label, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)));
  Widget _toggle(String label, bool value, VoidCallback onToggle) => InkWell(onTap: onToggle, borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [SizedBox(width: 24, height: 24, child: Checkbox(value: value, onChanged: (_) => onToggle(), activeColor: AppColors.primary)), const SizedBox(width: 12), Expanded(child: Text(label, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, color: AppColors.textPrimary)))])));
}
