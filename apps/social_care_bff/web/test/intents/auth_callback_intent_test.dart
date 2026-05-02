import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/auth_callback_intent.dart';

void main() {
  group('AuthCallbackIntent', () {
    test('constructs with required code + state', () {
      const intent = AuthCallbackIntent(code: 'abc123', state: 'state-xyz');

      expect(intent.code, equals('abc123'));
      expect(intent.state, equals('state-xyz'));
    });

    test('instances with equal fields are equal (Equatable)', () {
      const a = AuthCallbackIntent(code: 'abc', state: 'xyz');
      const b = AuthCallbackIntent(code: 'abc', state: 'xyz');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances differ if any field differs', () {
      const a = AuthCallbackIntent(code: 'abc', state: 'xyz');
      const b = AuthCallbackIntent(code: 'abc', state: 'other');

      expect(a, isNot(equals(b)));
    });

    group('parseFromQuery — Result<AuthCallbackIntent> (P2 if-case)', () {
      test('returns Success when code + state are present and non-empty', () {
        final result = AuthCallbackIntent.parseFromQuery(const {
          'code': 'abc',
          'state': 'xyz',
        });

        expect(result, isA<Success<AuthCallbackIntent>>());
        switch (result) {
          case Success(:final value):
            expect(value.code, equals('abc'));
            expect(value.state, equals('xyz'));
          case Failure():
            fail('Expected Success, got Failure');
        }
      });

      test('returns Failure when code is missing', () {
        final result = AuthCallbackIntent.parseFromQuery(const {
          'state': 'xyz',
        });

        expect(result, isA<Failure<AuthCallbackIntent>>());
      });

      test('returns Failure when code is empty', () {
        final result = AuthCallbackIntent.parseFromQuery(const {
          'code': '',
          'state': 'xyz',
        });

        expect(result, isA<Failure<AuthCallbackIntent>>());
      });

      test('returns Failure when state is missing', () {
        final result = AuthCallbackIntent.parseFromQuery(const {'code': 'abc'});

        expect(result, isA<Failure<AuthCallbackIntent>>());
      });

      test('returns Failure when state is empty', () {
        final result = AuthCallbackIntent.parseFromQuery(const {
          'code': 'abc',
          'state': '',
        });

        expect(result, isA<Failure<AuthCallbackIntent>>());
      });

      test('returns Failure when both code and state are absent', () {
        final result = AuthCallbackIntent.parseFromQuery(const {});

        expect(result, isA<Failure<AuthCallbackIntent>>());
      });

      test(
        'failure error message does NOT leak raw OIDC code (PII masking)',
        () {
          final result = AuthCallbackIntent.parseFromQuery(const {
            'code': 'sensitive-oidc-code-full-value',
            // missing state — forces Failure
          });

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              expect(
                error.toString(),
                isNot(contains('sensitive-oidc-code-full-value')),
                reason: 'Parse error must not echo the raw OIDC code',
              );
          }
        },
      );
    });
  });
}
