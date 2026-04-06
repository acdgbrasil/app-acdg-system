import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddMemberModalTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final List<TextInputFormatter>? formatters;
  final TextInputType? keyboardType;
  final bool isEnabled;

  const AddMemberModalTextInput({
    super.key,
    required this.controller,
    required this.placeholder,
    this.formatters,
    this.keyboardType,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      readOnly: !isEnabled,
      style: const TextStyle(
        color: AppColors.background,
        fontSize: 14,
        fontFamily: 'Playfair Display',
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w300,
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(
          color: AppColors.background.withValues(alpha: 0.5),
          fontStyle: FontStyle.italic,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.background.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.background),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.only(bottom: 6),
      ),
    );
  }
}
