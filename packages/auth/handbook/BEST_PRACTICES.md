# Best Practices — Lições dos Code Reviews

Regras consolidadas extraídas dos code reviews do package `auth`. Aplicáveis a todo o monorepo frontend.

---

## 1. Dart Moderno (Dart 3+)

### FAZER
- Usar `.firstOrNull` em vez de loops `for` manuais para buscar o primeiro match em listas/enums.
- Usar `.nonNulls` para filtrar nulos de iteráveis — já faz o cast para tipo não-nulo.
- Usar cadeias funcionais (`.map().nonNulls.toSet()`) em vez de loops imperativos com acumuladores mutáveis.
- Retornar `const {}` / `const []` para coleções vazias em caminhos de erro/nulo — evita alocação.

### NÃO FAZER
- Loops `for` imperativos para transformar/filtrar coleções quando existe um operador funcional equivalente.
- `values.byName()` quando o valor buscado difere do nome da variável no enum (ex: `socialWorker` vs `social_worker`).

---

## 2. Igualdade com `Equatable` (mixin do `core`)

Todos os modelos de dados devem usar `with Equatable` de `package:core/core.dart`. **Nunca** implementar `==`/`hashCode` na mão.

### FAZER
- Usar `with Equatable` em toda `class` / `sealed class` / `final class` que represente dados:
  ```dart
  import 'package:core/core.dart';

  final class AuthUser with Equatable {
    const AuthUser({required this.id, this.name});
    final String id;
    final String? name;

    @override
    List<Object?> get props => [id, name];
  }
  ```
- Em `sealed class`, aplicar o mixin na classe base — subclasses herdam `==`/`hashCode` e só precisam declarar `props`:
  ```dart
  sealed class AuthStatus with Equatable {
    const AuthStatus();
  }

  final class Authenticated extends AuthStatus {
    const Authenticated(this.user);
    final AuthUser user;

    @override
    List<Object?> get props => [user];
  }

  final class Unauthenticated extends AuthStatus {
    const Unauthenticated();

    @override
    List<Object?> get props => [];
  }
  ```
- Para `Set` ou coleções nos `props`, usar spread (`...roles`) para que cada elemento participe da comparação.
- Manter `toString()` customizado apenas quando necessário (ex: `AuthToken` esconde valores de token, `Authenticated` mostra `displayName`). Caso contrário, o `Equatable` gera automaticamente.

### NÃO FAZER
- Implementar `==` e `hashCode` manualmente — é propenso a erro ao adicionar campos novos e adiciona boilerplate.
- Usar `Object.hash()` / `Object.hashAll()` diretamente — o `Equatable` cuida disso via `props`.
- Esquecer de incluir todos os campos em `props` — campo ausente = ignorado na comparação.

---

## 3. Imutabilidade e `copyWith`

### FAZER
- Usar **ValueGetter** (`String? Function()?`) para campos nullable no `copyWith`:
  ```dart
  // Setar valor
  user.copyWith(name: () => 'Ana')
  // Limpar (setar null)
  user.copyWith(name: () => null)
  // Manter (não passar)
  user.copyWith()
  ```
- Aplicar este padrão **consistentemente em todos os modelos** que tenham campos nullable.
- Usar `final class` com todos os campos `final`.

### NÃO FAZER
- `copyWith` com `??` para campos nullable — `copyWith(name: null)` silenciosamente mantém o valor antigo em vez de limpá-lo. Esta é uma armadilha clássica do Dart.
- Campos mutáveis em modelos de domínio.

---

## 4. Testabilidade

### FAZER
- Injetar dependências de tempo: `isExpired({DateTime? now})` permite testes determinísticos.
- Aceitar `now` como parâmetro opcional com default `DateTime.now()` — zero impacto no código de produção.
- Escrever testes com datas fixas absolutas (`DateTime(2030, 1, 1)`) para evitar flakiness.

### NÃO FAZER
- Chamar `DateTime.now()` diretamente em getters/métodos que serão testados — o tempo avança entre a criação e a asserção, causando testes instáveis.
- Usar `package:clock` quando um simples parâmetro opcional resolve.

---

## 5. Contratos (Interfaces)

### FAZER
- Expor **todo o ciclo de vida** na interface abstrata — se a implementação exige `init()`, o contrato deve declará-lo.
- Documentar a **ordem de chamada** (ex: `init()` → `tryRestoreSession()` → ready).
- Garantir que Fakes e implementações reais sigam o mesmo contrato sem "conhecimento oculto".

### NÃO FAZER
- Métodos públicos apenas na implementação concreta que não existem na interface — isso quebra a abstração e acopla o consumidor à implementação.
- Injetar `AuthService` e precisar fazer cast para `OidcAuthService` para acessar `init()`.

---

## 6. Gerenciamento de Estado em Services

