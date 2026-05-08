# Subcommands — `noun verb` e Consistência

> "Quando uma ferramenta cresce, organize por substantivo (recurso) e verbo (ação)."
>
> Baseado em `CLI_Guidelines_Full.md` §"Subcommands" e §"Future-proofing".

## A Hierarquia Certa

```
acdg <noun> <verb> [flags]
```

Exemplos do `apps/cli/`:

```
acdg patient register
acdg patient list
acdg patient get <id>
acdg patient discharge <id>

acdg family add
acdg family remove
acdg family update-identity
acdg family assign-caregiver

acdg auth login
acdg auth logout
acdg auth status

acdg lookup create
acdg lookup get
acdg lookup request approve     ← 3 níveis quando faz sentido
```

**`noun verb` >> `verb noun`** porque:
- Tab-completion fica natural (`acdg patient <TAB>` mostra ações).
- Help organizado: `acdg patient --help` lista verbos do recurso.
- Crescimento orgânico: novo verbo = novo subsubcomando, sem coliding.

## Consistência Transversal

Para um mesmo verbo em recursos diferentes, **mesmas flags na mesma posição**:

| Verbo | Flags esperadas |
|-------|-----------------|
| `list` | `--output`, `--limit`, `--page`, `--filter`, `--sort` |
| `get <id>` | `--output` |
| `create` / `register` / `add` | `--from-file`, `--dry-run`, `--output` |
| `update` | `--from-file`, `--dry-run`, `--output`, `--if-version` |
| `delete` / `remove` | `--force`, `--dry-run`, `--yes` |

**Regra**: se você adicionou `--output` ao `patient list`, **adicione também** ao `family list`, `lookup list`, `team list`. Inconsistência aqui é o que faz `aws-cli` ser caótico e `gh` agradável.

## Hierarquia em Dart (`CommandRunner`)

```dart
class PatientCommand extends Command<int> {
  PatientCommand() {
    addSubcommand(PatientRegisterCommand());
    addSubcommand(PatientGetCommand());
    addSubcommand(PatientListCommand());
    addSubcommand(PatientDischargeCommand());
  }
  @override String get name => 'patient';
  @override String get description => 'Gestão de pacientes.';
}

// no CliRunner
runner.addCommand(PatientCommand());
runner.addCommand(FamilyCommand());
runner.addCommand(AuthCommand());
```

Cada `Command` filho herda flags globais do parent automaticamente quando adicionadas em `runner.argParser`.

## Sem Catch-All

```bash
# RUIM — bomba-relógio
$ mycmd unknown-thing      # cai num "run" implícito

# CERTO
$ mycmd unknown-thing
error: comando "unknown-thing" não existe.
hint:  rode `mycmd help` para ver a lista.
```

**Por quê**: se hoje `mycmd echo` cai num default e amanhã você adiciona `mycmd echo` real, todos os scripts antigos quebram silenciosamente.

`package:args` já recusa subcomandos desconhecidos. **Não monkey-patch isso.**

## Sem Auto-Abreviação

```bash
# RUIM — bloqueia evolução
$ mycmd ins        # = mycmd install (auto-completa)

# Depois você quer adicionar mycmd inspect → ambíguo, breaking change.

# CERTO
$ mycmd ins
error: comando "ins" não existe. Você quis dizer:
  install
  inspect
```

**Aliases explícitos são OK**:

```dart
class PatientListCommand extends Command<int> {
  @override String get name => 'list';
  @override List<String> get aliases => const ['ls'];   // EXPLÍCITO, documentado
  ...
}
```

## Naming dos Subcomandos

- **Lowercase**.
- **Hyphen-separated** se composto: `update-identity`, `assign-caregiver`.
- **Verbos imperativos**: `register`, não `registers` ou `registered`.
- **Recursos no singular**: `patient list`, não `patients list`. (Heroku, gh, kubectl divergem aqui — escolha um padrão e mantenha. ACDG usa singular.)
- **Sem palavras genéricas demais**: evite `do`, `run`, `exec` como verbo principal.
- **Sem ambiguidade**: `update` e `upgrade` no mesmo binário confunde — escolha um.

## 3 Níveis Quando Justifica

```
acdg lookup request create
acdg lookup request approve
acdg lookup request reject
acdg lookup request list
```

Use 3 níveis quando o "verbo do recurso" tem ele mesmo um sub-recurso. Não force 3 níveis para parecer profundo — `acdg auth login` (2 níveis) é mais claro que `acdg auth session create` (3).

## Flags Globais vs Locais

| Tipo | Onde |
|------|------|
| **Globais** (afeta toda CLI) | No `CommandRunner.argParser`: `--bff`, `--output`, `--quiet`, `--no-color`, `--config` |
| **Locais** (específicas do comando) | No `Command.argParser`: `--cpf` em `patient register` |

**Não duplique**. Se `--output` é global, NÃO adicione novamente em cada subcomando.

## Help Top-Level

```
$ acdg
Conecta Raros — operações via CLI.

USAGE
  $ acdg <recurso> <verbo> [flags]

RECURSOS
  auth         Autenticação (login, logout, status, refresh)
  patient      Pacientes (register, get, list, discharge, ...)
  family       Composição familiar
  assessment   Avaliações sociais
  care         Atendimentos
  protection   Proteção e violações
  lookup       Tabelas de domínio
  team         Equipe e profissionais
  health       Diagnóstico do sistema

GLOBAL FLAGS
  --bff <url>           URL do BFF (default: $ACDG_BFF_URL ou staging)
  -o, --output <fmt>    auto | json | yaml | table (default: auto)
  -q, --quiet           Silencia logs informativos
  --no-color            Desabilita cor

EXAMPLES
  $ acdg auth login
  $ acdg patient list
  $ acdg patient register --cpf 12345678901 --name "João"

Para detalhes: `acdg help <recurso>` ou `acdg <recurso> --help`.
Documentação: https://docs.acdg.dev/cli
```

## Anti-patterns

- **Mistura `noun verb` e `verb noun`**: `acdg patient register` E `acdg register-patient` no mesmo binário.
- **Catch-all subcomando** que cai num default.
- **Auto-abreviação** sem aliases explícitos.
- **Flag global redefinida** localmente com semântica diferente.
- **Verbos sinônimos**: `update` vs `upgrade`, `delete` vs `remove`, `list` vs `ls` (escolha um e use alias).
- **Singular vs plural inconsistente**: `patient` e `patients` no mesmo binário.
- **Hidden subcommands** sem deprecation — quem usa quebra na próxima versão.

## Future-Proofing

Quando precisar mudar:

1. **Additive sempre que possível**. Adicionar nova flag não quebra ninguém.
2. **Deprecation com warning**: `--old-flag` ainda funciona, mas imprime em stderr "deprecated, use --new-flag".
3. **Major version** para breaking changes. Documente em CHANGELOG.
4. **Aliases para renames**: `acdg list-patients` → alias para `acdg patient list`, com warning de uma versão.

## Cheat: Estrutura ACDG (referência)

```
acdg
├── auth       login, logout, status, refresh
├── patient    register, get, list, discharge, readmit, withdraw, audit, admit
├── family     add, remove, update-identity, assign-caregiver
├── assessment health, housing, education, socioeconomic, work-income,
│              community-support, social-health-summary
├── care       appointment, intake
├── protection referral, violation, placement
├── lookup     create, get, update, toggle, batch, request {create, list, approve, reject}
├── team       list, get, search, ... (9 verbos)
└── health     ping, status
```

Esse é o estado atual em `apps/cli/lib/src/commands/`. Mantenha.
