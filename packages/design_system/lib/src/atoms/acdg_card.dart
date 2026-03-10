import 'package:flutter/material.dart';

import '../tokens/acdg_colors.dart';
import '../tokens/acdg_radius.dart';
import '../tokens/acdg_shadows.dart';
import '../tokens/acdg_spacing.dart';

/// Card atom — container with optional tap, border, and shadow.
class AcdgCard extends StatelessWidget {
  const AcdgCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.elevation = 0,
    this.borderColor,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double elevation;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AcdgColors.surface,
      borderRadius: AcdgRadius.borderMd,
      elevation: elevation,
      shadowColor: AcdgColors.shadowBase,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AcdgRadius.borderMd,
        side: borderColor != null
            ? BorderSide(color: borderColor!)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AcdgSpacing.lg),
          child: child,
        ),
      ),
    );
  }
}
