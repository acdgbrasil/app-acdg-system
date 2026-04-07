import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

import 'family_member_modal_components/family_member_modal_relationship_list.dart';
import 'family_member_modal_components/modal_label.dart';

/// Relationship selection panel for the family member modal (right column).
///
/// Displays a label and a scrollable list of relationship options.
class FamilyMemberRelationshipPanel extends StatelessWidget {
  final List<(String, String)> parentescoOptions;
  final ValueNotifier<String?> relationshipNotifier;
  final String? errorText;

  const FamilyMemberRelationshipPanel({
    super.key,
    required this.parentescoOptions,
    required this.relationshipNotifier,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ModalLabel(
          text: ReferencePersonLn10.memberRelationshipLabel,
          isRequired: true,
        ),
        const SizedBox(height: 8),
        FamilyMemberModalRelationshipList(
          options: parentescoOptions,
          relationshipNotifier: relationshipNotifier,
          errorText: errorText,
        ),
      ],
    );
  }
}
