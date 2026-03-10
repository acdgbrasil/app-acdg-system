import 'package:flutter/foundation.dart';

/// Resolves the current platform for adaptive behavior.
///
/// Used to determine layout strategy (Desktop/Web/Mobile Page)
/// and BFF mode (in-process vs HTTP).
class PlatformResolver {
  const PlatformResolver._();

  /// True when running in a browser (Web WASM or JS).
  static bool get isWeb => kIsWeb;

  /// True when running as a native desktop app (macOS, Windows, Linux).
  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// True on macOS (native).
  static bool get isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  /// True on Windows (native).
  static bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// True on Linux (native).
  static bool get isLinux =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  /// True on Android or iOS (native).
  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
