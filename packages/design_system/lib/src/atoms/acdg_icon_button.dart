import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';

/// A standardized icon button for ACDG.
class AcdgIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  final String? tooltip;

  const AcdgIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 24,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      iconSize: size,
      color: color ?? AppColors.textPrimary,
      tooltip: tooltip,
      splashRadius: size * 0.8,
    );
  }
}
