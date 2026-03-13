import 'package:meta/meta.dart';
import 'equatable_config.dart';
import 'equatable_utils.dart';

/// A base class and mixin to facilitate [operator ==] and [hashCode] overrides.
///
/// Use as a base class:
/// ```dart
/// class Person extends Equatable { ... }
/// ```
///
/// Or as a mixin (Dart 3+):
/// ```dart
/// class Person with Equatable { ... }
/// ```
@immutable
abstract mixin class Equatable {
  const Equatable();

  /// List of properties used for equality.
  List<Object?> get props;

  /// Global or instance-specific stringify setting.
  bool? get stringify => null;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Equatable &&
            runtimeType == other.runtimeType &&
            iterableEquals(props, other.props);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode(props);

  @override
  String toString() {
    if (stringify ?? EquatableConfig.stringify) {
      return mapPropsToString(runtimeType, props);
    }
    return '$runtimeType';
  }
}
