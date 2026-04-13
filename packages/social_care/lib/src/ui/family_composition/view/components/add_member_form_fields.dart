import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../constants/family_composition_ln10.dart';
import 'add_member_form_state.dart';
import 'add_member_modal_components/add_member_modal_doc_checkboxes.dart';
import 'add_member_modal_components/add_member_modal_field.dart';
import 'add_member_modal_components/add_member_modal_radio_group.dart';
import 'add_member_modal_components/add_member_modal_text_input.dart';

/// Form fields for the add member modal (left column).
///
/// Passes [ValueNotifier]s from [AddMemberFormState] directly to child
/// widgets for atomic reactivity — no parent setState needed.
class AddMemberFormFields extends StatelessWidget {
  final AddMemberFormState formState;
  final bool showErrors;
  final bool isEditing;
  final void Function(String cpf)? onCpfComplete;

  static const _docOptions = ['CN', 'RG', 'CTPS', 'CPF', 'TE'];

  const AddMemberFormFields({
    super.key,
    required this.formState,
    required this.showErrors,
    required this.isEditing,
    this.onCpfComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isEditing) ...[
          AddMemberModalField(
            label: 'CPF (opcional)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AddMemberModalTextInput(
                  controller: formState.cpf,
                  placeholder: '000.000.000-00',
                  formatters: AppMasks.cpf,
                  keyboardType: TextInputType.number,
                  onChanged: _handleCpfChange,
                ),
                const SizedBox(height: 6),
                ValueListenableBuilder<bool>(
                  valueListenable: formState.cpfLookupLoading,
                  builder: (_, loading, __) {
                    if (!loading) return const SizedBox.shrink();
                    return const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        'Buscando...',
                        style: TextStyle(
                          color: AppColors.background,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  },
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: formState.linkedPersonName,
                  builder: (_, linkedName, __) {
                    if (linkedName == null) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_search,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pessoa encontrada: $linkedName',
                              style: const TextStyle(
                                color: AppColors.background,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
        AddMemberModalField(
          label: FamilyCompositionLn10.fieldName,
          isRequired: true,
          error: showErrors ? formState.nameError : null,
          child: AddMemberModalTextInput(
            controller: formState.name,
            placeholder: FamilyCompositionLn10.fieldNamePlaceholder,
            isEnabled: !isEditing,
          ),
        ),
        AddMemberModalField(
          label: FamilyCompositionLn10.fieldBirthDate,
          isRequired: true,
          error: showErrors ? formState.birthDateError : null,
          child: AddMemberModalTextInput(
            controller: formState.birthDate,
            placeholder: FamilyCompositionLn10.fieldBirthDatePlaceholder,
            formatters: AppMasks.date,
            keyboardType: TextInputType.number,
            isEnabled: !isEditing,
          ),
        ),
        AddMemberModalField(
          label: FamilyCompositionLn10.fieldSex,
          isRequired: true,
          error: showErrors ? formState.sexError : null,
          child: AddMemberModalRadioGroup<String>(
            notifier: formState.sex,
            options: const [
              ('masculino', FamilyCompositionLn10.sexMale),
              ('feminino', FamilyCompositionLn10.sexFemale),
              ('outro', FamilyCompositionLn10.sexOther),
            ],
            isEnabled: !isEditing,
          ),
        ),
        AddMemberModalField(
          label: FamilyCompositionLn10.fieldResiding,
          isRequired: true,
          error: showErrors ? formState.residingError : null,
          child: AddMemberModalRadioGroup<bool>(
            notifier: formState.residing,
            options: const [
              (true, FamilyCompositionLn10.residesYes),
              (false, FamilyCompositionLn10.residesNo),
            ],
          ),
        ),
        AddMemberModalField(
          label: FamilyCompositionLn10.fieldPcd,
          isRequired: true,
          error: showErrors ? formState.pcdError : null,
          child: AddMemberModalRadioGroup<bool>(
            notifier: formState.pcd,
            options: const [
              (true, FamilyCompositionLn10.residesYes),
              (false, FamilyCompositionLn10.residesNo),
            ],
          ),
        ),
        AddMemberModalField(
          label: FamilyCompositionLn10.fieldCaregiver,
          child: AddMemberModalRadioGroup<bool>(
            notifier: formState.caregiver,
            options: const [
              (true, FamilyCompositionLn10.residesYes),
              (false, FamilyCompositionLn10.residesNo),
            ],
          ),
        ),
        AddMemberModalField(
          label: FamilyCompositionLn10.fieldDocuments,
          child: AddMemberModalDocCheckboxes(
            notifier: formState.requiredDocuments,
            options: _docOptions,
          ),
        ),
      ],
    );
  }

  void _handleCpfChange(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      onCpfComplete?.call(digits);
    } else {
      formState.clearLinkedPerson();
    }
  }
}
