import 'package:logging/logging.dart';
import 'package:shared/shared.dart';
import 'package:social_care_web/social_care_web.dart';

/// Entry point for the Social Care Web BFF server.
///
/// Reads configuration from environment variables, creates the session
/// store, OIDC client, and wires up the full handler chain.
///
/// Note: the [AuthContract], [RegistryContract], [PeopleContract],
/// [AuditContract] and [AssessmentContract] wired below are temporary
/// [FakeAuthBff] / [FakeRegistryBff] / [FakePeopleBff] / [FakeAuditBff] /
/// [FakeAssessmentBff] instances — production-ready HTTP adapters are
/// scheduled for follow-up tickets. The existing [OidcServerClient] /
/// [SessionStore] plumbing is preserved so those follow-ups can swap in
/// without changing this entrypoint's shape.
Future<void> main() async {
  final config = ServerConfig.fromEnvironment();

  // C00 W2 Round 2 (S2) — startup signal on missing CLI client id.
  // Empty `oidcCliClientId` is fail-closed at runtime (every Bearer is
  // rejected with 401), but a silent boot is the wrong default for a
  // production gate: ops would only learn of the misconfiguration via
  // a 401 storm. Emit a warning at startup so the missing env var is
  // visible the moment the server comes up.
  if (config.oidcCliClientId.isEmpty) {
    Logger.root.warning(
      'OIDC_CLI_CLIENT_ID env var is not set. All Bearer auth requests '
      'will be rejected with 401 (fail-closed). Set this var to enable '
      'CLI auth.',
    );
  }

  final sessionStore = SessionStore(ttl: config.sessionTtl);

  // ADR-028: bootstrap discovery-driven. Endpoints (token, authorize,
  // revoke, jwks_uri) sao carregados do `.well-known/openid-configuration`
  // do issuer. Fail-fast se discovery indisponivel — IdP mal configurado
  // deve quebrar o boot, nao virar 401 storm depois.
  final oidcClient = await OidcServerClient.bootstrap(config: config);

  // C00 — Bearer Auth Middleware. JWKS cache compartilhada (single-flight,
  // 10min TTL). Pega `jwks_uri` do discovery (vendor-agnostic).
  final jwksCache = JwksCache(
    client: HttpJwksClient(jwksUri: oidcClient.endpoints.jwksUri),
    ttl: config.jwksCacheTtl,
  );

  final AuthContract authContract = FakeAuthBff();
  final RegistryContract registryContract = FakeRegistryBff();
  final PeopleContract peopleContract = FakePeopleBff();
  final AuditContract auditContract = FakeAuditBff();
  final AssessmentContract assessmentContract = FakeAssessmentBff();
  final CareContract careContract = FakeCareBff();
  final ProtectionContract protectionContract = FakeProtectionBff();
  final LookupContract lookupContract = FakeLookupBff();
  final TeamContract teamContract = FakeTeamBff();

  final appRouter = AppRouter(
    config: config,
    sessionStore: sessionStore,
    oidcClient: oidcClient,
    jwksCache: jwksCache,
    authContract: authContract,
    registryContract: registryContract,
    peopleContract: peopleContract,
    auditContract: auditContract,
    assessmentContract: assessmentContract,
    careContract: careContract,
    protectionContract: protectionContract,
    lookupContract: lookupContract,
    teamContract: teamContract,
  );

  final server = ShelfServer(config: config, appRouter: appRouter);
  await server.start();
}
