# ADR-028 — OIDC discovery document como fonte de verdade

**Status:** Proposed
**Date:** 2026-05-13
**Deciders:** Authentik Evaluation Spike (`acdg/auth-spike/REPORT.md`)
**Related:** [ADR-012](ADR-012-oidc-pkce.md), [ADR-027](ADR-027-authentik-replaces-zitadel.md)

---

## Contexto

A implementacao atual do BFF Dart (`acdg/frontend/apps/social_care_bff/web/lib/src/`) calcula URLs de endpoints OIDC manualmente a partir do `OIDC_ISSUER`, hardcoded com paths especificos do Zitadel:

```dart
// server_config.dart:172-175 (estado atual)
Uri get discoveryDocumentUri =>
    Uri.parse('$oidcIssuer/.well-known/openid-configuration');
Uri get tokenEndpoint => Uri.parse('$oidcIssuer/oauth/v2/token');
Uri get jwksUri => Uri.parse('$oidcIssuer/oauth/v2/keys');

// oidc_server_client.dart:58-66 (estado atual)
Uri get _authorizationEndpoint =>
    Uri.parse('${_config.oidcIssuer}/oauth/v2/authorize');
Uri get _tokenEndpoint => Uri.parse('${_config.oidcIssuer}/oauth/v2/token');
Uri get _revocationEndpoint =>
    Uri.parse('${_config.oidcIssuer}/oauth/v2/revoke');
```

Os paths `/oauth/v2/...` sao convencao Zitadel. **Em Authentik os mesmos endpoints ficam em**:

| Endpoint           | Zitadel                          | Authentik                                                |
|--------------------|-----------------------------------|------------------------------------------------------------|
| Discovery          | `/.well-known/openid-configuration` | `/application/o/<slug>/.well-known/openid-configuration` |
| Authorize          | `/oauth/v2/authorize`            | `/application/o/authorize/`                                |
| Token              | `/oauth/v2/token`                | `/application/o/token/`                                    |
| JWKS               | `/oauth/v2/keys`                 | `/application/o/<slug>/jwks/`                              |
| Revoke             | `/oauth/v2/revoke`               | `/application/o/revoke/`                                   |
| End session        | `/oidc/v1/end_session`           | `/application/o/<slug>/end-session/`                       |

Manter paths hardcoded significaria:

- **Acoplamento de codigo a IdP especifico** — trocar IdP no futuro exige PR de codigo, nao so env.
- **Boilerplate de divergencia** — adicionar `if (vendor == 'authentik') ...` em multiplos arquivos.
- **Risco de drift silencioso** — Authentik pode mudar paths em release (ja aconteceu com `/-/version/` que virou `/api/v3/admin/version/`).

A **OpenID Connect Discovery 1.0** (RFC 5785 + OIDC Discovery) padroniza um documento JSON publicado em `<issuer>/.well-known/openid-configuration` listando todos os endpoints da instancia. Lendo esse documento no boot, o BFF passa a ser agnostico de IdP.

Validado no spike (`acdg/auth-spike/notes/05-bff-dart-validation.md`): Authentik publica o discovery completo com 26 campos cobrindo todos endpoints + capabilities + algoritmos suportados.

## Decisao

**Todos os consumidores de OIDC do ecossistema ACDG DEVEM derivar endpoints exclusivamente do discovery document publicado pelo issuer.**

Regras concretas:

1. **`OIDC_ISSUER` e a unica variavel de ambiente** referente ao IdP nos consumidores. Nenhuma env do tipo `OIDC_TOKEN_ENDPOINT` ou `OIDC_JWKS_URL` em `.env` ou Helm values.
2. **Fetch do discovery e no boot** — BFF Dart e `social-care` Swift carregam o documento uma unica vez na partida do servico. Falha de fetch e falha fatal de boot.
3. **Cache em memoria por TTL configuravel** (default 1h). Refresh background a cada TTL/2 para tolerar rotacao de chaves do IdP.
4. **`OIDC_ISSUER` deve incluir o path do application** quando o IdP exigir (ex: Authentik usa `http://localhost:9000/application/o/social-care/`). Issuer e normalizado para sempre terminar com `/`.
5. **Scopes solicitados sao externalizados em env** — `OIDC_SCOPES` (default: `openid profile email offline_access`). Scopes Zitadel-especificos (`urn:zitadel:iam:org:project:roles`) removidos.

