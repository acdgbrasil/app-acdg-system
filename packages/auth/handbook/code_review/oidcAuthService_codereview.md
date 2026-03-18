Sua intuição está corretíssima! O método `_onUserChanged` está atuando como um "faz-tudo": ele escuta o evento, faz o *parsing* (conversão) dos dados do JWT, cria os objetos de domínio e gerencia o estado da classe. Isso fere o Princípio da Responsabilidade Única (SRP) e torna o código mais difícil de testar e debugar.

Podemos desmembrar essa lógica em funções **atômicas e puras** (que apenas transformam dados de A para B) e criar métodos auxiliares para garantir que as variáveis de estado (`_currentUser`, `_currentToken`, `_currentStatus`) nunca fiquem dessincronizadas.

Aqui está a versão refatorada focada em **previsibilidade e separação de responsabilidades**:

```dart
import 'dart:async';

import 'package:oidc/oidc.dart';
import 'package:oidc_default_store/oidc_default_store.dart';

import 'auth_role.dart';
import 'auth_service.dart';
import 'auth_status.dart';
import 'auth_token.dart';
import 'auth_user.dart';
import 'oidc_auth_config.dart';

/// Production [AuthService] backed by `package:oidc` (Bdaya-Dev).
///
/// Connects to Zitadel via OIDC Authorization Code + PKCE.
/// Manages the full auth lifecycle: login, logout, token refresh,
/// session restore, and auth state broadcasting.
class OidcAuthService implements AuthService {
  OidcAuthService({required OidcAuthConfig config}) : _config = config;

  final OidcAuthConfig _config;
  late final OidcUserManager _manager;
  final StreamController<AuthStatus> _statusController =
      StreamController<AuthStatus>.broadcast();

  StreamSubscription<OidcUser?>? _userSubscription;
  
  AuthStatus _currentStatus = const AuthLoading();
  AuthUser? _currentUser;
  AuthToken? _currentToken;
  bool _initialized = false;

  /// Initializes the OIDC manager. Must be called before any other method.
  Future<void> init() async {
    if (_initialized) return;

    _manager = OidcUserManager.lazy(
      discoveryDocumentUri: _config.discoveryDocumentUri,
      clientCredentials:
          OidcClientAuthentication.none(clientId: _config.clientId),
      store: OidcDefaultStore(),
      settings: OidcUserManagerSettings(
        redirectUri: _config.redirectUri,
        postLogoutRedirectUri: _config.postLogoutRedirectUri,
        scope: _config.scopes,
        strictJwtVerification: false,
      ),
    );

    _userSubscription = _manager.userChanges().listen(_onUserChanged);

    await _manager.init();
    _initialized = true;
  }

  // ---------- OIDC Event Handling ----------

  void _onUserChanged(OidcUser? oidcUser) {
    // Falha rápida: Se não há usuário ou não há access token real, limpe a sessão.
    if (oidcUser == null || oidcUser.token.accessToken == null) {
      _clearSession();
      return;
    }

    try {
      final user = _parseAuthUser(oidcUser);
      final token = _parseAuthToken(oidcUser.token);
      _setAuthenticatedSession(user, token);
    } catch (e) {
      // Evita crashar o app caso os claims venham malformados
      _clearSession();
      _updateStatus(AuthError('Erro ao ler dados do usuário: $e'));
    }
  }

  // ---------- Atomic Parsers (Puros) ----------

  AuthUser _parseAuthUser(OidcUser oidcUser) {
    final claims = oidcUser.claims.toJson();
    final rolesMap = claims['urn:zitadel:iam:org:project:roles'];

    return AuthUser(
      id: oidcUser.uid ?? claims['sub'] as String? ?? '',
      name: claims['name'] as String?,
      email: claims['email'] as String?,
      preferredUsername: claims['preferred_username'] as String?,
      roles: AuthRole.fromJwtClaim(
        rolesMap is Map<String, dynamic> ? rolesMap : null,
      ),
    );
  }

  AuthToken _parseAuthToken(OidcToken token) {
    return AuthToken(
      accessToken: token.accessToken!, // Seguro pois checamos null no _onUserChanged
      refreshToken: token.refreshToken,
      idToken: token.idToken,
      expiresAt: token.calculateExpiresAt() ?? DateTime.now(),
    );
  }

  // ---------- Predictable State Mutations ----------

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

  // ---------- AuthService contract ----------

  @override
  Stream<AuthStatus> get statusStream => _statusController.stream;

  @override
  AuthStatus get currentStatus => _currentStatus;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  AuthToken? get currentToken => _currentToken;

  @override
  Future<void> login() async {
    _updateStatus(const AuthLoading());
    try {
      final user = await _manager.loginAuthorizationCodeFlow();
      if (user == null) {
        _clearSession();
      }
    } catch (e) {
      _clearSession();
      _updateStatus(AuthError('Falha ao fazer login: $e'));
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _manager.logout();
    } catch (_) {
      // Ignora o erro da lib, mas garante que o app deslogue localmente
    } finally {
      _clearSession();
    }
  }

  @override
  Future<void> tryRestoreSession() async {
    if (_manager.currentUser == null) {
      _clearSession();
    }
  }

  @override
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

  @override
  void dispose() {
    _userSubscription?.cancel();
    _manager.dispose();
    _statusController.close();
  }
}

```

### O que melhorou nesta refatoração?

* **Extração de Parsers (`_parseAuthUser` e `_parseAuthToken`):** Agora o método `_onUserChanged` é apenas um "orquestrador" (ele decide *o que* fazer, e não *como* fazer). As regras de como extrair dados do JWT estão isoladas. Se no futuro o Zitadel mudar a estrutura do token, você altera apenas os parsers.
* **Segurança contra Access Token Inválido:** No seu código original, havia `accessToken: token.accessToken ?? ''`. Passar uma string vazia para as APIs como Bearer token inevitavelmente causará erros 401. Agora, adicionamos uma barreira no `_onUserChanged`: se `accessToken == null`, tratamos o usuário como deslogado imediatamente.
* **Mutações Sincronizadas (`_clearSession` e `_setAuthenticatedSession`):** Centralizamos a alteração das três variáveis (`_currentUser`, `_currentToken` e estado). Isso elimina a possibilidade de existir um "estado zumbi" no seu app (exemplo: o estado ser `Unauthenticated`, mas o `_currentUser` ainda estar preenchido em memória porque alguém esqueceu de anulá-lo).
* **Tratamento de Exceções Mais Seguro:** O bloco `try...finally` no `logout()` garante que as credenciais locais sempre serão limpas, mesmo se a chamada de rede para deslogar no Zitadel falhar por falta de internet.
