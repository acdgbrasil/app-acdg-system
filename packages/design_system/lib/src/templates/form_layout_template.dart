import 'package:flutter/material.dart';

import '../tokens/acdg_colors.dart';
import '../tokens/acdg_spacing.dart';
import '../tokens/acdg_typography.dart';

/// Form layout template — title + subtitle + scrollable area + action buttons.
///
/// Constrains max width for readability on wide screens.
class FormLayoutTemplate extends StatelessWidget {
  const FormLayoutTemplate({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actions,
    this.maxWidth = 724,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget>? actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AcdgSpacing.lg,
                vertical: AcdgSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AcdgTypography.headingLarge.copyWith(
                      color: AcdgColors.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AcdgSpacing.xs),
                    Text(
                      subtitle!,
                      style: AcdgTypography.bodyMedium.copyWith(
                        color: AcdgColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AcdgSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AcdgSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!
                      .expand((w) => [w, const SizedBox(width: AcdgSpacing.sm)])
                      .toList()
                    ..removeLast(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
