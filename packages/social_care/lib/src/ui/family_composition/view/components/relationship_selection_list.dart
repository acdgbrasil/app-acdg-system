import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import '../../constants/family_composition_ln10.dart';
import 'hoverable_relationship_item.dart';

class RelationshipSelectionList extends StatelessWidget {
  final List<LookupItem> parentescoLookup;
  final String? selectedRelationship;
  final ValueChanged<String> onChanged;
  final String? error;
  final bool showErrors;
  final bool enabled;

  const RelationshipSelectionList({
    super.key,
    required this.parentescoLookup,
    required this.selectedRelationship,
    required this.onChanged,
    required this.error,
    required this.showErrors,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final items = parentescoLookup.where((i) => i.codigo != 'PESSOA_REFERENCIA').toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              text: FamilyCompositionLn10.fieldRelationship,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.background,
              ),
              children: [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.danger, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.background.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in items)
                  HoverableRelationshipItem(
                    item: item,
                    isSelected: selectedRelationship == item.codigo,
                    isHighlighted: item.codigo == 'PESSOA_REFERENCIA',
                    enabled: enabled,
                    onTap: enabled ? () => onChanged(item.codigo) : () {},
                  ),
              ],
            ),
          ),
          if (showErrors && error != null) ...[
            const SizedBox(height: 4),
            Text(error!, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 11, color: AppColors.danger)),
          ],
        ],
      ),
    );
  }
}
