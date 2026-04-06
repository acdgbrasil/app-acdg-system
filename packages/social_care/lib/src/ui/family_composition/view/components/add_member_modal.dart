import 'dart:ui';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../../constants/family_composition_ln10.dart';
import '../../models/add_member_result.dart';
import 'add_member_form_state.dart';
import 'add_member_modal_components/add_member_modal_doc_checkboxes.dart';
import 'add_member_modal_components/add_member_modal_field.dart';
import 'add_member_modal_components/add_member_modal_radio_group.dart';
import 'add_member_modal_components/add_member_modal_text_input.dart';
import 'relationship_selection_list.dart';

/// Modal for adding or editing a family member.
class AddMemberModal extends StatefulWidget {
  final List<LookupItem> parentescoLookup;
  final void Function(AddMemberResult result) onSave;
  final AddMemberResult? existing;

  const AddMemberModal({
    super.key,
    required this.parentescoLookup,
    required this.onSave,
    this.existing,
  });

  @override
  State<AddMemberModal> createState() => _AddMemberModalState();
}

class _AddMemberModalState extends State<AddMemberModal> {
  final _formState = AddMemberFormState();
  bool _showErrors = false;

  static const _docOptions = ['CN', 'RG', 'CTPS', 'CPF', 'TE'];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _formState.populateFrom(widget.existing!);
    }
  }

  @override
  void dispose() {
    _formState.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formState.isValid) {
      setState(() => _showErrors = true);
      return;
    }

    widget.onSave(_formState.toResult());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 760),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.buttonShadow,
                  offset: Offset(-75, 75),
                  blurRadius: 75,
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.92,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(40, 40, 40, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInfoNote(),
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Icon(
                            Icons.close,
                            color: AppColors.danger,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 500;
                        final relationshipList = RelationshipSelectionList(
                          parentescoLookup: widget.parentescoLookup,
                          selectedRelationship: _formState.relationship.value,
                          onChanged: (val) => setState(
                            () => _formState.relationship.value = val,
                          ),
                          error: _formState.relationshipError,
                          showErrors: _showErrors,
                          enabled: !isEditing,
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildLeftColumn(isEditing: isEditing),
                              ),
                              const SizedBox(width: 40),
                              SizedBox(width: 240, child: relationshipList),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLeftColumn(isEditing: isEditing),
                            const SizedBox(height: 22),
                            relationshipList,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Divider(color: AppColors.background.withValues(alpha: 0.1)),
                    const SizedBox(height: 14),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.07),
        border: Border.all(color: AppColors.background.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(
            'ℹ',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.background.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              FamilyCompositionLn10.modalNote,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 10,
                color: AppColors.background.withValues(alpha: 0.55),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn({required bool isEditing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AddMemberModalField(
          label: FamilyCompositionLn10.fieldName,
          isRequired: true,
          error: _showErrors ? _formState.nameError : null,
          child: AddMemberModalTextInput(
            controller: _formState.name,
            placeholder: FamilyCompositionLn10.fieldNamePlaceholder,
            isEnabled: !isEditing,
          ),
        ),
        AddMemberModalField(
          label: FamilyCompositionLn10.fieldBirthDate,
          isRequired: true,
          error: _showErrors ? _formState.birthDateError : null,
          child: AddMemberModalTextInput(
            controller: _formState.birthDate,
            placeholder: FamilyCompositionLn10.fieldBirthDatePlaceholder,
            formatters: AppMasks.date,
            keyboardType: TextInputType.number,
            isEnabled: !isEditing,
          ),
        ),
        AddMemberModalField(
          label: FamilyCompositionLn10.fieldSex,
          isRequired: true,
          error: _showErrors ? _formState.sexError : null,
          child: AddMemberModalRadioGroup(
            values: const ['masculino', 'feminino', 'outro'],
            labels: const [
              FamilyCompositionLn10.sexMale,
              FamilyCompositionLn10.sexFemale,
              FamilyCompositionLn10.sexOther,
            ],
            selected: _formState.sex.value,
            onChanged: (v) => setState(() => _formState.sex.value = v),
            isEnabled: !isEditing,
          ),
        ),
        AddMemberModalField(
          label: FamilyCompositionLn10.fieldResiding,
          isRequired: true,
          error: _showErrors ? _formState.residingError : null,
          child: AddMemberModalRadioGroup(
            values: const ['true', 'false'],
            labels: const [
              FamilyCompositionLn10.residesYes,
              FamilyCompositionLn10.residesNo,
            ],
            selected: _formState.residing.value?.toString(),
            onChanged: (v) =>
                setState(() => _formState.residing.value = v == 'true'),
          ),
        ),
        AddMemberModalField(
          label: FamilyCompositionLn10.fieldPcd,
          isRequired: true,
          error: _showErrors ? _formState.pcdError : null,
          child: AddMemberModalRadioGroup(
            values: const ['true', 'false'],
            labels: const [
              FamilyCompositionLn10.residesYes,
              FamilyCompositionLn10.residesNo,
            ],
            selected: _formState.pcd.value?.toString(),
            onChanged: (v) =>
                setState(() => _formState.pcd.value = v == 'true'),
          ),
        ),
        AddMemberModalField(
          label: FamilyCompositionLn10.fieldCaregiver,
          child: AddMemberModalRadioGroup(
            values: const ['true', 'false'],
            labels: const [
              FamilyCompositionLn10.residesYes,
              FamilyCompositionLn10.residesNo,
            ],
            selected: _formState.caregiver.value.toString(),
            onChanged: (v) =>
                setState(() => _formState.caregiver.value = v == 'true'),
          ),
        ),
        AddMemberModalField(
          label: FamilyCompositionLn10.fieldDocuments,
          child: AddMemberModalDocCheckboxes(
            selectedDocs: _formState.requiredDocuments.value,
            options: _docOptions,
            onToggle: (doc) => setState(() => _formState.toggleDocument(doc)),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: _handleSave,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppColors.background.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.background.withValues(alpha: 0.12),
                  blurRadius: 6,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Text(
              FamilyCompositionLn10.modalSave,
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: AppColors.background,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
