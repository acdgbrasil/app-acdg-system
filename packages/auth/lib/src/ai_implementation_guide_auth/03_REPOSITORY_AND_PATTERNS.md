# 03 - REPOSITORY, ERROR HANDLING & PATTERNS

> Repository como ponte entre UI e services, padroes transversais, contrato de testes.

---

## 1. AuthRepository (Abstract)

### Definicao

```dart
abstract class AuthRepository extends Listenable {
  Stream<AuthStatus> get statusStream;
  AuthStatus get currentStatus;
  AuthUser? get currentUser;
  AuthToken? get currentToken;

  Future<Result<void>> login();
  Future<Result<void>> logout();
  Future<Result<void>> tryRestoreSession();
  Future<void> init();
  void dispose();
}
```

**Nota:** Extende `Listenable` (nao `ChangeNotifier`) para permitir que a UI escute mudancas sem acoplar com a implementacao.

### Diferenca do AuthService

| Aspecto | AuthService | AuthRepository |
|---------|-------------|----------------|
| Retorno | `Future<void>` (throws) | `Future<Result<void>>` (never throws) |
| Heranca | — | `Listenable` (UI pode escutar) |
| Erro | Exception propagada | `Failure(exception)` wrappada |
| Log | Interno ao service | Logging adicional no repository |

---

## 2. AuthRepositoryImpl (Implementacao)

### Definicao

```dart
class AuthRepositoryImpl extends ChangeNotifier implements AuthRepository {
  AuthRepositoryImpl({required AuthService authService})
    : _authService = authService {
    _statusSubscription = _authService.statusStream.listen(
      (_) => notifyListeners(),
    );
  }

  static final _log = AcdgLogger.get('AuthRepository');
  final AuthService _authService;
  late final StreamSubscription<AuthStatus> _statusSubscription;
}
```

### Padrao de Bridge (Service → Repository)

Cada metodo wrapa o service em try-catch e retorna `Result<void>`:

```dart
@override
Future<void> init() => _authService.init();

@override
Stream<AuthStatus> get statusStream => _authService.statusStream;

@override
AuthStatus get currentStatus => _authService.currentStatus;

@override
AuthUser? get currentUser => _authService.currentUser;

@override
AuthToken? get currentToken => _authService.currentToken;
```

### login()

```dart
@override
Future<Result<void>> login() async {
  try {
    await _authService.login();
    return const Success(null);
  } catch (e, st) {
    _log.severe('Login failed', e, st);
    return Failure(e);
  }
}
```

### logout()

```dart
@override
Future<Result<void>> logout() async {
  try {
    await _authService.logout();
    return const Success(null);
  } catch (e, st) {
    _log.severe('Logout failed', e, st);
    return Failure(e);
  }
}
```

### tryRestoreSession()

```dart
@override
Future<Result<void>> tryRestoreSession() async {
  try {
    await _authService.tryRestoreSession();
    return const Success(null);
  } catch (e, st) {
    _log.severe('Session restore failed', e, st);
    return Failure(e);
  }
}
```

### dispose()

```dart
@override
void dispose() {
  _statusSubscription.cancel();
  super.dispose();
}
```

### ChangeNotifier Bridge

O construtor subscreve no `statusStream` do service e chama `notifyListeners()` para cada evento:

```dart
_statusSubscription = _authService.statusStream.listen(
  (_) => notifyListeners(),
);
```

**Isso permite:**
- GoRouter usar `refreshListenable: authRepository` para redirect
- Provider/Riverpod escutar mudancas do repository
- Widgets reconstruirem via `ListenableBuilder`

---

## 3. ERROR HANDLING

### Hierarquia de Erros

```
AuthService (throws exceptions)
     │
     ▼
AuthRepository (catches → Result<void>)
     │
     ▼
UI (pattern match Result)
```

### No AuthService

Cada implementacao lida com erros internamente:

