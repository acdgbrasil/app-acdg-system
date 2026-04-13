# 02 - SERVICES: AuthService, OidcAuthService, BffAuthService, OidcClaimsParser

> Dois services concretos, uma interface, um parser stateless. Cada plataforma usa um service diferente.

---

## 1. AuthService (Interface Abstrata)

### Definicao

```dart
abstract class AuthService {
  Future<void> init();
  Stream<AuthStatus> get statusStream;
  AuthStatus get currentStatus;
  AuthUser? get currentUser;
  AuthToken? get currentToken;
  
  Future<void> login();
  Future<void> logout();
  Future<void> tryRestoreSession();
  Future<void> refreshToken();
  void dispose();
}
```

### Contrato de Cada Metodo

| Metodo | Descricao | Quando Chamar |
|--------|-----------|---------------|
| `init()` | Inicializa o service (cria OIDC manager, configura cache). Deve ser chamado UMA vez antes dos outros. Idempotente. | App startup |
| `statusStream` | Stream broadcast de `AuthStatus`. Emite em login, logout, refresh, expiracao. Usado pelo GoRouter `refreshListenable`. | Sempre (listen) |
| `currentStatus` | Snapshot sincrono do estado de auth. Inicialmente `AuthLoading`. | Leitura imediata |
| `currentUser` | `null` se nao autenticado | Acessar dados do usuario |
| `currentToken` | `null` se nao autenticado. **Web BFF: sempre null** (tokens server-side) | Attach em HTTP headers |
| `login()` | Inicia fluxo OIDC Authorization Code + PKCE. Abre pagina do Zitadel. | Botao de login |
| `logout()` | Encerra sessao, revoga tokens. **Non-fatal:** erros de logout NAO impedem limpeza local. | Botao de logout |
| `tryRestoreSession()` | Tenta restaurar sessao (Desktop: secure storage. Web: cookie HttpOnly refresh). | App startup apos init |
| `refreshToken()` | Forca renovacao de token. Normalmente automatico, exposto para edge cases (ex: interceptor 401). | Interceptor HTTP |
| `dispose()` | Libera recursos (stream controllers, listeners, OIDC manager). | App shutdown |

### Implementacoes Conhecidas

| Implementacao | Plataforma | Package |
|---------------|-----------|---------|
| `OidcAuthService` | Desktop (macOS/Windows/Linux) | `package:oidc` |
| `BffAuthService` | Web | `package:http` + `url_launcher` |
| `FakeAuthService` | Testes | (externo, nao neste package) |

---

## 2. OidcAuthConfig (Configuracao Desktop)

### Definicao

```dart
final class OidcAuthConfig {
  const OidcAuthConfig({
    required this.issuer,
    required this.clientId,
    required this.redirectUri,
    required this.postLogoutRedirectUri,
    this.scopes = defaultScopes,
  });

  final Uri issuer;
  final String clientId;
  final Uri redirectUri;
  final Uri postLogoutRedirectUri;
  final List<String> scopes;
}
```

### Campos

| Campo | Tipo | Required | Exemplo |
|-------|------|----------|---------|
| `issuer` | `Uri` | Sim | `https://auth.acdgbrasil.com.br` |
| `clientId` | `String` | Sim | OIDC client ID registrado no Zitadel |
| `redirectUri` | `Uri` | Sim | Desktop: `http://localhost:0` (OS escolhe porta) |
| `postLogoutRedirectUri` | `Uri` | Sim | Desktop: `http://localhost:0` |
| `scopes` | `List<String>` | Nao | Default: `defaultScopes` |

### Default Scopes

```dart
static const defaultScopes = [
  'openid',                                    // ID token
  'profile',                                   // name, preferred_username
  'email',                                     // email
  'offline_access',                            // refresh token
  'urn:zitadel:iam:org:project:roles',         // roles claim
];
```

### Getter Computado

#### `discoveryDocumentUri → Uri`

```dart
Uri get discoveryDocumentUri => Uri.parse(
  '${issuer.toString().replaceAll(RegExp(r'/$'), '')}/.well-known/openid-configuration',
);
```

