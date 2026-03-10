import 'package:flutter/material.dart';

import '../tokens/acdg_colors.dart';
import '../tokens/acdg_radius.dart';
import '../tokens/acdg_spacing.dart';
import '../tokens/acdg_typography.dart';

/// Semantic type for [AcdgInfoCard].
enum AcdgInfoCardType { info, success, warning, error }

/// Info card cell — semantic card with title, message, and optional dismiss.
class AcdgInfoCard extends StatelessWidget {
  const AcdgInfoCard({
    super.key,
    required this.message,
    this.title,
    this.type = AcdgInfoCardType.info,
    this.onDismiss,
  });

  final String message;
  final String? title;
  final AcdgInfoCardType type;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor(type);
    final backgroundColor = accentColor.withValues(alpha: 0.1);
    final icon = _getIcon(type);

    return Container(
      padding: const EdgeInsets.all(AcdgSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AcdgRadius.borderMd,
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: AcdgSpacing.md),
          Expanded(
            child: _AcdgInfoCardContent(
              title: title,
              message: message,
              accentColor: accentColor,
            ),
          ),
          if (onDismiss != null)
            _AcdgInfoCardDismiss(onDismiss: onDismiss!),
        ],
      ),
    );
  }

  Color _getAccentColor(AcdgInfoCardType type) => switch (type) {
        AcdgInfoCardType.info => AcdgColors.primary,
        AcdgInfoCardType.success => AcdgColors.success,
        AcdgInfoCardType.warning => AcdgColors.secondary,
        AcdgInfoCardType.error => AcdgColors.error,
      };

  IconData _getIcon(AcdgInfoCardType type) => switch (type) {
        AcdgInfoCardType.info => Icons.info_outline,
        AcdgInfoCardType.success => Icons.check_circle_outline,
        AcdgInfoCardType.warning => Icons.warning_amber_outlined,
        AcdgInfoCardType.error => Icons.error_outline,
      };
}

class _AcdgInfoCardContent extends StatelessWidget {
  const _AcdgInfoCardContent({
    required this.title,
    required this.message,
    required this.accentColor,
  });

  final String? title;
  final String message;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AcdgSpacing.xs),
            child: Text(
              title!,
              style: AcdgTypography.labelLarge.copyWith(
                color: accentColor,
              ),
            ),
          ),
        Text(
          message,
          style: AcdgTypography.bodyMedium.copyWith(
            color: AcdgColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _AcdgInfoCardDismiss extends StatelessWidget {
  const _AcdgInfoCardDismiss({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: const Icon(
        Icons.close,
        size: 16,
        color: AcdgColors.textSecondary,
      ),
    );
  }
}
