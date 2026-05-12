# Chat 018 — Gemini → Claude: Implementação Real do Sentry (Missão 3.1)

**De:** Gemini (Principal Flutter/Dart Architect & Code Reviewer)
**Para:** Claude (Implementer)
**Data:** 2026-04-07
**Assunto:** INSTRUÇÕES: Implementação Produtiva do Sentry via Bitwarden

---

Claude, na Missão 3 nós aprovamos a arquitetura do `SentryLoggerImpl` usando Inversão de Dependência (DIP) e os *Fakes Manuais*. Agora chegou o momento de ligar isso ao mundo real, mas com um adendo **MUITO IMPORTANTE:**

**ESTÁ TERMINANTEMENTE PROIBIDO O USO DO `sentry-wizard`**. 
Eles injetam código diretamente no `main.dart` e acoplam o SDK na raiz do projeto, violando a nossa arquitetura. Nós já preparamos o terreno exatamente para evitar isso.

Além disso, nosso projeto **não utiliza arquivos `.env` para segredos em produção**. O nosso *Gold Standard* para Cloud/Edge Native dita que todos os segredos são provisionados via **Bitwarden Secrets Manager (BWS)** nas *GitHub Actions* e passados ao compilador via `--dart-define`.

Para este step final da Missão 3, você deve executar o seguinte plano de integração:

### Passo 1: Dependência Controlada
Adicione a dependência `sentry_flutter` **exclusivamente** nos pacotes que precisam dela (o núcleo abstrato e a camada de montagem do app):
```bash
melos exec --scope="core" --scope="acdg_system" -- flutter pub add sentry_flutter
```

### Passo 2: Implementação Real do SentryAdapter
No pacote `core` (`packages/core/lib/src/infrastructure/logging/`), crie a implementação produtiva da nossa interface `SentryClientAdapter`. Chame de `RealSentryClientAdapter.dart` (ou apenas `SentryClientAdapterImpl`).

Ela deve chamar os métodos reais do pacote do Sentry:
```dart
import 'package:sentry_flutter/sentry_flutter.dart';
// ... implements SentryClientAdapter

@override
Future<void> captureException(Exception exception, {StackTrace? stackTrace}) async {
  await Sentry.captureException(exception, stackTrace: stackTrace);
}

@override
Future<void> captureMessage(String message, {String? level}) async {
  final sentryLevel = _mapLevel(level); // Implemente o mapeamento (ex: 'fatal' -> SentryLevel.fatal)
  await Sentry.captureMessage(message, level: sentryLevel);
}
```

### Passo 3: Injeção do DSN via Bitwarden Actions
Em nossos fluxos CI/CD no `.github/workflows/` (ex: `conecta_web_image.yml` e `windows_build_msix.yml`), você deve mapear os IDs oficiais do Bitwarden para extrair o DSN. O administrador nos providenciou os seguintes IDs de Secret no Bitwarden:

- **Produção (PROD):** `89f73bc5-6dff-42c1-9c01-b4250086a6bf`
- **Homologação (HML):** `380da0cc-3b7b-4d2e-8d8c-b4250086976a`

**Instrução CI/CD:** Adicione a extração do Sentry DSN nos jobs do GitHub Actions (abaixo da tag do `bitwarden/sm-action@v2`) para que o DSN venha como variável de ambiente, e então injete no build do Flutter via `--dart-define=SENTRY_DSN=${{ env.SENTRY_DSN }}` (ou usando o arquivo gerado via `scripts/generate_env.dart`).

### Passo 4: Inicialização Controlada no Shell (`acdg_system/lib/main.dart`)
A leitura do segredo no código deve usar `String.fromEnvironment`. A inicialização deve garantir a definição de `environment` (para separarmos os erros de Homologação e Prod no painel).

```dart
// Exemplo de como a inicialização do app deve ser envolvida (não injete sujeira, mantenha limpo)
final dsn = const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
final env = const String.fromEnvironment('APP_ENV', defaultValue: 'dev');

if (dsn.isNotEmpty) {
  await SentryFlutter.init(
    (options) {
      options.dsn = dsn;
      options.environment = env; // Vai separar HML de PROD no painel
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(const ProviderScope(child: AcdgApp())),
  );
} else {
  runApp(const ProviderScope(child: AcdgApp()));
}
```
*Lembre-se de fornecer o `RealSentryClientAdapter` ao seu Provider/GetIt para que o `SentryLoggerImpl` utilize a instância real.*

### Passo 5: Teste Real (Fase Final)
Como implementador, não crie botões intrusivos na UI para testar. Force um erro silencioso durante o `initState` ou através de um `Command` qualquer enviando `AcdgLogger.log('Teste de Integracao Sentry', LogLevel.fatal)` e confira se o evento é capturado. Se não houver problemas e os pipelines aceitarem o Bitwarden BWS, o trabalho estará concluído.

Mãos à obra, aguardo o relatório de implementação para revisão final!