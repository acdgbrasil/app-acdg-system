# Guia Técnico: Integração OIDC e Autenticação Real (Zitadel)

Este guia detalha como realizar a integração real de autenticação no ecossistema ACDG, cobrindo desde a infraestrutura do Zitadel até a implementação no Flutter e automação em CI/CD.

---

## 1. Visão Geral da Arquitetura de Auth

A autenticação segue o padrão **OIDC (OpenID Connect)** com fluxo **Authorization Code + PKCE**. No ACDG, dividimos a responsabilidade em 3 camadas:

1.  **Data Layer (`packages/auth`)**:
    *   `OidcAuthService`: Wrapper do `package:oidc` que gerencia tokens e persistência.
    *   `AuthRepository`: Interface que abstrai o serviço, permitindo a injeção de Fakes em testes ou implementações customizadas.
2.  **Logic Layer (`apps/acdg_system/lib/logic/use_cases`)**:
    *   UseCases puros (`LoginUseCase`, `LogoutUseCase`) que orquestram a chamada ao repositório.
3.  **UI Layer (`apps/acdg_system/lib/ui/view_models`)**:
    *   `AuthViewModel`: Expõe o estado reativo (`AuthStatus`) e expõe ações via `Command Pattern`.

---

## 2. Configuração de Produção vs. Homologação

A diferença crucial está na forma como o App obtém o token e como ele é validado.

### No Zitadel:
*   **App Nativo (PKCE)**: Usado para humanos. O `Redirect URI` deve ser configurado corretamente (`com.acdg.system://callback` para macOS/Mobile e URLs seguras para Web).
*   **App API (Service Account)**: Usado para máquinas (CI/CD e Testes de Integração). Utiliza chaves RSA (JWT Profile) para obter tokens sem intervenção humana.

### No App:
Utilizamos a classe `Env` e a `OidcConfigFactory` para ler configurações via `--dart-define`. **Nunca hardcode URLs de produção**.

---

## 3. Implementação Técnica da "Integração Séria"

Para validar a integração com o servidor real sem precisar de um humano clicando no browser, usamos o **JWT Profile Grant (RFC 7523)**.

### O Helper de Autenticação (`HmlAuthHelper`)
Esta classe (em `packages/core`) assina um JWT localmente com uma chave privada e troca por um `access_token` no Zitadel.

```dart
// Exemplo de uso para obter token em testes ou scripts
final helper = HmlAuthHelper.fromEnv(); // Lê userId, keyId e key (RSA) do ambiente
final token = await helper.getAccessToken();
```

### Injeção no Root
Para que o teste de integração seja "sério", ele deve rodar o widget `Root` real, mas injetando um `AuthRepository` que já possui o token obtido pelo helper.

```dart
final fakeRepository = _RealTokenAuthRepository(accessToken, realUser);
await tester.pumpWidget(Root(authRepository: fakeRepository));
```

---

## 4. Estratégia de CI/CD (GitHub Actions)

Para que os testes de integração funcionem no CI, os segredos devem ser injetados de forma segura.

### Passo 1: Segredos no GitHub
Adicione os segredos do Service Account obtidos no console do Zitadel:
*   `ZITADEL_USER_ID`: ID do usuário máquina.
*   `ZITADEL_KEY_ID`: ID da chave RSA.
*   `ZITADEL_PRIVATE_KEY`: O conteúdo da chave RSA (em Base64 para evitar quebras de linha no shell).

### Passo 2: Configuração do Workflow
No arquivo `.yml` do GitHub Actions, injete as variáveis no comando de teste:

```yaml
- name: Run Staging Integration Tests
  run: |
    # Codifica a chave em base64 se necessário
    flutter test integration_test/staging_integration_test.dart \
      --dart-define=userId=${{ secrets.ZITADEL_USER_ID }} \
      --dart-define=keyId=${{ secrets.ZITADEL_KEY_ID }} \
      --dart-define=key=${{ secrets.ZITADEL_PRIVATE_KEY_BASE64 }}
```

---

## 5. Boas Práticas e Mandatos

1.  **Proteção de Chaves**: Chaves RSA de Service Accounts de produção devem ser tratadas como "Master Keys". Se vazarem, o atacante pode simular qualquer `social_worker`. Use o **Bitwarden Secret Manager** para gerenciar essas chaves.
2.  **Injeção via Interface**: No `root.dart`, sempre injete via interface (`ListenableProvider<AuthRepository>`). Isso permite que o app troque o motor de auth sem quebrar a UI.
3.  **Mecanismo de Espera**: Em testes de integração, evite `pumpAndSettle()` se sua tela tiver animações infinitas (como o loading da Splash). Use `pump(Duration)` para avançar o tempo de forma controlada.
4.  **Base64 para Chaves**: Ao passar chaves RSA via linha de comando (`--dart-define`), sempre use Base64. Isso evita problemas com caracteres especiais, espaços e limites de tamanho do buffer de comando.

---

## 6. Checklist de Implementação em Produção

- [ ] Criar projeto "ACDG System" no Zitadel de Produção.
- [ ] Criar Application tipo "Native" para o App.
- [ ] Configurar os Ingress no K3s (`auth.acdgbrasil.com.br`).
- [ ] Gerar as variáveis de ambiente na Pipeline de Build.
- [ ] Validar o flow de PKCE em uma build real nativa (macOS/Windows).
