// Regression tests for B3 — CLI BFF allowlist
// References:
//   .pipeline/phase-6-security-remediation/tickets/B3-cli-flags-hardening/001-design/DESIGN.md §test-matrix
//   handbook/audit/2026-05-04-cli-pentest/REPORT.md §F1
//
// SEC: every test here exists because a real audit finding (F1, CVSS 8.8)
// proved that without `validateBffUrl`, `--bff=http://attacker.tld` exfils
// the OAuth Bearer in <1s. These tests prevent reintroduction.
//
// RED state at Wave 2 close (intentional):
//   * `package:cli/src/config/bff_allowlist.dart` does NOT exist yet.
//   * `validateBffUrl`, `BffAllowlistError`, the three error variants, and
//     `renderBffAllowlistError` will be created in Wave 3 (vulnerability-fixer).
//   * `dart analyze test/security/bff_allowlist_test.dart` is expected to
//     report unresolved imports/symbols — that's the agreed RED contract.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

// Wave 3 will create this file. Importing it now makes the whole suite RED.
// ignore: uri_does_not_exist
import 'package:cli/src/config/bff_allowlist.dart';

void main() {
  group('validateBffUrl — ALLOW (positive paths)', () {
    // Rule 1 — http://127.0.0.1[:port]
    test('U1: http://127.0.0.1:8081 → Success', () {
      final result = validateBffUrl('http://127.0.0.1:8081');
      expect(result, isA<Success<Uri>>());
      final uri = (result as Success<Uri>).value;
      expect(uri.host, equals('127.0.0.1'));
      expect(uri.scheme, equals('http'));
    });

    test('U2: http://127.0.0.1 (no port) → Success', () {
      final result = validateBffUrl('http://127.0.0.1');
      expect(result, isA<Success<Uri>>());
    });

    // Rule 2 — http://localhost[:port]
    test('U3: http://localhost:8081 → Success', () {
      final result = validateBffUrl('http://localhost:8081');
      expect(result, isA<Success<Uri>>());
    });

    test('U4: http://LOCALHOST:8081 → Success (case-insensitive host)', () {
      final result = validateBffUrl('http://LOCALHOST:8081');
      expect(result, isA<Success<Uri>>());
    });

    // Rule 3 — IPv6 loopback (::1)
    test('U5: http://[::1]:8081 → Success (IPv6 loopback)', () {
      final result = validateBffUrl('http://[::1]:8081');
      expect(result, isA<Success<Uri>>());
    });

    // Rule 4 — IPv4 127/8 block
    test('U6: http://127.42.0.1 → Success (127.0.0.0/8 loopback block)', () {
      final result = validateBffUrl('http://127.42.0.1');
      expect(result, isA<Success<Uri>>());
    });

    // Rule 5 — https://acdgbrasil.com.br (apex)
    test('U7: https://acdgbrasil.com.br → Success (production apex)', () {
      final result = validateBffUrl('https://acdgbrasil.com.br');
      expect(result, isA<Success<Uri>>());
    });

    // Rule 6 — https://*.acdgbrasil.com.br
    test('U8: https://api.acdgbrasil.com.br → Success (single subdomain)', () {
      final result = validateBffUrl('https://api.acdgbrasil.com.br');
      expect(result, isA<Success<Uri>>());
    });

    test(
      'U9: https://staging.api.acdgbrasil.com.br → Success (multi-label subdomain)',
      () {
        final result = validateBffUrl('https://staging.api.acdgbrasil.com.br');
        expect(result, isA<Success<Uri>>());
      },
    );

    test('U10: https://api.acdgbrasil.com.br:80 → Success (port-agnostic)', () {
      final result = validateBffUrl('https://api.acdgbrasil.com.br:80');
      expect(result, isA<Success<Uri>>());
    });

    // Rule 7 — https on loopback
    test('U11: https://localhost:8443 → Success (TLS on loopback)', () {
      final result = validateBffUrl('https://localhost:8443');
      expect(result, isA<Success<Uri>>());
    });

    // Parametrised: every loopback variant accepted
    final loopbackHttp = <String>[
      'http://127.0.0.1',
      'http://127.0.0.1:1',
      'http://127.0.0.1:65535',
      'http://localhost',
      'http://localhost:80',
      'http://[::1]',
      'http://[::1]:8081',
      'http://127.255.255.254',
    ];
    for (final input in loopbackHttp) {
      test('ALLOW http loopback variant: $input', () {
        expect(validateBffUrl(input), isA<Success<Uri>>());
      });
    }
  });

  group('validateBffUrl — REJECT host (BffHostNotAllowedError)', () {
    test(
      'U12: http://evil.tld → BffHostNotAllowedError (non-loopback http)',
      () {
        final result = validateBffUrl('http://evil.tld');
        expect(result, isA<Failure<Uri>>());
        final err = (result as Failure<Uri>).error;
        expect(err, isA<BffHostNotAllowedError>());
      },
    );

    test('U13: https://evil.tld → BffHostNotAllowedError (not in apex)', () {
      final result = validateBffUrl('https://evil.tld');
      expect(result, isA<Failure<Uri>>());
      expect((result as Failure<Uri>).error, isA<BffHostNotAllowedError>());
    });

    test(
      'U14: https://evil-acdgbrasil.com.br → BffHostNotAllowedError (suffix-confusion)',
      () {
        // SEC: anchor must be on '.acdgbrasil.com.br', not 'acdgbrasil.com.br'.
        final result = validateBffUrl('https://evil-acdgbrasil.com.br');
        expect(result, isA<Failure<Uri>>());
        expect((result as Failure<Uri>).error, isA<BffHostNotAllowedError>());
      },
    );

    test(
      'U15: https://acdgbrasil.com.br.evil.tld → BffHostNotAllowedError (DNS confusion)',
      () {
        final result = validateBffUrl('https://acdgbrasil.com.br.evil.tld');
        expect(result, isA<Failure<Uri>>());
        expect((result as Failure<Uri>).error, isA<BffHostNotAllowedError>());
      },
    );

    test(
      'U16: file:///etc/passwd → BffHostNotAllowedError (non-http(s) scheme)',
      () {
        final result = validateBffUrl('file:///etc/passwd');
        expect(result, isA<Failure<Uri>>());
        // Either malformed (no host) or host-not-allowed; both are exit-64 paths.
        expect(result, isA<Failure<Uri>>());
      },
    );

    test(
      'U17: https://api.acdgbrasil.com.br/api/v1 → BffHostNotAllowedError (non-empty path)',
      () {
        // SEC: base URL must end at host — `dio` adds the per-request path.
        final result = validateBffUrl('https://api.acdgbrasil.com.br/api/v1');
        expect(result, isA<Failure<Uri>>());
        expect((result as Failure<Uri>).error, isA<BffHostNotAllowedError>());
      },
    );

    test(
      'U18: https://api.acdgbrasil.com.br?x=1 → BffHostNotAllowedError (query)',
      () {
        final result = validateBffUrl('https://api.acdgbrasil.com.br?x=1');
        expect(result, isA<Failure<Uri>>());
        expect((result as Failure<Uri>).error, isA<BffHostNotAllowedError>());
      },
    );

    test(
      'U19: https://api.acdgbrasil.com.br#frag → BffHostNotAllowedError (fragment)',
      () {
        final result = validateBffUrl('https://api.acdgbrasil.com.br#frag');
        expect(result, isA<Failure<Uri>>());
        expect((result as Failure<Uri>).error, isA<BffHostNotAllowedError>());
      },
    );

    // Parametrised: every "attacker URL" payload rejected.
    final hostRejects = <String>[
      'http://attacker.tld',
      'http://attacker.tld:8080',
      'http://10.0.0.1',
      'http://192.168.1.1',
      'http://169.254.169.254', // AWS metadata
      'https://attacker.example.com',
      'https://acdgbrasil.evil.tld',
      'https://faked-acdgbrasil.com.br',
      'http://attacker.tld/api',
      'ssh://acdgbrasil.com.br',
      'javascript:alert(1)',
    ];
    for (final input in hostRejects) {
      test('REJECT host: $input', () {
        final result = validateBffUrl(input);
        expect(
          result,
          isA<Failure<Uri>>(),
          reason: 'attacker URL "$input" must be rejected',
        );
      });
    }
  });

  group('validateBffUrl — REJECT userinfo (BffEmbedsCredentialsError)', () {
    test(
      'U20: http://alice:secret@localhost:8081 → BffEmbedsCredentialsError',
      () {
        // SEC: classic URL-confusion vector. `http://acdgbrasil.com.br@evil.tld`
        // would otherwise resolve to host=evil.tld with userinfo=acdgbrasil.com.br.
        final result = validateBffUrl('http://alice:secret@localhost:8081');
        expect(result, isA<Failure<Uri>>());
        expect(
          (result as Failure<Uri>).error,
          isA<BffEmbedsCredentialsError>(),
        );
      },
    );

    test(
      'U20b: http://acdgbrasil.com.br@evil.tld → BffEmbedsCredentialsError (URL confusion)',
      () {
        final result = validateBffUrl('http://acdgbrasil.com.br@evil.tld');
        expect(result, isA<Failure<Uri>>());
        // Either embeds-credentials or host-not-allowed — both are 64.
        // The userinfo check runs BEFORE host check per design.
        expect(
          (result as Failure<Uri>).error,
          isA<BffEmbedsCredentialsError>(),
        );
      },
    );

    test(
      'U20c: http://user@127.0.0.1:8081 (user only, no password) → BffEmbedsCredentialsError',
      () {
        final result = validateBffUrl('http://user@127.0.0.1:8081');
        expect(result, isA<Failure<Uri>>());
        expect(
          (result as Failure<Uri>).error,
          isA<BffEmbedsCredentialsError>(),
        );
      },
    );
  });

  group('validateBffUrl — REJECT malformed (BffMalformedUrlError)', () {
    test('U21: "not a url" → BffMalformedUrlError', () {
      final result = validateBffUrl('not a url');
      expect(result, isA<Failure<Uri>>());
      expect((result as Failure<Uri>).error, isA<BffMalformedUrlError>());
    });

    test('U22: "http://" → BffMalformedUrlError (empty host)', () {
      final result = validateBffUrl('http://');
      expect(result, isA<Failure<Uri>>());
      expect((result as Failure<Uri>).error, isA<BffMalformedUrlError>());
    });

    test('U23: "" (empty) → BffMalformedUrlError', () {
      final result = validateBffUrl('');
      expect(result, isA<Failure<Uri>>());
      expect((result as Failure<Uri>).error, isA<BffMalformedUrlError>());
    });
  });

  group('renderBffAllowlistError — exact templates (D3)', () {
    test('U24: BffHostNotAllowedError template matches §6.1', () {
      final rendered = renderBffAllowlistError(const BffHostNotAllowedError());
      expect(rendered, contains('error:'));
      expect(rendered, contains('--bff URL'));
      expect(rendered, contains('not allowed'));
      expect(rendered, contains('hint:'));
      // Must teach the user the policy (cli-craftsman P6).
      expect(rendered, contains('https'));
      expect(rendered, contains('loopback'));
    });

    test('U25: BffEmbedsCredentialsError template matches §6.2', () {
      final rendered = renderBffAllowlistError(
        const BffEmbedsCredentialsError(),
      );
      expect(rendered, contains('error:'));
      expect(rendered, contains('credentials'));
      expect(rendered, contains('hint:'));
      // The userinfo concept must be explained.
      expect(rendered.toLowerCase(), contains('userinfo'));
    });

    test('U26: BffMalformedUrlError template matches §6.3', () {
      final rendered = renderBffAllowlistError(const BffMalformedUrlError());
      expect(rendered, contains('error:'));
      expect(rendered.toLowerCase(), contains('parsed'));
      expect(rendered, contains('hint:'));
    });

    test('U27 SEC: rendered error does NOT echo the rejected URL', () {
      // SEC: an attacker who tricks a user into one bad invocation could
      // craft variants from echo feedback — never echo. Tested across all
      // three rejection variants for defense in depth.
      const attackerInputs = <String>[
        'http://evil.tld',
        'http://attacker.tld:8080/exfil?token=abc',
        'http://alice:secret@evil.tld',
      ];
      final allErrors = <BffAllowlistError>[
        const BffHostNotAllowedError(),
        const BffEmbedsCredentialsError(),
        const BffMalformedUrlError(),
      ];
      for (final err in allErrors) {
        final rendered = renderBffAllowlistError(err);
        for (final input in attackerInputs) {
          expect(
            rendered,
            isNot(contains(input)),
            reason: 'render of ${err.runtimeType} must NOT echo input "$input"',
          );
          expect(rendered, isNot(contains('evil.tld')));
          expect(rendered, isNot(contains('attacker.tld')));
          expect(rendered, isNot(contains('secret')));
        }
      }
    });
  });
}
