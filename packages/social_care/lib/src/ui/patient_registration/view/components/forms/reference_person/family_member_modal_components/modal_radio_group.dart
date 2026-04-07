import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class ModalRadioGroup<T> extends StatelessWidget {
  final ValueNotifier<T?> notifier;
  final List<(T, String)> options;
  final String? errorText;

  const ModalRadioGroup({
    super.key,
    required this.notifier,
    required this.options,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T?>(
      valueListenable: notifier,
      builder: (context, selected, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 28,
              runSpacing: 8,
              children: [
                for (final (value, label) in options)
                  GestureDetector(
                    onTap: () => notifier.value = value,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AcdgRadioButton<T>(
                            value: value,
                            groupValue: selected,
                            onChanged: (v) => notifier.value = v,
                            activeColor: AppColors.surface,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            label,
                            style: TextStyle(
                              color: AppColors.textOnDark.withValues(
                                alpha: 0.8,
                              ),
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (errorText != null) ...[
              const SizedBox(height: 4),
              Text(
                errorText!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }
}