- Remove trailing slash do issuer antes de concatenar
- Resultado: `https://auth.acdgbrasil.com.br/.well-known/openid-configuration`

---

## 3. OidcAuthService (Implementacao Desktop)

### Definicao

```dart
class OidcAuthService implements AuthService {
  OidcAuthService({required OidcAuthConfig config}) : _config = config;

  static final _log = AcdgLogger.get('OidcAuthService');
  final OidcAuthConfig _config;
  late final OidcUserManager _manager;
  final StreamController<AuthStatus> _statusController =
      StreamController<AuthStatus>.broadcast();

  StreamSubscription<OidcUser?>? _userSubscription;
  AuthStatus _currentStatus = const AuthLoading();
  AuthUser? _currentUser;
  AuthToken? _currentToken;
  bool _initialized = false;
}
```

### Estado Inicial

| Propriedade | Valor Inicial |
|-------------|---------------|
| `_currentStatus` | `AuthLoading()` |
| `_currentUser` | `null` |
| `_currentToken` | `null` |
| `_initialized` | `false` |

### init()

```dart
Future<void> init() async {
  if (_initialized) return;  // idempotente
  
  _manager = OidcUserManager.lazy(
    discoveryDocumentUri: _config.discoveryDocumentUri,
    clientCredentials: OidcClientAuthentication.none(
      clientId: _config.clientId,
    ),
    store: OidcDefaultStore(),
    settings: OidcUserManagerSettings(
      redirectUri: _config.redirectUri,
      postLogoutRedirectUri: _config.postLogoutRedirectUri,
      scope: _config.scopes,
    ),
  );
  
  _userSubscription = _manager.userChanges().listen(_onUserChanged);
  await _manager.init();
  _initialized = true;
}
```

**Detalhes criticos:**
- `OidcUserManager.lazy()` — inicializacao preguicosa
- `OidcClientAuthentication.none()` — public client (sem secret)
- `OidcDefaultStore()` — persiste tokens via flutter_secure_storage
- Subscreve em `_manager.userChanges()` para updates automaticos
- `await _manager.init()` — carrega tokens do cache se existirem

### _onUserChanged(OidcUser? oidcUser)

Handler central que responde a mudancas do usuario OIDC:

```dart
void _onUserChanged(OidcUser? oidcUser) {
  if (oidcUser == null || oidcUser.token.accessToken == null) {
    _clearSession();
    return;
  }

  try {
    final claims = oidcUser.claims.toJson();
    final user = OidcClaimsParser.userFromClaims(
      uid: oidcUser.uid,
      claims: claims,
    );
    final token = OidcClaimsParser.tokenFromRaw(
      accessToken: oidcUser.token.accessToken!,
      refreshToken: oidcUser.token.refreshToken,
      idToken: oidcUser.token.idToken,
      expiresAt: oidcUser.token.calculateExpiresAt(),
    );
    _setAuthenticatedSession(user, token);
  } catch (e) {
    _clearSession();
    _updateStatus(AuthError('Erro ao ler dados do usuario: $e'));
  }
}
```

### login()

```dart
Future<void> login() async {
  _updateStatus(const AuthLoading());
  try {
    final user = await _manager.loginAuthorizationCodeFlow();
    if (user == null) {
      _clearSession();  // usuario cancelou
    }
    // Se user != null, _onUserChanged ja foi chamado pelo stream
  } catch (e) {
    _clearSession();
    _updateStatus(AuthError('Falha ao fazer login: $e'));
  }
}
```

**Fluxo:**
1. Emite `AuthLoading`
2. Abre browser/webview com pagina Zitadel
3. Usuario autentica
4. Redirect para `redirectUri`
5. `package:oidc` intercepta o callback
6. `_onUserChanged` e chamado automaticamente
7. Se cancelou ou erro → `Unauthenticated` ou `AuthError`

### logout()

```dart
Future<void> logout() async {
  try {
    await _manager.logout();
  } catch (e) {
    // Non-fatal: ignora erros de logout
  } finally {
    _clearSession();  // SEMPRE limpa, mesmo com erro
  }
}
```

**Garantia:** `finally` garante que sessao local e SEMPRE limpa.

