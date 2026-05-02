import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart' as djw;
import 'package:pointycastle/asymmetric/api.dart' as pc;

import 'jwks_client.dart';

/// Opaque RSA public key returned by [JwksCache.getKey].
///
/// Wraps a `dart_jsonwebtoken` [djw.RSAPublicKey] so callers can pass
/// it straight to [djw.JWTAlgorithm.RS256.verify] without re-parsing.
///
/// Stored only in-memory after the JWKS document is fetched and parsed.
/// The wire-form `kid` is the only untrusted input we ever observe; it
/// never leaves [JwksCache] except as a [Map] key (constraint #4 — no
/// path/file/SQL interpolation possible).
class RsaKey {
  RsaKey({required this.kid, required this.publicKey});

  final String kid;
  final djw.RSAPublicKey publicKey;
}

/// In-memory JWKS cache with:
/// - 10 minute TTL (configurable),
/// - single-flight semantics (concurrent cold-start hits coalesce into
///   exactly one upstream fetch),
/// - refresh-on-miss (lookup of an unknown kid triggers exactly one
///   extra refetch, then gives up — fail-closed),
/// - explicit [refresh] for refresh-on-signature-mismatch (CVE-2018-0114
///   defence — triggered by the middleware after a verified-but-failing
///   signature).
///
/// Fail-closed: timeouts, transport errors, or malformed JSON cause
/// [getKey] to return `null` (the middleware then maps to a 401 with a
/// generic body, no oracle leak).
class JwksCache {
  JwksCache({
    required JwksClient client,
    required Duration ttl,
    DateTime Function()? clock,
    Duration fetchTimeout = const Duration(seconds: 5),
  }) : _client = client,
       _ttl = ttl,
       _clock = clock ?? _defaultClock,
       _fetchTimeout = fetchTimeout;

  static DateTime _defaultClock() => DateTime.now().toUtc();

  final JwksClient _client;
  final Duration _ttl;
  final DateTime Function() _clock;
  final Duration _fetchTimeout;

  /// Map of kid → public key. `kid` is opaque; lookups are pure equality
  /// against keys we already loaded from upstream JWKS — there is no
  /// codepath where the [kid] string reaches a filesystem, URL, or SQL
  /// query (constraint #4).
  Map<String, RsaKey> _keys = const <String, RsaKey>{};
  DateTime? _loadedAt;

  /// Single-flight latch: when a fetch is in flight, every concurrent
  /// caller awaits the same future instead of dispatching its own.
  Completer<void>? _inFlight;

  bool get _isStale {
    final loadedAt = _loadedAt;
    if (loadedAt == null) return true;
    return _clock().isAfter(loadedAt.add(_ttl));
  }

  /// Returns the [RsaKey] for [kid], or null if it cannot be found
  /// even after one refresh-on-miss attempt.
  ///
  /// Refetches when:
  /// - the cache is empty or stale (TTL expired), OR
  /// - the cache is fresh but [kid] is not present (refresh-on-miss).
  ///
  /// Never throws. Fail-closed on every error path.
  Future<RsaKey?> getKey(String kid) async {
    // 1. TTL-driven refresh: if cache is stale, refetch first.
    if (_isStale) {
      await _fetchSingleFlight();
      // After a TTL-driven refetch we do NOT re-trigger refresh-on-miss
      // — the data we just loaded is authoritative for this lookup.
      return _keys[kid];
    }

    // 2. Cache hit on a fresh cache — return it.
    final cached = _keys[kid];
    if (cached != null) return cached;

    // 3. Refresh-on-miss: kid is unknown to us; fetch once and look again.
    await _fetchSingleFlight();
    return _keys[kid];
  }

  /// Forces a refetch of the JWKS (refresh-on-signature-mismatch path —
  /// triggered by the middleware after a known kid produces a failing
  /// signature). Single-flight protected so repeated calls during the
  /// same in-flight fetch coalesce.
  ///
  /// Never throws. Fail-closed.
  Future<void> refresh() => _fetchSingleFlight();

  Future<void> _fetchSingleFlight() {
    final existing = _inFlight;
    if (existing != null) return existing.future;

    final completer = Completer<void>();
    _inFlight = completer;

    // ignore: discarded_futures
    _doFetch()
        .then((_) {
          _inFlight = null;
          completer.complete();
        })
        .catchError((Object _) {
          // Fail-closed: swallow upstream errors so callers can pivot to 401.
          _inFlight = null;
          completer.complete();
        });

    return completer.future;
  }

  Future<void> _doFetch() async {
    try {
      // Constraint: JWKS fetch is bounded by [_fetchTimeout] (default 5s).
      // The test suite (Test #48) injects a 30s upstream delay and asserts
      // the middleware gives up at ~5s — without this timeout the fake
      // clients would hang the whole pipeline.
      final raw = await _client.fetch().timeout(_fetchTimeout);
      final parsed = _parseJwks(raw);
      _keys = parsed;
      _loadedAt = _clock();
    } on Object {
      // Fail-closed: leave previous cache state intact (or empty) and
      // surface "no key" to callers. Errors must not propagate so the
      // middleware can map to a generic 401 with no oracle leak.
      // We do NOT update `_loadedAt` so a transient failure becomes
      // immediately retryable on the next `getKey`/`refresh` call.
    }
  }

  /// Parses a JWKS JSON document into a kid → key map.
  ///
  /// Any malformed entry is skipped; unparseable JSON yields an empty
  /// result. The middleware turns "no key" into a 401.
  Map<String, RsaKey> _parseJwks(String raw) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on Object {
      return const <String, RsaKey>{};
    }
    if (decoded is! Map<String, dynamic>) return const <String, RsaKey>{};

    final keys = decoded['keys'];
    if (keys is! List) return const <String, RsaKey>{};

    final result = <String, RsaKey>{};
    for (final entry in keys) {
      if (entry is! Map<String, dynamic>) continue;
      final kid = entry['kid'];
      final kty = entry['kty'];
      final n = entry['n'];
      final e = entry['e'];
      // Allowlist: only RSA keys with kid + n + e.
      if (kid is! String || kty != 'RSA' || n is! String || e is! String) {
        continue;
      }
      final publicKey = _buildRsaPublicKey(n, e);
      if (publicKey == null) continue;
      result[kid] = RsaKey(kid: kid, publicKey: publicKey);
    }
    return result;
  }

  djw.RSAPublicKey? _buildRsaPublicKey(String nB64Url, String eB64Url) {
    try {
      final modulus = _bytesToBigInt(_decodeBase64Url(nB64Url));
      final exponent = _bytesToBigInt(_decodeBase64Url(eB64Url));
      return djw.RSAPublicKey.raw(pc.RSAPublicKey(modulus, exponent));
    } on Object {
      return null;
    }
  }

  Uint8List _decodeBase64Url(String input) {
    final pad = (4 - input.length % 4) % 4;
    return base64Url.decode(input + ('=' * pad));
  }

  BigInt _bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b);
    }
    return result;
  }
}
