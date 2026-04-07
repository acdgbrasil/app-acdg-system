import 'package:flutter/material.dart';

import '../atoms/acdg_icon_button.dart';
import '../atoms/acdg_text.dart';
import '../molecules/acdg_documents_checkbox_row.dart';

class FamilyMemberUIModel {
  final String id;
  final String fullName;
  final int age;
  final String sex;
  final String relationship;
  final bool hasDisability;
  final Map<RequiredDoc, bool> documents;

  const FamilyMemberUIModel({
    required this.id,
    required this.fullName,
    required this.age,
    required this.sex,
    required this.relationship,
    required this.hasDisability,
    required this.documents,
  });
}

/// A horizontal row representing a family member in the Desktop table.
class AcdgMemberTableRow extends StatelessWidget {
  final FamilyMemberUIModel member;
  final VoidCallback? onEdit;

  const AcdgMemberTableRow({super.key, required this.member, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 72),
      child: SizedBox(
        height: 46, // Exact row height from spec
        child: Row(
          children: [
            // Nome - Flex 4
            Expanded(
              flex: 4,
              child: AcdgText(member.fullName, overflow: TextOverflow.ellipsis),
            ),
            // Idade - Fixed Width
            SizedBox(width: 80, child: AcdgText('${member.age} Anos')),
            // Sexo - Fixed Width
            SizedBox(width: 120, child: AcdgText(member.sex)),
            // Parentesco - Flex 3
            Expanded(
              flex: 3,
              child: AcdgText(
                member.relationship,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // PCD - Fixed Width
            SizedBox(
              width: 80,
              child: AcdgText(member.hasDisability ? 'Sim' : 'Não'),
            ),
            // Documentos - Flex 5
            Expanded(
              flex: 5,
              child: AcdgDocumentsCheckboxRow(
                selectedDocuments: member.documents,
              ),
            ),
            // Editar - Icon Button
            AcdgIconButton(icon: Icons.edit, onPressed: onEdit),
          ],
        ),
      ),
    );
  }
}
