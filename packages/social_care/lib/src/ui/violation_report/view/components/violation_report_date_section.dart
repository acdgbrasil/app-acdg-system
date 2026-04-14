import 'package:flutter/material.dart';
import '../../constants/violation_report_l10n.dart';

class ViolationReportDateSection extends StatelessWidget {
  const ViolationReportDateSection({
    super.key,
    required this.reportDateController,
    required this.incidentDateController,
  });

  final TextEditingController reportDateController;
  final TextEditingController incidentDateController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: reportDateController,
            decoration: const InputDecoration(
              labelText: ViolationReportL10n.reportDateLabel,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: TextField(
            controller: incidentDateController,
            decoration: const InputDecoration(
              labelText: ViolationReportL10n.incidentDateLabel,
            ),
          ),
        ),
      ],
    );
  }
}
