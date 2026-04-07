import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/ui/home/constants/home_ln10.dart';
import 'package:social_care/src/ui/home/models/patient_detail.dart';

import 'circle_button.dart';
import 'data_field.dart';
import 'status_badge.dart';

class PanelDados extends StatelessWidget {
  final PatientDetail detail;
  final VoidCallback onClose;
  final VoidCallback onShowFichas;

  const PanelDados({
    super.key,
    required this.detail,
    required this.onClose,
    required this.onShowFichas,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 48, 48, 32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        HomeLn10.panelDadosTitle,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w700,
                          fontSize: 48,
                          color: AppColors.background,
                          height: 1,
                          letterSpacing: -0.02 * 48,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StatusBadge(status: detail.status),
                    ],
                  ),
                ),
                Row(
                  children: [
                    CircleButton(
                      onPressed: onShowFichas,
                      tooltip: 'Fichas',
                      child: const Icon(Icons.description_outlined),
                    ),
                    const SizedBox(width: 8),
                    const CircleButton(
                      tooltip: 'Editar',
                      child: Icon(Icons.edit_outlined),
                    ),
                    const SizedBox(width: 8),
                    CircleButton(
                      onPressed: onClose,
                      variant: CircleButtonVariant.close,
                      tooltip: 'Fechar',
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Data
            DataField(label: HomeLn10.labelFullName, value: detail.fullName),
            const SizedBox(height: 28),
            DataField(
              label: HomeLn10.labelMotherName,
              value: detail.motherName,
            ),
            const SizedBox(height: 24),

            Divider(
              color: AppColors.background.withValues(alpha: 0.15),
              height: 1,
            ),
            const SizedBox(height: 24),
            DataField(label: HomeLn10.labelDiagnosis, value: detail.diagnosis),
            const SizedBox(height: 24),

            // Grid 2 columns
            Wrap(
              spacing: 40,
              runSpacing: 24,
              children: [
                SizedBox(
                  width: 200,
                  child: DataField(
                    label: HomeLn10.labelBirthDate,
                    value: detail.birthDate,
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DataField(label: HomeLn10.labelCpf, value: detail.cpf),
                ),
                SizedBox(
                  width: 200,
                  child: DataField(
                    label: HomeLn10.labelEntryDate,
                    value: detail.entryDate,
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DataField(
                    label: HomeLn10.labelResponsible,
                    value: detail.responsible,
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DataField(label: HomeLn10.labelCep, value: detail.cep),
                ),
                SizedBox(
                  width: 200,
                  child: DataField(
                    label: HomeLn10.labelPhone,
                    value: detail.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Divider(
              color: AppColors.background.withValues(alpha: 0.15),
              height: 1,
            ),
            const SizedBox(height: 24),
            DataField(
              label: HomeLn10.labelAddress,
              value: detail.formattedAddress,
            ),
          ],
        ),
      ),
    );
  }
}
