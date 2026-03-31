/// Auth package for ACDG frontend ecosystem.
///
/// Provides authentication models, OIDC service, roles, and token management.
library;

export 'src/models/auth_role.dart';
export 'src/models/auth_status.dart';
export 'src/models/auth_token.dart';
export 'src/models/auth_user.dart';
export 'src/repositories/auth_repository.dart';
export 'src/services/auth_service.dart';
export 'src/services/oidc/oidc_auth_config.dart';
export 'src/services/oidc/oidc_auth_service.dart';
export 'src/services/oidc/oidc_claims_parser.dart';
