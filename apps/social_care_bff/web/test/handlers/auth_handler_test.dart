import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/auth/session_store.dart';
import 'package:social_care_web/src/handlers/auth_handler.dart';
import 'package:social_care_web/src/use_cases/auth_callback_use_case.dart';
import 'package:social_care_web/src/use_cases/login_use_case.dart';
import 'package:social_care_web/src/use_cases/logout_use_case.dart';
import 'package:social_care_web/src/use_cases/me_use_case.dart';
import 'package:social_care_web/src/use_cases/refresh_use_case.dart';

/// An [AuthContract] fake that simulates the full backend chain end-to-end.
///
/// Tests override specific behaviors through subclass composition, never via
/// mock magic — aligned with feedback_mapper_architecture and
/// feedback_dart_best_practices.
class _FailingLoginAuth extends FakeAuthBff {
  _FailingLoginAuth(this.error);
  final BackendError error;
  @override
  Future<Result<String>> login() async => Failure(error);
}

class _FailingMeAuth extends FakeAuthBff {
  _FailingMeAuth(this.error);
  final BackendError error;
  @override
  Future<Result<StandardResponse<MeResponse>>> me() async => Failure(error);
}

/// Builds a thin-handler fixture with all UseCases wired on a shared contract.
AuthHandler _buildHandler(AuthContract contract) {
  final sessionStore = SessionStore(
    ttl: const Duration(hours: 1),
    clock: () => DateTime.utc(2026, 5, 4, 12, 0),
  );
  return AuthHandler(
    login: LoginUseCase(auth: contract),
    callback: AuthCallbackUseCase(auth: contract, sessionStore: sessionStore),
    logout: LogoutUseCase(auth: contract),
    me: MeUseCase(auth: contract),
    refresh: RefreshUseCase(auth: contract),
  );
}

