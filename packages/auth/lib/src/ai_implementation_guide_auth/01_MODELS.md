# 01 - MODELS: AuthRole, AuthStatus, AuthToken, AuthUser

> Todos os models sao imutaveis, usam `Equatable` (via core), e seguem o padrao `final class` do Dart 3.

---

## 1. AuthRole (Enum)

### Definicao

```dart
enum AuthRole {
  socialWorker('social_worker'),
  owner('owner'),
  admin('admin');

  const AuthRole(this.value);
  final String value;
}
```

### Valores

| Enum Value | JWT String | Descricao |
|------------|-----------|-----------|
| `socialWorker` | `'social_worker'` | CRUD completo em todos os modulos social-care |
| `owner` | `'owner'` | Acesso read-only aos dados social-care |
| `admin` | `'admin'` | Read social-care + area administrativa |

### Metodos

#### `fromString(String value) → AuthRole?`

Resolve role a partir da string JWT. Retorna `null` se desconhecido.

```dart
static AuthRole? fromString(String value) {
  return AuthRole.values.where((r) => r.value == value).firstOrNull;
}
```

**Comportamento:**
- `fromString('social_worker')` → `AuthRole.socialWorker`
- `fromString('owner')` → `AuthRole.owner`
- `fromString('admin')` → `AuthRole.admin`
- `fromString('superuser')` → `null`
- `fromString('')` → `null`

> **Nota:** Usa `.firstOrNull` (Dart 3) ao inves de `byName()` para evitar exception em valores desconhecidos.

#### `fromJwtClaim(Map<String, dynamic>? claim) → Set<AuthRole>`

Extrai roles do claim JWT do Zitadel.

```dart
static Set<AuthRole> fromJwtClaim(Map<String, dynamic>? claim) {
  if (claim == null) return const {};
  return claim.keys
      .map(AuthRole.fromString)
      .nonNulls
      .toSet();
}
```

**Formato do claim Zitadel:**

```json
{
  "urn:zitadel:iam:org:project:roles": {
    "social_worker": {
      "363110312318140539": "acdgbrasil.com.br"
    },
    "admin": {
      "363110312318140539": "acdgbrasil.com.br"
    }
  }
}
```

**Comportamento:**
- Extrai apenas as **outer keys** (`social_worker`, `admin`) — ignora inner map
- Roles desconhecidas sao silenciosamente ignoradas (`.nonNulls`)
- `null` claim → `const {}` (empty set, const para eficiencia)
- Claim vazio `{}` → `const {}`
- Claim com role desconhecida `{'superuser': {...}}` → `{}`

### Claim Path

```
urn:zitadel:iam:org:project:roles
```

Esse path e usado em:
- `AuthRole.fromJwtClaim()` (extrai roles)
- `OidcClaimsParser.userFromClaims()` (le do JWT claims map)
- `OidcAuthConfig.defaultScopes` (solicita o claim no OIDC flow)

---

## 2. AuthStatus (Sealed Class)

### Definicao

```dart
sealed class AuthStatus with Equatable {
  const AuthStatus();
}
```

### Subtipos

#### Authenticated

```dart
final class Authenticated extends AuthStatus {
  const Authenticated(this.user);
  final AuthUser user;

  @override
  List<Object?> get props => [user];

  @override
  String toString() => 'Authenticated(${user.displayName})';
}
```

#### Unauthenticated

```dart
final class Unauthenticated extends AuthStatus {
  const Unauthenticated();

  @override
  List<Object?> get props => [];

  @override
  String toString() => 'Unauthenticated';
}
```

#### AuthLoading

```dart
final class AuthLoading extends AuthStatus {
  const AuthLoading();

  @override
  List<Object?> get props => [];

  @override
  String toString() => 'AuthLoading';
}
```

#### AuthError

```dart
final class AuthError extends AuthStatus {
  const AuthError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'AuthError($message)';
}
```

### Pattern Matching

```dart
switch (status) {
  case Authenticated(:final user):
    // user.displayName, user.roles, etc.
  case Unauthenticated():
    // redirect to login
  case AuthLoading():
    // show spinner
  case AuthError(:final message):
    // show error message
}
```

### Maquina de Estados

