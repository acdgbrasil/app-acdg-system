import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class ModalDocCheckboxes extends StatelessWidget {
  final ValueNotifier<Set<String>> notifier;
  final List<String> options;

  const ModalDocCheckboxes({
    super.key,
    required this.notifier,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: notifier,
      builder: (context, selected, _) {
        return Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            for (final doc in options)
              GestureDetector(
                onTap: () {
                  final current = {...selected};
                  if (current.contains(doc)) {
                    current.remove(doc);
                  } else {
                    current.add(doc);
                  }
                  notifier.value = current;
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AcdgCheckbox(
                        value: selected.contains(doc),
                        onChanged: (_) {
                          final current = {...selected};
                          if (current.contains(doc)) {
                            current.remove(doc);
                          } else {
                            current.add(doc);
                          }
                          notifier.value = current;
                        },
                        activeColor: AppColors.surface,
                        checkColor: AppColors.backgroundDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        doc,
                        style: TextStyle(
                          color: selected.contains(doc)
                              ? AppColors.textOnDark
                              : AppColors.textOnDark.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
