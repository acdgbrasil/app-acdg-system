import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

class SpecOption {
  const SpecOption(this.key, this.label);
  final String key;
  final String label;
}

class SpecificityColumn extends StatelessWidget {
  final String title;
  final List<SpecOption> options;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final TextEditingController descriptionController;
  final Set<String> keysRequiringDescription;

  const SpecificityColumn({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.descriptionController,
    required this.keysRequiringDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.5,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 14),
        RadioGroup<String>(
          groupValue: selected,
          onChanged: onSelected,
          child: Column(
            children: options.map((opt) {
              return Column(
                children: [
                  RadioListTile<String>(
                    title: Text(
                      opt.label,
                      style: const TextStyle(fontSize: 15),
                    ),
                    value: opt.key,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: AppColors.primary,
                  ),
                  if (keysRequiringDescription.contains(opt.key) &&
                      selected == opt.key)
                    Padding(
                      padding: const EdgeInsets.only(left: 28, bottom: 8),
                      child: TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          hintText: opt.key == 'outras'
                              ? ReferencePersonLn10.specOtherPlaceholder
                              : ReferencePersonLn10.specDescriptionPlaceholder,
                          isDense: true,
                          contentPadding: const EdgeInsets.only(bottom: 5),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