### Implementacao de referencia (Dart)

```dart
// server_config.dart (proposta)
class ServerConfig {
  factory ServerConfig.fromEnvironment([Map<String, String>? env]) {
    final e = env ?? Platform.environment;
    String issuer = required('OIDC_ISSUER');
    if (!issuer.endsWith('/')) issuer = '$issuer/';   // normalizacao
    return ServerConfig(
      oidcIssuer: issuer,
      oidcScopes: e['OIDC_SCOPES'] ?? 'openid profile email offline_access',
      // ...
    );
  }

  Uri get discoveryDocumentUri =>
      Uri.parse('${oidcIssuer}.well-known/openid-configuration');
}

// oidc_server_client.dart (proposta)
class OidcServerClient {
  OidcServerClient._({required this.config, required this.discovery});

  final ServerConfig config;
  final Map<String, dynamic> discovery;

  static Future<OidcServerClient> bootstrap(ServerConfig config) async {
    final res = await http.get(config.discoveryDocumentUri);
    if (res.statusCode != 200) {
      throw StateError('OIDC discovery failed: ${res.statusCode}');
    }
    return OidcServerClient._(
      config: config,
      discovery: jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Uri get _authorizationEndpoint => Uri.parse(discovery['authorization_endpoint']);
  Uri get _tokenEndpoint          => Uri.parse(discovery['token_endpoint']);
  Uri get _revocationEndpoint     => Uri.parse(discovery['revocation_endpoint']);
  Uri get _endSessionEndpoint     => Uri.parse(discovery['end_session_endpoint']);
}
```

### Implementacao de referencia (Swift)

```swift
// configure.swift (proposta)
let discoveryURL = URL(string: "\(issuer).well-known/openid-configuration")!
let discovery = try await loadDiscovery(from: discoveryURL)
let jwksURL = URL(string: discovery.jwksUri)!
app.jwt.signers.use(jwks: try await fetchJWKS(from: jwksURL))
```

## Consequencias

### Positivas

- **Portabilidade total entre IdPs** — trocar Authentik por Keycloak (hipotetico) so muda `OIDC_ISSUER`.
- **Auto-recuperacao de mudancas de path** — se Authentik move `/application/o/token/` para `/oidc/v3/token/` em release maior, o consumer pega automaticamente.
- **Reducao de hardcodes em ~14 linhas** (BFF Dart) + ~6 linhas (Swift `configure.swift`).
- **Reuso do mesmo cache TTL** para refresh de JWKS (chaves de assinatura) e endpoints.

### Negativas

- **+1 chamada HTTP no boot** de cada servico (~50-200ms). Aceitavel em troca da portabilidade.
- **Falha de boot se IdP estiver indisponivel** — comportamento desejado (fail-fast > fail-silent). Health check do consumer reflete isso.
- **Discovery e cacheado em memoria** — instancia precisa rebootar para pegar mudanca de path imediatamente. Mitigacao: refresh background a cada TTL/2.

## Plano de implementacao

Detalhado em `acdg/auth-spike/notes/05-bff-dart-validation.md` (BFF Dart) e `acdg/auth-spike/notes/01-oidc-mapping.md` (mapping completo de endpoints).

Arquivos afetados:

- `acdg/frontend/apps/social_care_bff/web/lib/src/auth/oidc_server_client.dart`
- `acdg/frontend/apps/social_care_bff/web/lib/src/auth/jwks_client.dart`
- `acdg/frontend/apps/social_care_bff/web/lib/src/config/server_config.dart`
- `acdg/social-care/Sources/social-care-s/IO/HTTP/Bootstrap/configure.swift`
- Tests em `Tests/IO/` (fixtures de discovery document)

Estimativa: ~3.25 dias (incluso na Sprint 1-2 do plano em [ADR-027](ADR-027-authentik-replaces-zitadel.md)).