### tryRestoreSession()

```dart
Future<void> tryRestoreSession() async {
  if (_manager.currentUser == null) {
    _clearSession();
  }
  // Se currentUser != null, _onUserChanged ja foi triggered no init
}
```

### refreshToken()

```dart
Future<void> refreshToken() async {
  try {
    final user = await _manager.refreshToken();
    if (user == null) {
      _clearSession();
    }
  } catch (e) {
    _updateStatus(AuthError('Falha ao renovar token: $e'));
  }
}
```

### Metodos Privados de Estado

```dart
void _setAuthenticatedSession(AuthUser user, AuthToken token) {
  _currentUser = user;
  _currentToken = token;
  _updateStatus(Authenticated(user));
}

void _clearSession() {
  _currentUser = null;
  _currentToken = null;
  _updateStatus(const Unauthenticated());
}

void _updateStatus(AuthStatus status) {
  _currentStatus = status;
  _statusController.add(status);
}
```

### dispose()

```dart
void dispose() {
  _userSubscription?.cancel();
  _manager.dispose();
  _statusController.close();
}
```

### Strings Hardcoded (PT-BR)

| Contexto | String |
|----------|--------|
| Erro ao parsear claims | `'Erro ao ler dados do usuario: $e'` |
| Erro no login | `'Falha ao fazer login: $e'` |
| Erro no refresh | `'Falha ao renovar token: $e'` |

### Log Messages (EN)

| Nivel | Mensagem |
|-------|----------|
| INFO | `'Initializing OIDC Manager for issuer: ${_config.issuer}'` |
| INFO | `'OIDC Manager initialized successfully'` |
| INFO | `'User changed: ${oidcUser?.uid ?? "null"}'` |
| INFO | `'Session authenticated for user: ${user.id}'` |
| INFO | `'Session cleared'` |
| INFO | `'Starting login flow...'` |
| INFO | `'Starting logout flow...'` |
| INFO | `'Attempting to restore session...'` |
| INFO | `'No session found to restore'` |
| INFO | `'Session found for user: ${uid}'` |
| INFO | `'Refreshing token...'` |
| WARNING | `'Login flow cancelled or returned null user'` |
| WARNING | `'Logout flow error (ignoring): $e'` |
| WARNING | `'Token refresh returned null user'` |
| SEVERE | `'Error parsing user claims: $e'` |
| SEVERE | `'Login flow error: $e'` |
| SEVERE | `'Token refresh error: $e'` |

---

## 4. BffAuthConfig (Configuracao Web)

### Definicao

```dart
class BffAuthConfig {
  const BffAuthConfig({required this.bffBaseUrl});
  final String bffBaseUrl;
}
```

| Campo | Tipo | Required | Exemplo |
|-------|------|----------|---------|
| `bffBaseUrl` | `String` | Sim | `'/api'` (same-origin) ou `'http://localhost:8081'` (dev) |

---

## 5. BffAuthService (Implementacao Web)

### Definicao

```dart
class BffAuthService implements AuthService {
  BffAuthService({required BffAuthConfig config, http.Client? httpClient})
    : _config = config,
      _httpClient = httpClient ?? http.Client();

  static final _log = AcdgLogger.get('BffAuthService');
  final BffAuthConfig _config;
  final http.Client _httpClient;
  final StreamController<AuthStatus> _statusController =
      StreamController<AuthStatus>.broadcast();

  AuthStatus _currentStatus = const AuthLoading();
  AuthUser? _currentUser;
  bool _initialized = false;
}
```

### Estado Inicial

| Propriedade | Valor Inicial |
|-------------|---------------|
| `_currentStatus` | `AuthLoading()` |
| `_currentUser` | `null` |
| `_initialized` | `false` |

### Diferenca Fundamental do OIDC

- **`currentToken` → SEMPRE `null`** (tokens gerenciados server-side via HttpOnly cookies)
- **Login:** redireciona browser para BFF (nao usa package:oidc)
- **Session:** verificada via HTTP GET ao BFF, nao via token local

### Endpoints BFF