```
                 init()
                   │
                   ▼
            ┌─ AuthLoading ─┐
            │                │
     tryRestoreSession()     │ (no session)
            │                │
            ▼                ▼
     Authenticated ←──── Unauthenticated
            │                │
     logout()            login()
            │                │
            ▼                ▼
     Unauthenticated    AuthLoading
                             │
                        ┌────┴────┐
                        ▼         ▼
                 Authenticated  AuthError
                                    │
                              (retry/dismiss)
                                    │
                                    ▼
                             Unauthenticated
```

### Igualdade

- `Authenticated` e igual se `user` e igual
- `Unauthenticated` e `AuthLoading` sao sempre iguais (const singletons)
- `AuthError` e igual se `message` e igual
- Subtipos diferentes NUNCA sao iguais entre si

---

## 3. AuthToken (Final Class)

### Definicao

```dart
final class AuthToken with Equatable {
  const AuthToken({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
    this.idToken,
  });

  final String accessToken;
  final String? refreshToken;
  final String? idToken;
  final DateTime expiresAt;
}
```

### Campos

| Campo | Tipo | Required | Descricao |
|-------|------|----------|-----------|
| `accessToken` | `String` | Sim | Bearer token para API. Short-lived, apenas em memoria |
| `refreshToken` | `String?` | Nao | Token de renovacao. **Web:** null (HttpOnly cookie). **Desktop:** persistido via flutter_secure_storage |
| `idToken` | `String?` | Nao | ID token com claims do usuario |
| `expiresAt` | `DateTime` | Sim | Expiracao absoluta do access token |

### Metodos

#### `isExpired({DateTime? now}) → bool`

```dart
bool isExpired({DateTime? now}) =>
    (now ?? DateTime.now()).isAfter(expiresAt);
```

- Retorna `true` se o token ja expirou
- Parametro `now` injetavel para testes deterministicos

**Exemplos:**
- Token expira em 1h no futuro → `false`
- Token expirou 1h atras → `true`

#### `expiresWithin(Duration threshold, {DateTime? now}) → bool`

```dart
bool expiresWithin(Duration threshold, {DateTime? now}) =>
    (now ?? DateTime.now()).isAfter(expiresAt.subtract(threshold));
```

- Retorna `true` se o token expira dentro do `threshold`
- Util para refresh proativo (ex: renovar 30s antes de expirar)

**Exemplos:**
- Token expira em 20s, threshold 30s → `true` (precisa renovar)
- Token expira em 50s, threshold 30s → `false` (ainda tem tempo)

#### `copyWith({...}) → AuthToken`

```dart
AuthToken copyWith({
  String? accessToken,
  String? Function()? refreshToken,  // ValueGetter para nullable
  String? Function()? idToken,       // ValueGetter para nullable
  DateTime? expiresAt,
})
```

**Padrao ValueGetter para campos nullable:**
- `token.copyWith()` → copia tudo sem alterar
- `token.copyWith(accessToken: 'new')` → altera accessToken
- `token.copyWith(refreshToken: () => null)` → limpa refreshToken explicitamente
- `token.copyWith(refreshToken: () => 'new')` → define novo refreshToken

> **IMPORTANTE:** Campos nullable usam `String? Function()?` (ValueGetter) ao inves de `String?` para distinguir "nao informado" de "explicitamente null".

#### `toString() → String`

```dart
@override
String toString() => 'AuthToken(expiresAt: $expiresAt, expired: ${isExpired()})';
```

**Seguranca:** NAO expoe valores de tokens no toString. Apenas mostra expiracao.

### Igualdade (Equatable)

```dart
@override
List<Object?> get props => [accessToken, refreshToken, idToken, expiresAt];
```

---

## 4. AuthUser (Final Class)

### Definicao

```dart
final class AuthUser with Equatable {
  const AuthUser({
    required this.id,
    required this.roles,
    this.name,
    this.email,
    this.preferredUsername,
  });

  final String id;
  final String? name;
  final String? email;
  final String? preferredUsername;
  final Set<AuthRole> roles;
}
```

### Campos

| Campo | Tipo | Required | Fonte (OIDC Claim) |
|-------|------|----------|-------------------|
| `id` | `String` | Sim | `sub` (Zitadel subject identifier) |
| `name` | `String?` | Nao | `name` (profile scope) |
| `email` | `String?` | Nao | `email` (email scope) |
| `preferredUsername` | `String?` | Nao | `preferred_username` (profile scope) |
| `roles` | `Set<AuthRole>` | Sim | `urn:zitadel:iam:org:project:roles` |

