/// W2 RED — `McpToolRegistry` dispatch / RBAC / redaction contract.
///
/// Validates DESIGN §2.4 + §3 + §5: the registry is the only class that
///   1. resolves the tool by name (or returns "Unknown tool"),
///   2. validates JSON Schema args,
///   3. enforces RBAC against the local session,
///   4. invokes the handler,
///   5. wraps Success/Failure into a `CallToolResult` with a redacted
///      message when the handler surfaces a sensitive error.
///
/// W3 (impl-agent) creates `apps/cli/lib/src/mcp/mcp_tool_registry.dart`
/// with `McpToolRegistry` + `McpToolHandler`. Until then these imports
/// are unresolved (expected RED).
library;

import 'dart:typed_data';

import 'package:cli/src/mcp/mcp_tool_registry.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/oidc_session.dart';
import 'package:dart_mcp/server.dart' as mcp;
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'testing/fake_bff_client.dart';
import 'testing/fake_credential_store.dart';

void main() {
  group('McpToolRegistry.dispatch — routing', () {
    test('returns "Unknown tool: <name>" for an unregistered tool', () async {
      final registry = _buildRegistry();

      final result = await registry.dispatch(
        'totally.not.a.tool',
        const <String, Object?>{},
      );

      expect(result.isError, isTrue);
      expect(_text(result), contains('Unknown tool'));
      expect(_text(result), contains('totally.not.a.tool'));
    });

    test('rejects malformed args BEFORE invoking the handler', () async {
      // patient.get requires { patientId: string }. Dispatching an empty
      // arg map must surface a schema error instead of reaching the
      // handler — proves DESIGN §2.4 step 2 (schema first, handler last).
      final registry = _buildRegistry(
        seededSession: FakeCredentialStore.seededSession(
          roles: const ['social_worker'],
        ),
      );

      final result = await registry.dispatch(
        'patient.get',
        const <String, Object?>{},
      );

      expect(result.isError, isTrue);
      expect(_text(result), contains('Invalid arguments'));
    });
  });

  group('McpToolRegistry.dispatch — RBAC', () {
    test(
      'returns "Authentication required" when no session is persisted',
      () async {
        // patient.list has requiredRoles {social_worker, owner, admin} —
        // an empty store must trip the auth gate.
        final registry = _buildRegistry();

        final result = await registry.dispatch(
          'patient.list',
          const <String, Object?>{},
        );

        expect(result.isError, isTrue);
        expect(_text(result), contains('Authentication required'));
      },
    );

    test(
      'returns "Forbidden" when session lacks every required role',
      () async {
        // Session has a role that no MVP tool grants — must be denied even
        // though authentication is present.
        final registry = _buildRegistry(
          seededSession: FakeCredentialStore.seededSession(
            roles: const ['some_unrelated_role'],
          ),
        );

        final result = await registry.dispatch(
          'patient.list',
          const <String, Object?>{},
        );

        expect(result.isError, isTrue);
        expect(_text(result), contains('Forbidden'));
      },
    );
  });

  group('McpToolRegistry.dispatch — error redaction', () {
    test('NetworkError (Dio connection error) is redacted to a generic '
        '"Network error" message — host:port detail must NOT leak', () async {
      // Drive the BFF into a NetworkError by raising a DioException with
      // a connection-level failure type. The error message contains a
      // synthetic host:port that MUST be stripped from the redacted
      // CallToolResult text.
      final throwingAdapter = _ThrowingAdapter(
        message: 'connection refused at 10.0.0.5:5432',
      );
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
        ..httpClientAdapter = throwingAdapter;
      final store = FakeCredentialStore(
        seed: FakeCredentialStore.seededSession(roles: const ['social_worker']),
      );
      final bff = BffClient(
        baseUrl: 'http://localhost:3000',
        credentialStore: store,
        dio: dio,
      );
      final registry = McpToolRegistry(
        bffClient: bff,
        credentialStore: store,
        logger: Logger('acdg.mcp.registry.test'),
      );

      final result = await registry.dispatch(
        'patient.list',
        const <String, Object?>{},
      );

      expect(result.isError, isTrue);
      // DESIGN §2.4 _redactCliError(NetworkError) — the technical detail
      // (host:port) MUST NOT leak to the AI host.
      expect(
        _text(result),
        isNot(contains('10.0.0.5')),
        reason: 'NetworkError detail must not leak to the AI host',
      );
      expect(_text(result), contains('Network error'));
    });

    test('AuthRequiredError preserves its `stderrMessage` literal '
        '(already user-safe, no redaction)', () async {
      // Drive a 401 with no TokenClient wired → BffClient returns
      // Failure(AuthRequiredError()) deterministically (see
      // bff_client.dart:305).
      final adapter = _StatusAdapter(status: 401, body: 'unauthorized');
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
        ..httpClientAdapter = adapter;
      final store = FakeCredentialStore(
        seed: FakeCredentialStore.seededSession(roles: const ['social_worker']),
      );
      final bff = BffClient(
        baseUrl: 'http://localhost:3000',
        credentialStore: store,
        dio: dio,
        // No TokenClient → the 401 path resolves to AuthRequiredError.
      );
      final registry = McpToolRegistry(
        bffClient: bff,
        credentialStore: store,
        logger: Logger('acdg.mcp.registry.test'),
      );

      final result = await registry.dispatch(
        'patient.list',
        const <String, Object?>{},
      );

      expect(result.isError, isTrue);
      // Literal copy from AuthRequiredError.stderrMessage — the registry
      // MUST NOT rewrap or paraphrase this user-facing string.
      expect(
        _text(result),
        equals('Authentication required. Run: acdg auth login'),
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

McpToolRegistry _buildRegistry({OidcSession? seededSession}) {
  final bff = buildFakeBffClient();
  final store = FakeCredentialStore(seed: seededSession);
  return McpToolRegistry(
    bffClient: bff.client,
    credentialStore: store,
    logger: Logger('acdg.mcp.registry.test'),
  );
}

String _text(mcp.CallToolResult result) {
  // Each CallToolResult in MVP wraps a single TextContent with the user-
  // facing message. We surface that text for assertion ergonomics.
  final first = result.content.first;
  if (first is mcp.TextContent) return first.text;
  return first.toString();
}

class _ThrowingAdapter implements HttpClientAdapter {
  _ThrowingAdapter({required this.message});
  final String message;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      message: message,
    );
  }
}

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter({required this.status, required this.body});
  final int status;
  final String body;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        'content-type': ['text/plain'],
      },
    );
  }
}
