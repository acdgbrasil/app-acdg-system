import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/ui/home/constants/home_ln10.dart';
import 'package:social_care/src/ui/home/models/ficha_status.dart';

import 'circle_button.dart';
import 'ficha_row.dart';

class PanelFichas extends StatelessWidget {
  final String familyLastName;
  final List<FichaStatus> fichas;
  final VoidCallback onClose;
  final VoidCallback onBack;
  final void Function(FichaStatus ficha)? onFichaTap;

  const PanelFichas({
    super.key,
    required this.familyLastName,
    required this.fichas,
    required this.onClose,
    required this.onBack,
    this.onFichaTap,
  });

  @override
  Widget build(BuildContext context) {
    final filledCount = fichas.where((f) => f.filled).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 48, 48, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  HomeLn10.panelFichasTitle,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w700,
                    fontSize: 48,
                    color: AppColors.background,
                    height: 1,
                    letterSpacing: -0.02 * 48,
                  ),
                ),
              ),
              Row(
                children: [
                  CircleButton(
                    onPressed: onBack,
                    tooltip: 'Voltar',
                    child: const Icon(Icons.arrow_back),
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
          const SizedBox(height: 16),

          // Subtitle
          Text(
            HomeLn10.fichasSubtitle(familyLastName, filledCount, fichas.length),
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: AppColors.background.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 24),

          // List
          Expanded(
            child: ListView.builder(
              itemCount: fichas.length,
              itemBuilder: (context, index) {
                final ficha = fichas[index];
                return FichaRow(
                  ficha: ficha,
                  isLast: index == fichas.length - 1,
                  onTap: onFichaTap != null ? () => onFichaTap!(ficha) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
