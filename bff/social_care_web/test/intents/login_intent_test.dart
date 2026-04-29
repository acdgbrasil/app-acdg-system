import 'package:test/test.dart';

import 'package:social_care_web/src/intents/login_intent.dart';

void main() {
  group('LoginIntent', () {
    test('can be constructed without returnTo (nullable)', () {
      const intent = LoginIntent();

      expect(intent.returnTo, isNull);
    });

    test('preserves returnTo when provided', () {
      const intent = LoginIntent(returnTo: '/dashboard');

      expect(intent.returnTo, equals('/dashboard'));
    });

    test('instances with equal returnTo are equal (Equatable)', () {
      const a = LoginIntent(returnTo: '/home');
      const b = LoginIntent(returnTo: '/home');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different returnTo are not equal', () {
      const a = LoginIntent(returnTo: '/home');
      const b = LoginIntent(returnTo: '/other');

      expect(a, isNot(equals(b)));
    });

    test('null returnTo is distinct from empty string', () {
      const a = LoginIntent();
      const b = LoginIntent(returnTo: '');

      expect(a, isNot(equals(b)));
    });

    group('parseFromQuery — P2 if-case', () {
      test('returns intent with null returnTo when query is empty', () {
        final intent = LoginIntent.parseFromQuery(const {});

        expect(intent.returnTo, isNull);
      });

      test('returns intent with returnTo when query contains returnTo', () {
        final intent = LoginIntent.parseFromQuery(const {'returnTo': '/dash'});

        expect(intent.returnTo, equals('/dash'));
      });

      test('ignores empty returnTo values (whitespace or empty string)', () {
        final intent = LoginIntent.parseFromQuery(const {'returnTo': ''});

        expect(intent.returnTo, isNull);
      });
    });
  });
}
