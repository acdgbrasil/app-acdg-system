import 'package:flutter/material.dart';
import 'package:social_care/src/ui/home/models/ficha_status.dart';
import 'package:social_care/src/ui/home/models/patient_detail.dart';

import 'panel_dados.dart';
import 'panel_fichas.dart';

class DetailPanel extends StatelessWidget {
  final bool visible;
  final String panelView;
  final PatientDetail? detail;
  final List<FichaStatus> fichas;
  final bool isLoading;
  final VoidCallback onClose;
  final VoidCallback onShowFichas;
  final VoidCallback onShowDados;

  const DetailPanel({
    super.key,
    required this.visible,
    required this.panelView,
    this.detail,
    required this.fichas,
    this.isLoading = false,
    required this.onClose,
    required this.onShowFichas,
    required this.onShowDados,
  });

  @override
  Widget build(BuildContext context) {
    if (detail == null && !isLoading) return const SizedBox.shrink();

    return Stack(
      children: [
        // Overlay
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: visible ? 1.0 : 0.0,
          child: GestureDetector(
            onTap: onClose,
            child: Container(color: const Color(0x0D261D11)),
          ),
        ),

        // Panel
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          right: visible ? 0 : -600,
          top: 0,
          bottom: 0,
          width: MediaQuery.sizeOf(context).width * 0.56 > 720
              ? 720
              : MediaQuery.sizeOf(context).width * 0.56,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF172D48),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x4D172D48),
                  blurRadius: 40,
                  offset: Offset(-8, 0),
                ),
              ],
            ),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFF2E2C4),
                    ),
                  )
                : panelView == 'dados'
                    ? PanelDados(
                        detail: detail!,
                        onClose: onClose,
                        onShowFichas: onShowFichas,
                      )
                    : PanelFichas(
                        familyLastName: detail!.fullName.split(' ').last,
                        fichas: fichas,
                        onClose: onClose,
                        onBack: onShowDados,
                      ),
          ),
        ),
      ],
    );
  }
}
