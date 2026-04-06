import 'package:shared/src/contract/social_care_contract.dart';
import 'package:social_care_web/social_care_web.dart';

/// Entry point for the Social Care Web BFF server.
///
/// Reads configuration from environment variables, creates the
/// session store, OIDC client, and wires up the full handler chain.
Future<void> main() async {
  final config = ServerConfig.fromEnvironment();
  final sessionStore = SessionStore(ttl: config.sessionTtl);
  final oidcClient = OidcServerClient(config: config);

  SocialCareContract contractFactory(Session session) {
    return SocialCareApiClient(
      baseUrl: config.apiBaseUrl,
      actorId: session.userId,
      accessToken: session.accessToken,
    );
  }

  final appRouter = AppRouter(
    config: config,
    sessionStore: sessionStore,
    oidcClient: oidcClient,
    contractFactory: contractFactory,
  );

  final server = ShelfServer(config: config, appRouter: appRouter);
  await server.start();
}
