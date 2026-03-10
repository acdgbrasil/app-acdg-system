import 'package:flutter/material.dart';

import '../tokens/acdg_colors.dart';

/// Size preset for [AcdgIcon].
enum AcdgIconSize {
  small(16),
  medium(24),
  large(32);

  const AcdgIconSize(this.value);
  final double value;
}

/// Icon atom — sized icon with semantic label.
///
/// Sizes from Figma: 16 (small helper icons), 24 (standard), 32 (close/action).
class AcdgIcon extends StatelessWidget {
  const AcdgIcon(
    this.icon, {
    super.key,
    this.size = AcdgIconSize.medium,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final AcdgIconSize size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size.value,
      color: color ?? AcdgColors.onSurface,
      semanticLabel: semanticLabel,
    );
  }
}
