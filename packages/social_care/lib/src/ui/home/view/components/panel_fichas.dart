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

  const PanelFichas({
    super.key,
    required this.familyLastName,
    required this.fichas,
    required this.onClose,
    required this.onBack,
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
                    color: Color(0xFFF2E2C4),
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
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Color(0x73F2E2C4),
            ),
          ),
          const SizedBox(height: 24),

          // List
          Expanded(
            child: ListView.builder(
              itemCount: fichas.length,
              itemBuilder: (context, index) {
                return FichaRow(
                  ficha: fichas[index],
                  isLast: index == fichas.length - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
