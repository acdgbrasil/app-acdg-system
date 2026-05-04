/// W0 RED — PKCE pair generation contract (C02 §5.4).
///
/// W1 must create `apps/cli/lib/src/oidc/pkce_pair.dart` with:
///
/// ```dart
/// final class PkcePair with Equatable {
///   const PkcePair({required this.verifier, required this.challenge});
///   final String verifier;
///   final String challenge;
///
///   /// SHA-256(verifier ASCII) → base64url no-pad.
///   static const String method = 'S256';
///
///   /// Generates a fresh pair using `Random.secure()` over 64 random bytes.
///   factory PkcePair.generate();
/// }
/// ```
///
/// Spike-derived contract:
///   * `method` is always `S256` — no fallback to `plain` (Zitadel does not
///     advertise it in `code_challenge_methods_supported`).
///   * `verifier` is base64url-no-pad of 64 random bytes. Per RFC 7636, the
///     resulting string is 86 chars, well within the 43..128 range.
///   * `challenge` = base64url-no-pad of `SHA-256(utf8(verifier))`. Always
///     43 chars (256-bit digest → 32 bytes → 43 b64url chars).
///   * Two consecutive `generate()` calls produce different verifiers (entropy).
///
/// Test discipline (REGRA #1):
///   * The crypto math is verified by hand against a known vector (RFC 7636 §B
///     and a recomputed SHA-256 via `crypto`), so the test is a *contract
///     check*, not a tautology of the impl.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import 'package:cli/src/oidc/pkce_pair.dart';

void main() {
  group('PkcePair.method', () {
    test('is "S256" — Zitadel only supports S256, never plain', () {
      expect(PkcePair.method, equals('S256'));
    });
  });

  group('PkcePair.generate() — verifier shape (RFC 7636 §4.1)', () {
    test('verifier length is in the [43, 128] range', () {
      final pair = PkcePair.generate();

      expect(pair.verifier.length, greaterThanOrEqualTo(43));
      expect(pair.verifier.length, lessThanOrEqualTo(128));
    });

    test('verifier is base64url with no padding (no "=", "+", "/")', () {
      final pair = PkcePair.generate();

      expect(pair.verifier, isNot(contains('=')));
      expect(pair.verifier, isNot(contains('+')));
      expect(pair.verifier, isNot(contains('/')));
      // base64url alphabet: A-Z a-z 0-9 - _
      expect(pair.verifier, matches(RegExp(r'^[A-Za-z0-9\-_]+$')));
    });
  });

  group('PkcePair.generate() — challenge shape (RFC 7636 §4.2)', () {
    test(
      'challenge length is exactly 43 chars (b64url no-pad of 32 bytes)',
      () {
        final pair = PkcePair.generate();

        expect(pair.challenge.length, equals(43));
      },
    );

    test('challenge is base64url with no padding', () {
      final pair = PkcePair.generate();

      expect(pair.challenge, isNot(contains('=')));
      expect(pair.challenge, matches(RegExp(r'^[A-Za-z0-9\-_]+$')));
    });

    test(
      'challenge equals base64url-no-pad(SHA-256(verifier ASCII bytes))',
      () {
        final pair = PkcePair.generate();

        final expected = base64Url
            .encode(sha256.convert(utf8.encode(pair.verifier)).bytes)
            .replaceAll('=', '');

        expect(pair.challenge, equals(expected));
      },
    );
  });

  group('PkcePair.generate() — entropy', () {
    test('two consecutive calls produce different verifiers', () {
      final a = PkcePair.generate();
      final b = PkcePair.generate();

      expect(a.verifier, isNot(equals(b.verifier)));
      expect(a.challenge, isNot(equals(b.challenge)));
    });

    test('20 calls produce 20 unique verifiers (no collisions)', () {
      final verifiers = <String>{};
      for (var i = 0; i < 20; i++) {
        verifiers.add(PkcePair.generate().verifier);
      }
      expect(verifiers.length, equals(20));
    });
  });
}
