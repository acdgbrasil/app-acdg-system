import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class ModuleCard extends StatefulWidget {
  const ModuleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accentColor = AppColors.primary,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  State<ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<ModuleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor:
            widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppSpacing.space5),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surface : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered
                  ? widget.accentColor.withValues(alpha: 0.3)
                  : AppColors.inputLine,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    const BoxShadow(
                      color: AppColors.elevationXs,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : const [AppShadows.xsShadow],
          ),
          child: Row(
            children: [
              // Icon container - larger and more prominent
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: _hovered ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.accentColor,
                  size: 40,
                ),
              ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AcdgText(
                      widget.title,
                      variant: AcdgTextVariant.headingMedium,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(height: 6),
                    AcdgText(
                      widget.subtitle,
                      variant: AcdgTextVariant.bodyLarge,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _hovered
                      ? widget.accentColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: _hovered ? widget.accentColor : AppColors.textMuted,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