**OidcAuthService:**
- Claims parsing error → `AuthError('Erro ao ler dados do usuario: $e')`
- Login error → `AuthError('Falha ao fazer login: $e')`
- Refresh error → `AuthError('Falha ao renovar token: $e')`
- Logout error → ignorado (try/finally garante cleanup)

**BffAuthService:**
- Restore session (non-200) → `Unauthenticated`
- Restore session (exception) → `Unauthenticated`
- Logout (exception) → warning log, limpa sessao
- Refresh (non-200 ou exception) → `Unauthenticated`

### No AuthRepository

```dart
try {
  await _authService.login();
  return const Success(null);
} catch (e, st) {
  _log.severe('Login failed', e, st);
  return Failure(e);
}
```

- **Nunca propaga exceptions** para a UI
- Sempre retorna `Result<void>`
- Loga com `_log.severe` incluindo stack trace

### Na UI

```dart
final result = await authRepository.login();
switch (result) {
  case Success():
    // sucesso, status ja atualizado via stream
  case Failure(:final error):
    // mostrar mensagem de erro
}
```

---

## 4. PADROES TRANSVERSAIS

### 4.1 Sealed Classes para Estado

```dart
sealed class AuthStatus with Equatable { ... }
```

- **Exaustividade:** `switch` garante todos os casos cobertos
- **Imutabilidade:** todos os subtipos sao `final class` com `const` constructor
- **Igualdade:** via Equatable (por conteudo, nao referencia)

### 4.2 ValueGetter para copyWith Nullable

```dart
AuthToken copyWith({
  String? Function()? refreshToken,  // nullable ValueGetter
}) {
  return AuthToken(
    refreshToken: refreshToken != null ? refreshToken() : this.refreshToken,
  );
}
```

Usado em: `AuthToken.copyWith()`, `AuthUser.copyWith()`

**Regra:** Campos `String?` usam `String? Function()?`. Campos `String` usam `String?`.

### 4.3 Injectable Time

```dart
bool isExpired({DateTime? now}) =>
    (now ?? DateTime.now()).isAfter(expiresAt);
```

- Parametro `now` permite testes deterministicos
- Default e `DateTime.now()` para uso em producao

Usado em: `AuthToken.isExpired()`, `AuthToken.expiresWithin()`

### 4.4 Broadcast Streams

```dart
final StreamController<AuthStatus> _statusController =
    StreamController<AuthStatus>.broadcast();
```

- **Broadcast:** multiplos listeners (GoRouter, Provider, widgets)
- Cada service cria seu proprio StreamController
- Repository forwarda o stream do service + notifyListeners

### 4.5 Idempotent Init

```dart
Future<void> init() async {
  if (_initialized) return;
  // ... setup
  _initialized = true;
}
```

Usado em: `OidcAuthService.init()`, `BffAuthService.init()`

### 4.6 Non-Fatal Logout

```dart
try {
  await _manager.logout();
} catch (e) {
  // ignorar
} finally {
  _clearSession();  // SEMPRE limpa
}
```

- Logout de rede pode falhar (server down, timeout)
- Estado local DEVE ser limpo independente do resultado
- `finally` garante cleanup

### 4.7 Centralized State Mutations

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

- Toda mutacao de estado passa por esses 3 metodos
- Garante consistencia (user+token+status sempre em sync)
- Facilita debugging (ponto unico de mudanca)

### 4.8 Stateless Parser Extraction

```dart
class OidcClaimsParser {
  const OidcClaimsParser._();  // nao instanciavel
  
  static AuthUser userFromClaims({...}) { ... }
  static AuthToken tokenFromRaw({...}) { ... }
}
```

- Funcoes puras extraidas do service
- Testavel sem OIDC manager
- Sem estado, sem side effects

### 4.9 AcdgLogger

```dart
static final _log = AcdgLogger.get('BffAuthService');

_log.info('message');
_log.warning('message', error, stackTrace);
_log.severe('message', error, stackTrace);
```

