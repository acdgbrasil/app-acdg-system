/// PKCE pair (RFC 7636) — verifier + S256 challenge.
///
/// The CLI uses PKCE-only (no `client_secret`). The pair is generated
/// once per `acdg auth login` invocation:
///   * `verifier` = base64url-no-pad of 64 cryptographically random bytes
///     (86 chars — within the 43..128 range mandated by RFC 7636 §4.1).
///   * `challenge` = base64url-no-pad of `SHA-256(verifier ASCII bytes)`
///     (always 43 chars — 256-bit digest → 32 bytes → 43 b64url chars).
///   * `method` is hard-coded `S256`. Zitadel does not advertise `plain`
///     in `code_challenge_methods_supported`, so falling back is unsafe.
library;

import 'dart:convert';
import 'dart:math';

import 'package:core_contracts/core_contracts.dart';
import 'package:crypto/crypto.dart';

/// Immutable verifier/challenge pair generated for one PKCE handshake.
final class PkcePair with Equatable {
  /// Manual construction is intended for tests + the [generate] factory.
  /// Real callers use [PkcePair.generate].
  const PkcePair({required this.verifier, required this.challenge});

  /// Base64url-no-pad verifier — sent to the token endpoint as
  /// `code_verifier` in the authorization-code exchange.
  final String verifier;

  /// Base64url-no-pad SHA-256 challenge — sent to the authorize endpoint
  /// as `code_challenge`.
  final String challenge;

  /// PKCE challenge method advertised to the authorize endpoint.
  ///
  /// Always `S256`. We never fall back to `plain` — Zitadel does not
  /// support it and silently failing back would defeat the entire point
  /// of PKCE.
  static const String method = 'S256';

  /// Generates a fresh pair from `Random.secure()` over 64 random bytes.
  factory PkcePair.generate() {
    final rng = Random.secure();
    final verifierBytes = List<int>.generate(64, (_) => rng.nextInt(256));
    final verifier = _base64UrlNoPad(verifierBytes);
    final digest = sha256.convert(utf8.encode(verifier)).bytes;
    final challenge = _base64UrlNoPad(digest);
    return PkcePair(verifier: verifier, challenge: challenge);
  }

  static String _base64UrlNoPad(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  @override
  List<Object?> get props => [verifier, challenge];
}