### FAZER
- Centralizar mutações de estado em métodos dedicados:
  - `_setAuthenticatedSession(user, token)` — seta user + token + emite status.
  - `_clearSession()` — limpa user + token + emite `Unauthenticated`.
- Usar `try/finally` em `logout()` — garante limpeza local mesmo se a rede falhar.
- Tratar claims malformados com `try/catch` no parsing — emitir `AuthError` em vez de crashar.

### NÃO FAZER
- Limpar `_currentUser` e `_currentToken` em locais separados — risco de "estado zumbi" (status `Unauthenticated` mas user ainda preenchido em memória).
- Aceitar `accessToken ?? ''` — string vazia como Bearer token causa 401 silencioso. Verificar null e tratar como sessão inválida.
- Colocar toda a lógica num único handler (`_onUserChanged` fazendo parsing + criação + estado) — extrair parsers puros.

---

## 7. Separação de Responsabilidades (Services)

### FAZER
- Extrair parsing/transformação para métodos **puros e atômicos** (`_parseUser`, `_parseToken`) — recebem dados, retornam objetos, sem side effects.
- Manter handlers de eventos como **orquestradores** — decidem *o que* fazer, delegam o *como*.
- Organizar em seções claras com comentários de região:
  ```dart
  // ---------- JWT parsing ----------
  // ---------- Predictable State Mutations ----------
  // ---------- AuthService contract ----------
  ```

### NÃO FAZER
- Métodos "faz-tudo" que escutam evento + fazem parsing + criam objetos + gerenciam estado.
- Lógica de transformação de dados dentro de callbacks de stream.

---

## 8. Organização de Packages

### FAZER
- Separar por **domínio e responsabilidade**:
  ```
  src/models/     — dados puros (imutáveis, sem dependências externas)
  src/services/   — contratos (interfaces)
  src/services/x/ — implementações específicas
  ```
- Barrel file único (`auth.dart`) exportando tudo — consumidores importam `package:auth/auth.dart`.

### NÃO FAZER
- Lista plana de arquivos em `lib/src/` ("saco de arquivos") — dificulta descoberta.
- Importar arquivos internos (`package:auth/src/...`) de fora do package — apenas o barrel.

---

## 9. Arquivos Pequenos e Coesos

### FAZER
- **Uma responsabilidade por arquivo.** Se um arquivo faz parsing, gerencia estado e orquestra fluxos, ele precisa ser dividido.
- Extrair lógica pura (parsers, mappers, validators) para classes/arquivos próprios — testáveis sem mock, rápidos de ler.
- Preferir 5 arquivos de ~100 linhas a 1 arquivo de ~500 linhas. A descoberta por nome de arquivo é mais rápida que scroll.
- Quando um método privado não usa `this`, é candidato a virar `static` ou ser extraído para uma classe utilitária.

### NÃO FAZER
- Arquivos "God Class" que crescem indefinidamente porque "é tudo do mesmo service".
- Manter métodos privados que são funções puras dentro de classes stateful — eles escondem lógica testável.

---

## 10. Estrutura e Organização de Testes

### FAZER
- **Espelhar `lib/src/` em `test/`.** Se o código está em `lib/src/models/auth_role.dart`, o teste está em `test/models/auth_role_test.dart`. Encontrar a cobertura de qualquer arquivo é imediato.
- **Separar testes por fluxo em services complexos:**
  - `*_test.dart` — skeleton: instanciação, estado inicial, streams abertos.
  - `*_login_test.dart` — fluxo de login (sucesso, cancelamento, erro de rede).
  - `*_logout_test.dart` — fluxo de logout (sucesso, erro de rede, limpeza garantida).
  - `*_session_test.dart` — restore de sessão e refresh de token.
  - `*_parsers_test.dart` — conversão de dados puros (JWT → Model), sem mock.
- **Testes de parsers/modelos não precisam de mock** — são funções puras que recebem dados e retornam objetos. Devem rodar instantaneamente.
- **Testes de services precisam de mock/fake** — isolar a dependência externa (ex: `OidcUserManager`) para simular sucesso, erro e edge cases.
- Criar **helpers de teste** (`createTestUser()`, `createTestToken()`) quando o setup se repetir em mais de 2 arquivos. Colocá-los em `test/helpers/` ou `testing/`.
- Cada `group()` testa **um aspecto** (equality, copyWith, permissions). Cada `test()` testa **um cenário** (sucesso, erro, edge case).

### NÃO FAZER
- "Super Arquivo" de 500+ linhas com todos os testes de um service — quando um teste falha, é difícil saber se o problema é no login, no logout ou no parser.
- Testes de lógica pura (parsing, modelos) que dependem de mocks — adiciona complexidade sem valor.
- `setUp()` com lógica complexa compartilhada entre testes que testam coisas diferentes — dificulta entender o que cada teste realmente valida.