- Logger hierarquico (do core package)
- Cada classe tem seu proprio logger com nome identificador
- 3 niveis: info, warning, severe

---

## 5. CONTRATO DE TESTES (85 testes)

### Models (4 arquivos)

#### auth_role_test.dart
- Valores corretos de string para cada enum
- `fromString`: resolve conhecidos, null para desconhecidos
- `fromJwtClaim`: extrai roles, ignora desconhecidos, null/empty handling

#### auth_status_test.dart
- 4 subtipos: Authenticated, Unauthenticated, AuthLoading, AuthError
- Igualdade por conteudo (Equatable)
- Pattern matching exaustivo
- Subtipos diferentes nunca iguais
- toString correto para cada subtipo

#### auth_token_test.dart
- Armazena todos os campos corretamente
- `isExpired(now?)`: testavel com tempo injetavel
- `expiresWithin(threshold, now?)`: testavel
- `copyWith` com ValueGetter (limpar nullable, definir novo valor)
- toString NAO expoe tokens

#### auth_user_test.dart
- `displayName` fallback chain: name → preferredUsername → email → id
- `hasRole`, `hasAnyRole`: lookup correto em Set
- `canWrite`: true apenas para socialWorker
- `canRead`: true se roles nao vazio
- `copyWith` com ValueGetter
- Igualdade por todos os campos

### Services (6 arquivos)

#### bff_auth_service_test.dart (Full Coverage)
- `init`: seta Unauthenticated, idempotente
- `loginUrl`: retorna `{base}/auth/login`
- `tryRestoreSession`: 200→Authenticated, 401→Unauthenticated, exception→Unauthenticated
- `logout`: POST /auth/logout, seta Unauthenticated, limpa user
- `refreshToken`: POST /auth/refresh, 500→Unauthenticated
- `currentToken`: sempre null
- `statusStream`: emite mudancas, done apos dispose

#### oidc_auth_config_test.dart
- Armazena issuer, clientId, redirectUri, postLogoutRedirectUri
- Default scopes (5 entries)
- Custom scopes override
- Discovery URI construido corretamente
- Trailing slash removido do issuer

#### oidc_auth_service_test.dart
- Instanciacao com config
- Estado inicial: AuthLoading
- statusStream e Stream<AuthStatus>

#### oidc_auth_service_login_test.dart (Stubs/TODOs)
- Emite AuthLoading no inicio do login
- Sucesso emite Authenticated
- Cancelamento emite Unauthenticated
- Erro de rede emite AuthError
- Limpa user/token em falha

#### oidc_auth_service_logout_test.dart (Stubs/TODOs)
- Logout limpa user, token, emite Unauthenticated
- Erro de rede NAO impede cleanup (try/finally)
- Logout de estado nao-autenticado e no-op

#### oidc_auth_service_session_test.dart (Stubs/TODOs)
- Restore emite Authenticated quando cache existe
- Restore emite Unauthenticated quando cache vazio
- Refresh atualiza token e emite Authenticated
- Refresh null → Unauthenticated
- Refresh erro → AuthError

#### oidc_parsers_test.dart (Full Coverage)
- Extrai todos os campos de claims completos
- Fallback uid → sub → '' (empty)
- Roles claim ausente → empty set
- Roles claim tipo errado → empty set
- Claims opcionais null → fields null
- Roles desconhecidas ignoradas
- Token com todos os campos
- Token com refreshToken null (web)
- Token com expiresAt null → DateTime.now()
- Token expiracao correta (isExpired)

### Fixtures de Teste

**AuthUser de teste:**
```dart
AuthUser(
  id: '123',
  name: 'Maria Silva',
  email: 'maria@acdg.com.br',
  preferredUsername: 'maria.silva',
  roles: {AuthRole.socialWorker},
)
```

