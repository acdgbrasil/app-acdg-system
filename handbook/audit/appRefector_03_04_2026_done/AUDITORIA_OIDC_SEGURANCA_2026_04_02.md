# Auditoria Arquitetural Detalhada — Segurança e Ciclo de Vida OIDC
**Data:** 02 de Abril de 2026
**Especialista:** flutter-arch-review (Gemini CLI)

Esta auditoria concentrou-se na camada de autenticação do projeto, englobando o gerenciamento de estado do `AuthViewModel`, as regras de roteamento do `GoRouter`, a implementação do OIDC (Zitadel) e o ciclo de vida dos tokens de segurança.

A principal preocupação era de que a reatividade redundante no `AuthViewModel` estivesse causando múltiplos disparos no `GoRouter`, bem como potenciais riscos de expiração silenciosa de sessão (token refresh).

---

## 1. Problemas Críticos e Anti-padrões Identificados

### 1.1. Reatividade Redundante Extrema (`AuthViewModel` + `GoRouter`)
**Arquivos afetados:**
- `apps/acdg_system/lib/ui/view_models/auth_view_model.dart`
- `apps/acdg_system/lib/logic/router/app_router.dart`

**🚫 Anti-padrão:**
O `AuthViewModel` herda de `BaseViewModel` (que é um `ChangeNotifier`). No entanto, ele declara internamente `ValueNotifier<AuthStatus> status` e `ValueNotifier<AuthUser?> user`. 
No método `_onStatusChanged`, ele atualiza os valores dos `ValueNotifiers` **E** chama `notifyListeners()`. 

O `GoRouter` (`app_router.dart`) está configurado com `refreshListenable: authViewModel`. 
Como resultado:
1. O repositório emite um novo status via Stream.
2. O `AuthViewModel` recebe, altera os `ValueNotifiers` (disparando os listeners deles).
3. O `AuthViewModel` chama `notifyListeners()` (disparando o listener do GoRouter).
4. A UI pode reagir de 2 a 3 vezes para uma única mudança de estado, causando *flickering*, navegações abortadas ou loops no `_globalRedirect`.

**✅ O Padrão Correto:**
- **Ação:** Eliminar completamente os `ValueNotifier` do `AuthViewModel`.
- O estado de autenticação deve ser armazenado em variáveis privadas:
  ```dart
  AuthStatus _status = const AuthLoading();
  AuthStatus get status => _status;
  ```
- No `_onStatusChanged`, atualiza-se a variável `_status` e chama-se apenas `notifyListeners()`. O `GoRouter` (como `refreshListenable`) lidará com o resto.

### 1.2. Omissão de Auto-Refresh de Tokens (Sessões Expirando)
**Arquivo afetado:** `packages/auth/lib/src/services/oidc/oidc_auth_service.dart`

**🚫 Anti-padrão / Risco de Segurança:**
A biblioteca `oidc` (Bdaya-Dev) lida com PKCE e armazena os tokens no `OidcDefaultStore` (que usa `flutter_secure_storage`, portanto, a criptografia "at-rest" está correta e segura).
Entretanto, não há nenhuma configuração visível de auto-refresh no `OidcAuthService` ou interceptors injetados no cliente HTTP (Dio/BFF) que garanta que o `accessToken` seja renovado automaticamente antes de expirar. Existe um método `refreshToken()` no serviço, mas ele só é chamado se engatilhado manualmente.
Se o usuário ficar com o aplicativo aberto além do tempo de vida (TTL) do token JWT, as requisições ao BFF começarão a falhar com `401 Unauthorized`.

**✅ O Padrão Correto:**
- O pacote `oidc` normalmente permite configurar a renovação silenciosa no `OidcUserManagerSettings` (ou requer o uso de um interceptor no Dio).
- **Ação:** Adicionar um mecanismo que escute a expiração do token (ou dispare proativamente quando o TTL estiver próximo) para invocar silenciosamente o `refreshToken()` do manager. Alternativamente, criar um interceptor HTTP global em `package:network` que intercepte erros 401 e peça ao `AuthRepository` para tentar o refresh antes de jogar o usuário para a tela de Login.

### 1.3. RestoreSession incompleto e Side-Effects
**Arquivo afetado:** `packages/auth/lib/src/services/oidc/oidc_auth_service.dart`

**🚫 Anti-padrão:**
O método `tryRestoreSession()` apenas faz um `if (_manager.currentUser == null)` e loga se achou a sessão. Ele depende do fluxo reativo (`_userSubscription = _manager.userChanges().listen(...)`) engatilhado no `init()` para magicamente propagar a sessão.
Embora funcione tecnicamente (devido à reatividade do pacote `oidc`), o comando `restoreSession` do `AuthViewModel` vai "completar" antes mesmo da stream emitir o status real de `Authenticated`, porque o `tryRestoreSession()` retorna `Success` instantaneamente sem aguardar a resolução do parsing das *Claims*.

**✅ O Padrão Correto:**
- O `tryRestoreSession` deve aguardar (await) a confirmação do parse do token guardado antes de retornar sucesso, garantindo que o `GoRouter` não jogue o usuário pro Login de forma precipitada enquanto o token está sendo lido da memória segura.

---

## 2. Pontos Positivos Encontrados

🟢 **Armazenamento Seguro:** A escolha do `OidcDefaultStore` delega a guarda dos tokens a meios nativos de segurança (Keychain no iOS / EncryptedSharedPreferences no Android). **Não há vazamento de chaves ou tokens hardcoded em memória não volátil insegura.**

🟢 **Roteamento Global Seguro:** A lógica do `_globalRedirect` no `AppRouter` está muito robusta. Ela captura adequadamente a máquina de estados (`AuthLoading -> Splash`, `Unauthenticated -> Login`, `Authenticated -> Home`), bloqueando de forma segura qualquer rota sem autorização.

---

## 3. Plano de Ação Recomendado

1. **Refatorar o `AuthViewModel` imediatamente:**
   - Remover os `ValueNotifiers`.
   - Manter a herança de `BaseViewModel` (`ChangeNotifier`).
   - Isso interromperá os múltiplos disparos da árvore de roteamento e tornará o ciclo de login/logout 100% determinístico.

2. **Implementar Token Interceptor (ou Auto-refresh):**
   - Investigar a documentação do `package:oidc` sobre como ativar o background silent refresh (ex: `autoRefresh: true` nos settings, se suportado pela lib).
   - Alternativamente (e recomendado pela ACDG), adicionar um interceptor no Dio do BFF que ao receber 401, pause a fila de requisições, chame `AuthRepository.refreshToken()`, e re-tente os requests falhos.

3. **Sincronizar Splash Screen com o Restore Session:**
   - O `AppRouter` começa na `/` (Splash). A Splash só deve sair de lá quando o estado mudar de `AuthLoading` para `Authenticated` ou `Unauthenticated`.
   - Garantir que o `_manager.init()` só dissipe o estado final de usuário quando a inicialização e parse de claims estiverem concluídos.