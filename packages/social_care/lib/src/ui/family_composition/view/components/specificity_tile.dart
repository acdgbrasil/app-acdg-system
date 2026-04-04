import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// A single selectable specificity option tile.
///
/// Displays a checkbox-style indicator and a label.
/// Pure Atom: receives only primitives and a callback.
class SpecificityTile extends StatelessWidget {
  const SpecificityTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.inputLine,
                  width: 1.5,
                ),
                color: selected ? AppColors.primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 9),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
