# Plataforma ACDG — Setup OIDC para CLI Dart + Integração BFF

> **Status:** ✅ Setup do Zitadel pronto para implementação
> **Versão do documento:** 1.0 (final)
> **Data:** 2026-05-04
> **Autor:** Tech Lead (Gabriel Aderaldo) com auditoria automatizada
> **Audiência primária:** Dev do BFF Vapor (Swift), Dev do CLI Dart, Tech Lead
> **Validade:** Até mudanças no Zitadel ou nos scopes/audience exigidos pelo BFF

---

## Índice

1. [TL;DR](#1-tldr)
2. [Setup do Zitadel — configuração canônica](#2-setup-do-zitadel--configuração-canônica)
3. [Glossário de claims e endpoints](#3-glossário-de-claims-e-endpoints)
4. [Para o dev do BFF Vapor (Swift)](#4-para-o-dev-do-bff-vapor-swift)
5. [Para o dev do CLI Dart](#5-para-o-dev-do-cli-dart)
6. [Contrato compartilhado CLI ↔ BFF](#6-contrato-compartilhado-cli--bff)
7. [Casos de teste obrigatórios](#7-casos-de-teste-obrigatórios)
8. [Pendências conhecidas (não-bloqueantes)](#8-pendências-conhecidas-não-bloqueantes)
9. [Apêndices](#9-apêndices)

---

## 1. TL;DR

Foi provisionado um Native App PKCE no Zitadel self-hosted (`https://auth.acdgbrasil.com.br`) chamado **ACDG CLI**, dedicado ao novo CLI Dart. Está no mesmo project do BFF Web Confidential já em produção, herda automaticamente as 13 roles e o audience do project, e **não interfere** em nada do BFF Web atual.

Foram executadas duas rodadas de validação end-to-end. A primeira detectou três bugs aparentemente críticos (PKCE não enforced, sem refresh_token, nonce ausente) que se revelaram **falsos positivos** causados por um listener naive capturando um `code` fantasma do prefetch RSC do Next.js da UI de login. A segunda rodada, com listener defensivo + janela anônima + `prompt=login`, confirmou que tudo funciona como esperado.

**Próximos passos imediatos:**

- Dev BFF Vapor: implementar validação de JWT contra JWKS, com cache, e middleware de auth Bearer. Detalhes na [Seção 4](#4-para-o-dev-do-bff-vapor-swift).
- Dev CLI Dart: bootstrap do projeto Dart com módulos OIDC, listener loopback defensivo, Device Code Flow paralelo, e secure storage por SO. Detalhes na [Seção 5](#5-para-o-dev-do-cli-dart).
- Tech Lead: revalidar o setup com user secundário (sem `superadmin`) antes do release pra garantir RBAC granular.

**O que NÃO mudou no Zitadel:** o BFF Web Confidential, a API app de introspecção, as roles e o audience do project permanecem intactos. Toda a configuração nova foi adicionada num app separado.

---

## 2. Setup do Zitadel — configuração canônica

### 2.1 Identidade do app Native

| Campo | Valor |
|---|---|
| Nome | `ACDG CLI` |
| Tipo | Native |
| Application ID | `371410163745161219` |
| **Client ID** | `371410163745226755` |
| Client Secret | (não emitido — PKCE-only) |
| Status | Active |
| Criado em | 2026-05-04 02:48 BRT |

### 2.2 OIDC Settings

| Campo | Valor |
|---|---|
| Authentication Method | **None** (PKCE-only, sem secret) |
| Grant Types | `authorization_code` + `refresh_token` |
| Response Types | `code` |
| PKCE method | **S256** (obrigatório, sem fallback `plain`) |
| Redirect URIs | `http://127.0.0.1/callback`, `http://[::1]/callback` |
| Post Logout URIs | `http://127.0.0.1/logout` |
| Development Mode | OFF (loopback não precisa) |
| Use new Login UI | OFF |
| Back-Channel Logout URI | (vazio) |

### 2.3 Token Settings

| Campo | Valor |
|---|---|
| Auth Token Type | **JWT** (não opaque) |
| Add user roles to access token | ON |
| User roles inside ID Token | ON |
| Include user's profile info in ID Token | ON |
| ClockSkew | `0s` |

### 2.4 Project (mesmo do BFF Web)

| Campo | Valor |
|---|---|
| Nome | ACDG Platform |
| **Project ID** | `363109883022671995` |
| Org ID | `363109592139300987` |
| Org Domain | `acdg.auth.acdgbrasil.com.br` |
| Return user roles during authentication | **ON** (já estava — mantido) |
| Only authorized users can authenticate | OFF (mantido — não bloqueia users sem roles) |
| Restrict to granted orgs | OFF (mantido) |

### 2.5 Lifetimes (definidos no instance, não no app)

| Token | Lifetime |
|---|---|
| Access token | 12 horas (43200 s) |
| ID token | 12 horas |
| Refresh token (idle / sliding) | conforme default da instância |
| Refresh token (absolute) | conforme default da instância |
| Refresh rotation | **ENFORCED** — token antigo invalidado após uso |

> ⚠️ **Não modificar lifetimes na default settings da instância** — afeta TODOS os apps, incluindo o BFF Web em produção.

---

## 3. Glossário de claims e endpoints

### 3.1 Endpoints OIDC

Todos descobertos via `GET /.well-known/openid-configuration`. Apesar dos valores serem estáveis, **CLI e BFF devem fazer discovery dinâmico no boot** e cachear.

| Função | URL |
|---|---|
| Issuer | `https://auth.acdgbrasil.com.br` |
| Discovery | `https://auth.acdgbrasil.com.br/.well-known/openid-configuration` |
| Authorize | `https://auth.acdgbrasil.com.br/oauth/v2/authorize` |
| Token | `https://auth.acdgbrasil.com.br/oauth/v2/token` |
| JWKS | `https://auth.acdgbrasil.com.br/oauth/v2/keys` |
| UserInfo | `https://auth.acdgbrasil.com.br/oidc/v1/userinfo` |
| End Session | `https://auth.acdgbrasil.com.br/oidc/v1/end_session` |
| Revocation | `https://auth.acdgbrasil.com.br/oauth/v2/revoke` |
| Introspection | `https://auth.acdgbrasil.com.br/oauth/v2/introspect` |
| Device Authorization | `https://auth.acdgbrasil.com.br/oauth/v2/device_authorization` |

### 3.2 Capabilities relevantes

```
grant_types_supported:
  authorization_code, refresh_token, client_credentials, implicit,
  urn:ietf:params:oauth:grant-type:jwt-bearer,
  urn:ietf:params:oauth:grant-type:device_code

code_challenge_methods_supported:  S256          # sem 'plain'
token_endpoint_auth_methods_supported:  none, client_secret_basic, client_secret_post, private_key_jwt
id_token_signing_alg_values_supported:  RS256, RS384, RS512, ES256, ES384, ES512, EdDSA
subject_types_supported:  public
response_types_supported:  code, id_token, "id_token token"
response_modes_supported:  query, fragment, form_post
scopes_supported:  openid, profile, email, phone, address, offline_access
backchannel_logout_supported:  true
```

### 3.3 Scopes que o CLI deve solicitar

```
openid profile email offline_access urn:zitadel:iam:org:project:id:363109883022671995:aud
```

| Scope | Função |
|---|---|
| `openid` | Habilita OIDC e emissão de id_token |
| `profile` | Inclui name, family_name, given_name, etc. no id_token |
| `email` | Inclui email + email_verified no id_token |
| `offline_access` | Habilita emissão de refresh_token |
| `urn:zitadel:iam:org:project:id:<PROJECT_ID>:aud` | **Scope mágico Zitadel.** Injeta o Project ID no `aud` do JWT. Sem ele, o BFF rejeita. |

### 3.4 Claims do access_token (JWT)

| Claim | Tipo | Sempre presente? | Notas |
|---|---|---|---|
| `iss` | string | sim | `https://auth.acdgbrasil.com.br` (exato) |
| `sub` | string | sim | User ID (snowflake) |
| `aud` | array | sim | **9 entries**, sempre contém Project ID. Validar com `contains`, não `==`. |
| `client_id` | string | sim | `371410163745226755` (CLI) |
| `iat` | int | sim | Unix timestamp |
| `exp` | int | sim | Unix timestamp; ~43200s após iat |
| `nbf` | int | sim | Igual a iat |
| `jti` | string | sim | JWT unique ID (formato Zitadel: `V2_<authReq>-at_<token>`) |
| `urn:zitadel:iam:org:project:roles` | object | sim | **Use esta** (genérica). Objeto, não array. |
| `urn:zitadel:iam:org:project:<PROJECT_ID>:roles` | object | sim | Mesma info, chave específica do project. Backup. |
| `azp` | string | **NÃO** | Existe apenas no id_token (conforme OIDC Core §2). NÃO validar no access_token. |
| `email` / `email_verified` | — | **NÃO** | NÃO viajam no access_token. Use `/userinfo`. |
| `name` / profile | — | **NÃO** | NÃO viajam no access_token. Use `/userinfo`. |

### 3.5 Estrutura do claim de roles

**Importante:** roles vêm como **objeto**, não array. Cada chave é o nome da role; o valor é um objeto `{ "<orgId>": "<orgDomain>" }`.

```json
{
  "urn:zitadel:iam:org:project:roles": {
    "superadmin": {
      "363109592139300987": "acdg.auth.acdgbrasil.com.br"
    },
    "owner": {
      "363109592139300987": "acdg.auth.acdgbrasil.com.br"
    },
    "social-care:admin": {
      "363109592139300987": "acdg.auth.acdgbrasil.com.br"
    }
  }
}
```

Para extrair a lista plana de roles que o user tem:

```swift
// Swift / BFF
let rolesClaim = jwt["urn:zitadel:iam:org:project:roles"] as? [String: Any] ?? [:]
let userRoles = Array(rolesClaim.keys)  // ["superadmin", "owner", "social-care:admin", ...]
```

```dart
// Dart / CLI
final rolesClaim = payload['urn:zitadel:iam:org:project:roles'] as Map<String, dynamic>? ?? {};
final userRoles = rolesClaim.keys.toList();
```

### 3.6 Claims do id_token

Tudo que está no access_token, **mais**:

| Claim | Notas |
|---|---|
| `azp` | Authorized Party = client_id do CLI |
| `at_hash` | `b64url(SHA-256(access_token).leftHalf)` — valida pareamento com access_token |
| `nonce` | Echo do nonce enviado no authorize. **Validar match.** |
| `auth_time` | Quando o user efetivamente autenticou |
| `amr` | `["pwd"]` — método de autenticação |
| `sid` | Session ID (útil para back-channel logout) |
| `email`, `email_verified`, `name`, `family_name`, `given_name`, `nickname`, `preferred_username`, `gender`, `locale`, `updated_at` | Profile completo |

### 3.7 Resposta do `/userinfo`

`GET /oidc/v1/userinfo` com `Authorization: Bearer <access_token>` retorna JSON com `sub`, `email`, `email_verified`, profile completo, e as 12 roles em ambas as chaves (genérica e project-specific).

> Quando o BFF precisa do email/profile mas só tem o access_token, é aqui que ele busca.

---

## 4. Para o dev do BFF Vapor (Swift)

### 4.1 Visão geral

O BFF tem três responsabilidades novas relacionadas ao CLI:

1. **Aceitar `Authorization: Bearer <JWT>`** em todos os endpoints protegidos.
2. **Validar o JWT** contra o JWKS do Zitadel.
3. **Resolver identidade** (email/name) via `/userinfo` quando necessário, com cache.

O BFF atual já valida sessão de cookie do BFF Web. **Não substitua** essa lógica — adicione um **segundo middleware** que reconhece Bearer no header e roteia pra essa pipeline. Decisão de qual usar: se header `Authorization: Bearer ...` presente → pipeline JWT; senão → pipeline cookie tradicional.

### 4.2 Discovery + JWKS cache

**Boot do BFF:**

```swift
// Pseudocódigo Swift / Vapor
struct OidcConfig {
    let issuer = "https://auth.acdgbrasil.com.br"
    let projectId = "363109883022671995"
    let cliClientId = "371410163745226755"
}

actor OidcDiscovery {
    private var endpoints: DiscoveryEndpoints?
    private var jwksCache: JWKS?
    private var jwksCachedAt: Date?

    func bootstrap() async throws {
        let url = URL(string: "\(config.issuer)/.well-known/openid-configuration")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let discovery = try JSONDecoder().decode(DiscoveryResponse.self, from: data)
        guard discovery.issuer == config.issuer else {
            throw OidcError.issuerMismatch
        }
        self.endpoints = discovery.endpoints
        try await refreshJwks()
    }

    func refreshJwks() async throws {
        let (data, _) = try await URLSession.shared.data(
            from: URL(string: endpoints!.jwksUri)!
        )
        self.jwksCache = try JSONDecoder().decode(JWKS.self, from: data)
        self.jwksCachedAt = Date()
    }

    func getKey(kid: String) async throws -> JWK {
        // tenta cache
        if let key = jwksCache?.keys.first(where: { $0.kid == kid }) {
            return key
        }
        // kid desconhecido → refresh (rotação de chave) — rate-limit a 1/min
        guard let cachedAt = jwksCachedAt, Date().timeIntervalSince(cachedAt) > 60 else {
            throw OidcError.unknownKid
        }
        try await refreshJwks()
        guard let key = jwksCache?.keys.first(where: { $0.kid == kid }) else {
            throw OidcError.unknownKid
        }
        return key
    }
}
```

**Por que rate-limit no refresh:** sem isso, um atacante pode forçar refresh ininterrupto enviando JWTs com kids inválidos = DoS amplificado contra o Zitadel.

### 4.3 Validação do JWT

```swift
struct JwtValidator {
    let discovery: OidcDiscovery
    let config: OidcConfig
    let clockSkew: TimeInterval = 30  // segundos

    func validate(token: String) async throws -> JwtClaims {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { throw OidcError.malformed }

        let header = try decode(parts[0])
        let payload = try decode(parts[1])

        // 1. Algoritmo
        guard header["alg"] as? String == "RS256" else {
            throw OidcError.invalidAlgorithm
        }

        // 2. Kid presente
        guard let kid = header["kid"] as? String else {
            throw OidcError.noKid
        }

        // 3. Buscar chave (cache + refresh se necessário)
        let key = try await discovery.getKey(kid: kid)

        // 4. Verificar assinatura RS256 (use sua lib JWT favorita — Vapor JWT, JWTKit etc.)
        try verifyRS256(token: token, publicKey: key)

        // 5. Issuer exato
        guard payload["iss"] as? String == config.issuer else {
            throw OidcError.invalidIssuer
        }

        // 6. Audience contém Project ID
        let aud = (payload["aud"] as? [String]) ?? [(payload["aud"] as? String).map { [$0] } ?? []].flatMap { $0 }
        guard aud.contains(config.projectId) else {
            throw OidcError.audienceMissing
        }

        // 7. Tempo
        let now = Date().timeIntervalSince1970
        if let exp = payload["exp"] as? Double, now > exp + clockSkew {
            throw OidcError.expired
        }
        if let nbf = payload["nbf"] as? Double, now < nbf - clockSkew {
            throw OidcError.notYetValid
        }

        // 8. (NÃO) validar azp no access_token — não existe lá

        return JwtClaims(payload: payload)
    }
}
```

**Erros canônicos a retornar como 401:**

| Caso | Mensagem segura |
|---|---|
| Header ausente | `Unauthorized` |
| Header malformado (não Bearer, não 3 partes) | `Unauthorized` |
| Algoritmo errado / kid ausente | `Unauthorized` |
| Kid desconhecido após refresh | `Unauthorized` |
| Assinatura inválida | `Unauthorized` |
| Issuer errado | `Unauthorized` |
| Audience sem Project ID | `Unauthorized` |
| `exp` no passado | `Unauthorized` |

> ⚠️ Não dê hints específicos no body da resposta 401 — atacante usa pra fingerprintar. `WWW-Authenticate: Bearer error="invalid_token"` é o máximo. Detalhes só no log interno.

### 4.4 Resolver email/profile via `/userinfo`

Implementar **lazy load + cache** por sub:

```swift
actor UserInfoCache {
    private var cache: [String: (info: UserInfo, fetchedAt: Date)] = [:]
    private let ttl: TimeInterval = 5 * 60  // 5 minutos

    func get(sub: String, accessToken: String) async throws -> UserInfo {
        if let entry = cache[sub], Date().timeIntervalSince(entry.fetchedAt) < ttl {
            return entry.info
        }
        let info = try await fetchUserInfo(accessToken: accessToken)
        cache[sub] = (info, Date())
        return info
    }

    private func fetchUserInfo(accessToken: String) async throws -> UserInfo {
        var req = URLRequest(url: URL(string: discovery.endpoints.userinfoEndpoint)!)
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw OidcError.userinfoFailed
        }
        return try JSONDecoder().decode(UserInfo.self, from: data)
    }
}
```

**Quando chamar `/userinfo`:**
- Primeiro request da sessão (sub não cacheado)
- TTL expirado
- Endpoints que precisam de email pra log/audit

**Quando NÃO chamar:**
- Endpoints que só precisam de `sub` ou roles (já no JWT)
- Toda request individual (sobrecarrega o Zitadel)

### 4.5 Autorização baseada em roles

```swift
extension JwtClaims {
    var roles: Set<String> {
        let claim = payload["urn:zitadel:iam:org:project:roles"] as? [String: Any] ?? [:]
        return Set(claim.keys)
    }

    func hasRole(_ role: String) -> Bool {
        roles.contains(role)
    }

    func hasAnyRole(_ candidates: [String]) -> Bool {
        !roles.intersection(Set(candidates)).isEmpty
    }
}

// Uso em rotas
app.get("admin", "stats") { req in
    let claims = try await req.auth.require(JwtClaims.self)
    guard claims.hasAnyRole(["superadmin", "social-care:admin"]) else {
        throw Abort(.forbidden)
    }
    // ...
}
```

**Lista de 12 roles atualmente em uso na plataforma:**

```
superadmin          owner               social_worker
social-care:admin   social-care:owner   social-care:worker
people-context:admin   people-context:owner   people-context:worker
analysis-bi:admin   analysis-bi:analyst   analysis-bi:exporter
```

> A role `admin` (do group `platform`) existe no Zitadel mas não é atribuída a usuários humanos no momento — é usada apenas em service accounts. Decisão de uso será revisada futuramente. **Não dependa dela na lógica do BFF agora.**

### 4.6 Erros HTTP padronizados

| Cenário | HTTP | Body |
|---|---|---|
| Sem Bearer | 401 | `{"error":"unauthorized"}` |
| JWT inválido | 401 | `{"error":"invalid_token"}` |
| JWT válido mas role insuficiente | 403 | `{"error":"forbidden","required_roles":["x","y"]}` |
| `/userinfo` indisponível (Zitadel down) | 503 | `{"error":"upstream_unavailable"}` |
| Endpoint não existe | 404 | padrão |

### 4.7 Coexistência com BFF Web Confidential

Os dois apps (BFF Web Confidential com cookie + CLI Native com Bearer) compartilham o mesmo project, mesmo audience, mesmas roles. **Um JWT do CLI é válido pro BFF e um cookie de sessão do BFF Web também é** — eles se complementam, não competem.

Roteamento no Vapor:

```swift
app.middleware.use(BearerOrCookieAuthMiddleware())
// internamente:
//   if Authorization: Bearer X presente → JwtValidator
//   senão se cookie de sessão presente → SessionAuth (existente)
//   senão → unauthenticated (decisão fica pro endpoint)
```

---

## 5. Para o dev do CLI Dart

### 5.1 Estrutura de módulos sugerida

```
acdg_cli/
├── bin/
│   └── acdg_cli.dart                    # entrypoint
├── lib/
│   ├── commands/
│   │   ├── login_command.dart           # acdg-cli login [--device]
│   │   ├── logout_command.dart
│   │   ├── whoami_command.dart
│   │   └── ...
│   ├── oidc/
│   │   ├── discovery.dart               # fetch+cache .well-known
│   │   ├── pkce.dart                    # S256 verifier/challenge
│   │   ├── loopback_listener.dart       # multi-hit defensivo
│   │   ├── device_flow.dart             # RFC 8628
│   │   ├── token_client.dart            # /token calls
│   │   ├── jwt_decoder.dart             # decode (sem validar — validação é no BFF)
│   │   └── session.dart                 # modelo de sessão
│   ├── storage/
│   │   ├── secure_store.dart            # interface
│   │   ├── secure_store_macos.dart      # Keychain
│   │   ├── secure_store_linux.dart      # libsecret
│   │   └── secure_store_windows.dart    # DPAPI
│   ├── http/
│   │   └── api_client.dart              # cliente HTTP autenticado
│   └── config.dart                      # constantes do .env
└── test/
    └── ... (ver Seção 7.2)
```

### 5.2 Constantes do CLI (de `config.dart` ou `.env` empacotado)

```dart
class OidcConfig {
  static const issuer = 'https://auth.acdgbrasil.com.br';
  static const clientId = '371410163745226755';
  static const projectId = '363109883022671995';
  static const scopes =
      'openid profile email offline_access '
      'urn:zitadel:iam:org:project:id:363109883022671995:aud';
  static const redirectUriTemplate = 'http://127.0.0.1:{port}/callback';

  // Cache do discovery
  static const discoveryCacheTtl = Duration(hours: 24);

  // Loopback listener
  static const loopbackTimeout = Duration(minutes: 5);

  // Device flow
  static const deviceFlowDefaultInterval = Duration(seconds: 5);
}
```

### 5.3 Discovery dinâmico

```dart
class OidcDiscovery {
  final String issuer;
  final String authorizationEndpoint;
  final String tokenEndpoint;
  final String jwksUri;
  final String userinfoEndpoint;
  final String endSessionEndpoint;
  final String revocationEndpoint;
  final String deviceAuthorizationEndpoint;

  static Future<OidcDiscovery> load(String issuer) async {
    final url = Uri.parse('$issuer/.well-known/openid-configuration');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw OidcException('discovery_failed', 'HTTP ${res.statusCode}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (j['issuer'] != issuer) {
      throw OidcException(
        'issuer_mismatch',
        '${j['issuer']} != $issuer',
      );
    }
    return OidcDiscovery(
      issuer: j['issuer'] as String,
      authorizationEndpoint: j['authorization_endpoint'] as String,
      tokenEndpoint: j['token_endpoint'] as String,
      jwksUri: j['jwks_uri'] as String,
      userinfoEndpoint: j['userinfo_endpoint'] as String,
      endSessionEndpoint: j['end_session_endpoint'] as String,
      revocationEndpoint: j['revocation_endpoint'] as String,
      deviceAuthorizationEndpoint: j['device_authorization_endpoint'] as String,
    );
  }
}
```

### 5.4 PKCE — S256 only

```dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

String _b64UrlNoPad(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

class PkcePair {
  final String verifier;
  final String challenge;
  PkcePair(this.verifier, this.challenge);

  factory PkcePair.generate() {
    final rand = Random.secure();
    final bytes = List<int>.generate(64, (_) => rand.nextInt(256));
    final verifier = _b64UrlNoPad(bytes);
    final challenge = _b64UrlNoPad(sha256.convert(utf8.encode(verifier)).bytes);
    return PkcePair(verifier, challenge);
  }
}
```

**Nunca usar `code_challenge_method=plain`.** O servidor suporta apenas S256.

### 5.5 Loopback listener defensivo (CRÍTICO — não simplifique)

Esse é o módulo mais delicado. A versão naive **vai falhar em produção** para qualquer user que tenha sessão ativa no Zitadel (cookie residual de outro login), porque o Next.js da UI de login dispara prefetch RSC contra o `redirect_uri`. Veja [Apêndice A](#a1-listener-python-de-referência-run-2) para a referência canônica em Python.

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

class CallbackResult {
  final String code;
  CallbackResult(this.code);
}

class LoopbackListener {
  final String expectedState;
  final Duration timeout;
  HttpServer? _server;
  int? _port;

  LoopbackListener({required this.expectedState, required this.timeout});

  Future<int> bindEphemeralPort() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    return _port!;
  }

  Future<CallbackResult> awaitCallback() async {
    if (_server == null) {
      throw StateError('Call bindEphemeralPort() first');
    }

    final completer = Completer<CallbackResult>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          OidcException('callback_timeout', 'No valid callback in ${timeout.inSeconds}s'),
        );
      }
    });

    _server!.listen(
      (req) => _handleRequest(req, completer),
      onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );

    try {
      return await completer.future;
    } finally {
      timer.cancel();
      await _server?.close(force: true);
      _server = null;
    }
  }

  Future<void> _handleRequest(
    HttpRequest req,
    Completer<CallbackResult> completer,
  ) async {
    // 1. Filtra método
    if (req.method != 'GET') {
      _drop(req, statusCode: 405, reason: 'method_not_allowed');
      return;
    }

    // 2. Filtra path
    if (req.uri.path != '/callback') {
      _drop(req, statusCode: 404, reason: 'wrong_path');
      return;
    }

    final q = req.uri.queryParameters;

    // 3. Filtra prefetch RSC do Next.js
    if (q.containsKey('_rsc')) {
      _drop(req, statusCode: 204, reason: 'rsc_prefetch');
      return;
    }

    // 4. Erro vindo do authorize
    if (q['error'] != null) {
      final err = q['error']!;
      final desc = q['error_description'] ?? '';
      _respondHtml(
        req,
        statusCode: 400,
        body: '<h1>Login error</h1><p>${_escape(err)}: ${_escape(desc)}</p>',
      );
      if (!completer.isCompleted) {
        completer.completeError(OidcException(err, desc));
      }
      return;
    }

    // 5. Validação de state (CSRF)
    final state = q['state'] ?? '';
    final code = q['code'] ?? '';
    if (state.isEmpty || state != expectedState || code.isEmpty) {
      // NÃO loga query string completa — pode conter code de outro flow
      _log('drop (state/code mismatch — keep listening)');
      _drop(req, statusCode: 204, reason: 'state_mismatch');
      return;  // continua ouvindo!
    }

    // 6. Sucesso
    _respondHtml(
      req,
      statusCode: 200,
      body: '<!DOCTYPE html><html><head><title>Login OK</title>'
          '<meta charset="utf-8"></head><body style="font-family:sans-serif">'
          '<h1>✅ Login concluído</h1><p>Pode fechar esta aba.</p>'
          '</body></html>',
    );
    if (!completer.isCompleted) {
      completer.complete(CallbackResult(code));
    }
  }

  void _drop(HttpRequest req, {required int statusCode, required String reason}) {
    _log('drop ${req.method} ${req.uri.path} -> $reason');
    req.response.statusCode = statusCode;
    req.response.close();
  }

  void _respondHtml(HttpRequest req, {required int statusCode, required String body}) {
    req.response.statusCode = statusCode;
    req.response.headers.contentType = ContentType.html;
    req.response.write(body);
    req.response.close();
  }

  String _escape(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  void _log(String msg) {
    // logger interno do CLI — NÃO incluir query strings
    stderr.writeln('[loopback] $msg');
  }
}
```

**Pontos não-negociáveis:**

1. **Multi-hit:** o listener continua ouvindo mesmo após receber requests inválidos. Só completa quando vê `state == expected` E `code` não-vazio.
2. **Filtra `_rsc=`:** prefetch RSC do Next.js dispara contra `/callback` antes do user clicar. Sem esse filtro, captura code-fantasma.
3. **Valida state:** CSRF guard. Estado vazio/diferente = drop silencioso.
4. **Porta efêmera:** `bind(loopbackIPv4, 0)` deixa o OS escolher. Recupera de `server.port`.
5. **Timeout 5min:** janela razoável para o user navegar e logar.
6. **NÃO loga query strings:** o code vaza em log = vetor de auditoria ruim.

### 5.6 Authorize URL

```dart
class AuthorizeUrlBuilder {
  static Uri build({
    required String authorizationEndpoint,
    required String clientId,
    required String redirectUri,
    required String scopes,
    required String state,
    required String nonce,
    required String codeChallenge,
  }) {
    return Uri.parse(authorizationEndpoint).replace(queryParameters: {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': scopes,
      'state': state,
      'nonce': nonce,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'prompt': 'login',  // força tela mesmo com sessão residual
    });
  }
}
```

**`prompt=login` é importante.** Sem ele, se o user já tem cookie de sessão em `auth.acdgbrasil.com.br` (ex: usou o BFF Web recentemente), o Zitadel pula a tela de login e dispara o redirect direto. Isso ativa o cenário de prefetch RSC e exige que o listener seja muito robusto. Com `prompt=login`, o user é forçado a re-autenticar — sessão limpa, sem prefetch indesejado.

### 5.7 Abrir browser

```dart
import 'dart:io';

Future<void> openBrowser(Uri url) async {
  if (Platform.isMacOS) {
    await Process.run('open', [url.toString()]);
  } else if (Platform.isLinux) {
    await Process.run('xdg-open', [url.toString()]);
  } else if (Platform.isWindows) {
    await Process.run('rundll32', ['url.dll,FileProtocolHandler', url.toString()]);
  } else {
    // Fallback: imprimir URL pra user copiar
    stdout.writeln('Open this URL in your browser:');
    stdout.writeln(url);
  }
}
```

**Fallback é importante.** Em ambientes SSH/CI/Docker o browser pode não abrir — nesse caso, o CLI imprime a URL e o user copia. Combinar com `--device` (ver 5.10) é a UX correta.

### 5.8 Token client

```dart
class TokenClient {
  final OidcDiscovery discovery;

  Future<TokenResponse> exchangeCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    required String clientId,
  }) async {
    final res = await http.post(
      Uri.parse(discovery.tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': codeVerifier,
      },
    );
    return _parseTokenResponse(res);
  }

  Future<TokenResponse> refresh({
    required String refreshToken,
    required String clientId,
    required String scopes,
  }) async {
    final res = await http.post(
      Uri.parse(discovery.tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': clientId,
        'scope': scopes,
      },
    );
    return _parseTokenResponse(res);
  }

  TokenResponse _parseTokenResponse(http.Response res) {
    if (res.statusCode == 200) {
      return TokenResponse.fromJson(jsonDecode(res.body));
    }
    if (res.statusCode == 400) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final error = body['error'] as String? ?? 'invalid_request';
      final desc = body['error_description'] as String? ?? '';

      // CRÍTICO: refresh rotation enforcement
      if (error == 'invalid_grant' &&
          desc.contains('RefreshTokenInvalid')) {
        throw RefreshTokenInvalidException(
          'Refresh token foi rotacionado ou usado em outra sessão. '
          'Possível leak. Re-login obrigatório.',
        );
      }

      throw OidcException(error, desc);
    }
    if (res.statusCode >= 500) {
      throw OidcException('server_error', 'HTTP ${res.statusCode}');
    }
    throw OidcException('unexpected', 'HTTP ${res.statusCode}: ${res.body}');
  }
}
```

### 5.9 Tratamento de `RefreshTokenInvalid`

**REGRA DE OURO:** se o refresh falha com `RefreshTokenInvalid`, **NÃO retry**.

Isso é sinal de que:
- O refresh já foi consumido por outra instância (você logou em outra máquina)
- O refresh foi exfiltrado e usado por atacante (você foi frontruna)
- O Zitadel revogou (admin forçou)

Em todos os casos, a ação correta é:

```dart
try {
  final newTokens = await tokenClient.refresh(...);
  await sessionStore.save(newTokens);
} on RefreshTokenInvalidException {
  // 1. Apaga sessão local
  await sessionStore.clear();

  // 2. Avisa o user de forma clara
  stderr.writeln('⚠️  Sua sessão foi invalidada.');
  stderr.writeln('    Possíveis causas: você logou em outra máquina, ou o token expirou.');
  stderr.writeln('    Execute: acdg-cli login');

  // 3. (Opcional) Audit log local
  await auditLogger.log(
    event: 'refresh_invalid',
    severity: 'warning',
    timestamp: DateTime.now(),
  );

  // 4. Sai com código de erro distinto pra scripts saberem
  exit(7);  // 7 = re-auth required
}
```

### 5.10 Device Code Flow (`acdg-cli login --device`)

Para uso em SSH, CI, containers — onde browser local não está disponível.

```dart
class DeviceFlow {
  final OidcDiscovery discovery;
  final String clientId;
  final String scopes;

  Future<DeviceAuthResponse> initiate() async {
    final res = await http.post(
      Uri.parse(discovery.deviceAuthorizationEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': clientId,
        'scope': scopes,
      },
    );
    if (res.statusCode != 200) {
      throw OidcException('device_init_failed', 'HTTP ${res.statusCode}');
    }
    return DeviceAuthResponse.fromJson(jsonDecode(res.body));
  }

  Future<TokenResponse> poll({
    required String deviceCode,
    required Duration interval,
    required Duration expiresIn,
  }) async {
    final start = DateTime.now();
    var currentInterval = interval;

    while (DateTime.now().difference(start) < expiresIn) {
      await Future.delayed(currentInterval);

      final res = await http.post(
        Uri.parse(discovery.tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          'device_code': deviceCode,
          'client_id': clientId,
        },
      );

      if (res.statusCode == 200) {
        return TokenResponse.fromJson(jsonDecode(res.body));
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final error = body['error'] as String?;

      switch (error) {
        case 'authorization_pending':
          continue;  // user ainda não autorizou — manter polling
        case 'slow_down':
          // RFC 8628 §3.5: aumentar intervalo em 5s
          currentInterval += const Duration(seconds: 5);
          continue;
        case 'access_denied':
          throw OidcException('access_denied', 'User cancelou a autorização');
        case 'expired_token':
          throw OidcException('expired_token', 'Device code expirou');
        default:
          throw OidcException(error ?? 'unknown', body['error_description'] ?? '');
      }
    }
    throw OidcException('timeout', 'Device flow timeout');
  }
}
```

UX recomendada:

```
$ acdg-cli login --device
Para autorizar este CLI, abra:

    https://auth.acdgbrasil.com.br/device

Em qualquer browser (mesmo em outro dispositivo), e digite o código:

    ABCD-EFGH

Aguardando autorização...  [⠋]
✅ Autorizado como Gabriel Aderaldo (gabriel.aderaldo@acdgbrasil.com.br)
   Roles: superadmin, owner, social_worker (+9 outras)
   Token expira em 12h
```

### 5.11 Storage de tokens por SO

**Nunca salvar em arquivo plaintext.**

#### macOS — Keychain

```dart
// Use https://pub.dev/packages/flutter_secure_storage (mesmo em CLI Dart puro funciona)
// Alternativa: FFI direto pra Security framework

const storage = FlutterSecureStorage(
  iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked_this_device),
);

await storage.write(key: 'acdg_session', value: jsonEncode(session));
final raw = await storage.read(key: 'acdg_session');
```

#### Linux — libsecret / Secret Service

```dart
// flutter_secure_storage no Linux usa libsecret (gnome-keyring/KWallet)
// Verificar se libsecret-1 está instalado: apt-get install libsecret-1-dev

const storage = FlutterSecureStorage(
  lOptions: LinuxOptions(),
);
```

#### Windows — DPAPI

```dart
// flutter_secure_storage no Windows usa DPAPI nativamente
const storage = FlutterSecureStorage();
```

#### Fallback

Se o secure storage falhar (sem GUI no Linux servidor, etc.), avisar o user e oferecer:

1. Salvar criptografado com passphrase do user (interativo)
2. OU salvar plaintext em `~/.config/acdg/credentials` (chmod 600) com warning explícito

### 5.12 Modelo de sessão

```dart
class Session {
  final String accessToken;
  final String refreshToken;
  final String idToken;
  final DateTime accessExpiresAt;
  final String sub;
  final String email;
  final List<String> roles;

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'id_token': idToken,
        'access_expires_at': accessExpiresAt.toIso8601String(),
        'sub': sub,
        'email': email,
        'roles': roles,
      };

  bool get isExpired => DateTime.now().isAfter(
        accessExpiresAt.subtract(const Duration(seconds: 60)),
      );
}
```

### 5.13 Auto-refresh middleware

Toda chamada autenticada ao BFF passa por:

```dart
class AuthenticatedHttpClient {
  final SecureStore store;
  final TokenClient tokenClient;

  Future<http.Response> request(String method, Uri url, {Object? body}) async {
    var session = await store.load();
    if (session == null) {
      throw NotLoggedInException();
    }

    if (session.isExpired) {
      try {
        final newTokens = await tokenClient.refresh(
          refreshToken: session.refreshToken,
          clientId: OidcConfig.clientId,
          scopes: OidcConfig.scopes,
        );
        session = Session.fromTokenResponse(newTokens);
        await store.save(session);
      } on RefreshTokenInvalidException {
        await store.clear();
        rethrow;
      }
    }

    return http.Request(method, url)
      ..headers['Authorization'] = 'Bearer ${session.accessToken}'
      ..headers['Content-Type'] = 'application/json'
      ..body = body != null ? jsonEncode(body) : ''
      ..send();
  }
}
```

### 5.14 Logout

```dart
Future<void> logout() async {
  final session = await store.load();
  if (session == null) return;

  // 1. Revoke remoto (best effort — não falha se Zitadel down)
  try {
    await http.post(
      Uri.parse(discovery.revocationEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'token': session.refreshToken,
        'token_type_hint': 'refresh_token',
        'client_id': OidcConfig.clientId,
      },
    );
  } catch (_) {
    // ignora erros — apaga local mesmo assim
  }

  // 2. Apaga local
  await store.clear();
}
```

### 5.15 Logging seguro

| Pode logar | Não logar |
|---|---|
| `kid` do header JWT | Tokens completos |
| `sub`, `email` (ofuscar) | `code`, `code_verifier`, `state`, `nonce` |
| `expires_at`, `iat` | Query strings de `/callback` |
| Status HTTP, latência | Refresh token (mesmo opaque) |
| Etapas do flow ("authorize", "exchange") | Bodies de POST que contenham credentials |

Para debug, mostrar primeiros 8 + últimos 4 chars de tokens:

```dart
String redact(String token) =>
    token.length > 16 ? '${token.substring(0, 8)}...${token.substring(token.length - 4)}' : '***';
```

---

## 6. Contrato compartilhado CLI ↔ BFF

### 6.1 Headers obrigatórios

Toda request do CLI ao BFF:

```http
Authorization: Bearer <access_token>
Content-Type: application/json
User-Agent: acdg-cli/<version> dart/<dart-version>
```

### 6.2 Códigos de status

| Status | Significado | Ação do CLI |
|---|---|---|
| 200/201/204 | Sucesso | processar resposta |
| 400 | Bad request (validação) | mostrar erro user-friendly |
| 401 | Token inválido/expirado | tentar refresh; se falhar, forçar relogin |
| 403 | Token válido, role insuficiente | mostrar quais roles seriam necessárias |
| 404 | Recurso não existe | mostrar mensagem |
| 429 | Rate limit | retry com backoff |
| 500-599 | Erro do BFF | mostrar erro genérico, log detalhado |

### 6.3 Formato de erro do BFF

Padronizar em todos os endpoints:

```json
{
  "error": "forbidden",
  "error_description": "Esta ação requer uma das roles: superadmin, social-care:admin",
  "required_roles": ["superadmin", "social-care:admin"],
  "user_roles": ["social-care:worker"]
}
```

CLI parseia e mostra:

```
$ acdg-cli admin reset-database
❌ Sem permissão.
   Você tem: social-care:worker
   Necessário: superadmin OU social-care:admin
```

### 6.4 Refresh rotation — comportamento esperado

| Cenário CLI | Cenário Zitadel | BFF percebe? |
|---|---|---|
| CLI usa refresh_token N pra obter access_token novo | Zitadel emite N+1 e invalida N | não — só vê access_tokens válidos |
| Atacante usa refresh_token N (que já foi rotacionado) | Zitadel retorna 400 RefreshTokenInvalid | não envolvido — atacante fala direto com Zitadel |
| CLI tenta usar refresh_token N+1 após N+2 já existir (race) | Zitadel retorna 400 RefreshTokenInvalid | não envolvido |

**Implicação para BFF:** nada a fazer. A invalidação é responsabilidade exclusiva CLI ↔ Zitadel. BFF só vê access_tokens que vêm dessa pipeline e os valida normalmente.

---

## 7. Casos de teste obrigatórios

### 7.1 BFF (Vapor / Swift)

Casos que o test suite do BFF **deve** cobrir antes do release.

#### Validação de JWT

| Caso | JWT input | Esperado |
|---|---|---|
| Header ausente | `(no header)` | 401 |
| Bearer mas vazio | `Bearer ` | 401 |
| Não-JWT | `Bearer foo.bar` | 401 (não tem 3 partes ou base64 inválido) |
| JWT bem-formado mas alg=none | `{"alg":"none"}.{...}.` | 401 |
| JWT com alg=HS256 | `{"alg":"HS256"}.{...}.<sig>` | 401 (não suportado) |
| JWT sem kid | `{"alg":"RS256"}.{...}.<sig>` | 401 |
| JWT com kid desconhecido | `{"alg":"RS256","kid":"foo"}.{...}.<sig>` | refresh JWKS, ainda inválido → 401 |
| Assinatura inválida | JWT real mas `<sig>` adulterada | 401 |
| `iss` errado | `https://evil.com` | 401 |
| `aud` sem PROJECT_ID | `["371410163745226755"]` apenas | 401 |
| `exp` no passado | `exp = now - 100` | 401 |
| `exp` no passado mas dentro do clock skew | `exp = now - 20`, skew 30 | 200 |
| `nbf` no futuro | `nbf = now + 100` | 401 |
| JWT válido mas sem roles necessárias | `roles = ["social-care:worker"]` para endpoint que exige `superadmin` | 403 |
| JWT válido com role correta | `roles = ["superadmin"]` | 200 |

#### Cache `/userinfo`

| Caso | Esperado |
|---|---|
| Primeiro request com sub novo | chama `/userinfo`, cacheia |
| Segundo request mesmo sub, dentro do TTL | usa cache, não chama `/userinfo` |
| Após TTL | chama `/userinfo` novamente |
| `/userinfo` retorna 401 (token revogado) | propaga 401 ao client |
| `/userinfo` retorna 5xx | retry 1x, depois fallback (usar só dados do JWT) |

#### Concorrência

| Caso | Esperado |
|---|---|
| 100 requests simultâneos com mesmo JWT | JWKS chamado 1x, validação stateless escala |
| Rotação de chave do Zitadel (kid muda) | refresh JWKS automático na primeira falha; rate-limited a 1/min |

### 7.2 CLI (Dart)

#### Login loopback

| Caso | Setup | Esperado |
|---|---|---|
| Happy path em janela limpa | sem cookies | login OK, tokens salvos |
| Sessão residual | cookie de auth.acdgbrasil.com.br ativo | `prompt=login` força reauth, OK |
| Prefetch RSC | (simula com mock) | listener filtra, captura code real |
| State mismatch (CSRF attempt) | mock envia state diferente | listener drena silenciosamente |
| Browser fecha sem completar | timeout de 5min | erro `callback_timeout` |
| User cancela na tela do Zitadel | `?error=access_denied` no callback | erro `access_denied` |
| Porta efêmera ocupada | bind falha | falha clara, sugere retry |
| Listener mata-mata | dois `acdg-cli login` simultâneos | um falha, outro sucede |

#### Refresh

| Caso | Esperado |
|---|---|
| Refresh válido | novos tokens, sessão atualizada |
| Refresh já rotacionado | `RefreshTokenInvalidException`, sessão limpa, exit 7 |
| Refresh expirado (passou idle/absolute) | mesma coisa, exit 7 |
| Zitadel retorna 5xx | retry com backoff exponencial (3x), depois falha |

#### Device flow

| Caso | Esperado |
|---|---|
| Happy path | polling até autorização, tokens salvos |
| `slow_down` | aumenta intervalo em 5s |
| `authorization_pending` | continua polling |
| `expired_token` | erro claro, sugere retry |
| `access_denied` | user cancelou, erro claro |
| Network down durante polling | retry; se persistir, falha após N tentativas |

#### Storage

| Caso | macOS | Linux | Windows |
|---|---|---|---|
| Save → Read | Keychain | libsecret | DPAPI |
| Read sem save | retorna null | retorna null | retorna null |
| Clear | apaga | apaga | apaga |
| Sem libsecret instalado | n/a | erro claro, sugere instalar | n/a |
| Keychain bloqueado | prompt do OS | n/a | n/a |

#### Logout

| Caso | Esperado |
|---|---|
| Logout com sessão | revoke remoto + clear local |
| Logout sem sessão | no-op silencioso |
| Logout com Zitadel down | clear local mesmo assim, log warning |

---

## 8. Pendências conhecidas (não-bloqueantes)

### 8.1 Role `admin` não atribuída a humanos

**Status:** A role `admin` (do group `platform`) existe no project mas atualmente está atribuída apenas a service accounts (`people-context-sa` e similares).

**Decisão:** seguir com 12 roles ativas para usuários humanos. Investigar caso de uso futuro se houver demanda.

**Impacto:**
- BFF não deve exigir `admin` em nenhum endpoint que humanos precisam acessar.
- CLI não precisa tratar `admin` de forma especial.
- Service accounts (que usam Client Credentials grant, não PKCE) não interagem com o CLI.

**Reavaliação prevista:** quando o BFF Vapor for refatorado para a nova matriz de permissions.

### 8.2 Lista de 9 entries em `aud`

**Status:** O `aud` do JWT vem com 9 IDs — Project ID + 8 outras applications do mesmo project. O scope mágico funciona, e o BFF que valida com `contains` não tem problema.

**Decisão:** aceitar como está.

**Impacto:**
- BFF **deve** usar `aud.contains(PROJECT_ID)`, **nunca** `aud == [...]` ou `aud.length == 1`.
- Caso futuramente a equipe queira reduzir o `aud` (boa prática de minimização), revisar a config dos outros 8 apps no Zitadel — mas é trabalho coordenado e arriscado para produção.

### 8.3 `scope` ausente na resposta de `/token`

**Status:** Mesmo solicitando scopes específicos, a resposta do `/token` vem sem o campo `scope`. RFC 6749 §5.1 permite isso quando os scopes concedidos são iguais aos solicitados (`MAY` em vez de `MUST`).

**Decisão:** não depender desse campo.

**Impacto:**
- CLI não deve verificar `response.scope == requested` — assume que se o request foi 200, todos os scopes foram concedidos.
- BFF: irrelevante (BFF só vê o JWT, não a resposta do token endpoint).

### 8.4 Role `admin` futura — checklist

Se decidirem atribuir `admin` a humanos no futuro:

- [ ] Atribuir role no Zitadel Console
- [ ] Atualizar lista de 12 → 13 roles na docs (esta seção)
- [ ] Atualizar test fixtures do BFF e CLI
- [ ] Decidir semântica: `admin` é mais forte que `superadmin`? Ou é diferente em escopo?
- [ ] Atualizar `hasAnyRole` em endpoints que dependem de role admin-level

---

## 9. Apêndices

### A.1 Listener Python de referência (Run 2)

Versão usada no teste — referência para portar pra Dart. Mostra exatamente o comportamento esperado: filtra RSC, valida state, drena silenciosamente.

```python
#!/usr/bin/env python3
import os, sys, urllib.parse
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(os.environ.get('PORT', '8765'))
EXPECTED_STATE = os.environ['EXPECTED_STATE']
TIMEOUT = int(os.environ.get('TIMEOUT', '300'))

CAPTURED = {'code': None, 'state': None}

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        # NÃO logar query strings — só método, path, motivo
        msg = fmt % args
        # remove query strings do path
        if '?' in msg:
            msg = msg.split('?')[0] + ' [query redacted]'
        sys.stderr.write(f'[listener] {msg}\n')

    def do_OPTIONS(self):
        self.send_response(405); self.end_headers()

    def do_HEAD(self):
        self.send_response(405); self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path != '/callback':
            self.send_response(404); self.end_headers(); return

        q = urllib.parse.parse_qs(parsed.query)

        # filtra prefetch RSC do Next.js
        if '_rsc' in q:
            self.log_message('drop GET /callback -> rsc_prefetch')
            self.send_response(204); self.end_headers(); return

        # erro do authorize
        if 'error' in q:
            err = q['error'][0]
            desc = q.get('error_description', [''])[0]
            self.send_response(400)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            self.wfile.write(f'<h1>Erro: {err}</h1><p>{desc}</p>'.encode())
            CAPTURED['error'] = err
            return

        state = q.get('state', [''])[0]
        code = q.get('code', [''])[0]

        if not state or state != EXPECTED_STATE or not code:
            self.log_message('drop GET /callback -> state_mismatch')
            self.send_response(204); self.end_headers(); return

        # sucesso
        self.log_message('OK   GET /callback -> state matched, code captured')
        CAPTURED['code'] = code
        CAPTURED['state'] = state
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.end_headers()
        self.wfile.write(b'<!DOCTYPE html><h1>Login OK</h1><p>Pode fechar.</p>')

server = HTTPServer(('127.0.0.1', PORT), Handler)
server.timeout = TIMEOUT
sys.stderr.write(f'[listener] listening on http://127.0.0.1:{PORT}/callback (timeout={TIMEOUT}s)\n')

while CAPTURED['code'] is None:
    server.handle_request()  # loop até pegar o code real

with open('/tmp/acdg-callback-code', 'w') as f:
    f.write(CAPTURED['code'])
sys.exit(0)
```

### A.2 `.env` final completo

```env
# OIDC / Zitadel — CLI ACDG
OIDC_ISSUER=https://auth.acdgbrasil.com.br
OIDC_DISCOVERY=https://auth.acdgbrasil.com.br/.well-known/openid-configuration

# Endpoints (descobrir dinamicamente; valores aqui são referência)
OIDC_AUTHORIZE_ENDPOINT=https://auth.acdgbrasil.com.br/oauth/v2/authorize
OIDC_TOKEN_ENDPOINT=https://auth.acdgbrasil.com.br/oauth/v2/token
OIDC_JWKS_URI=https://auth.acdgbrasil.com.br/oauth/v2/keys
OIDC_USERINFO_ENDPOINT=https://auth.acdgbrasil.com.br/oidc/v1/userinfo
OIDC_END_SESSION_ENDPOINT=https://auth.acdgbrasil.com.br/oidc/v1/end_session
OIDC_DEVICE_AUTH_ENDPOINT=https://auth.acdgbrasil.com.br/oauth/v2/device_authorization
OIDC_REVOCATION_ENDPOINT=https://auth.acdgbrasil.com.br/oauth/v2/revoke

# Identidade do CLI
OIDC_CLI_CLIENT_ID=371410163745226755
OIDC_CLI_APP_ID=371410163745161219
OIDC_PROJECT_ID=363109883022671995
OIDC_ORG_ID=363109592139300987

# Loopback (porta efêmera substitui {port} em runtime)
OIDC_CLI_REDIRECT_URI_TEMPLATE=http://127.0.0.1:{port}/callback

# Scopes
OIDC_CLI_SCOPES=openid profile email offline_access urn:zitadel:iam:org:project:id:363109883022671995:aud

# Authorize sempre força login (defesa contra prefetch RSC)
OIDC_CLI_AUTHORIZE_PROMPT=login

# Roles claim
OIDC_ROLES_CLAIM=urn:zitadel:iam:org:project:roles
OIDC_ROLES_CLAIM_PROJECT_SPECIFIC=urn:zitadel:iam:org:project:363109883022671995:roles

# Validação BFF
OIDC_EXPECTED_ISSUER_EXACT=https://auth.acdgbrasil.com.br
OIDC_AUD_MUST_CONTAIN=363109883022671995
OIDC_CLOCK_SKEW_SECONDS=30

# Refresh rotation
OIDC_REFRESH_ROTATION_ENFORCED=true
OIDC_REFRESH_INVALID_GRANT_MEANS_RELOGIN=true

# Lifetimes (informacional — definidos na default settings da instância)
OIDC_ACCESS_TOKEN_TTL_HOURS=12
OIDC_USERINFO_CACHE_TTL_MINUTES=5
```

### A.3 Sample de access_token decodificado (sanitizado)

```json
{
  "header": {
    "alg": "RS256",
    "kid": "363088832046039161",
    "typ": "JWT"
  },
  "payload": {
    "iss": "https://auth.acdgbrasil.com.br",
    "sub": "363088829932634233",
    "client_id": "371410163745226755",
    "aud": [
      "363678038996549834", "363679353508266186", "363684701061251274",
      "363110312318140539", "367375117048610966", "367617280390987926",
      "367349956392059030",
      "371410163745226755",
      "363109883022671995"
    ],
    "iat": 1777878833,
    "exp": 1777922033,
    "nbf": 1777878833,
    "jti": "V2_371418761229500419-at_371418761229565955",
    "urn:zitadel:iam:org:project:roles": {
      "superadmin": { "363109592139300987": "acdg.auth.acdgbrasil.com.br" },
      "owner": { "363109592139300987": "acdg.auth.acdgbrasil.com.br" },
      "social_worker": { "363109592139300987": "acdg.auth.acdgbrasil.com.br" },
      "social-care:admin": { "363109592139300987": "acdg.auth.acdgbrasil.com.br" },
      "social-care:owner": { "363109592139300987": "acdg.auth.acdgbrasil.com.br" },
      "social-care:worker": { "363109592139300987": "acdg.auth.acdgbrasil.com.br" },
      "people-context:admin": { "363109592139300987": "acdg.auth.acdgbrasil.com.br" },
      "people-context:owner": { "363109592139300987": "acdg.auth.acdgbrasil.com.br" },
      "people-context:worker": { "363109592139300987": "acdg.auth.acdgbrasil.com.br" },
      "analysis-bi:admin": { "363109592139300987": "acdg.auth.acdgbrasil.com.br" },
      "analysis-bi:analyst": { "363109592139300987": "acdg.auth.acdgbrasil.com.br" },
      "analysis-bi:exporter": { "363109592139300987": "acdg.auth.acdgbrasil.com.br" }
    },
    "urn:zitadel:iam:org:project:363109883022671995:roles": {
      "...": "(mesmas 12 roles)"
    }
  }
}
```

### A.4 Sample de id_token decodificado (sanitizado)

```json
{
  "header": {
    "alg": "RS256",
    "kid": "363088832046039161",
    "typ": "JWT"
  },
  "payload": {
    "iss": "https://auth.acdgbrasil.com.br",
    "sub": "363088829932634233",
    "azp": "371410163745226755",
    "aud": ["...same 9 entries..."],
    "amr": ["pwd"],
    "auth_time": 1777878516,
    "at_hash": "DUwLxmhwZR68FT3BT8opqg",
    "nonce": "0100ed1443f91de7ddc8c1f1b8217d5dbe3c1c0ebf7416850d07e6520e57c7fc",
    "iat": 1777878833,
    "exp": 1777922033,
    "email": "gaderaldo10@gmail.com",
    "email_verified": true,
    "name": "Gabriel Aderaldo | Super Admin",
    "family_name": "Vieira Soriano Aderaldo",
    "given_name": "Gabriel",
    "nickname": "Gabriel Aderaldo",
    "gender": "male",
    "locale": "en",
    "preferred_username": "gabriel.aderaldo@acdgbrasil.com.br",
    "sid": "371418221019922435",
    "updated_at": 1776154976,
    "client_id": "371410163745226755",
    "urn:zitadel:iam:org:project:roles": "...same 12 roles..."
  }
}
```

### A.5 Histórico de validação

| Run | Data | Listener | Sessão | Resultado | Falsos positivos |
|---|---|---|---|---|---|
| 1 | 2026-05-04 03:00–03:08 BRT | one-shot ingênuo | suja (cookie ativo) | 9 ✅ / 2 🔴 / 7 🟡 | F1 (PKCE), F2 (refresh), A5 (nonce) |
| 2 | 2026-05-04 04:10–04:20 BRT | multi-hit defensivo | limpa (anônima + `prompt=login`) | 14 ✅ / 0 🔴 / 5 🟡 | nenhum |

Run 2 confirmou que F1/F2/A5 do Run 1 eram artefatos da metodologia (listener naive + sessão com cookie). Configuração do Zitadel está correta.

---

## Mudanças neste documento

| Versão | Data | Autor | Mudanças |
|---|---|---|---|
| 1.0 | 2026-05-04 | Tech Lead | Versão inicial consolidada após validação Run 1 + Run 2 |

---

**Fim do relatório.**