import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../../constants/family_composition_ln10.dart';
import '../../models/family_member_model.dart';
import 'family_table_doc_checkbox.dart';

/// Main table displaying all family members.
///
/// PR row is always first and locked (no edit/remove actions).
/// Other members have: ★ caregiver toggle, ✎ edit, ✕ remove.
/// Documents are inline checkboxes per row (local state).
class FamilyTable extends StatelessWidget {
  final List<FamilyMemberModel> members;
  final void Function(int index, String doc, bool checked) onToggleDoc;
  final void Function(FamilyMemberModel member) onEdit;
  final void Function(FamilyMemberModel member) onRemove;
  final void Function(FamilyMemberModel member) onToggleCaregiver;

  const FamilyTable({
    super.key,
    required this.members,
    required this.onToggleDoc,
    required this.onEdit,
    required this.onRemove,
    required this.onToggleCaregiver,
  });

  static const _docs = ['CN', 'RG', 'CTPS', 'CPF', 'TE'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        headingRowHeight: 40,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 56,
        headingTextStyle: TextStyle(
          fontFamily: 'Satoshi',
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 1.5,
          color: Colors.black.withValues(alpha: 0.5),
        ),
        columns: const [
          DataColumn(label: Text(FamilyCompositionLn10.colName)),
          DataColumn(label: Text(FamilyCompositionLn10.colAge)),
          DataColumn(label: Text(FamilyCompositionLn10.colSex)),
          DataColumn(label: Text(FamilyCompositionLn10.colRelationship)),
          DataColumn(label: Text(FamilyCompositionLn10.colResides)),
          DataColumn(label: Text(FamilyCompositionLn10.colPcd)),
          DataColumn(label: Text(FamilyCompositionLn10.colDocuments)),
          DataColumn(label: Text('')),
        ],
        rows: [
          for (var i = 0; i < members.length; i++) _buildRow(i, members[i]),
        ],
      ),
    );
  }

  DataRow _buildRow(int index, FamilyMemberModel member) {
    final isPr = member.isReferencePerson;
    final isCg = member.isPrimaryCaregiver;

    return DataRow(
      color: WidgetStateProperty.resolveWith((_) {
        if (isPr) return AppColors.primary.withValues(alpha: 0.05);
        if (isCg) return AppColors.backgroundDark.withValues(alpha: 0.04);
        return null;
      }),
      cells: [
        // Name + badges
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                member.displayName,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  fontWeight: isPr ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
              if (isPr) ...[
                const SizedBox(width: 6),
                const AcdgBadge(
                  label: FamilyCompositionLn10.badgeReference,
                  color: AppColors.primary,
                ),
              ],
              if (isCg && !isPr) ...[
                const SizedBox(width: 6),
                const AcdgBadge(
                  label: FamilyCompositionLn10.badgeCaregiver,
                  color: AppColors.backgroundDark,
                ),
              ],
            ],
          ),
        ),
        // Age
        DataCell(
          Text(
            '${member.age} ${FamilyCompositionLn10.ageYears}',
            style: const TextStyle(fontFamily: 'Satoshi', fontSize: 13),
          ),
        ),
        // Sex
        DataCell(
          Text(
            member.sex,
            style: const TextStyle(fontFamily: 'Satoshi', fontSize: 13),
          ),
        ),
        // Relationship
        DataCell(
          Text(
            member.relationshipLabel,
            style: const TextStyle(fontFamily: 'Satoshi', fontSize: 13),
          ),
        ),
        // Resides
        DataCell(
          Text(
            isPr
                ? '—'
                : member.residesWithPatient
                ? FamilyCompositionLn10.residesYes
                : FamilyCompositionLn10.residesNo,
            style: const TextStyle(fontFamily: 'Satoshi', fontSize: 13),
          ),
        ),
        // PcD
        DataCell(
          Text(
            member.hasDisability
                ? FamilyCompositionLn10.residesYes
                : FamilyCompositionLn10.residesNo,
            style: const TextStyle(fontFamily: 'Satoshi', fontSize: 13),
          ),
        ),
        // Documents
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (member.requiredDocuments.isEmpty && isPr)
                const Text(
                  FamilyCompositionLn10.docsNone,
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                )
              else
                for (final doc in _docs)
                  FamilyTableDocCheckbox(
                    label: doc,
                    checked: member.requiredDocuments.contains(doc),
                    enabled: false,
                  ),
            ],
          ),
        ),
        // Actions
        DataCell(
          isPr
              ? const Opacity(
                  opacity: 0.2,
                  child: Icon(Icons.lock_outline, size: 14),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AcdgIconButton(
                      icon: Icons.star_rounded,
                      tooltip: isCg
                          ? FamilyCompositionLn10.tooltipRemoveCaregiver
                          : FamilyCompositionLn10.tooltipSetCaregiver,
                      color: isCg ? AppColors.warning : AppColors.textMuted,
                      size: 14,
                      onPressed: () => onToggleCaregiver(member),
                    ),
                    AcdgIconButton(
                      icon: Icons.edit_outlined,
                      tooltip: FamilyCompositionLn10.tooltipEdit,
                      color: AppColors.textMuted,
                      size: 14,
                      onPressed: () => onEdit(member),
                    ),
                    AcdgIconButton(
                      icon: Icons.close,
                      tooltip: FamilyCompositionLn10.tooltipRemove,
                      color: AppColors.danger,
                      size: 14,
                      onPressed: () => onRemove(member),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
