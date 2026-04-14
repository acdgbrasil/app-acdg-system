import 'package:flutter/material.dart';
import '../../constants/violation_report_l10n.dart';
import '../../view_models/violation_report_view_model.dart';
import 'violation_report_actions_field.dart';
import 'violation_report_date_section.dart';
import 'violation_report_description_field.dart';
import 'violation_report_section_title.dart';
import 'violation_report_success_banner.dart';
import 'violation_report_type_chips.dart';
import 'violation_report_victim_dropdown.dart';

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
    _reportDateCtrl = TextEditingController(text: vm.reportDate)
      ..addListener(() => vm.updateReportDate(_reportDateCtrl.text));
    _incidentDateCtrl = TextEditingController(text: vm.incidentDate)
      ..addListener(() => vm.updateIncidentDate(_incidentDateCtrl.text));
    _descriptionCtrl = TextEditingController(text: vm.descriptionOfFact)
      ..addListener(() => vm.updateDescription(_descriptionCtrl.text));
    _actionsCtrl = TextEditingController(text: vm.actionsTaken)
      ..addListener(() => vm.updateActions(_actionsCtrl.text));
    vm.addListener(_sync);
  }

  void _sync() {
    if (_reportDateCtrl.text != vm.reportDate) {
      _reportDateCtrl.text = vm.reportDate;
    }
    if (_incidentDateCtrl.text != vm.incidentDate) {
      _incidentDateCtrl.text = vm.incidentDate;
    }
    if (_descriptionCtrl.text != vm.descriptionOfFact) {
      _descriptionCtrl.text = vm.descriptionOfFact;
    }
    if (_actionsCtrl.text != vm.actionsTaken) {
      _actionsCtrl.text = vm.actionsTaken;
    }
  }

  @override
  void dispose() {
    vm.removeListener(_sync);
    _reportDateCtrl.dispose();
    _incidentDateCtrl.dispose();
    _descriptionCtrl.dispose();
    _actionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final seen = <String>{};
          final unique = vm.familyMembers.where((m) => seen.add(m.id)).toList();
          final validVictim =
              vm.victimId != null && unique.any((m) => m.id == vm.victimId)
              ? vm.victimId
              : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (vm.saved) const ViolationReportSuccessBanner(),
              const ViolationReportSectionTitle(
                text: ViolationReportL10n.sectionReport,
              ),
              const SizedBox(height: 16),
              ViolationReportDateSection(
                reportDateController: _reportDateCtrl,
                incidentDateController: _incidentDateCtrl,
              ),
              const SizedBox(height: 16),
              ViolationReportVictimDropdown(
                validVictim: validVictim,
                uniqueMembers: unique,
                onChanged: vm.updateVictim,
              ),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 24),
              const ViolationReportSectionTitle(
                text: ViolationReportL10n.sectionType,
              ),
              const SizedBox(height: 16),
              ViolationReportTypeChips(
                selectedType: vm.violationType,
                onSelected: vm.updateViolationType,
              ),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 24),
              const ViolationReportSectionTitle(
                text: ViolationReportL10n.sectionDescription,
              ),
              const SizedBox(height: 16),
              ViolationReportDescriptionField(controller: _descriptionCtrl),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 24),
              const ViolationReportSectionTitle(
                text: ViolationReportL10n.sectionActions,
              ),
              const SizedBox(height: 16),
              ViolationReportActionsField(controller: _actionsCtrl),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
