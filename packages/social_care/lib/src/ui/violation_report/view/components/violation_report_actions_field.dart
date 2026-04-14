import 'package:flutter/material.dart';
import '../../constants/violation_report_l10n.dart';

class ViolationReportActionsField extends StatelessWidget {
  const ViolationReportActionsField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      maxLength: 5000,
      decoration: const InputDecoration(
        labelText: ViolationReportL10n.actionsLabel,
        hintText: ViolationReportL10n.actionsHint,
        alignLabelWithHint: true,
      ),
    );
  }
}