| Metodo | Endpoint | HTTP Method | Descricao |
|--------|----------|-------------|-----------|
| `login()` | `/auth/login` | Browser redirect | Redireciona para Zitadel via BFF |
| `logout()` | `/auth/logout` | POST | Encerra sessao server-side |
| `tryRestoreSession()` | `/auth/me` | GET | Verifica sessao ativa |
| `refreshToken()` | `/auth/refresh` | POST | Renova tokens server-side |

### init()

```dart
Future<void> init() async {
  if (_initialized) return;
  _initialized = true;
  _updateStatus(const Unauthenticated());
}
```

**Diferenca:** Inicia como `Unauthenticated` (nao `AuthLoading` como OIDC). Nao ha cache local para verificar.

### login()

```dart
Future<void> login() async {
  _updateStatus(const AuthLoading());
  await launchUrl(
    Uri.parse(loginUrl),
    webOnlyWindowName: '_self',  // navega na mesma aba
  );
}

String get loginUrl => '${_config.bffBaseUrl}/auth/login';
```

**Fluxo Web completo:**
1. App chama `login()`
2. Browser navega para `{bffBaseUrl}/auth/login`
3. BFF redireciona para Zitadel
4. Usuario autentica no Zitadel
5. Zitadel redireciona para BFF callback
6. BFF troca code por tokens, seta session cookie HttpOnly
7. BFF redireciona browser para `/` (app root)
8. App recarrega, chama `tryRestoreSession()`
9. GET `/auth/me` retorna dados do usuario → `Authenticated`

### tryRestoreSession()

```dart
Future<void> tryRestoreSession() async {
  try {
    final response = await _httpClient.get(
      Uri.parse('${_config.bffBaseUrl}/auth/me'),
    );
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final userId = json['userId'] as String;
      final rolesList = (json['roles'] as List<dynamic>).cast<String>();
      final roles = rolesList
          .map(AuthRole.fromString)
          .whereType<AuthRole>()
          .toSet();
      
      _currentUser = AuthUser(id: userId, roles: roles);
      _updateStatus(Authenticated(_currentUser!));
    } else {
      _clearSession();
    }
  } catch (e, st) {
    _log.severe('Session restore failed', e, st);
    _clearSession();
  }
}
```

**Response JSON esperado (200):**

```json
{
  "userId": "user-123",
  "roles": ["social_worker", "admin"]
}
```

**Response nao-200 (401, 403, etc.):** → `Unauthenticated`

### logout()

```dart
Future<void> logout() async {
  try {
    await _httpClient.post(
      Uri.parse('${_config.bffBaseUrl}/auth/logout'),
    );
  } catch (e, st) {
    _log.warning('Logout request failed (best-effort)', e, st);
  }
  _clearSession();  // SEMPRE limpa, mesmo com erro
}
```

### refreshToken()

```dart
Future<void> refreshToken() async {
  try {
    final response = await _httpClient.post(
      Uri.parse('${_config.bffBaseUrl}/auth/refresh'),
    );
    if (response.statusCode != 200) {
      _clearSession();
    }
  } catch (e, st) {
    _log.severe('Token refresh failed', e, st);
    _clearSession();
  }
}
```

### Metodos Privados

```dart
void _updateStatus(AuthStatus status) {
  _currentStatus = status;
  _statusController.add(status);
}

void _clearSession() {
  _currentUser = null;
  _updateStatus(const Unauthenticated());
}
```

### dispose()

```dart
void dispose() {
  _statusController.close();
}
```

---

## 6. OidcClaimsParser (Pure Functions)

### Definicao

```dart
class OidcClaimsParser {
  const OidcClaimsParser._();  // Nao instanciavel
}
```

**Proposito:** Funcoes puras extraidas do OidcAuthService para testabilidade sem inicializar OidcUserManager.

### userFromClaims()

```dart
static AuthUser userFromClaims({
  required String? uid,
  required Map<String, dynamic> claims,
}) {
  final rolesMap = claims['urn:zitadel:iam:org:project:roles'];
  
  return AuthUser(
    id: uid ?? claims['sub'] as String? ?? '',
    name: claims['name'] as String?,
    email: claims['email'] as String?,
    preferredUsername: claims['preferred_username'] as String?,
    roles: AuthRole.fromJwtClaim(
      rolesMap is Map<String, dynamic> ? rolesMap : null,
    ),
  );
}
```

