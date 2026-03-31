import 'package:flutter/material.dart';
import '../atoms/acdg_text.dart';

/// Header row for the Family Members table on Desktop.
class AcdgMemberTableHeader extends StatelessWidget {
  const AcdgMemberTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 72),
      child: Row(
        children: [
          // Nome - Flex 4
          Expanded(
            flex: 4,
            child: AcdgText('Nome', variant: AcdgTextVariant.headingSmall),
          ),
          // Idade - Fixed Width
          SizedBox(
            width: 80,
            child: AcdgText('Idade', variant: AcdgTextVariant.headingSmall),
          ),
          // Sexo - Fixed Width
          SizedBox(
            width: 120,
            child: AcdgText('Sexo', variant: AcdgTextVariant.headingSmall),
          ),
          // Parentesco - Flex 3
          Expanded(
            flex: 3,
            child: AcdgText(
              'Parentesco',
              variant: AcdgTextVariant.headingSmall,
            ),
          ),
          // PCD - Fixed Width
          SizedBox(
            width: 80,
            child: AcdgText('PCD', variant: AcdgTextVariant.headingSmall),
          ),
          // Documentos - Flex 5
          Expanded(
            flex: 5,
            child: AcdgText(
              'Documentos Necessários',
              variant: AcdgTextVariant.headingSmall,
            ),
          ),
          // Offset for edit icon in rows
          SizedBox(width: 48),
        ],
      ),
    );
  }
}
