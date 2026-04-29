import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/middleware/observability.dart';
import 'package:social_care_web/src/observability/observability_context.dart';

/// Spy on [Logger.root.onRecord] for the duration of the test.
///
/// The middleware uses `package:logging` (per ticket spec) — AcdgLogger bridges
/// to Sentry. Tests stay at the `Logger.root` layer so we don't require Sentry
/// to be initialized.
class _LogSpy {
  _LogSpy() {
    _sub = Logger.root.onRecord.listen(records.add);
  }

  final List<LogRecord> records = [];
  late final StreamSubscription<LogRecord> _sub;

  void dispose() => _sub.cancel();
}

void main() {
  group('observabilityMiddleware', () {
    late _LogSpy spy;

    setUp(() {
      Logger.root.level = Level.ALL;
      spy = _LogSpy();
    });

    tearDown(() => spy.dispose());

    test('injects a non-empty requestId into Request.context', () async {
      String? seenRequestId;
      final handler = const Pipeline()
          .addMiddleware(observabilityMiddleware())
          .addHandler((request) {
            seenRequestId = request.context['requestId'] as String?;
            return Response.ok('ok');
          });

      await handler(Request('GET', Uri.parse('http://localhost/x')));

      expect(seenRequestId, isNotNull);
      expect(seenRequestId!, isNotEmpty);
    });

    test('generates a fresh requestId for each request', () async {
      final captured = <String>[];
      final handler = const Pipeline()
          .addMiddleware(observabilityMiddleware())
          .addHandler((request) {
            captured.add(request.context['requestId']! as String);
            return Response.ok('ok');
          });

      await handler(Request('GET', Uri.parse('http://localhost/a')));
      await handler(Request('GET', Uri.parse('http://localhost/b')));

      expect(captured.length, equals(2));
      expect(captured[0], isNot(equals(captured[1])));
    });

    test('exposes ObservabilityContext via .of(request)', () async {
      ObservabilityContext? captured;
      final handler = const Pipeline()
          .addMiddleware(observabilityMiddleware())
          .addHandler((request) {
            captured = ObservabilityContext.of(request);
            return Response.ok('ok');
          });

      await handler(Request('GET', Uri.parse('http://localhost/x')));

      expect(captured, isNotNull);
      expect(captured!.requestId, isNotEmpty);
    });

    test('emits a request.received breadcrumb on every request', () async {
      final handler = const Pipeline()
          .addMiddleware(observabilityMiddleware())
          .addHandler((_) => Response.ok('ok'));

      await handler(Request('GET', Uri.parse('http://localhost/x')));

      expect(
        spy.records.any((r) => r.message.contains('request.received')),
        isTrue,
        reason: 'request.received breadcrumb must reach the logger',
      );
    });

    test('emits a request.completed breadcrumb with status code', () async {
      final handler = const Pipeline()
          .addMiddleware(observabilityMiddleware())
          .addHandler((_) => Response(204));

      await handler(Request('GET', Uri.parse('http://localhost/x')));

      final completed = spy.records.where(
        (r) => r.message.contains('request.completed'),
      );
      expect(completed, isNotEmpty);
      expect(
        completed.any((r) => r.message.contains('204')),
        isTrue,
        reason: 'completed breadcrumb must carry the response status',
      );
    });

    test('emits completed breadcrumb with elapsed time (ms field)', () async {
      final handler = const Pipeline()
          .addMiddleware(observabilityMiddleware())
          .addHandler((_) => Response.ok('ok'));

      await handler(Request('GET', Uri.parse('http://localhost/x')));

      final completed = spy.records.where(
        (r) => r.message.contains('request.completed'),
      );
      expect(
        completed.any((r) => r.message.toLowerCase().contains('ms')),
        isTrue,
        reason: 'completed breadcrumb should include elapsed ms',
      );
    });

    test(
      'converts unhandled exceptions into a 500 Response (no rethrow)',
      () async {
        final handler = const Pipeline()
            .addMiddleware(observabilityMiddleware())
            .addHandler((_) => throw StateError('boom'));

        final response = await handler(
          Request('GET', Uri.parse('http://localhost/x')),
        );

        expect(response.statusCode, equals(500));
      },
    );

    test('logs exception at severe level with stack trace captured', () async {
      final handler = const Pipeline()
          .addMiddleware(observabilityMiddleware())
          .addHandler((_) => throw StateError('boom'));

      await handler(Request('GET', Uri.parse('http://localhost/x')));

      expect(
        spy.records.any((r) => r.level >= Level.SEVERE && r.error != null),
        isTrue,
        reason: 'exception must reach severe log with error attached',
      );
    });

    test('500 response body does NOT leak the exception message raw', () async {
      final handler = const Pipeline()
          .addMiddleware(observabilityMiddleware())
          .addHandler((_) => throw StateError('internal-secret-boom'));

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/x')),
      );
      final body = await response.readAsString();

      expect(
        body,
        isNot(contains('internal-secret-boom')),
        reason: 'internal exception messages must not leak to the client',
      );
    });

    test(
      'request.received breadcrumb does NOT carry raw OIDC code from query',
      () async {
        const rawCode = 'secret-oidc-code-xyz';
        final handler = const Pipeline()
            .addMiddleware(observabilityMiddleware())
            .addHandler((_) => Response.ok('ok'));

        await handler(
          Request(
            'GET',
            Uri.parse('http://localhost/auth/callback?code=$rawCode&state=s'),
          ),
        );

        for (final record in spy.records) {
          expect(
            record.message,
            isNot(contains(rawCode)),
            reason:
                'OIDC codes must be masked/stripped at the middleware layer',
          );
        }
      },
    );

    test(
      'request.received breadcrumb does NOT carry raw access/refresh tokens',
      () async {
        final handler = const Pipeline()
            .addMiddleware(observabilityMiddleware())
            .addHandler((_) => Response.ok('ok'));

        await handler(
          Request(
            'POST',
            Uri.parse('http://localhost/auth/refresh'),
            headers: {
              'Authorization': 'Bearer super-secret-access-token',
              'Cookie': '__Host-session=secret-session-id',
            },
            body: '{"access_token":"stuff"}',
          ),
        );

        for (final record in spy.records) {
          final msg = record.message.toLowerCase();
          expect(msg, isNot(contains('super-secret-access-token')));
          expect(msg, isNot(contains('secret-session-id')));
          expect(msg, isNot(contains('bearer super')));
        }
      },
    );

    test('ObservabilityContext.of fails fast when middleware is missing', () {
      final request = Request('GET', Uri.parse('http://localhost/x'));

      expect(
        () => ObservabilityContext.of(request),
        throwsA(isA<Exception>()),
        reason:
            'Calling of(request) without middleware must surface a clear error '
            '(use unreachable — P4 — not silent noop)',
      );
    });
  });
}
