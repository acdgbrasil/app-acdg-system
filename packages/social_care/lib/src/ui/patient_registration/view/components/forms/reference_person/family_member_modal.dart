import 'dart:ui';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'family_composition_form_state.dart';
import 'family_member_form_fields.dart';
import 'family_member_modal_components/family_member_modal_footer.dart';
import 'family_member_modal_components/family_member_modal_header.dart';
import 'family_member_relationship_panel.dart';

/// Callback type for validating a save attempt before actually saving.
///
/// Returns `true` if the save should proceed, `false` if it should be blocked
/// (e.g. due to caregiver conflict).
typedef SaveValidator = bool Function(FamilyMemberSnapshot snapshot);

/// Modal dialog for adding or editing a family member.
class FamilyMemberModal extends StatefulWidget {
  final FamilyMemberEntry entry;
  final FamilyMemberSnapshot? existingMember;
  final void Function(FamilyMemberSnapshot snapshot) onSave;
  final SaveValidator? onValidateSave;
  final List<LookupItem> parentescoLookup;

  const FamilyMemberModal({
    super.key,
    required this.entry,
    this.existingMember,
    required this.onSave,
    this.onValidateSave,
    this.parentescoLookup = const [],
  });

  @override
  State<FamilyMemberModal> createState() => _FamilyMemberModalState();
}

class _FamilyMemberModalState extends State<FamilyMemberModal> {
  FamilyMemberEntry get _entry => widget.entry;
  bool _showErrors = false;

  List<(String, String)> get _parentescoOptions {
    if (widget.parentescoLookup.isEmpty) return const [];
    return widget.parentescoLookup
        .where((item) => item.codigo != 'PESSOA_REFERENCIA')
        .map((item) => (item.codigo, '${item.codigo} - ${item.descricao}'))
        .toList();
  }

  void _handleSave() {
    if (!_entry.isValid) {
      setState(() => _showErrors = true);
      return;
    }

    final snapshot = FamilyMemberSnapshot(
      name: _entry.name.text.trim(),
      birthDate: _entry.dateParsed!,
      sex: _entry.sex.value!,
      relationshipCode: _entry.relationship.value!,
      hasDisability: _entry.hasDisability.value ?? false,
      isResiding: _entry.isResiding.value ?? true,
      isCaregiver: _entry.isCaregiver.value ?? false,
      requiredDocuments: {..._entry.requiredDocuments.value},
    );

    if (widget.onValidateSave != null && !widget.onValidateSave!(snapshot)) {
      return;
    }

    widget.onSave(snapshot);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingMember != null;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 788),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(-9, 9),
                  blurRadius: 9,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(-18, 18),
                  blurRadius: 18,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  offset: const Offset(-37, 37),
                  blurRadius: 37,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  offset: const Offset(-75, 75),
                  blurRadius: 75,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.48),
                  offset: const Offset(-150, 150),
                  blurRadius: 150,
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.92,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FamilyMemberModalHeader(
                      isEditing: isEditing,
                      onClose: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 28),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 500;

                        final formFields = FamilyMemberFormFields(
                          entry: _entry,
                          showErrors: _showErrors,
                        );
                        final relationshipPanel = FamilyMemberRelationshipPanel(
                          parentescoOptions: _parentescoOptions,
                          relationshipNotifier: _entry.relationship,
                          errorText: _showErrors
                              ? _entry.relationshipError
                              : null,
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: formFields),
                              const SizedBox(width: 40),
                              SizedBox(width: 260, child: relationshipPanel),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            formFields,
                            const SizedBox(height: 28),
                            relationshipPanel,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Divider(
                      color: AppColors.textOnDark.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 16),
                    FamilyMemberModalFooter(onSave: _handleSave),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
