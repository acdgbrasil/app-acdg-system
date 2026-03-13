Novamente, a estrutura da sua classe está excelente! O uso de `final class`, a clareza da documentação (especialmente a nota sobre o padrão *Split-Token*) e a utilização do `Object.hash` são exatamente as práticas recomendadas no Dart moderno.

No entanto, há **dois pontos arquiteturais** muito importantes que podem ser melhorados aqui: a **testabilidade** (devido ao uso do tempo) e uma **limitação clássica do `copyWith**` no Dart.

Aqui estão as melhorias detalhadas:

### 1. Testabilidade e o problema do `DateTime.now()`

Atualmente, `isExpired` e `expiresWithin` dependem rigidamente de `DateTime.now()`. Isso torna a classe quase impossível de ser testada de forma determinística em testes unitários, porque o tempo está sempre avançando. Se você escrever um teste hoje, ele pode falhar amanhã.

**A solução:** Permitir a injeção do tempo atual (ou usar o pacote oficial `clock`). A forma mais simples e sem dependências externas é passar um parâmetro opcional.

### 2. A "Armadilha" do `copyWith` com valores nulos

No seu `copyWith` atual, se você quiser remover o `refreshToken` (passando `null` para ele), o método fará `refreshToken ?? this.refreshToken` e acabará mantendo o token antigo. O Dart nativo não consegue diferenciar um `null` passado intencionalmente de um `null` gerado por omissão do parâmetro.

**A solução:** Usar um padrão de encapsulamento com funções (`ValueGetter` ou apenas funções anônimas) para os campos que podem ser anulados, ou adotar um gerador de código como o pacote `freezed`.

---

### O Código Refatorado (Dart Nativo)

Aqui está como sua classe fica aplicando a correção de testabilidade e um `copyWith` à prova de falhas:

```dart
/// Token set returned by the Zitadel OIDC flow.
///
/// Immutable model holding the access token (short-lived, memory-only)
/// and optional refresh/ID tokens.
final class AuthToken {
  const AuthToken({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
    this.idToken,
  });

  /// Bearer token for API requests.
  final String accessToken;

  /// Refresh token for silent renewal.
  ///
  /// On web: stored in HttpOnly cookie (Split-Token pattern), so this
  /// field may be `null` after page refresh — the cookie handles it.
  /// On desktop: persisted via flutter_secure_storage.
  final String? refreshToken;

  /// Raw ID token containing user claims.
  final String? idToken;

  /// Absolute expiration time of the access token.
  final DateTime expiresAt;

  /// Whether the access token has expired.
  /// 
  /// Accepts an optional [now] parameter for deterministic unit testing.
  bool isExpired({DateTime? now}) => (now ?? DateTime.now()).isAfter(expiresAt);

  /// Whether the access token will expire within the given [threshold].
  ///
  /// Useful for proactive refresh (e.g., refresh 30s before expiry).
  bool expiresWithin(Duration threshold, {DateTime? now}) =>
      (now ?? DateTime.now()).isAfter(expiresAt.subtract(threshold));

  /// Creates a copy of this token set, replacing the provided fields.
  /// 
  /// To set a nullable field to `null`, pass a function returning `null`.
  /// Example: `token.copyWith(refreshToken: () => null)`
  AuthToken copyWith({
    String? accessToken,
    DateTime? expiresAt,
    String? Function()? refreshToken,
    String? Function()? idToken,
  }) {
    return AuthToken(
      accessToken: accessToken ?? this.accessToken,
      expiresAt: expiresAt ?? this.expiresAt,
      // Se a função foi passada, executa para pegar o valor (que pode ser null).
      // Se não foi passada, mantém o valor atual.
      refreshToken: refreshToken != null ? refreshToken() : this.refreshToken,
      idToken: idToken != null ? idToken() : this.idToken,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthToken &&
          other.accessToken == accessToken &&
          other.refreshToken == refreshToken &&
          other.idToken == idToken &&
          other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken, idToken, expiresAt);

  @override
  String toString() => 'AuthToken(expiresAt: $expiresAt, expired: ${isExpired()})';
}

```

### O que melhorou?

* **Tempo Injetável:** Agora você pode fazer `token.isExpired(now: mockTime)` nos seus testes, garantindo que eles nunca quebrem por causa do relógio do sistema.
* **`copyWith` Robusto:** Se você precisar limpar o refresh token da memória, agora você pode chamar `token.copyWith(refreshToken: () => null)`. É um truque avançado de Dart que resolve a limitação de anulação sem precisar de pacotes externos.
* **Documentação Preservada:** Toda a sua ótima documentação técnica foi mantida intacta.

*(Nota sobre Boilerplate: Assim como no `AuthStatus`, se essa classe começar a crescer, considerar o pacote `equatable` para o `==` e `hashCode`, ou o pacote `freezed` / `dart_mappable` para gerar o `copyWith` automaticamente, vai poupar muito trabalho manual).*
