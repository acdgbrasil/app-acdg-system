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
  final sessionStore = SessionStore(ttl: config.sessionTtl);
  final oidcClient = OidcServerClient(config: config);

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
