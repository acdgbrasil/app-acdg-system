import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// A quick action chip with icon and label.
class QuickActionButton extends StatefulWidget {
  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  State<QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<QuickActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          decoration: BoxDecoration(
            color: _hovered && enabled
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered && enabled
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.inputLine,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: enabled
                    ? (_hovered ? AppColors.primary : AppColors.textPrimary)
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              AcdgText(
                widget.label,
                variant: AcdgTextVariant.bodyLarge,
                color: enabled
                    ? (_hovered ? AppColors.primary : AppColors.textPrimary)
                    : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
