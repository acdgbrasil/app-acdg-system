/// Pure Dart contracts and utilities — no Flutter dependency.
///
/// Used by BFF packages (server-side) to avoid pulling in dart:ui.
/// Flutter packages should import `package:core/core.dart` which
/// re-exports this barrel transparently.
library;

// Base
export 'src/base/result.dart';
export 'src/base/base_use_case.dart';

// Utils
export 'src/utils/uuid_util.dart';
export 'src/utils/equatable/equatable.dart';
export 'src/utils/equatable/equatable_config.dart';
