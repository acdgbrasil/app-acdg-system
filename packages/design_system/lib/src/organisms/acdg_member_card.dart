import 'package:flutter/material.dart';

import '../atoms/acdg_pill_button.dart';
import '../atoms/acdg_text.dart';
import '../molecules/acdg_documents_checkbox_row.dart';
import '../tokens/app_breakpoints.dart';
import '../tokens/app_colors.dart';
import 'acdg_member_table_row.dart';

/// A card representing a family member for Tablet and Mobile layouts.
///
/// Adapts from 2 columns (Tablet) to 1 column (Mobile).
class AcdgMemberCard extends StatelessWidget {
  final FamilyMemberUIModel member;
  final int index;
  final VoidCallback? onEdit;

  const AcdgMemberCard({
    super.key,
    required this.member,
    required this.index,
    this.onEdit,
  });

  Color get backgroundColor =>
      index.isEven ? Colors.transparent : AppColors.cardAlternate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;
        final isMobile = AppBreakpoints.isMobile(width);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 64,
            vertical: isMobile ? 24 : 32,
          ),
          decoration: BoxDecoration(color: backgroundColor),
          child: isMobile
              ? _buildMobileLayout(width)
              : _buildTabletLayout(width),
        );
      },
    );
  }

  Widget _buildTabletLayout(double width) {
    return SizedBox(
      height:
          190, // Fixed content height to allow 254px total height with padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection('Nome', member.fullName, width),
                const Spacer(),
                _buildInfoSection('Parentesco', member.relationship, width),
                const Spacer(),
                Row(
                  children: [
                    _buildInfoSection('Idade', '${member.age} Anos', width),
                    const SizedBox(width: 32),
                    _buildInfoSection('Sexo', member.sex, width),
                  ],
                ),
              ],
            ),
          ),
          // Right Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AcdgText(
                  'Documentos Necessários',
                  variant: AcdgTextVariant.headingSmall,
                ),
                const SizedBox(height: 8),
                AcdgDocumentsCheckboxRow(selectedDocuments: member.documents),
                const Spacer(),
                _buildInfoSection(
                  'Pessoa com deficiência',
                  member.hasDisability ? 'Sim' : 'Não',
                  width,
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: AcdgPillButton.outlined(
                    label: 'Editar',
                    icon: Icons.edit,
                    onPressed: onEdit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoSection('Nome', member.fullName, width),
        const SizedBox(height: 16),
        _buildInfoSection('Parentesco', member.relationship, width),
        const SizedBox(height: 16),
        const AcdgText(
          'Documentos Necessários',
          variant: AcdgTextVariant.headingSmall,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: AcdgDocumentsCheckboxRow(selectedDocuments: member.documents),
        ),
        const SizedBox(height: 16),
        _buildInfoSection(
          'Pessoa com deficiência',
          member.hasDisability ? 'Sim' : 'Não',
          width,
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoSection('Idade', '${member.age} Anos', width),
                const SizedBox(width: 24),
                _buildInfoSection('Sexo', member.sex, width),
              ],
            ),
            AcdgPillButton.outlined(
              label: 'Editar',
              icon: Icons.edit,
              onPressed: onEdit,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection(String label, String value, double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AcdgText(label, variant: AcdgTextVariant.headingSmall),
        const SizedBox(height: 4),
        AcdgText(value, variant: AcdgTextVariant.bodyLarge),
      ],
    );
  }
}
