import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class AddMemberModalRadioGroup extends StatelessWidget {
  final List<String> values;
  final List<String> labels;
  final String? selected;
  final void Function(String) onChanged;
  final bool isEnabled;

  const AddMemberModalRadioGroup({
    super.key,
    required this.values,
    required this.labels,
    this.selected,
    required this.onChanged,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Wrap(
        spacing: 20,
        runSpacing: 8,
        children: [
          for (var i = 0; i < values.length; i++)
            GestureDetector(
              onTap: isEnabled ? () => onChanged(values[i]) : null,
              child: MouseRegion(
                cursor: isEnabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background.withValues(
                            alpha: selected == values[i] ? 1.0 : 0.4,
                          ),
                          width: 2,
                        ),
                        color: selected == values[i]
                            ? AppColors.background
                            : Colors.transparent,
                      ),
                      child: selected == values[i]
                          ? Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.backgroundDark,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      labels[i],
                      style: const TextStyle(
                        fontFamily: 'Playfair Display',
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                        color: AppColors.background,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
