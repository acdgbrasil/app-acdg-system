# Output & Errors — Disciplina de I/O

> "Expect the output of every program to become the input to another, as yet unknown, program." — Doug McIlroy.
>
> Baseado em `CLI_Guidelines_Full.md` §"Output" e §"Errors".

## A Regra de Ouro

| Stream | Conteúdo |
|--------|----------|
| `stdout` | DADOS — o que `\| jq`, `\| grep`, `\| awk` consome |
| `stderr` | MENSAGENS — logs, progresso, avisos, erros, prompts |

Em Dart:

```dart
stdout.writeln(jsonEncode(data));   // dado → pipe
stderr.writeln('Carregando...');    // mensagem → terminal
```

**NUNCA use `print()` para dados estruturados** se houver chance de pipe — `print()` vai para `stdout`, mas misturar mensagens fica difícil de auditar.

## Detecção de TTY

```dart
final outIsTty = stdout.hasTerminal;        // stdout é terminal interativo?
final errIsTty = stderr.hasTerminal;
final inIsTty  = stdin.hasTerminal;         // input vem do teclado?
```

**Regras**:
- `stdout` não-TTY → desligue cor, animação, tabela com auto-width.
- `stdin` não-TTY → desligue prompts (use `--no-input` implícito).
- `stderr` pode ter cor mesmo se `stdout` for pipe (logs ainda vão para o usuário).

## Formato de Saída — Os Quatro Modos

| Modo | Quando | Ativação |
|------|--------|----------|
| **auto** | default | TTY → tabela colorida; pipe → texto plano |
| **json** | scripts | `--output json` ou `--json` |
| **yaml** | configs/diffs | `--output yaml` |
| **table** | forçar tabela | `--output table` |
| **plain** | tabular sem cor/multi-line | `--plain` |
| **quiet** | só erros | `-q` / `--quiet` |
| **verbose** | debug | `-v` / `--verbose` |

No `apps/cli/`, isso já é resolvido por `resolveFormatter` em `lib/src/formatters/`. Mantenha o padrão.

## Cores: Detecção, NO_COLOR, FORCE_COLOR

A convenção `no-color.org` é **lei de facto**. Implemente assim:

```dart
bool useColor() {
  if (Platform.environment['NO_COLOR']?.isNotEmpty ?? false) return false;
  if (Platform.environment['FORCE_COLOR']?.isNotEmpty ?? false) return true;
  if (Platform.environment['TERM'] == 'dumb') return false;
  if (!stdout.hasTerminal) return false;
  return true;
}
```

**Nunca**: `--no-color` apenas (sem respeitar `NO_COLOR`).
**Nunca**: cor em `stderr` quando o usuário pediu `--quiet`.

## JSON — Como Fazer Direito

```dart
// Linha por registro (JSONL/NDJSON) — ideal para streaming e grep
for (final patient in patients) {
  stdout.writeln(jsonEncode(patient.toJson()));
}

// Array completo — quando o consumer espera JSON único
stdout.writeln(jsonEncode({
  'meta': {'count': patients.length, 'timestamp': DateTime.now().toIso8601String()},
  'data': patients.map((p) => p.toJson()).toList(),
}));
```

**Regras de output JSON**:
1. Sempre **um objeto raiz** ou **um JSON por linha (JSONL)**. Decida e mantenha.
2. **Sem ANSI escapes** dentro de strings JSON.
3. **Datas em ISO 8601** (`2026-05-04T12:00:00Z`).
4. **Erros também em JSON** quando `--output json`: `{"error":{"code":"AUTH_EXPIRED","message":"...","hint":"..."}}` em stderr (sim, JSON em stderr quando fizer sentido).
5. **Preserve campos desconhecidos** se for proxy — não silenciosamente filtrar.

## Paginação (`less`)

```dart
// Page só se for TTY e a saída for grande
if (stdout.hasTerminal && lines.length > stdout.terminalLines) {
  final pager = Platform.environment['PAGER'] ?? 'less -FIRX';
  // pipe lines para o pager
}
```

`less -FIRX`: `-F` sai se cabe na tela, `-I` ignore-case, `-R` cores ANSI, `-X` não limpa tela ao sair.

**Não pague output em pipe**. `git diff | cat` quebra se você forçar pager.

## Mensagens de Erro

### Estrutura recomendada

```
<vermelho>error:</vermelho> <mensagem humana, 1 linha>
hint:  <ação acionável, 1 linha>
detail (opcional): <contexto adicional>

Para mais informações: --verbose ou https://docs.acdg.dev/errors/<código>
```

### Exemplos bons

```
error: CPF inválido.
hint:  use 11 dígitos sem pontuação. Recebido: "123.456.789-01" (15 chars).

error: Sessão expirada.
hint:  rode `acdg auth login` para renovar.

error: BFF respondeu 503 (Service Unavailable).
hint:  o serviço pode estar passando por manutenção. Tente novamente em 30s.
       Status: https://status.acdg.dev
```

### Exemplos ruins

```
Error: AuthError(code: 401, message: ..., stackTrace: ...)
[2026-05-04 12:00:00] [ERROR] [auth.dart:42] failed to authenticate: ...
Exception: NoSuchMethodError: ...
```

### Para erros inesperados

Salve traceback em `$XDG_CACHE_HOME/acdg/last-error.log` e mostre apenas:

```
error: ocorreu um erro inesperado.
detail: <1 linha resumindo>

Stack trace salvo em: ~/.cache/acdg/last-error.log
Reporte em: https://github.com/acdg/cli/issues/new?template=bug.md
```

### Múltiplos erros similares

Em vez de imprimir 47 linhas iguais, **agrupe**:

```
error: 47 arquivos com payload inválido.

Tipo                       Quantidade  Exemplo
--------------------------------------------------------
CPF inválido                       12  paciente_03.yaml
Birthdate fora do range             8  paciente_18.yaml
Campo "name" vazio                 27  paciente_22.yaml

Para detalhes: --verbose
```

## Progresso — Spinner vs Bar vs Logs

| Situação | Use |
|----------|-----|
| Operação curta (< 2s) | Nada |
| Operação longa, tamanho conhecido | Progress bar |
| Operação longa, tamanho desconhecido | Spinner com ETA opcional |
| Operações paralelas | Multi-bar (com cuidado) |
| Pipe / não-TTY | Linhas de log simples |

**SEMPRE em stderr**, nunca em stdout. **SEMPRE detecte TTY** — em CI vira lixo se não.

## Anti-patterns

- **`print()` para dados que devem ser JSONL** — sem timestamp, sem newline correto.
- **Stack trace cru** sem rede de redação.
- **Cor em CI** — Christmas tree.
- **Spinner em pipe** — caracteres `\r` viram lixo no log.
- **Output que muda entre versões** sem deprecation — quebra scripts.
- **`stderr` tratado como log file** com prefixos `[ERROR]`/`[INFO]` por default.
- **Saída útil só em verbose** — usuário tem que descobrir `-v` para ver progresso básico.

## Tabela de Decisão

| Situação | Output |
|----------|--------|
| Usuário humano em TTY, comando "list" | Tabela colorida + total no rodapé |
| Pipe para `\| jq` | JSONL em stdout |
| CI / script | `--output json` explícito (de novo, JSONL) |
| `--quiet` | Apenas erros em stderr |
| Erro fatal | Stderr, vermelho na palavra `error:`, hint logo abaixo |
| Operação OK silenciosa (cp-style) | Nada por default — exit 0 fala |
| Operação OK loud (push-style) | Resumo do que mudou em stderr |
