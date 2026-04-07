import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

import 'family_composition_form_state.dart';
import 'family_member_modal_components/modal_doc_checkboxes.dart';
import 'family_member_modal_components/modal_label.dart';
import 'family_member_modal_components/modal_radio_group.dart';
import 'family_member_modal_components/modal_text_input.dart';

/// Form fields for the family member modal (left column).
///
/// Displays name, birth date, sex, disability, residing, caregiver,
/// and required documents fields.
class FamilyMemberFormFields extends StatelessWidget {
  final FamilyMemberEntry entry;
  final bool showErrors;

  static const _docOptions = ['CN', 'RG', 'CTPS', 'CPF', 'TE', 'CNS'];

  const FamilyMemberFormFields({
    super.key,
    required this.entry,
    required this.showErrors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ModalLabel(
          text: ReferencePersonLn10.memberNameLabel,
          isRequired: true,
        ),
        ModalTextInput(
          controller: entry.name,
          placeholder: ReferencePersonLn10.memberNamePlaceholder,
          errorText: showErrors ? entry.nameError : null,
        ),
        const SizedBox(height: 28),
        const ModalLabel(
          text: ReferencePersonLn10.memberBirthDateLabel,
          isRequired: true,
        ),
        ModalTextInput(
          controller: entry.birthDate,
          placeholder: ReferencePersonLn10.birthDatePlaceholder,
          errorText: showErrors ? entry.birthDateError : null,
          formatters: AppMasks.date,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 28),
        const ModalLabel(
          text: ReferencePersonLn10.memberSexLabel,
          isRequired: true,
        ),
        ModalRadioGroup<String>(
          notifier: entry.sex,
          options: const [
            ('masculino', ReferencePersonLn10.genderOptionMale),
            ('feminino', ReferencePersonLn10.genderOptionFemale),
            ('outro', ReferencePersonLn10.genderOptionOther),
          ],
          errorText: showErrors ? entry.sexError : null,
        ),
        const SizedBox(height: 28),
        const ModalLabel(
          text: ReferencePersonLn10.memberPcdLabel,
          isRequired: true,
        ),
        ModalRadioGroup<bool>(
          notifier: entry.hasDisability,
          options: const [
            (true, ReferencePersonLn10.radioYes),
            (false, ReferencePersonLn10.radioNo),
          ],
          errorText: showErrors ? entry.hasDisabilityError : null,
        ),
        const SizedBox(height: 28),
        const ModalLabel(text: ReferencePersonLn10.memberResidingLabel),
        ModalRadioGroup<bool>(
          notifier: entry.isResiding,
          options: const [
            (true, ReferencePersonLn10.radioYes),
            (false, ReferencePersonLn10.radioNo),
          ],
        ),
        const SizedBox(height: 28),
        const ModalLabel(text: ReferencePersonLn10.memberCaregiverLabel),
        ModalRadioGroup<bool>(
          notifier: entry.isCaregiver,
          options: const [
            (true, ReferencePersonLn10.radioYes),
            (false, ReferencePersonLn10.radioNo),
          ],
        ),
        const SizedBox(height: 28),
        const ModalLabel(text: ReferencePersonLn10.memberDocsLabel),
        ModalDocCheckboxes(
          notifier: entry.requiredDocuments,
          options: _docOptions,
        ),
      ],
    );
  }
}
