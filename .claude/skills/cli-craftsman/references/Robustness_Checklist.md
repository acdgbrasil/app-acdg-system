# Robustness — Checklist Operacional

> "Robustness is both an objective and a subjective property. Software should be robust, but it should also feel robust."
>
> Baseado em `CLI_Guidelines_Full.md` §"Robustness" e §"Signals and control characters".

## Objetivo vs Subjetivo

- **Objetivo**: timeout, idempotência, validação. Mensurável.
- **Subjetivo**: usuário sente que NÃO vai quebrar. Atenção a detalhes.

## Checklist — 18 Pontos

### Responsividade
- [ ] **< 100ms** para imprimir ALGO (mesmo "Carregando...").
- [ ] **Spinner em stderr** para operações > 2s.
- [ ] **Progress bar com ETA** se tamanho conhecido.
- [ ] **Sem animação em não-TTY** (CI logs ficam limpos).

### Network / I/O
- [ ] **Timeout configurável** (`--timeout=30s`) com default sensato (15-30s para HTTP).
- [ ] **Retry com backoff exponencial** para erros transientes (5xx, network).
- [ ] **Sem retry** em 4xx (erro do cliente, não vai melhorar).
- [ ] **Idempotência** onde possível: re-rodar não duplica.
- [ ] **Recoverable**: `<up><enter>` retoma de onde parou (estado em XDG cache).

### Sinais
- [ ] **`Ctrl-C` (SIGINT)** imprime "cancelando..." imediatamente.
- [ ] **Cleanup com timeout** — não trava forever no cleanup.
- [ ] **Segundo `Ctrl-C`** força saída imediata (`exit(130)`).
- [ ] **`SIGTERM`** trata como `SIGINT` (deploys/k8s).
- [ ] **`SIGPIPE`** sai limpo (caso `mycmd | head` feche o pipe).

### Validação
- [ ] **Input validado ANTES** de chamar rede/disk.
- [ ] **Erros bons** (cf. `Output_And_Errors.md`) — humano + hint.
- [ ] **Edge cases**: input vazio, gigante, bytes inválidos, encoding.
- [ ] **Crash-only**: prefira sair imediatamente a tentar reparar estado complexo.

## Padrão Dart: Cancelamento Limpo

```dart
import 'dart:async';
import 'dart:io';

Future<int> run(List<String> args) async {
  final cancelToken = Completer<void>();
  late StreamSubscription sigintSub;
  bool firstSigint = true;

  sigintSub = ProcessSignal.sigint.watch().listen((_) {
    if (firstSigint) {
      firstSigint = false;
      stderr.writeln('\nCancelando... (Ctrl-C novamente força saída)');
      cancelToken.complete();
      Timer(Duration(seconds: 5), () {
        stderr.writeln('Cleanup demorou demais. Saindo.');
        exit(130);
      });
    } else {
      exit(130);
    }
  });

  try {
    return await _doWork(cancelToken.future);
  } finally {
    await sigintSub.cancel();
  }
}
```

## Padrão Dart: Timeout em HTTP

```dart
final dio = Dio(BaseOptions(
  baseUrl: bffUrl,
  connectTimeout: const Duration(seconds: 5),
  sendTimeout:    const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 30),
));

// Override por request
final resp = await dio.get('/patient', options: Options(
  receiveTimeout: Duration(seconds: timeoutSec ?? 30),
));
```

## Padrão Dart: Retry com Backoff

```dart
Future<T> retryWithBackoff<T>(
  Future<T> Function() op, {
  int maxAttempts = 3,
  Duration baseDelay = const Duration(milliseconds: 200),
}) async {
  var attempt = 0;
  while (true) {
    try {
      return await op();
    } catch (e) {
      attempt++;
      if (attempt >= maxAttempts) rethrow;
      if (!_isTransient(e)) rethrow;
      final delay = baseDelay * (1 << (attempt - 1)); // 200, 400, 800ms
      stderr.writeln('Tentativa $attempt falhou (${e.runtimeType}). '
                     'Retry em ${delay.inMilliseconds}ms...');
      await Future.delayed(delay);
    }
  }
}

bool _isTransient(Object e) {
  if (e is DioException) {
    final code = e.response?.statusCode;
    if (code == null) return true;     // network failure
    return code >= 500 && code < 600;  // 5xx
  }
  return false;
}
```

## Padrão: Idempotência

Para operações de "registro", aceite uma chave de idempotência:

```bash
$ acdg patient register --cpf 123 --idempotency-key abc123
```

```dart
argParser.addOption('idempotency-key',
    help: 'UUID. Re-rodar com a mesma chave não duplica.');
```

No BFF, cache de respostas por chave por 24h.

Se o usuário NÃO passar, **gere automaticamente** baseado em hash do payload + timestamp em janela. Re-execução em < 1min reusa resposta.

## Padrão: Estado Recuperável

