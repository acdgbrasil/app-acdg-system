import 'package:flutter/material.dart';

import '../../../shared/models/member_option.dart';

class HealthMemberDropdown extends StatelessWidget {
  const HealthMemberDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.familyMembers,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<MemberOption> familyMembers;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final uniqueMembers = familyMembers.where((m) => seen.add(m.id)).toList();
    final validValue = value != null && uniqueMembers.any((m) => m.id == value)
        ? value
        : null;
    return DropdownButtonFormField<String>(
      initialValue: validValue,
      decoration: InputDecoration(labelText: label),
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
