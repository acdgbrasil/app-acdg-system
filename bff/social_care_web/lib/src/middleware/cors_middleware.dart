import 'package:shelf/shelf.dart';

/// CORS middleware for local development.
///
/// Allows the Flutter dev server (running on a different port)
/// to call the BFF with credentials (session cookies).
Middleware corsMiddleware({required String allowedOrigin}) {
  return (Handler innerHandler) {
    return (Request request) async {
      // Handle preflight
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders(allowedOrigin));
      }

      final response = await innerHandler(request);
      return response.change(headers: _corsHeaders(allowedOrigin));
    };
  };
}

Map<String, String> _corsHeaders(String origin) => {
  'Access-Control-Allow-Origin': origin,
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, X-Requested-With',
  'Access-Control-Allow-Credentials': 'true',
  'Access-Control-Max-Age': '86400',
};