```dart
// XDG cache para estado em progresso
final stateFile = File(
  '${Platform.environment['XDG_CACHE_HOME'] ?? "${Platform.environment['HOME']}/.cache"}'
  '/acdg/in-progress.json');

// Salva antes de operação longa
await stateFile.writeAsString(jsonEncode({
  'op': 'patient-register',
  'payload': payload.toJson(),
  'started_at': DateTime.now().toIso8601String(),
}));

// Limpa ao concluir
if (await stateFile.exists()) await stateFile.delete();

// Em próximo run
if (await stateFile.exists()) {
  stderr.writeln('Operação anterior interrompida. Retomar? [y/N]');
  // ...
}
```

## Padrão: Dry-Run

**Toda operação destrutiva** ou que causa side effect na rede deve ter `--dry-run`:

```dart
argParser.addFlag('dry-run', abbr: 'n', negatable: false,
    help: 'Mostra o que seria feito sem executar.');

@override
Future<int> run() async {
  final payload = _buildPayload();
  if (argResults!['dry-run'] as bool) {
    stdout.writeln('--- DRY RUN ---');
    stdout.writeln(formatter.render(payload));
    stdout.writeln('--- Não foi enviado ao BFF ---');
    return 0;
  }
  return await _execute(payload);
}
```

## Padrão: Confirmação Destrutiva (3 Níveis)

| Nível | Quando | Como |
|-------|--------|------|
| **Mild** | `delete` de arquivo/registro local | `[y/N]` simples |
| **Moderate** | `delete` remoto, bulk update | Mostra diff/preview, depois `[y/N]` |
| **Severe** | Drop de tudo, dados irreversíveis | Pede digitar nome do recurso |

```dart
Future<bool> confirmSevere(String resourceName) async {
  if (argResults!['force'] as bool) return true;
  if (!stdin.hasTerminal) {
    stderr.writeln('error: operação severa requer --force ou TTY.');
    return false;
  }
  stderr.writeln('PERIGO: vai deletar $resourceName irreversivelmente.');
  stderr.write('Digite "$resourceName" para confirmar: ');
  final answer = stdin.readLineSync();
  return answer?.trim() == resourceName;
}
```

## Padrão: Validação Local Forte

```dart
@override
Future<int> run() async {
  // 1. Parse args
  final cpfRaw = argResults!['cpf'] as String?;
  if (cpfRaw == null) {
    stderr.writeln('error: --cpf é obrigatória.');
    return 64;
  }

  // 2. Domain validation (smart constructor)
  final cpf = CPF.tryParse(cpfRaw);
  if (cpf == null) {
    stderr.writeln('error: CPF inválido: "$cpfRaw"');
    stderr.writeln('hint:  use 11 dígitos sem pontuação.');
    return 64;
  }

  // 3. Cross-field validation (gender + pregnancy, etc.)
  final cross = CrossValidator.validate(payload);
  if (cross.isErr) {
    stderr.writeln('error: ${cross.error.message}');
    return 64;
  }

  // 4. Network call (com timeout/retry)
  return await _network(payload);
}
```

## Anti-patterns

- **Sem timeout** em chamada HTTP — trava infinito.
- **Retry em 4xx** — só piora, gasta rate-limit.
- **Cleanup sem timeout** — `Ctrl-C` não funciona durante "shutting down...".
- **Sem `--dry-run`** em operação destrutiva.
- **Sem `--yes`/`--force`** em operação destrutiva — bloqueia automação.
- **Estado perdido** — re-rodar refaz tudo do zero.
- **`exit(1)`** para todo erro — script não consegue distinguir.
- **Validação só no servidor** — ux ruim, latência alta.
- **Spinner sem ETA** parado em "loading" por 5min — usuário não sabe se travou.
- **Bypass `Ctrl-C`** durante "fase crítica" — usuário fica refém.

## Tabela: Modos de Falha → Exit Codes

| Tipo | Código | Convenção |
|------|--------|-----------|
| Sucesso | 0 | — |
| Erro genérico | 1 | — |
| Uso inválido | 64 | EX_USAGE |
| Dado inválido | 65 | EX_DATAERR |
| Não pode abrir input | 66 | EX_NOINPUT |
| Endereço/usuário desconhecido | 67/68 | EX_NOUSER/EX_NOHOST |
| Serviço indisponível | 69 | EX_UNAVAILABLE |
| Erro interno do software | 70 | EX_SOFTWARE |
| Erro de OS | 71 | EX_OSERR |
| Permissão negada | 77 | EX_NOPERM |
| Config inválida | 78 | EX_CONFIG |
| Terminado por SIGINT (Ctrl-C) | 130 | 128+SIGINT(2) |
| Terminado por SIGTERM | 143 | 128+SIGTERM(15) |

Mapeie sua sealed `CliError` hierarchy para esses códigos.
