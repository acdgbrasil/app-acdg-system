import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';

class AcdgRadioGroup<T> extends StatelessWidget {
  final T? value;
  final ValueChanged<T?>? onChanged;
  final List<AcdgRadioOption<T>> options;
  final String? errorText;
  final bool isDense;

  const AcdgRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
    this.errorText,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    final onChangedVal = onChanged;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onChangedVal != null)
          RadioGroup<T>(
            groupValue: value,
            onChanged: onChangedVal,
            child: Column(
              children: options.map((option) {
                return RadioListTile<T>(
                  title: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: isDense ? 14 : 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  value: option.value,
                  contentPadding: EdgeInsets.zero,
                  dense: isDense,
                  activeColor: AppColors.primary,
                );
              }).toList(),
            ),
          )
        else
          RadioGroup<T>(
            groupValue: value,
            onChanged: (_) {},
            child: Column(
              children: options.map((option) {
                return RadioListTile<T>(
                  title: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: isDense ? 14 : 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  value: option.value,
                  contentPadding: EdgeInsets.zero,
                  dense: isDense,
                  activeColor: AppColors.primary,
                  toggleable: false,
                );
              }).toList(),
            ),
          ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class AcdgRadioOption<T> {
  final T value;
  final String label;

  const AcdgRadioOption({required this.value, required this.label});
}
