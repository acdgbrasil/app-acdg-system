import 'dart:ui';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../../models/add_member_result.dart';
import 'add_member_footer.dart';
import 'add_member_form_fields.dart';
import 'add_member_form_state.dart';
import 'add_member_info_note.dart';
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
                    const AddMemberInfoNote(),
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
                          relationshipNotifier: _formState.relationship,
                          error: _formState.relationshipError,
                          showErrors: _showErrors,
                          enabled: !isEditing,
                        );

                        final formFields = AddMemberFormFields(
                          formState: _formState,
                          showErrors: _showErrors,
                          isEditing: isEditing,
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: formFields),
                              const SizedBox(width: 40),
                              SizedBox(width: 240, child: relationshipList),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            formFields,
                            const SizedBox(height: 22),
                            relationshipList,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Divider(color: AppColors.background.withValues(alpha: 0.1)),
                    const SizedBox(height: 14),
                    AddMemberFooter(onSave: _handleSave),
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