void main() {
  group('AuthHandler (thin handler — UseCase orchestration)', () {
    group('GET /auth/login', () {
      test(
        'returns 302 redirect to the URL provided by AuthContract.login',
        () async {
          final fake = FakeAuthBff();
          final handler = _buildHandler(fake);

          final request = Request(
            'GET',
            Uri.parse('http://localhost/auth/login'),
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(302));
          expect(
            response.headers['location'],
            equals('https://fake-idp.local/authorize?state=fake'),
          );
        },
      );

      test('passes returnTo query param into LoginIntent', () async {
        final fake = FakeAuthBff();
        final handler = _buildHandler(fake);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/auth/login?returnTo=/dashboard'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(302));
      });

      test('returns 502 when AuthContract.login fails', () async {
        final failing = _FailingLoginAuth(
          const BackendError(
            id: 'err-1',
            code: 'OIDC_UNAVAILABLE',
            message: 'Zitadel is down',
            http: 502,
          ),
        );
        final handler = _buildHandler(failing);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/auth/login'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(502));
      });
    });

    group('GET /auth/callback', () {
      test('returns 302 to "/" with Set-Cookie on success', () async {
        final fake = FakeAuthBff();
        final handler = _buildHandler(fake);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/auth/callback?code=abc&state=xyz'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(302));
        expect(response.headers['location'], equals('/'));
        expect(response.headers['set-cookie'], isNotNull);
        expect(response.headers['set-cookie']!, contains('__Host-session='));
      });

      test('session cookie has HttpOnly + Secure + SameSite=Strict', () async {
        final fake = FakeAuthBff();
        final handler = _buildHandler(fake);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/auth/callback?code=abc&state=xyz'),
        );
        final response = await handler.router.call(request);

        final cookie = response.headers['set-cookie']!.toLowerCase();
        expect(cookie, contains('httponly'));
        expect(cookie, contains('secure'));
        expect(cookie, contains('samesite=strict'));
      });

      test('returns 400 when code is missing from query', () async {
        final fake = FakeAuthBff();
        final handler = _buildHandler(fake);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/auth/callback?state=xyz'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });

      test('returns 400 when state is missing from query', () async {
        final fake = FakeAuthBff();
        final handler = _buildHandler(fake);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/auth/callback?code=abc'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });

      test('400 error body does NOT leak the raw OIDC code', () async {
        const rawCode = 'leak-me-please-oidc-code';
        final fake = FakeAuthBff();
        final handler = _buildHandler(fake);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/auth/callback?code=$rawCode'),
          // missing state
        );
        final response = await handler.router.call(request);
        final body = await response.readAsString();

        expect(response.statusCode, equals(400));
        expect(
          body,
          isNot(contains(rawCode)),
          reason: 'Error responses must not echo the raw OIDC code',
        );
      });
    });

    group('POST /auth/logout', () {
      test('returns 200 and clears session cookie on success', () async {
        final fake = FakeAuthBff();
        final handler = _buildHandler(fake);

        final request = Request(
          'POST',
          Uri.parse('http://localhost/auth/logout'),
          headers: {'Cookie': '__Host-session=abc123'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));
        final cookie = response.headers['set-cookie']!;
        expect(cookie, contains('__Host-session='));
        expect(cookie.toLowerCase(), contains('max-age=0'));
      });

      test(
        'returns 200 even when no session cookie is present (idempotent)',
        () async {
          final fake = FakeAuthBff();
          final handler = _buildHandler(fake);

          final request = Request(
            'POST',
            Uri.parse('http://localhost/auth/logout'),
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(200));
        },
      );
    });

    group('GET /auth/me', () {
      test('returns 200 with MeResponse JSON when session exists', () async {
        final fake = FakeAuthBff();
        final handler = _buildHandler(fake);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/auth/me'),
          headers: {'Cookie': '__Host-session=abc123'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['userId'], equals('fake-user-id'));
        expect(body['email'], equals('fake@acdgbrasil.com.br'));
        expect(body['roles'], equals(<String>['social_worker']));
      });

      test('returns 401 when no session cookie is present', () async {
        final fake = FakeAuthBff();
        final handler = _buildHandler(fake);

        final request = Request('GET', Uri.parse('http://localhost/auth/me'));
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(401));
      });

      test(
        'returns 401 when AuthContract.me fails with SESSION_INVALID',
        () async {
          final failing = _FailingMeAuth(
            const BackendError(
              id: 'err-1',
              code: 'SESSION_INVALID',
              message: 'Session expired',
              http: 401,
            ),
          );
          final handler = _buildHandler(failing);

          final request = Request(
            'GET',
            Uri.parse('http://localhost/auth/me'),
            headers: {'Cookie': '__Host-session=abc123'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(401));
        },
      );
    });

    group('POST /auth/refresh', () {
      test('returns 200 when AuthContract.refresh succeeds', () async {
        final fake = FakeAuthBff();
        final handler = _buildHandler(fake);

        final request = Request(
          'POST',
          Uri.parse('http://localhost/auth/refresh'),
          headers: {'Cookie': '__Host-session=abc123'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));
      });

      test('returns 401 when no session cookie is present', () async {
        final fake = FakeAuthBff();
        final handler = _buildHandler(fake);

        final request = Request(
          'POST',
          Uri.parse('http://localhost/auth/refresh'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(401));
      });
    });

    group('State matrix (P1) — result → response consistency', () {
      test('all success paths return 2xx or 3xx — never 4xx/5xx', () async {
        final fake = FakeAuthBff();
        final handler = _buildHandler(fake);

        final cases = <(String, Request)>[
          ('login', Request('GET', Uri.parse('http://localhost/auth/login'))),
          (
            'callback',
            Request(
              'GET',
              Uri.parse('http://localhost/auth/callback?code=abc&state=xyz'),
            ),
          ),
          (
            'logout',
            Request(
              'POST',
              Uri.parse('http://localhost/auth/logout'),
              headers: {'Cookie': '__Host-session=abc123'},
            ),
          ),
          (
            'me',
            Request(
              'GET',
              Uri.parse('http://localhost/auth/me'),
              headers: {'Cookie': '__Host-session=abc123'},
            ),
          ),
          (
            'refresh',
            Request(
              'POST',
              Uri.parse('http://localhost/auth/refresh'),
              headers: {'Cookie': '__Host-session=abc123'},
            ),
          ),
        ];

        for (final (name, req) in cases) {
          final res = await handler.router.call(req);
          expect(
            res.statusCode,
            lessThan(400),
            reason: '$name should succeed against FakeAuthBff defaults',
          );
        }
      });
    });
  });
}
