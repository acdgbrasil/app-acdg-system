import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../../constants/violation_report_l10n.dart';
import '../../view_models/violation_report_view_model.dart';

class ViolationReportContent extends StatefulWidget {
  const ViolationReportContent({super.key, required this.viewModel});
  final ViolationReportViewModel viewModel;
  @override
  State<ViolationReportContent> createState() => _ViolationReportContentState();
}

class _ViolationReportContentState extends State<ViolationReportContent> {
  late final TextEditingController _reportDateCtrl;
  late final TextEditingController _incidentDateCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _actionsCtrl;
  ViolationReportViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _reportDateCtrl = TextEditingController(text: vm.reportDate)..addListener(() => vm.updateReportDate(_reportDateCtrl.text));
    _incidentDateCtrl = TextEditingController(text: vm.incidentDate)..addListener(() => vm.updateIncidentDate(_incidentDateCtrl.text));
    _descriptionCtrl = TextEditingController(text: vm.descriptionOfFact)..addListener(() => vm.updateDescription(_descriptionCtrl.text));
    _actionsCtrl = TextEditingController(text: vm.actionsTaken)..addListener(() => vm.updateActions(_actionsCtrl.text));
    vm.addListener(_sync);
  }

  void _sync() {
    if (_reportDateCtrl.text != vm.reportDate) _reportDateCtrl.text = vm.reportDate;
    if (_incidentDateCtrl.text != vm.incidentDate) _incidentDateCtrl.text = vm.incidentDate;
    if (_descriptionCtrl.text != vm.descriptionOfFact) _descriptionCtrl.text = vm.descriptionOfFact;
    if (_actionsCtrl.text != vm.actionsTaken) _actionsCtrl.text = vm.actionsTaken;
  }

  @override
  void dispose() { vm.removeListener(_sync); _reportDateCtrl.dispose(); _incidentDateCtrl.dispose(); _descriptionCtrl.dispose(); _actionsCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8), child: ListenableBuilder(listenable: vm, builder: (context, _) {
      final seen = <String>{}; final unique = vm.familyMembers.where((m) => seen.add(m.id)).toList();
      final validVictim = vm.victimId != null && unique.any((m) => m.id == vm.victimId) ? vm.victimId : null;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (vm.saved) ...[
          Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [Icon(Icons.check_circle, color: AppColors.primary), SizedBox(width: 12), Text('Relato registrado com sucesso. Preencha outro ou volte.', style: TextStyle(fontFamily: 'Satoshi', fontSize: 14, color: AppColors.primary))])),
        ],
        _title(ViolationReportL10n.sectionReport), const SizedBox(height: 16),
        Row(children: [
          Expanded(child: TextField(controller: _reportDateCtrl, decoration: const InputDecoration(labelText: ViolationReportL10n.reportDateLabel))),
          const SizedBox(width: 24),
          Expanded(child: TextField(controller: _incidentDateCtrl, decoration: const InputDecoration(labelText: ViolationReportL10n.incidentDateLabel))),
        ]),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(value: validVictim, decoration: const InputDecoration(labelText: ViolationReportL10n.victimLabel), items: unique.map((m) => DropdownMenuItem(value: m.id, child: Text(m.label))).toList(), onChanged: (v) { if (v != null) vm.updateVictim(v); }),

        const SizedBox(height: 28), const Divider(), const SizedBox(height: 24),
        _title(ViolationReportL10n.sectionType), const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: {
          'neglect': ViolationReportL10n.typeNeglect,
          'psychologicalViolence': ViolationReportL10n.typePsychological,
          'physicalViolence': ViolationReportL10n.typePhysical,
          'sexualAbuse': ViolationReportL10n.typeSexualAbuse,
          'sexualExploitation': ViolationReportL10n.typeSexualExploitation,
          'childLabor': ViolationReportL10n.typeChildLabor,
          'financialExploitation': ViolationReportL10n.typeFinancial,
          'discrimination': ViolationReportL10n.typeDiscrimination,
          'other': ViolationReportL10n.typeOther,
        }.entries.map((e) {
          final selected = vm.violationType == e.key;
          return ChoiceChip(label: Text(e.value), selected: selected, onSelected: (_) => vm.updateViolationType(e.key),
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            labelStyle: TextStyle(fontFamily: 'Satoshi', fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppColors.primary : AppColors.textPrimary));
        }).toList()),

        const SizedBox(height: 28), const Divider(), const SizedBox(height: 24),
        _title(ViolationReportL10n.sectionDescription), const SizedBox(height: 16),
        TextField(controller: _descriptionCtrl, maxLines: 5, maxLength: 5000, decoration: const InputDecoration(labelText: ViolationReportL10n.descriptionLabel, hintText: ViolationReportL10n.descriptionHint, alignLabelWithHint: true)),

        const SizedBox(height: 28), const Divider(), const SizedBox(height: 24),
        _title(ViolationReportL10n.sectionActions), const SizedBox(height: 16),
        TextField(controller: _actionsCtrl, maxLines: 3, maxLength: 5000, decoration: const InputDecoration(labelText: ViolationReportL10n.actionsLabel, hintText: ViolationReportL10n.actionsHint, alignLabelWithHint: true)),
        const SizedBox(height: 40),
      ]);
    }));
  }

  Widget _title(String t) => Text(t, style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary));
}
