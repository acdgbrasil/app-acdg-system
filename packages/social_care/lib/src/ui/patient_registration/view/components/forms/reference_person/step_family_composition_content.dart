import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/family_composition_form_state.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_section_title.dart';

import 'family_composition_table.dart';
import 'family_member_modal.dart';

/// Step 4 — Family composition table with reference person + additional members.
class StepFamilyCompositionContent extends StatelessWidget {
  final FamilyCompositionFormState formState;
  final String refPersonName;
  final int? refPersonAge;
  final String? refPersonSex;
  final List<LookupItem> parentescoLookup;
  final bool showErrors;

  const StepFamilyCompositionContent({
    super.key,
    required this.formState,
    required this.refPersonName,
    required this.refPersonAge,
    required this.refPersonSex,
    required this.parentescoLookup,
    this.showErrors = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RegistrationSectionTitle(
          ReferencePersonLn10.sectionFamilyMembers,
        ),
        ValueListenableBuilder<List<FamilyMemberSnapshot>>(
          valueListenable: formState.members,
          builder: (context, members, _) {
            return Column(
              children: [
                FamilyCompositionTable(
                  members: members,
                  refName: refPersonName,
                  refAge: refPersonAge,
                  refSex: refPersonSex,
                  parentescoLookup: parentescoLookup,
                  onEdit: (index) => _openModal(context, editIndex: index),
                  onRemove: (index) => formState.removeMember(index),
                ),
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

  void _openModal(BuildContext context, {required int editIndex}) {
    final existing = editIndex >= 0 ? formState.members.value[editIndex] : null;
    final entry = existing != null
        ? formState.createEntryFromSnapshot(existing)
        : formState.createEntry();

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black38,
      builder: (dialogContext) => FamilyMemberModal(
        entry: entry,
        existingMember: existing,
        parentescoLookup: parentescoLookup,
        onValidateSave: (snapshot) {
          final wantsCaregiver = snapshot.isCaregiver;
          final isEditingSameCaregiver = existing?.isCaregiver == true;
          if (wantsCaregiver &&
              formState.hasPrimaryCaregiver &&
              !isEditingSameCaregiver) {
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              const SnackBar(
                content: Text(ReferencePersonLn10.errorCaregiverExists),
                duration: Duration(seconds: 3),
              ),
            );
            return false;
          }
          return true;
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
