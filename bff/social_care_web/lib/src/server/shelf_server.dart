import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

import '../config/server_config.dart';
import 'app_router.dart';

/// HTTP server wrapper that creates and manages the shelf server.
///
/// Combines the [AppRouter] handler with request logging
/// and starts/stops the underlying [HttpServer].
class ShelfServer {
  ShelfServer({required this.config, required this.appRouter});

  /// Server configuration (host, port, etc.).
  final ServerConfig config;

  /// The assembled application router.
  final AppRouter appRouter;

  HttpServer? _server;

  /// Whether the server is currently running.
  bool get isRunning => _server != null;

  /// Starts the HTTP server.
  ///
  /// Wraps the router handler with [logRequests] middleware
  /// and binds to [config.host]:[config.port].
  Future<void> start() async {
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(appRouter.handler);

    _server = await io.serve(handler, config.host, config.port);
    print('BFF Web server listening on ${config.host}:${config.port}');
  }

  /// Stops the HTTP server gracefully.
  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }
}