**Mapeamento de Claims:**

| Campo AuthUser | Claim OIDC | Fallback |
|----------------|-----------|----------|
| `id` | `uid` (param) | `claims['sub']` → `''` |
| `name` | `claims['name']` | `null` |
| `email` | `claims['email']` | `null` |
| `preferredUsername` | `claims['preferred_username']` | `null` |
| `roles` | `claims['urn:zitadel:iam:org:project:roles']` | `const {}` |

**Fallback chain do ID:** `uid` → `claims['sub']` → `''` (empty string)

**Defensividade:**
- Se `rolesMap` nao e `Map<String, dynamic>`, passa `null` para `fromJwtClaim`
- Claims opcionais retornam `null` naturalmente
- Nao lanca exception (seguro para chamar com claims incompletos)

### tokenFromRaw()

```dart
static AuthToken tokenFromRaw({
  required String accessToken,
  String? refreshToken,
  String? idToken,
  DateTime? expiresAt,
}) {
  return AuthToken(
    accessToken: accessToken,
    refreshToken: refreshToken,
    idToken: idToken,
    expiresAt: expiresAt ?? DateTime.now(),
  );
}
```

**Fallback:** Se `expiresAt` nao fornecido, usa `DateTime.now()` (token ja "expirado").

---

## 7. COMPARACAO OIDC vs BFF

| Aspecto | OidcAuthService | BffAuthService |
|---------|----------------|----------------|
| **Plataforma** | Desktop | Web |
| **Package** | `oidc` + `oidc_default_store` | `http` + `url_launcher` |
| **Token storage** | flutter_secure_storage | HttpOnly cookie (server) |
| **currentToken** | AuthToken (acessivel) | SEMPRE `null` |
| **Login flow** | `_manager.loginAuthorizationCodeFlow()` | `launchUrl(loginUrl)` |
| **Session restore** | `_manager.currentUser` check | GET `/auth/me` |
| **Auto-refresh** | `_manager.userChanges()` stream | Manual via `/auth/refresh` |
| **User data source** | JWT claims (local) | BFF response JSON |
| **Init status** | `AuthLoading` | `Unauthenticated` |
| **Client type** | Public (PKCE) | Confidential (server-side) |
| **Error strings** | PT-BR (3 strings) | — (apenas logs EN) |

---

## 8. FLUXOS DE AUTENTICACAO

### Desktop (OidcAuthService)

```
1. App inicia
2. init() → cria OidcUserManager, subscreve userChanges
3. _manager.init() → carrega tokens do Keychain
4. Se encontrou token valido:
   4a. _onUserChanged(oidcUser) → parseia claims → Authenticated
5. Se nao encontrou:
   5a. _onUserChanged(null) → Unauthenticated
6. Usuario clica Login:
   6a. login() → AuthLoading
   6b. _manager.loginAuthorizationCodeFlow()
   6c. Browser abre pagina Zitadel
   6d. Usuario autentica
   6e. Callback interceptado pelo package:oidc
   6f. _onUserChanged(user) → Authenticated
7. Usuario clica Logout:
   7a. logout() → _manager.logout() → _clearSession() → Unauthenticated
```

### Web (BffAuthService)

```
1. App inicia
2. init() → Unauthenticated
3. tryRestoreSession() → GET /auth/me
4. Se 200 com userId+roles:
   4a. Cria AuthUser → Authenticated
5. Se 401 ou erro:
   5a. Unauthenticated
6. Usuario clica Login:
   6a. login() → AuthLoading
   6b. launchUrl('/auth/login') → browser navega
   6c. BFF redireciona para Zitadel
   6d. Usuario autentica
   6e. Zitadel callback → BFF → session cookie → redirect /
   6f. App recarrega → tryRestoreSession() → Authenticated
7. Usuario clica Logout:
   7a. logout() → POST /auth/logout → _clearSession() → Unauthenticated
```