**JWT Claims de teste:**
```dart
{
  'sub': 'sub-456',
  'name': 'Maria Silva',
  'email': 'maria@acdg.com.br',
  'preferred_username': 'maria.silva',
  'urn:zitadel:iam:org:project:roles': {
    'social_worker': {
      '363110312318140539': 'acdgbrasil.com.br',
    },
  },
}
```

**BFF Config de teste:**
```dart
BffAuthConfig(bffBaseUrl: 'http://localhost:8081')
```

**BFF Response de teste:**
```dart
{
  'userId': 'user-123',
  'roles': ['social_worker', 'admin'],
}
```

**OIDC Config de teste:**
```dart
OidcAuthConfig(
  issuer: Uri.parse('https://auth.example.com'),
  clientId: '123',
  redirectUri: Uri.parse('http://localhost:0'),
  postLogoutRedirectUri: Uri.parse('http://localhost:0'),
)
```

**MockHttpClient:**
```dart
class MockHttpClient extends http.BaseClient {
  late Future<http.Response> Function(http.BaseRequest) handler;
  http.BaseRequest? lastRequest;
  
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
    );
  }
}
```

---

## 6. INTEGRACAO COM O APP

### Como usar no Shell (app principal)

```dart
// 1. Criar config baseado na plataforma
final authService = kIsWeb
    ? BffAuthService(config: BffAuthConfig(bffBaseUrl: '/api'))
    : OidcAuthService(config: OidcAuthConfig(
        issuer: Uri.parse(env.oidcIssuer),
        clientId: env.oidcClientId,
        redirectUri: Uri.parse(env.oidcRedirectUri),
        postLogoutRedirectUri: Uri.parse(env.oidcPostLogoutUri),
      ));

// 2. Criar repository
final authRepository = AuthRepositoryImpl(authService: authService);

// 3. Inicializar
await authRepository.init();
await authRepository.tryRestoreSession();

// 4. Fornecer via Provider/Riverpod
ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(authRepository),
  ],
  child: MaterialApp.router(
    routerConfig: GoRouter(
      refreshListenable: authRepository,  // ChangeNotifier
      redirect: (context, state) {
        final status = authRepository.currentStatus;
        switch (status) {
          case Authenticated():
            if (state.matchedLocation == '/login') return '/';
            return null;
          case Unauthenticated():
            return '/login';
          case AuthLoading():
            return null; // nao redireciona durante loading
          case AuthError():
            return '/login';
        }
      },
      routes: [...],
    ),
  ),
);
```

### Como usar em HTTP Interceptor (Desktop)

```dart
class AuthInterceptor extends Interceptor {
  final AuthRepository _auth;
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _auth.currentToken;
    if (token != null && !token.isExpired()) {
      options.headers['Authorization'] = 'Bearer ${token.accessToken}';
    }
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final result = await _auth.tryRestoreSession();
      // retry request...
    }
    handler.next(err);
  }
}
```

### Como usar em HTTP Interceptor (Web)

```dart
// Web: NAO precisa de interceptor para tokens
// Cookies HttpOnly sao enviados automaticamente pelo browser
// Basta configurar withCredentials: true no Dio
```

---

## 7. BEST PRACTICES (Consolidadas do Handbook)

1. **Dart 3+ features:** `.firstOrNull`, `.nonNulls`, functional chains, `const {}`
2. **Equatable:** `with Equatable` em todos os data classes
3. **Imutabilidade:** `final class`, ValueGetter em copyWith
4. **Testabilidade:** Injectable time (`{DateTime? now}`)
5. **Contracts:** Interface abstrata expoe lifecycle completo
6. **State Management:** Mutacoes centralizadas (`_setAuthenticatedSession`, `_clearSession`)
7. **Separacao:** Parser stateless extraido do service
8. **Organizacao:** Pastas por dominio (models, services/bff, services/oidc)
9. **Coesao:** Um proposito por arquivo
10. **Testes:** Espelham estrutura de lib/src, separados por fluxo
