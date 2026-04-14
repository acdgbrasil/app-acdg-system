import 'package:flutter/material.dart';
import '../../constants/violation_report_l10n.dart';

class ViolationReportDescriptionField extends StatelessWidget {
  const ViolationReportDescriptionField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 5,
      maxLength: 5000,
      decoration: const InputDecoration(
        labelText: ViolationReportL10n.descriptionLabel,
        hintText: ViolationReportL10n.descriptionHint,
        alignLabelWithHint: true,
      ),
    );
  }
}
