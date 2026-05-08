/// Canonical names and attributes for the BFF session cookie.
///
/// SEC: Single source of truth for the cookie name. Reader (sessionMiddleware)
/// and writer (AuthHandler) both import [sessionCookieName]. Drift between the
/// two — observed in Pentest §B3 (writer used `__Host-session=`, reader scanned
/// for `__session=`) — is now a compile-time impossibility: each side names
/// the same symbol.
///
/// SEC: The `__Host-` prefix is browser-enforced — the browser rejects the
/// cookie unless `Path=/`, `Secure`, and no `Domain` attribute are set. Pinning
/// to those three properties via [buildSessionSetCookie] avoids accidental
/// scope-widening via misconfigured operator overrides.
library;

/// Name of the BFF session cookie (Host-prefixed; HttpOnly; SameSite=Strict).
///
/// SEC: Both [sessionMiddleware] (reader) and [AuthHandler] (writer) import
/// this constant. Do NOT inline `'__Host-session'` anywhere else in `lib/`.
/// A regression test (`test/security/oidc_cookie_path_test.dart` — T7) greps
/// `lib/src/` for stray literals and fails the build if any are found.
const String sessionCookieName = '__Host-session';

/// Default cookie lifetime, in seconds.
///
/// SEC: aligns the browser-side cookie expiry with the [SessionStore] TTL
/// default (1h). If the operator overrides `SessionStore.ttl`, the caller
/// MUST pass that override into [buildSessionSetCookie] so the browser does
/// not retain a cookie that points at a swept session.
const int sessionCookieMaxAgeSeconds = 3600;

/// Builds a `Set-Cookie` value that establishes a new session.
///
/// SEC: emits the canonical attribute set
///   `Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=<ttl>`.
/// The `__Host-` prefix on [sessionCookieName] is enforced by the browser
/// (Path=/, Secure, no Domain). [maxAgeSeconds] aligns the browser-side
/// expiry with the server-side `SessionStore.ttl`.
String buildSessionSetCookie(
  String sessionId, {
  int maxAgeSeconds = sessionCookieMaxAgeSeconds,
}) {
  // SEC: Max-Age MUST be a non-negative integer; defensive clamp avoids a
  // negative value being interpreted as a session-cookie (no Max-Age).
  final maxAge = maxAgeSeconds < 0 ? 0 : maxAgeSeconds;
  return '$sessionCookieName=$sessionId; '
      'Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=$maxAge';
}

/// Builds a `Set-Cookie` value that clears the session cookie client-side.
///
/// SEC: same attributes as the establish variant, with `Max-Age=0` — the
/// browser MUST overwrite the existing cookie and immediately discard it.
/// Using identical attributes (Path, HttpOnly, Secure, SameSite) is required
/// for the browser to recognize this as a write to the same cookie slot.
String buildClearSessionSetCookie() {
  return '$sessionCookieName=; '
      'Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=0';
}
