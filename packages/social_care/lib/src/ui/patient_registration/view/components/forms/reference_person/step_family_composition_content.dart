import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/family_composition_form_state.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/personal_data_form_state.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/documents_form_state.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_section_title.dart';

import 'family_member_modal.dart';

/// Step 4 — Family composition table with reference person + additional members.
class StepFamilyCompositionContent extends StatelessWidget {
  final FamilyCompositionFormState formState;
  final PersonalDataFormState personalDataFormState;
  final DocumentsFormState documentsFormState;
  final List<LookupItem> parentescoLookup;
  final bool showErrors;

  const StepFamilyCompositionContent({
    super.key,
    required this.formState,
    required this.personalDataFormState,
    required this.documentsFormState,
    required this.parentescoLookup,
    this.showErrors = false,
  });

  String _refPersonName() {
    final first = personalDataFormState.firstName.text.trim();
    final last = personalDataFormState.lastName.text.trim();
    return [first, last].where((s) => s.isNotEmpty).join(' ');
  }

  int? _refPersonAge() {
    final parsed = documentsFormState.birthDateParsed;
    if (parsed == null) return null;
    final now = DateTime.now();
    int age = now.year - parsed.year;
    if (now.month < parsed.month ||
        (now.month == parsed.month && now.day < parsed.day)) {
      age--;
    }
    return age;
  }

  String _sexLabel(String? sex) => switch (sex) {
        'masculino' => ReferencePersonLn10.genderOptionMale,
        'feminino' => ReferencePersonLn10.genderOptionFemale,
        _ => ReferencePersonLn10.genderOptionOther,
      };

  String _parentescoLabel(String code) {
    final item = parentescoLookup
        .where((i) => i.codigo == code || i.id == code)
        .firstOrNull;
    return item != null ? '${item.codigo} - ${item.descricao}' : code;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RegistrationSectionTitle(ReferencePersonLn10.sectionFamilyMembers),
        ValueListenableBuilder<List<FamilyMemberSnapshot>>(
          valueListenable: formState.members,
          builder: (context, members, _) {
            return Column(
              children: [
                _buildTable(context, members),
                if (members.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 20),
                    child: Text(
                      ReferencePersonLn10.tableMembersHint,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _openModal(context, editIndex: -1),
                    icon: const Icon(Icons.add),
                    label: const Text(ReferencePersonLn10.addMemberBtn),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTable(BuildContext context, List<FamilyMemberSnapshot> members) {
    final refName = _refPersonName();
    final refAge = _refPersonAge();
    final refSex = personalDataFormState.gender.value?.name;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        columns: [
          DataColumn(label: Text(ReferencePersonLn10.tableHeaderName)),
          DataColumn(label: Text(ReferencePersonLn10.tableHeaderAge)),
          DataColumn(label: Text(ReferencePersonLn10.tableHeaderSex)),
          DataColumn(label: Text(ReferencePersonLn10.tableHeaderRelationship)),
          DataColumn(label: Text(ReferencePersonLn10.tableHeaderPcd)),
          DataColumn(label: Text(ReferencePersonLn10.tableHeaderDocs)),
          const DataColumn(label: Text('')),
        ],
        rows: [
          // Reference person row — locked
          DataRow(
            color: WidgetStateProperty.all(
              AppColors.primary.withValues(alpha: 0.06),
            ),
            cells: [
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(refName.isNotEmpty ? refName : '—',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      ReferencePersonLn10.badgeReference,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              )),
              DataCell(Text(refAge != null ? '$refAge ${ReferencePersonLn10.ageYears}' : '–')),
              DataCell(Text(refSex != null ? _sexLabel(refSex) : '–')),
              DataCell(Text(ReferencePersonLn10.tableRefPersonRelationship)),
              const DataCell(Text('–')),
              const DataCell(Text('–')),
              const DataCell(Icon(Icons.lock_outline, size: 14, color: Colors.black26)),
            ],
          ),
          // Additional members
          for (var i = 0; i < members.length; i++)
            DataRow(cells: [
              DataCell(Text(members[i].name)),
              DataCell(Text('${members[i].age} ${ReferencePersonLn10.ageYears}')),
              DataCell(Text(_sexLabel(members[i].sex))),
              DataCell(Text(_parentescoLabel(members[i].relationshipCode))),
              DataCell(Text(members[i].hasDisability ? ReferencePersonLn10.radioYes : ReferencePersonLn10.radioNo)),
              DataCell(Text(
                members[i].requiredDocuments.isEmpty
                    ? '–'
                    : members[i].requiredDocuments.join(', '),
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              )),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    onPressed: () => _openModal(context, editIndex: i),
                    tooltip: ReferencePersonLn10.tooltipEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: AppColors.danger),
                    onPressed: () => formState.removeMember(i),
                    tooltip: ReferencePersonLn10.tooltipRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              )),
            ]),
        ],
      ),
    );
  }

  void _openModal(BuildContext context, {required int editIndex}) {
    final existing = editIndex >= 0 ? formState.members.value[editIndex] : null;
    final entry = existing != null
        ? formState.createEntryFromSnapshot(existing)
        : formState.createEntry();

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black38,
      builder: (dialogContext) => FamilyMemberModal(
        entry: entry,
        existingMember: existing,
        hasPrimaryCaregiver: formState.hasPrimaryCaregiver,
        parentescoLookup: parentescoLookup,
        onCaregiverConflict: () {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(
              content: Text(ReferencePersonLn10.errorCaregiverExists),
              duration: Duration(seconds: 3),
            ),
          );
        },
        onSave: (snapshot) {
          if (editIndex >= 0) {
            formState.updateMember(editIndex, snapshot);
          } else {
            formState.addMember(snapshot);
          }
        },
      ),
    );
  }
}
