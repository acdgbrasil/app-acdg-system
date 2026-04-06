/// Social Care Web BFF — shelf HTTP server.
///
/// Serves the Flutter WASM frontend, handles OIDC authentication
/// (Confidential Client), manages sessions via HttpOnly cookies,
/// and proxies API requests to the backend.
library;

// Config
export 'src/config/server_config.dart';

// Auth
export 'src/auth/oidc_server_client.dart';
export 'src/auth/session_store.dart';

// Middleware
export 'src/middleware/session_middleware.dart';
export 'src/middleware/auth_guard_middleware.dart';

// Handlers
export 'src/handlers/handler_utils.dart';
export 'src/handlers/health_handler.dart';
export 'src/handlers/auth_handler.dart';
export 'src/handlers/registry_handler.dart';
export 'src/handlers/assessment_handler.dart';
export 'src/handlers/care_handler.dart';
export 'src/handlers/protection_handler.dart';
export 'src/handlers/lookup_handler.dart';

// Remote
export 'src/remote/social_care_api_client.dart';

// Server
export 'src/server/app_router.dart';
export 'src/server/shelf_server.dart';
