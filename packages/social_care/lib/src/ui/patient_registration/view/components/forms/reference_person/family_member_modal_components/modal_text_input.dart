import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModalTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final String? errorText;
  final List<TextInputFormatter>? formatters;
  final TextInputType? keyboardType;

  const ModalTextInput({
    super.key,
    required this.controller,
    required this.placeholder,
    this.errorText,
    this.formatters,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          style: const TextStyle(
            color: AppColors.textOnDark,
            fontSize: 15,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w300,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: AppColors.textOnDark.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.textOnDark.withValues(alpha: 0.35),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textOnDark),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12),
          ),
        );
      },
    );
  }
}
