/// Social Care Web BFF — shelf HTTP server.
///
/// Serves the Flutter WASM frontend, handles OIDC authentication
/// (Confidential Client), manages sessions via HttpOnly cookies,
/// and proxies API requests to the backend.
library;

// Config
export 'src/config/server_config.dart';

// Auth
export 'src/auth/jwks_cache.dart';
export 'src/auth/jwks_client.dart';
export 'src/auth/oidc_server_client.dart';
export 'src/auth/session_store.dart';

// Middleware
export 'src/middleware/auth_guard_middleware.dart';
export 'src/middleware/bearer_auth_middleware.dart';
export 'src/middleware/session_middleware.dart';

// Handlers (canonical A07+)
export 'src/handlers/auth_handler.dart';
export 'src/handlers/registry_patient_handler.dart';

// Server
export 'src/server/app_router.dart';
export 'src/server/shelf_server.dart';
