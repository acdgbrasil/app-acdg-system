import 'package:flutter/material.dart';

/// The ACDG brand logo.
///
/// Renders the PNG logo asset at the specified size.
/// Works on both web (WASM) and desktop (native).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 80});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/acdg_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
