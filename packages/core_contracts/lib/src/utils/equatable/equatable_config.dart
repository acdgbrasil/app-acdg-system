// ignore_for_file: avoid_classes_with_only_static_members
import 'equatable.dart';

/// The default configuration for all [Equatable] instances.
class EquatableConfig {
  /// Global [stringify] setting for all [Equatable] instances.
  ///
  /// This value defaults to true in debug mode and false in release mode.
  static bool get stringify {
    if (_stringify == null) {
      assert(() {
        _stringify = true;
        return true;
      }());
    }
    return _stringify ??= false;
  }

  /// Sets the global [stringify] value.
  static set stringify(bool value) => _stringify = value;

  static bool? _stringify;
}
