import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/family_composition_form_state.dart';

class FamilyCompositionTable extends StatelessWidget {
  final List<FamilyMemberSnapshot> members;
  final String refName;
  final int? refAge;
  final String? refSex;
  final List<LookupItem> parentescoLookup;
  final void Function(int) onEdit;
  final void Function(int) onRemove;

  const FamilyCompositionTable({
    super.key,
    required this.members,
    required this.refName,
    required this.refAge,
    required this.refSex,
    required this.parentescoLookup,
    required this.onEdit,
    required this.onRemove,
  });

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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text(ReferencePersonLn10.tableHeaderName)),
          DataColumn(label: Text(ReferencePersonLn10.tableHeaderAge)),
          DataColumn(label: Text(ReferencePersonLn10.tableHeaderSex)),
          DataColumn(label: Text(ReferencePersonLn10.tableHeaderRelationship)),
          DataColumn(label: Text(ReferencePersonLn10.tableHeaderPcd)),
          DataColumn(label: Text(ReferencePersonLn10.tableHeaderDocs)),
          DataColumn(label: Text('')),
        ],
        rows: [
          // Reference person row — locked
          DataRow(
            color: WidgetStateProperty.all(
              AppColors.primary.withValues(alpha: 0.06),
            ),
            cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      refName.isNotEmpty ? refName : '—',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
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
                ),
              ),
              DataCell(
                Text(
                  refAge != null
                      ? '$refAge ${ReferencePersonLn10.ageYears}'
                      : '–',
                ),
              ),
              DataCell(Text(refSex != null ? _sexLabel(refSex) : '–')),
              const DataCell(
                Text(ReferencePersonLn10.tableRefPersonRelationship),
              ),
              const DataCell(Text('–')),
              const DataCell(Text('–')),
              const DataCell(
                Icon(Icons.lock_outline, size: 14, color: Colors.black26),
              ),
            ],
          ),
          // Additional members
          for (var i = 0; i < members.length; i++)
            DataRow(
              cells: [
                DataCell(Text(members[i].name)),
                DataCell(
                  Text(
                    '${members[i].ageAt(DateTime.now())} ${ReferencePersonLn10.ageYears}',
                  ),
                ),
                DataCell(Text(_sexLabel(members[i].sex))),
                DataCell(Text(_parentescoLabel(members[i].relationshipCode))),
                DataCell(
                  Text(
                    members[i].hasDisability
                        ? ReferencePersonLn10.radioYes
                        : ReferencePersonLn10.radioNo,
                  ),
                ),
                DataCell(
                  Text(
                    members[i].requiredDocuments.isEmpty
                        ? '–'
                        : members[i].requiredDocuments.join(', '),
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        onPressed: () => onEdit(i),
                        tooltip: ReferencePersonLn10.tooltipEdit,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.danger,
                        ),
                        onPressed: () => onRemove(i),
                        tooltip: ReferencePersonLn10.tooltipRemove,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
