/// Public OIDC config — committed, embedded in the AOT binary.
///
/// These values are public by design (they appear in browser authorize URLs,
/// in audit logs, and in the compiled `acdg` executable). Distributing them
/// as committed constants — rather than runtime `.env` — keeps the binary
/// self-contained and matches the convention used by `gh`, `gcloud`, and
/// `claude-code`.
///
/// Source-of-truth: `handbook/spikes/OICD_AUTH_SPIKE.md` v1.0 (2026-05-04).
/// Native App "ACDG CLI" provisioned + validated end-to-end on Zitadel
/// self-hosted (`https://auth.acdgbrasil.com.br`) on 2026-05-04.
///
/// The only runtime override is [bffBaseUrl], read from
/// `--dart-define=ACDG_BFF_URL=<...>` so dev/staging/prod swap without a
/// rebuild.
library;

/// Configuration constants for the CLI's OIDC client.
abstract final class OidcConfig {
  const OidcConfig._();

  // --- Zitadel identity ---------------------------------------------------

  /// Zitadel issuer (no trailing slash — exact match validated at boot).
  static const String issuer = 'https://auth.acdgbrasil.com.br';

  /// Native App "ACDG CLI" client_id (PKCE-only, no client_secret).
  static const String clientId = '371410163745226755';

  /// Application ID on Zitadel (informational; not part of OIDC requests).
  static const String appId = '371410163745161219';

  /// Project ID — must appear in the JWT `aud` claim (validated by the BFF
  /// using `aud.contains(projectId)`, never `==`).
  static const String projectId = '363109883022671995';

  /// Organization ID — present inside the project-roles claim object.
  static const String orgId = '363109592139300987';

  // --- OIDC scopes --------------------------------------------------------

  /// Scopes requested at `/authorize`.
  ///
  /// * `openid` enables OIDC + id_token issuance.
  /// * `profile` + `email` populate id_token / userinfo (NOT access_token).
  /// * `offline_access` mandatory for refresh_token issuance.
  /// * The `urn:zitadel:iam:org:project:id:<projectId>:aud` "magic" scope
  ///   injects [projectId] into the `aud` array of every emitted JWT.
  static const String scopes =
      'openid profile email offline_access '
      'urn:zitadel:iam:org:project:id:$projectId:aud';

  // --- Loopback redirect (RFC 8252 §7.3) ----------------------------------

  /// Template for the loopback redirect URI. The CLI binds an ephemeral
  /// port at runtime and substitutes `{port}`.
  ///
  /// Zitadel accepts arbitrary ports for `127.0.0.1` and `[::1]` per
  /// RFC 8252 §7.3, even though the registered URIs omit the port.
  static const String redirectUriTemplate = 'http://127.0.0.1:{port}/callback';

  /// Resolves [redirectUriTemplate] for a concrete [port].
  static String redirectUriFor(int port) =>
      redirectUriTemplate.replaceAll('{port}', port.toString());

  // --- Authorize hardening ------------------------------------------------

  /// Always send `prompt=login` to defeat residual Zitadel sessions that
  /// would otherwise trigger the Next.js RSC prefetch race (validated in
  /// the spike Run 1 vs Run 2 comparison).
  static const String authorizePrompt = 'login';

  // --- Roles claim names --------------------------------------------------

  /// Generic Zitadel project-roles claim. Use this as the primary read
  /// target — Zitadel emits the same payload under both this key and
  /// [rolesClaimProjectSpecific], and the generic key survives if the
  /// project ID changes.
  static const String rolesClaim = 'urn:zitadel:iam:org:project:roles';

  /// Project-specific roles claim — same payload, project-prefixed key.
  /// Kept as a fallback in case Zitadel ever stops emitting the generic
  /// key for non-default projects.
  static const String rolesClaimProjectSpecific =
      'urn:zitadel:iam:org:project:$projectId:roles';

  // --- Validation knobs ---------------------------------------------------

  /// Tolerance window for `exp`/`nbf` validation. Mirrors the spike's
  /// recommended 30s.
  static const Duration clockSkew = Duration(seconds: 30);

  /// Loopback listener hard timeout before giving up on the user.
  static const Duration loopbackTimeout = Duration(minutes: 5);

  /// TTL for the `.well-known/openid-configuration` cache. Discovery
  /// itself is idempotent; this is just to avoid hammering Zitadel on
  /// every CLI invocation.
  static const Duration discoveryCacheTtl = Duration(hours: 24);

  // --- BFF endpoint (the only runtime override) ---------------------------

  /// Base URL for the BFF Web HTTP server. Dev defaults to localhost; CI
  /// and prod override via `--dart-define=ACDG_BFF_URL=<...>`.
  static const String bffBaseUrl = String.fromEnvironment(
    'ACDG_BFF_URL',
    defaultValue: 'http://localhost:8081',
  );

  /// Apex domain for the production BFF allowlist (consumed by
  /// `bff_allowlist.dart`). Single source of truth — host suffix match
  /// anchors against this.
  static const String bffApexDomain = 'acdgbrasil.com.br';
}
