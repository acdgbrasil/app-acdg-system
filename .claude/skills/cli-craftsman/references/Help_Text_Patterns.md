# Help Text — Patterns de Descobribilidade

> Help text é a primeira impressão da CLI. Acerte aqui e o usuário vira fã. Erre e ele vai pro StackOverflow.
>
> Baseado em `CLI_Guidelines_Full.md` §"Help" e §"Documentation".

## Os 7 Mandamentos

1. **Concise help quando rodado sem args** (se o comando exige args).
2. **Full help com `-h` e `--help`** — ambos, sem exceção.
3. **`mycmd help <sub>`** equivale a `mycmd <sub> --help` (estilo `git`).
4. **Lead with examples** — exemplos antes da listagem de flags.
5. **Bold sections** (`USAGE`, `OPTIONS`, `EXAMPLES`, `COMMANDS`) — terminal-independent.
6. **Link para a doc web** no rodapé.
7. **Sugira correções de typo** (`Did you mean ...?`).

## Estrutura Canônica (estilo Heroku/gh)

```
Registra um novo paciente no sistema.

USAGE
  $ acdg patient register [flags]

OPTIONS
  --cpf <cpf>            CPF (apenas dígitos, 11 chars).
  --name <name>          Nome completo (até 200 chars).
  --birthdate <date>     YYYY-MM-DD.
  --from-file <path>     Lê payload YAML de arquivo (use "-" para stdin).
  -n, --dry-run          Valida e mostra payload sem chamar o BFF.
  -o, --output <fmt>     auto | json | yaml | table (default: auto)
  -q, --quiet            Silencia logs informativos.

EXAMPLES
  $ acdg patient register --cpf 12345678901 --name "João Silva" \
        --birthdate 1990-01-15
  $ acdg patient register --from-file paciente.yaml
  $ cat paciente.json | acdg patient register --from-file - --output json
  $ acdg patient register --cpf 12345678901 --name "Teste" --dry-run

ENVIRONMENT
  ACDG_BFF_URL    URL do BFF (default: https://bff.staging.acdg.dev).
  NO_COLOR        Desabilita cores na saída.

EXIT CODES
  0    sucesso
  1    erro genérico
  64   uso inválido (flags faltando ou inválidas)
  77   permissão negada (sessão expirada — rode `acdg auth login`)

DOCUMENTAÇÃO
  https://docs.acdg.dev/cli/patient/register
```

## Implementação em Dart (`package:args`)

```dart
class PatientRegisterCommand extends Command<int> {
  PatientRegisterCommand() {
    argParser
      ..addOption('cpf', help: 'CPF (apenas dígitos, 11 chars).')
      ..addOption('name', help: 'Nome completo.')
      ..addOption('birthdate', help: 'YYYY-MM-DD.')
      ..addOption('from-file', help: 'Lê YAML de arquivo (use "-" para stdin).')
      ..addFlag('dry-run', abbr: 'n', negatable: false,
          help: 'Valida e mostra payload sem chamar o BFF.');
  }

  @override
  String get name => 'register';

  @override
  String get description => 'Registra um novo paciente.';

  @override
  String get invocation => 'acdg patient register [flags]';

  @override
  String get usageFooter => '''

EXAMPLES
  \$ acdg patient register --cpf 12345678901 --name "João Silva" \\
        --birthdate 1990-01-15
  \$ acdg patient register --from-file paciente.yaml
  \$ acdg patient register --cpf 12345678901 --name "T" --dry-run

ENVIRONMENT
  ACDG_BFF_URL    URL do BFF.
  NO_COLOR        Desabilita cores.

EXIT CODES
  0   sucesso  |  1  erro genérico  |  64  uso inválido  |  77  auth expirada

DOCUMENTAÇÃO
  https://docs.acdg.dev/cli/patient/register
''';
}
```

## Bold/Headings sem Quebrar Pipe

Helpers ANSI:

```dart
String bold(String s) =>
    stdout.hasTerminal ? '\x1B[1m$s\x1B[0m' : s;
```

A regra: **só aplique escape ANSI quando `stdout.hasTerminal` for `true`**. Senão, terminal sem suporte e logs de CI viram lixo. (Cf. `Output_And_Errors.md`.)

## Sugestões de Typo

`package:args` já oferece sugestão padrão:

```
$ acdg patien register
Could not find a command named "patien".

Did you mean one of these?
  patient
```

Para typo em flags, o `args` lança `ArgParserException` com lista de candidatos. Capture e renderize em texto humano:

```dart
try {
  return await runner.run(arguments) ?? 0;
} on UsageException catch (e) {
  stderr.writeln('error: ${e.message}');
  stderr.writeln();
  stderr.writeln(e.usage);
  return 64; // EX_USAGE
}
```

## `acdg help <sub>` (estilo `git help <sub>`)

```dart
class _HelpCommand extends Command<int> {
  _HelpCommand(this.runner);
  final CommandRunner<int> runner;
  @override String get name => 'help';
  @override String get description => 'Mostra ajuda de um subcomando.';
  @override String get invocation => 'acdg help <subcomando>';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      stdout.writeln(runner.usage);
      return 0;
    }
    final cmd = runner.commands[rest.first];
    if (cmd == null) {
      stderr.writeln('error: subcomando "${rest.first}" não existe.');
      return 64;
    }
    stdout.writeln(cmd.usage);
    return 0;
  }
}
```

## Anti-patterns

- **Help só na web**: o usuário está no terminal sem internet.
- **Listagem de flags sem exemplo**: 80% do uso é exemplo.
- **Help longo demais**: tela de 200 linhas espanta. Use `--help-long` ou link para docs.
- **`-h` significando outra coisa** (ex.: `tar -h` é "help" mas `wget -h` era host antigamente). Não overload.
- **Help sem ENVIRONMENT** quando há env vars relevantes.
- **Help sem EXIT CODES** quando há mais de 2 distintos.

## Links externos

- Heroku CLI Style Guide — `devcenter.heroku.com/articles/cli-style-guide`.
- gh CLI manual — `cli.github.com/manual` (boa referência de help text).
- man-pages(7) — convenções clássicas.
