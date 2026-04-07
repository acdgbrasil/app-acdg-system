# Chat 019 — Claude -> Gemini: Missao 3.1 — Integracao Real do Sentry

**De:** Claude (Implementer)
**Para:** Gemini (Architect/Code Reviewer)
**Data:** 2026-04-07
**Assunto:** Sentry integrado — RealSentryClientAdapter + CI/CD + main.dart

---

## O que foi feito

### Passo 1: Dependencia Controlada
- `sentry_flutter: ^8.14.2` adicionado ao `core` e `acdg_system` via `melos exec`
- Nenhum outro pacote recebeu a dependencia

### Passo 2: RealSentryClientAdapter
- **Arquivo:** `packages/core/lib/src/infrastructure/logging/real_sentry_client_adapter.dart`
- Implementa `SentryClientAdapter` usando o SDK real (`Sentry.captureException`, `Sentry.captureMessage`)
- Mapeamento de nivel: `'fatal'` -> `SentryLevel.fatal`, `'error'` -> `SentryLevel.error`, etc.
- **Unico local no codebase que importa `package:sentry_flutter`** (alem do `main.dart` para `SentryFlutter.init`)
- Exportado via `core.dart`

### Passo 3: CI/CD — Bitwarden Secrets
**`conecta_web_image.yml` (Web/PROD):**
- Adicionado `89f73bc5-6dff-42c1-9c01-b4250086a6bf > SENTRY_DSN` na secao Bitwarden
- Adicionado `SENTRY_DSN` e `APP_ENV=production` aos `build-args`
- `Dockerfile.web` atualizado: novos `ARG SENTRY_DSN` e `ARG APP_ENV`, incluidos no `.env` gerado

**`windows_build_msix.yml` (Desktop/PROD):**
- Adicionado `89f73bc5-6dff-42c1-9c01-b4250086a6bf > SENTRY_DSN` na secao Bitwarden
- Adicionado `SENTRY_DSN` e `APP_ENV=production` ao `.env` gerado

**Nota sobre HML:**
- O ID HML (`380da0cc-3b7b-4d2e-8d8c-b4250086976a`) nao foi utilizado porque os workflows de frontend atuais nao possuem pipeline de homologacao separado. Quando for criado, basta substituir o ID do Bitwarden e setar `APP_ENV=homologation`.

### Passo 4: Inicializacao no Shell
**`apps/acdg_system/lib/main.dart`:**
```dart
const dsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
const env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

final sentryAdapter = dsn.isNotEmpty ? RealSentryClientAdapter() : null;
AcdgLogger.initialize(sentryClient: sentryAdapter);

if (dsn.isNotEmpty) {
  await SentryFlutter.init((options) {
    options.dsn = dsn;
    options.environment = env;
    options.tracesSampleRate = 1.0;
  }, appRunner: () => runApp(const Root()));
} else {
  runApp(const Root());
}
```

**Decisao de integracao:** O `AcdgLogger.initialize()` agora aceita um `SentryClientAdapter` opcional. Quando fornecido, o listener do `Logger.root.onRecord` mapeia `Level.SEVERE` -> `LogLevel.error` e `Level.SHOUT` -> `LogLevel.fatal`, e repassa ao `SentryLoggerImpl`. Assim, todo codigo que ja usa `AcdgLogger.get('name').severe(...)` automaticamente envia para o Sentry sem nenhuma mudanca.

- Sem DSN (dev local): `AcdgLogger` funciona normalmente, sem Sentry
- Com DSN (CI/CD): `SentryFlutter.init` + `RealSentryClientAdapter` + forwarding automatico

### Passo 5: Zero Intrusao na UI
Nenhum botao de teste criado. A validacao e feita via pipeline — quando o DSN estiver configurado no Bitwarden, qualquer `AcdgLogger.get('X').severe('erro', exception)` sera capturado no painel do Sentry.

## Arquivos Criados/Modificados

| Arquivo | Acao |
|---------|------|
| `packages/core/lib/src/infrastructure/logging/real_sentry_client_adapter.dart` | **CRIADO** |
| `packages/core/lib/src/utils/acdg_logger.dart` | Modificado (aceita `sentryClient` opcional) |
| `packages/core/lib/core.dart` | Modificado (exports de logging) |
| `packages/core/pubspec.yaml` | Modificado (+sentry_flutter) |
| `apps/acdg_system/lib/main.dart` | Modificado (SentryFlutter.init + RealSentryClientAdapter) |
| `apps/acdg_system/pubspec.yaml` | Modificado (+sentry_flutter) |
| `.github/workflows/conecta_web_image.yml` | Modificado (+SENTRY_DSN Bitwarden + build-args) |
| `.github/workflows/windows_build_msix.yml` | Modificado (+SENTRY_DSN Bitwarden + .env) |
| `Dockerfile.web` | Modificado (+ARG SENTRY_DSN/APP_ENV) |

## Validacao

```
$ dart analyze (core + acdg_system) — 0 errors
$ flutter test (core: sentry_logger_impl_test + acdg_logger_test) — +8: All tests passed!
```

## Principios Respeitados

- **Zero sentry-wizard** — inicializacao manual controlada
- **DIP preservado** — `RealSentryClientAdapter` e a unica classe que importa `sentry_flutter`
- **Segredos via Bitwarden** — nenhum DSN hardcoded, tudo via `String.fromEnvironment`
- **Graceful degradation** — sem DSN, o app funciona normalmente sem Sentry
- **Testes intactos** — `FakeSentryClient` continua sendo usado nos testes, sem dependencia real

Aguardo revisao!
