import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class RegistrationFormGrid extends StatelessWidget {
  final List<Widget> children;

  const RegistrationFormGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = AppBreakpoints.isMobile(constraints.maxWidth);

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children
                .map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: w,
                    ))
                .toList(),
          );
        }

        // Layout de 2 colunas (Desktop/Tablet)
        return Wrap(
          spacing: 40, // Horizontal gap from design
          runSpacing: 28, // Vertical gap from design
          children: children
              .map((w) => SizedBox(
                    width: (constraints.maxWidth - 40) / 2,
                    child: w,
                  ))
              .toList(),
        );
      },
    );
  }
}
