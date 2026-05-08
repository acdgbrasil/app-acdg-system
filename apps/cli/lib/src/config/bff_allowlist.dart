/// BFF URL allowlist — single source of truth for `--bff` validation.
///
/// SEC: defense against token exfiltration via attacker-controlled URL
/// (CLI pentest F1, 2026-05-04). Every Bearer-injecting Dio client must
/// be constructed with a base URL that has passed [validateBffUrl].
///
/// Policy table (first match wins):
///   1. `http://127.0.0.1[:port][/]`    → ALLOW (loopback dev)
///   2. `http://localhost[:port][/]`    → ALLOW (loopback dev)
///   3. `http://[::1][:port][/]`        → ALLOW (IPv6 loopback dev)
///   4. `http://` (any IPv4 in 127/8)   → ALLOW (loopback dev)
///   5. `https://acdgbrasil.com.br`     → ALLOW (production apex)
///   6. `https://*.acdgbrasil.com.br`   → ALLOW (any subdomain depth)
///   7. `https://localhost / 127.0.0.1` → ALLOW (TLS-on-loopback dev)
///   *. anything else                   → REJECT ([BffHostNotAllowedError])
///
/// Always rejected (regardless of host match):
///   - userinfo segment                 → [BffEmbedsCredentialsError]
///   - non-http/https scheme            → [BffHostNotAllowedError]
///   - empty host                       → [BffMalformedUrlError]
///   - path other than '' or '/'        → [BffHostNotAllowedError]
///   - any query string or fragment     → [BffHostNotAllowedError]
///   - `Uri.parse` failure              → [BffMalformedUrlError]
library;

import 'package:core_contracts/core_contracts.dart';

import 'oidc_config.dart';

/// Sealed error union — discriminated on the rejection reason so callers
/// pick the matching stderr template via [renderBffAllowlistError].
sealed class BffAllowlistError {
  const BffAllowlistError();
}

/// `Uri.parse` failed, host is empty, or scheme missing.
final class BffMalformedUrlError extends BffAllowlistError {
  const BffMalformedUrlError();
}

/// URL embeds a userinfo segment (`user:pass@host`). Always rejected —
/// classic URL-confusion vector and credential-leakage path.
final class BffEmbedsCredentialsError extends BffAllowlistError {
  const BffEmbedsCredentialsError();
}

/// Host (or scheme/path/query/fragment) not on the allowlist.
final class BffHostNotAllowedError extends BffAllowlistError {
  const BffHostNotAllowedError();
}

/// Validates [raw] against the BFF allowlist. Pure — never throws, no I/O.
/// Returns `Success<Uri>` on accept; `Failure<Uri>` carrying a
/// [BffAllowlistError] otherwise.
Result<Uri> validateBffUrl(String raw) {
  // SEC: Uri.parse is the only parser; never regex on the raw string.
  final Uri parsed;
  try {
    parsed = Uri.parse(raw);
  } on FormatException {
    return const Failure(BffMalformedUrlError());
  }
  // SEC: empty/missing scheme or host → fail-fast (cannot reason about it).
  if (!parsed.hasScheme || parsed.host.isEmpty) {
    return const Failure(BffMalformedUrlError());
  }
  // SEC: userinfo (user:pass@) is never accepted — credential leakage and
  // URL-confusion vector (`http://acdgbrasil.com.br@evil.tld`). Checked
  // BEFORE host policy so the user gets the right hint.
  if (parsed.userInfo.isNotEmpty) {
    return const Failure(BffEmbedsCredentialsError());
  }
  // SEC: base URL invariants — empty path or "/", no query, no fragment.
  // Per design: dio appends per-request paths to baseUrl; the base must end
  // at the host.
  final pathOk = parsed.path.isEmpty || parsed.path == '/';
  if (!pathOk || parsed.hasQuery || parsed.fragment.isNotEmpty) {
    return const Failure(BffHostNotAllowedError());
  }
  // SEC: DNS is case-insensitive. Lowercase before comparing.
  final scheme = parsed.scheme.toLowerCase();
  final host = parsed.host.toLowerCase();
  final isLoopbackHost =
      host == '127.0.0.1' ||
      host == 'localhost' ||
      host == '::1' ||
      _isInLoopbackBlock(host);
  // SEC: only http+loopback, https+loopback, and https+acdg are accepted.
  // Every other (scheme, host) tuple — including non-http schemes
  // (file/ssh/javascript) — falls through to the reject path.
  if (scheme == 'http' && isLoopbackHost) {
    return Success(parsed);
  }
  if (scheme == 'https' && isLoopbackHost) {
    return Success(parsed);
  }
  if (scheme == 'https' && _matchesAcdgApex(host)) {
    return Success(parsed);
  }
  return const Failure(BffHostNotAllowedError());
}

/// True iff [host] is a literal IPv4 in 127.0.0.0/8 (loopback per RFC 1122).
bool _isInLoopbackBlock(String host) {
  final parts = host.split('.');
  if (parts.length != 4) return false;
  final octets = parts.map(int.tryParse).toList(growable: false);
  if (octets.any((o) => o == null || o < 0 || o > 255)) return false;
  return octets[0] == 127;
}

/// True iff [host] equals the apex or is a (multi-label) subdomain of it.
/// SEC: suffix anchored to "." — `evil-acdgbrasil.com.br` MUST NOT pass.
bool _matchesAcdgApex(String host) {
  const apex = OidcConfig.bffApexDomain;
  if (host == apex) return true;
  return host.endsWith('.$apex');
}

/// Exact stderr templates per `cli-craftsman` P6 (errors that teach).
/// SEC: NEVER echoes the rejected URL — an attacker-crafted variant could
/// be inferred from echo feedback (D3 of the B3 design).
String renderBffAllowlistError(BffAllowlistError e) => switch (e) {
  BffMalformedUrlError() =>
    'error: --bff URL could not be parsed.\n'
        'hint:  pass a full URL like https://api.acdgbrasil.com.br or\n'
        '       http://localhost:8081.',
  BffEmbedsCredentialsError() =>
    'error: --bff URL must not embed credentials.\n'
        'hint:  remove the userinfo segment ("user:pass@") from the URL.',
  BffHostNotAllowedError() =>
    'error: --bff URL is not allowed.\n'
        'hint:  must be https for remote (e.g. https://api.acdgbrasil.com.br)\n'
        '       or http only on loopback (127.0.0.1, localhost, [::1]).',
};
