# Arguments & Flags — Convenções e Naming

> Args = posicional (`cp <src> <dst>`). Flags = nomeado (`--output json`).
>
> Baseado em `CLI_Guidelines_Full.md` §"Arguments and flags".

## Regra Geral

**Prefira flags a args.** Mais explícito, mais extensível, melhor para scripts.

| Use args para... | Use flags para... |
|------------------|-------------------|
| Lista variável do mesmo tipo (`rm a.txt b.txt c.txt`) | Configuração, opções, parâmetros nomeados |
| Comando primário óbvio (`cp <src> <dst>`) | Qualquer coisa que precisa contexto |
| Globs (`mycmd *.yaml`) | Tudo que pode ser ambíguo |

## Nomes Padrão (use sempre que aplicável)

| Short | Long | Significado |
|-------|------|-------------|
| `-h` | `--help` | Ajuda — **EXCLUSIVAMENTE** |
| `-v` | `--verbose` | Detalhado (use `-V` para version se conflitar) |
| | `--version` | Versão |
| `-q` | `--quiet` | Silencia logs informativos |
| `-f` | `--force` | Pula confirmação destrutiva |
| `-n` | `--dry-run` | Valida sem executar |
| `-o` | `--output` | Formato/destino de saída |
| `-p` | `--port` | Porta de rede |
| `-u` | `--user` | Usuário |
| `-a` | `--all` | Inclui itens normalmente filtrados |
| `-d` | `--debug` | Logs de debug |
| | `--json` | Output em JSON (atalho para `--output json`) |
| | `--plain` | Output em texto puro tabular |
| | `--no-color` | Desabilita cor |
| | `--no-input` | Desabilita prompts interativos |
| | `--yes` | Confirma todas as prompts (não-interativo) |
| | `--config` | Caminho para arquivo de config |

## Long Form é Obrigatório

**TODA flag short tem versão long.** Scripts devem usar a long para legibilidade:

```bash
# ruim em script
acdg p l -q -o json

# certo em script
acdg patient list --quiet --output json
```

**Nunca** crie short flag sem long. Reserve shorts para flags **muito** usadas.

## Anatomia em Dart (`package:args`)

```dart
argParser
  // Flag boolean — valor opcional, com negação automática
  ..addFlag('quiet', abbr: 'q', negatable: false,
            help: 'Silencia logs informativos.')

  // Option — valor obrigatório quando passada
  ..addOption('output', abbr: 'o',
              allowed: ['auto', 'json', 'yaml', 'table'],
              defaultsTo: 'auto',
              help: 'Formato de saída.')

  // Multi-option — pode ser passada várias vezes
  ..addMultiOption('include',
                   help: 'Tags a incluir (pode repetir).')

  // Option mandatória
  ..addOption('cpf', mandatory: true,
              help: 'CPF do paciente.');
```

## Formatos Aceitos

POSIX/GNU:
```
-q                    short flag boolean
-q -o json            várias flags
-qo json              flags agrupadas (Dart args NÃO suporta — use forma longa)
--quiet               long flag boolean
--output json         long option com espaço
--output=json         long option com igual
--                    fim de flags (resto é arg posicional)
```

`package:args` aceita `--output json` E `--output=json`. **Sempre suporte ambos.**

## Validação de Valores

```dart
final cpfRaw = argResults!['cpf'] as String;
final cpf = CPF.tryParse(cpfRaw);
if (cpf == null) {
  stderr.writeln('error: CPF inválido: "$cpfRaw"');
  stderr.writeln('hint:  use 11 dígitos sem pontuação.');
  return 64; // EX_USAGE
}

final output = argResults!['output'] as String;
// `allowed:` em addOption já valida — args lança UsageException
```

**Não delegue validação ao backend.** Falhe rápido localmente para feedback < 100ms.

## Stdin/Stdout via `-`

Convenção UNIX: `-` representa stdin/stdout.

```dart
final fromFile = argResults!['from-file'] as String?;
final input = switch (fromFile) {
  null => null,
  '-'  => await stdin.transform(utf8.decoder).join(),
  _    => File(fromFile).readAsStringSync(),
};
```

Permite:
```bash
$ cat paciente.yaml | acdg patient register --from-file -
$ acdg patient list --output json | acdg patient export --from-file -
```

## Segredos: NUNCA via Flag

```bash
# ERRADO — vaza em ps, history, logs
$ acdg auth login --password "minhasenha"

# Certo — flag aceita ARQUIVO
$ acdg auth login --password-file ~/.secrets/acdg

# Certo — stdin
$ pass acdg | acdg auth login --password-stdin

# Certo — interativo (echoMode = false)
$ acdg auth login
Password: ********
```

```dart
// stdin sem echo
stdin.echoMode = false;
final password = stdin.readLineSync();
stdin.echoMode = true;
```

## Ordem de Args/Flags Livre (quando possível)

```bash
# Ambos devem funcionar
$ acdg --output json patient list
$ acdg patient list --output json
$ acdg patient --output json list  # esse pode falhar dependendo da hierarquia
```

`package:args` por default torna flags do parent visíveis em todos os filhos — bom comportamento. **Teste isso**.

## Flags Negáveis

```dart
argParser.addFlag('color', defaultsTo: true);
// usuário pode passar --no-color → false, --color → true
```

**Boa prática**: para defaults `true`, exponha `--no-X`. Para defaults `false`, deixe apenas `--X`.

## Multi-valor

```dart
// Repetível
argParser.addMultiOption('tag');
// $ acdg patient list --tag urgent --tag pendente

// Ou separador (menos comum, evite)
// $ acdg patient list --tag urgent,pendente
```

Prefira **repetição** a **separador por vírgula** — mais limpo, sem ambiguidade com vírgula em valores.

## Especial: `--`

Tudo após `--` é arg posicional, mesmo que comece com `-`:

```bash
$ acdg run -- --weird-arg-with-dashes
```

`package:args` lida com isso automaticamente.

## Anti-patterns

- **Args posicionais demais** (`mycmd a b c d e`) — o usuário precisa decorar ordem.
- **Short flag única** sem long — não pode usar em script.
- **Short conflitante** (`-V` para version e verbose) — confunde.
- **`-h` significando "host"** — overload do help.
- **Senha em flag** — vaza em todo lugar.
- **Validação só no backend** — feedback lento, ux ruim.
- **Sem `--`** — força reescrita quando arg começa com `-`.
- **Defaults invisíveis** — sempre mostre default no help.

## Cheat: Decisão Rápida

| Pergunta | Resposta |
|----------|----------|
| "Adiciono short flag?" | Só se for muito usada e não conflitar |
| "Args ou flags?" | Flags, exceto lista variável do mesmo tipo |
| "Como aceito stdin?" | `-` como valor de flag de arquivo |
| "Como aceito senha?" | `--xxx-file` ou stdin com echo off, NUNCA flag |
| "Default valor mostrado?" | Sempre, em parênteses no help: `(default: auto)` |
| "Flag obrigatória?" | `mandatory: true` em `package:args` |
| "Repetível?" | `addMultiOption` |
| "Boolean negável?" | `addFlag(... defaultsTo: true)` → `--no-X` aparece |
