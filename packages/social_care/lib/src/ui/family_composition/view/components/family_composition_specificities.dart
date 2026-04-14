import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../constants/family_composition_ln10.dart';
import 'specificity_tile.dart';

/// Clickable "Especificidades" radio list driven by lookup data.
///
/// Follows the Selectors & Connectors pattern:
/// receives only the data it needs (items, selectedId) and a callback.
class FamilyCompositionSpecificities extends StatelessWidget {
  const FamilyCompositionSpecificities({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  /// Available specificity options from lookup.
  final List<LookupItem> items;

  /// Currently selected specificity ID, or null.
  final String? selectedId;

  /// Called when the user taps an option.
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    debugPrint('[UI] Building FamilyCompositionSpecificities');
    debugPrint('[UI] Items count: ${items.length}');
    debugPrint('[UI] Selected ID: $selectedId');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          FamilyCompositionLn10.specificitiesTitle,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 1.5,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 7),
        const Divider(height: 1, color: AppColors.inputLine),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const Text(
            'Nenhuma especificidade carregada (Lista Vazia)',
            style: TextStyle(color: AppColors.danger, fontSize: 12),
          ),
        for (final item in items)
          SpecificityTile(
            label: item.descricao,
            selected: item.id == selectedId,
            onTap: () {
              debugPrint(
                '[UI] Tapped specificity: ${item.descricao} (${item.id})',
              );
              onSelected(item.id);
            },
          ),
      ],
    );
  }
}
