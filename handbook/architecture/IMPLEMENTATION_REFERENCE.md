# Referência de Implementação — O Padrão ACDG

Este guia serve como o exemplo definitivo de como escrever código no monorepo ACDG. Ele utiliza a refatoração do módulo de Autenticação como estudo de caso para demonstrar a aplicação dos padrões **Repository**, **Command** e **Clean MVVM**.

---

## 1. A Camada de Dados: O Padrão Repository

**Por que?** Nunca exponha um `Service` (API bruta) diretamente para um `ViewModel`. O `Repository` é a única fonte de verdade e o lugar para orquestrar cache, persistência e transformações.

### Exemplo: `AuthRepository`
```dart
// 1. Defina a interface (Contrato)
abstract class AuthRepository extends Listenable {
  AuthStatus get currentStatus;
  Future<Result<void>> login();
  // ...
}

// 2. Implementação privada encapsulando o Service
class AuthRepositoryImpl extends ChangeNotifier implements AuthRepository {
  AuthRepositoryImpl({required AuthService authService}) : _authService = authService;

  final AuthService _authService; // Privado!

  @override
  Future<Result<void>> login() async {
    try {
      await _authService.login();
      return const Success(null);
    } catch (e) {
      return Failure(e); // Erros são capturados e retornados como Result
    }
  }
}
```

---

## 2. A Camada de Lógica: O Padrão Command

**Por que?** Evita o boilerplate de `bool busy = true; try { ... } finally { busy = false; }` e centraliza o estado de erro/execução no ViewModel.

### Exemplo: `AuthViewModel`
```dart
class AuthViewModel extends BaseViewModel {
  AuthViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository {
    // Inicialize comandos vinculando-os aos métodos do Repository
    login = Command0(_authRepository.login);
  }

  final AuthRepository _authRepository;

  // Comandos expostos para a View
  late final Command0<void> login;
}
```

---

## 3. A Camada de UI: Reatividade Atômica

**Por que?** Use `ListenableBuilder` ou `ValueListenableBuilder` para reconstruir apenas o que é necessário. O botão de login deve reagir ao estado do `Command`.

### Exemplo: `LoginPage`
```dart
ListenableBuilder(
  listenable: viewModel.login, // Escuta o comando específico
  builder: (context, _) {
    final busy = viewModel.login.running; // Estado automático
    return ElevatedButton.icon(
      onPressed: busy ? null : viewModel.login.execute, // Desabilita se ocupado
      icon: busy ? CircularProgressIndicator() : Icon(Icons.login),
      label: const Text('Entrar'),
    );
  },
)
```

---

## 4. Isolamento de Infraestrutura: Config Factories

**Por que?** O arquivo `main.dart` deve ser um orquestrador limpo. Lógicas de ambiente (`--dart-define`) e decisão de plataforma (Web vs Native) devem ser extraídas.

### Exemplo: `OidcConfigFactory`
```dart
class OidcConfigFactory {
  static OidcAuthConfig fromEnvironment() {
    // Use a utilidade Env do core em vez de String.fromEnvironment diretamente
    const issuer = Env.oidcIssuer;
    // ... lógica complexa de redirecionamento por plataforma
    return OidcAuthConfig(issuer: Uri.parse(issuer), ...);
  }
}
```

---

## 5. Gerenciamento de Ambiente: Classe `Env`

**Por que?** Centraliza todas as chaves de configuração, provê tipos fortes (`getBool`, `getInt`) e abstrai a fonte dos dados (seja `--dart-define` ou futuramente um arquivo `.env`).

### Exemplo: `Env` no core
```dart
class Env {
  static String getString(String key) => String.fromEnvironment(key);
  
  // Getters tipados facilitam o uso e evitam typos
  static String get oidcIssuer => getString('OIDC_ISSUER');
}
```

---

## 6. Testabilidade: O Poder dos Fakes

**Por que?** Mocks costumam ser frágeis e verbosos. `Fakes` (test doubles) permitem simular comportamento real de forma controlada e reutilizável entre testes de unidade e de widget.

### Exemplo: `FakeAuthRepository`
```dart
class FakeAuthRepository extends ChangeNotifier implements AuthRepository {
  bool loginShouldFail = false;

  @override
  Future<Result<void>> login() async {
    if (loginShouldFail) return Failure('Erro simulado');
    return Success(null);
  }
}
```

---

## Checklist de "Código de Ouro"
- [ ] O ViewModel fala com um Repository? (Nunca com um Service)
- [ ] Ações assíncronas usam o padrão `Command`?
- [ ] Erros são tratados via tipo `Result`? (Sem `throw` para controle de fluxo)
- [ ] A UI usa `ListenableBuilder` para evitar `setState` globais?
- [ ] O `main.dart` está livre de lógicas de decisão de plataforma?
- [ ] Existe um `Fake` para cada Repository para fins de teste?
