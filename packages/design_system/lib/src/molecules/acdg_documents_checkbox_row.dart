import 'package:flutter/material.dart';

import '../atoms/acdg_checkbox.dart';
import '../atoms/acdg_text.dart';
import '../tokens/app_breakpoints.dart';
import '../tokens/app_colors.dart';

/// Mapping for document labels and internal values.
/// This is used to maintain consistency between UI and Domain.
enum RequiredDoc {
  cn('CN'),
  rg('RG'),
  ctps('CTPS'),
  cpf('CPF'),
  te('TE');

  final String label;
  const RequiredDoc(this.label);
}

/// A row of checkboxes for required documents (CN, RG, CTPS, CPF, TE).
class AcdgDocumentsCheckboxRow extends StatelessWidget {
  final Map<RequiredDoc, bool> selectedDocuments;
  final bool readOnly;
  final bool inverted;
  final ValueChanged<RequiredDoc>? onChanged;

  const AcdgDocumentsCheckboxRow({
    super.key,
    required this.selectedDocuments,
    this.readOnly = true,
    this.inverted = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;
        final isDesktop = AppBreakpoints.isDesktop(width);
        final isTablet = AppBreakpoints.isTablet(width);

        final double gap = isDesktop ? 68.0 : (isTablet ? 38.0 : 24.0);

        return Wrap(
          spacing: gap,
          runSpacing: 8.0,
          children: RequiredDoc.values.map((doc) {
            return _buildDocItem(doc, width);
          }).toList(),
        );
      },
    );
  }

  Widget _buildDocItem(RequiredDoc doc, double screenWidth) {
    final isSelected = selectedDocuments[doc] ?? false;
    final textColor = inverted
        ? (isSelected ? AppColors.textOnDark : AppColors.textAntiFlash)
        : AppColors.textBlack;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AcdgCheckbox(
          value: isSelected,
          onChanged: readOnly ? null : (val) => onChanged?.call(doc),
          activeColor: inverted ? AppColors.textOnDark : AppColors.primary,
          checkColor: inverted
              ? AppColors.backgroundDark
              : AppColors.textOnDark,
        ),
        const SizedBox(width: 8),
        AcdgText(
          doc.label,
          variant: screenWidth >= AppBreakpoints.desktop
              ? AcdgTextVariant.bodyLarge
              : AcdgTextVariant.caption,
          color: textColor,
        ),
      ],
    );
  }
}
