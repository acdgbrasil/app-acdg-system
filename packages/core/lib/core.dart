/// Core package for ACDG frontend ecosystem.
///
/// Provides base classes and platform resolution shared across all packages.
/// Pure Dart contracts are re-exported from [core_contracts].
library;

// Pure Dart (from core_contracts — no Flutter dependency)
export 'package:core_contracts/core_contracts.dart';

// Flutter-dependent (local)
export 'src/base/base_view_model.dart';
export 'src/base/command.dart';
export 'src/platform/platform_resolver.dart';
export 'src/utils/env.dart';
export 'src/utils/acdg_logger.dart';
export 'src/infrastructure/logging/log_level.dart';
export 'src/infrastructure/logging/sentry_client_adapter.dart';
export 'src/infrastructure/logging/sentry_logger_impl.dart';
export 'src/infrastructure/logging/real_sentry_client_adapter.dart';
export 'src/utils/hml_auth_helper.dart';
export 'src/utils/custom_masks.dart';
