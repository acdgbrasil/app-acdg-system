import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class HealthLookupDropdown extends StatelessWidget {
  const HealthLookupDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<LookupItem> items;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final validValue = value != null && items.any((item) => item.id == value)
        ? value
        : null;
    return DropdownButtonFormField<String>(
      initialValue: validValue,
      decoration: InputDecoration(labelText: label),
      items: items
          .map<DropdownMenuItem<String>>(
            (item) =>
                DropdownMenuItem(value: item.id, child: Text(item.descricao)),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) {
          onChanged(v);
        }
      },
    );
  }
}
