### Review de Arquitetura, Ciclo de Vida e Organização

Sua análise cobriu muito bem a robustez individual das classes, mas ao olharmos para o pacote como um todo, ainda temos alguns "vazamentos" de responsabilidade e problemas de organização. Aqui estão os pontos que complementam seus reviews anteriores:

---

### 1. O Problema do `AuthUser.copyWith`
Você identificou o erro no `AuthToken`, mas o `AuthUser` sofre do mesmo mal. Se precisarmos remover o nome ou email de um usuário (setar para `null`), o `copyWith` atual falhará miseravelmente.
*   **Solução:** Padronizar o uso de `ValueGetter` (ex: `String? Function()? name`) em todos os modelos do sistema.

### 2. Contrato de Serviço e o "Conhecimento Oculto"
A interface `AuthService` não possui o método `init()`, mas a implementação `OidcAuthService` exige que ele seja chamado. Isso quebra a abstração: se eu injetar um `AuthService`, meu código não saberá que precisa inicializá-lo.
*   **Solução:** Adicionar `Future<void> init()` ao contrato `AuthService`. Isso garante que qualquer implementação (Fake ou Real) tenha um ciclo de vida previsível.

### 3. Organização de Pastas (O "Saco de Arquivos")
Atualmente, `lib/src/` é uma lista plana. Isso dificulta encontrar onde termina um modelo e onde começa um serviço.
*   **Proposta:** Separar por domínio e responsabilidade.
    *   `src/models/`: Dados puros.
    *   `src/services/`: Contratos e lógica de negócio.
    *   `src/services/oidc/`: Implementação específica do Zitadel.

---

## 🚀 Plano de Refatoração Consolidado

Este plano condensa todos os seus reviews e os pontos acima em 4 passos lógicos:

### Passo 1: Modelagem Robusta (Dart Nativo)
*   **AuthStatus:** Remover boilerplate de `==` e `hashCode` das classes `const` (Unauthenticated, Loading). Manter apenas o `toString`.
*   **AuthToken:** Aplicar o tempo injetável `isExpired({DateTime? now})` e o `copyWith` seguro para nulos.
*   **AuthUser:** Aplicar o `copyWith` seguro para nulos usando funções para os campos opcionais.

### Passo 2: Saneamento do Contrato
*   **AuthService:** Adicionar `Future<void> init()` à interface.
*   **AuthService:** Adicionar documentação clara sobre a ordem de chamada (init -> tryRestoreSession).

### Passo 3: Refatoração do OidcAuthService
*   **Separação:** Mover a lógica de parsing de JWT (que hoje está dentro do `_onUserChanged`) para métodos privados dedicados ou uma classe auxiliar.
*   **Sincronização:** Garantir que o `_updateStatus` limpe todas as variáveis de estado (`_currentUser`, `_currentToken`) para evitar estados inconsistentes.

### Passo 4: Reorganização Estrutural
Mover os arquivos para a seguinte estrutura:
```text
lib/
  auth.dart (Exports)
  src/
    models/
      auth_role.dart
      auth_user.dart
      auth_token.dart
      auth_status.dart
    services/
      auth_service.dart (Interface)
      oidc/
        oidc_auth_service.dart
        oidc_auth_config.dart
```

### Por que essa organização é melhor?
1.  **Baixo Acoplamento:** Se amanhã trocarmos o OIDC por outra tecnologia, a pasta `models/` e a interface do serviço continuam intactas.
2.  **Arquivos Menores:** Ao extrair parsers e configurações, o `OidcAuthService` foca apenas no fluxo de login/logout.
3.  **Descoberta:** Um novo desenvolvedor entende o pacote apenas lendo os nomes das pastas, sem precisar abrir arquivo por arquivo.
