/// Core package for ACDG frontend ecosystem.
///
/// Provides network, auth, platform resolution, connectivity,
/// and base classes shared across all packages.
library;

// Auth
export 'src/auth/auth_role.dart';
export 'src/auth/auth_status.dart';
export 'src/auth/auth_token.dart';
export 'src/auth/auth_user.dart';
export 'src/auth/auth_service.dart';
export 'src/auth/oidc_auth_config.dart';
export 'src/auth/oidc_auth_service.dart';

// Base
export 'src/base/result.dart';
export 'src/base/base_view_model.dart';
export 'src/base/base_use_case.dart';

// Network
export 'src/network/dio_client.dart';

// Platform
export 'src/platform/platform_resolver.dart';

// Connectivity
export 'src/connectivity/connectivity_service.dart';