### Getters Computados

#### `displayName → String`

Fallback chain hierarquico:

```dart
String get displayName => name ?? preferredUsername ?? email ?? id;
```

| Cenario | Resultado |
|---------|-----------|
| name = 'Maria Silva' | 'Maria Silva' |
| name = null, preferredUsername = 'maria.silva' | 'maria.silva' |
| name = null, preferredUsername = null, email = 'maria@acdg.com.br' | 'maria@acdg.com.br' |
| tudo null | id (ex: 'user-123') |

#### `canWrite → bool`

```dart
bool get canWrite => hasRole(AuthRole.socialWorker);
```

Apenas `socialWorker` pode escrever.

#### `canRead → bool`

```dart
bool get canRead => roles.isNotEmpty;
```

Qualquer usuario com pelo menos 1 role pode ler.

### Metodos

#### `hasRole(AuthRole role) → bool`

```dart
bool hasRole(AuthRole role) => roles.contains(role);
```

#### `hasAnyRole(Set<AuthRole> required) → bool`

```dart
bool hasAnyRole(Set<AuthRole> required) =>
    roles.intersection(required).isNotEmpty;
```

#### `copyWith({...}) → AuthUser`

```dart
AuthUser copyWith({
  String? id,
  String? Function()? name,              // ValueGetter
  String? Function()? email,             // ValueGetter
  String? Function()? preferredUsername,  // ValueGetter
  Set<AuthRole>? roles,
})
```

Mesmo padrao ValueGetter do AuthToken:
- `user.copyWith(name: () => null)` → limpa name
- `user.copyWith(name: () => 'Ana')` → define novo name
- `user.copyWith(roles: {AuthRole.admin})` → altera roles

#### `toString() → String`

```dart
@override
String toString() => 'AuthUser(id: $id, name: $name, roles: $roles)';
```

### Igualdade (Equatable)

```dart
@override
List<Object?> get props => [id, name, email, preferredUsername, ...roles];
```

### Tabela de Permissoes por Role

| Role | `canWrite` | `canRead` | Descricao |
|------|-----------|-----------|-----------|
| `socialWorker` | `true` | `true` | CRUD completo |
| `owner` | `false` | `true` | Somente leitura |
| `admin` | `false` | `true` | Leitura + admin area |
| (nenhum) | `false` | `false` | Sem acesso |

---

## 5. PADRAO VALUEGETTER (Transversal)

Todos os `copyWith` de campos nullable usam este padrao:

```dart
// Definicao no copyWith
AuthUser copyWith({
  String? Function()? name,  // parametro e um Function? que retorna String?
}) {
  return AuthUser(
    // Se a function foi fornecida, chama-a. Senao, mantem valor atual.
    name: name != null ? name() : this.name,
    // ...
  );
}
```

**Por que nao usar `String?` diretamente?**
- `copyWith(name: null)` → ambiguo: "nao alterar" ou "limpar"?
- `copyWith(name: () => null)` → explicito: "limpar para null"
- `copyWith(name: () => 'Ana')` → explicito: "definir como 'Ana'"
- `copyWith()` (sem parametro) → "nao alterar"

---

## 6. CONTRATO DE TESTE (Comportamento Esperado)

### AuthRole
- 3 valores de enum com strings correspondentes
- `fromString`: resolve conhecidos, retorna null para desconhecidos
- `fromJwtClaim`: extrai outer keys, ignora desconhecidos, null → `const {}`

### AuthStatus
- 4 subtipos sealed
- Pattern matching exaustivo
- Igualdade por conteudo (Equatable)
- Subtipos diferentes nunca iguais

### AuthToken
- Armazena 4 campos (2 required, 2 optional)
- `isExpired(now?)` aceita tempo injetavel
- `expiresWithin(threshold, now?)` idem
- `copyWith` com ValueGetter para nullables
- `toString` NAO expoe valores de token

### AuthUser
- `displayName` segue fallback chain: name → preferredUsername → email → id
- `canWrite` → true apenas para socialWorker
- `canRead` → true se roles nao vazio
- `hasRole` e `hasAnyRole` fazem lookup em Set
- `copyWith` com ValueGetter para nullables
- Igualdade inclui todos os campos + roles spread
