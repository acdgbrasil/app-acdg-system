import 'package:flutter/material.dart';

import '../tokens/app_breakpoints.dart';
import 'acdg_member_card.dart';
import 'acdg_member_table_header.dart';
import 'acdg_member_table_row.dart';

/// Organism that orchestrates the family member list view.
///
/// Switches between Table (Desktop) and Card List (Tablet/Mobile) automatically.
class AcdgMemberList extends StatelessWidget {
  final List<FamilyMemberUIModel> members;
  final ValueChanged<FamilyMemberUIModel>? onEditMember;

  const AcdgMemberList({super.key, required this.members, this.onEditMember});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;

        if (AppBreakpoints.isDesktop(width)) {
          return _buildDesktopTable();
        } else {
          return _buildCardList();
        }
      },
    );
  }

  Widget _buildDesktopTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AcdgMemberTableHeader(),
        const SizedBox(height: 16),
        ...members.map(
          (m) => AcdgMemberTableRow(
            member: m,
            onEdit: () => onEditMember?.call(m),
          ),
        ),
      ],
    );
  }

  Widget _buildCardList() {
    return Column(
      children: members
          .asMap()
          .entries
          .map(
            (entry) => AcdgMemberCard(
              member: entry.value,
              index: entry.key,
              onEdit: () => onEditMember?.call(entry.value),
            ),
          )
          .toList(),
    );
  }
}
