import 'package:flutter/material.dart';

import '../../../shared/models/member_option.dart';
import '../../constants/violation_report_l10n.dart';

class ViolationReportVictimDropdown extends StatelessWidget {
  const ViolationReportVictimDropdown({
    super.key,
    required this.validVictim,
    required this.uniqueMembers,
    required this.onChanged,
  });

  final String? validVictim;
  final List<MemberOption> uniqueMembers;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: validVictim,
      decoration: const InputDecoration(
        labelText: ViolationReportL10n.victimLabel,
      ),
      items: uniqueMembers
          .map((m) => DropdownMenuItem(value: m.id, child: Text(m.label)))
          .toList(),
      onChanged: (v) {
        if (v != null) {
          onChanged(v);
        }
      },
    );
  }
}
