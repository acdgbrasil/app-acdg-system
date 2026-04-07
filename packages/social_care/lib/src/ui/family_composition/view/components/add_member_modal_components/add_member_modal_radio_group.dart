import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class AddMemberModalRadioGroup<T> extends StatelessWidget {
  final ValueNotifier<T?> notifier;
  final List<(T, String)> options;
  final bool isEnabled;

  const AddMemberModalRadioGroup({
    super.key,
    required this.notifier,
    required this.options,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T?>(
      valueListenable: notifier,
      builder: (context, selected, _) {
        return Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              for (final (value, label) in options)
                GestureDetector(
                  onTap: isEnabled ? () => notifier.value = value : null,
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
                                alpha: selected == value ? 1.0 : 0.4,
                              ),
                              width: 2,
                            ),
                            color: selected == value
                                ? AppColors.background
                                : Colors.transparent,
                          ),
                          child: selected == value
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
                          label,
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
      },
    );
  }
}
