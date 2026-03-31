import 'package:flutter/material.dart';
import '../atoms/acdg_pill_button.dart';
import '../tokens/app_breakpoints.dart';

class ActionButtonConfig {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const ActionButtonConfig({required this.label, this.icon, this.onPressed});
}

/// The footer action bar organism.
///
/// Adapts its layout and button sizes based on 3 breakpoints.
class AcdgActionRow extends StatelessWidget {
  final ActionButtonConfig? destructive;
  final ActionButtonConfig? secondary;
  final ActionButtonConfig primary;

  const AcdgActionRow({
    super.key,
    this.destructive,
    this.secondary,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;
        final isDesktop = AppBreakpoints.isDesktop(width);
        final isTablet = AppBreakpoints.isTablet(width);

        final horizontalPadding = isDesktop ? 120.0 : (isTablet ? 40.0 : 16.0);
        final bottomMargin = isDesktop ? 88.0 : (isTablet ? 40.0 : 24.0);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            bottomMargin,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Destructive Slot (Left)
              if (destructive != null)
                AcdgPillButton.danger(
                  label: destructive!.label,
                  icon: destructive!.icon,
                  onPressed: destructive!.onPressed,
                )
              else
                const Spacer(),

              // Spacer between left and right groups
              const Spacer(),

              // 2. Secondary Slot (Center-Right)
              if (secondary != null) ...[
                AcdgPillButton.outlined(
                  label: secondary!.label,
                  icon: secondary!.icon,
                  onPressed: secondary!.onPressed,
                ),
                const SizedBox(width: 16),
              ],

              // 3. Primary Slot (Right)
              AcdgPillButton.primary(
                label: primary.label,
                icon: primary.icon,
                onPressed: primary.onPressed,
              ),
            ],
          ),
        );
      },
    );
  }
}
