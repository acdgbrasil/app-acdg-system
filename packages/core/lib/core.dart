/// Core package for ACDG frontend ecosystem.
///
/// Provides base classes and platform resolution shared across all packages.
library;

// Base
export 'src/base/result.dart';
export 'src/base/base_view_model.dart';
export 'src/base/base_use_case.dart';
export 'src/base/command.dart';

// Platform
export 'src/platform/platform_resolver.dart';

// Utils
export 'src/utils/env.dart';
export 'src/utils/hml_auth_helper.dart';
export 'src/utils/equatable/equatable.dart';
export 'src/utils/equatable/equatable_config.dart';
