# CLI Anti-Patterns — Catálogo

> Os erros que aparecem em CLIs ruins, com remediação concreta.
>
> Compilação cruzada com `CLI_Guidelines_Full.md` (todas as seções).

## Estrutura

Cada item: **(Sintoma) — (Por quê é ruim) — (Correção)**.

---

## Help & Discovery

### A1 — Help só na web
**Sintoma**: `mycmd --help` mostra `mycmd [options]. See https://docs.example.com.`
**Por quê é ruim**: o usuário está num terminal, possivelmente offline. Help no terminal é gratuito e instantâneo.
**Correção**: full help inline com EXEMPLOS primeiro, link para web no rodapé.

### A2 — Help sem exemplos
**Sintoma**: listagem mecânica de flags, zero exemplos.
**Por quê é ruim**: 80% do uso aprende-se por exemplo, não por ler signatures.
**Correção**: 2-3 exemplos concretos antes da seção `OPTIONS`.

### A3 — `-h` overloaded
**Sintoma**: `wget -h` significa "host", não "help".
**Por quê é ruim**: convenção universal espera `-h`/`--help` para help. Confunde fingers.
**Correção**: `-h` é help, sempre. Use `-H` ou `--host` para host.

### A4 — Sem sugestão de typo
**Sintoma**: `acdg patien register` → "comando inválido". Fim.
**Por quê é ruim**: o usuário digitou algo próximo, dê uma dica.
**Correção**: distância de Levenshtein contra subcomandos conhecidos. `package:args` já faz isso por default.

---

## Output

### A5 — `print()` no lugar errado
**Sintoma**: `print('Carregando...')` aparece no `| jq` e quebra parsing.
**Por quê é ruim**: `print()` vai para stdout. Logs devem ir para stderr.
**Correção**: `stderr.writeln('Carregando...')` para mensagens; `stdout.writeln(jsonEncode(...))` apenas para dados.

### A6 — JSON sempre, mesmo em TTY
**Sintoma**: `acdg patient list` cospe JSON cru no terminal humano.
**Por quê é ruim**: usuário em TTY quer ler. JSON é para script.
**Correção**: detecta TTY → tabela; pipe ou `--output json` → JSON.

### A7 — Cor sem detectar TTY
**Sintoma**: CI log cheio de `\x1B[31m...\x1B[0m`.
**Por quê é ruim**: terminal não-interativo não interpreta ANSI.
**Correção**: `stdout.hasTerminal` + respeitar `NO_COLOR`/`FORCE_COLOR`/`TERM=dumb`.

### A8 — Spinner em pipe
**Sintoma**: `acdg patient list | head` mostra `\r` repetidos no log.
**Por quê é ruim**: `\r` (carriage return) só funciona em terminal interativo.
**Correção**: spinner condicional a `stderr.hasTerminal`.

### A9 — Output instável entre versões
**Sintoma**: v2.0 muda formato da tabela, todos os scripts quebram.
**Por quê é ruim**: humanos podem se adaptar, scripts não.
**Correção**: `--output json` é contrato estável; texto humano pode evoluir.

### A10 — Stack trace cru por default
**Sintoma**: `Exception: NoSuchMethodError: ... at file.dart:123`.
**Por quê é ruim**: assusta usuário, não é acionável, pode vazar info interna.
**Correção**: capture, salve em `~/.cache/acdg/last-error.log`, mostre 1 linha humana + caminho do log.

### A11 — Logs com prefixo `[INFO]`/`[ERROR]` em stderr por default
**Sintoma**: `[INFO] [2026-05-04 12:00:00] [auth.dart:42] Carregando...` em stderr.
**Por quê é ruim**: stderr é mensagem ao usuário, não log file.
**Correção**: prefixos só em `--verbose` ou `--json-logs`.

---

## Args & Flags

### A12 — Args posicionais demais
**Sintoma**: `mycmd a b c d e` — usuário precisa decorar a ordem.
**Por quê é ruim**: ordem mágica, ambiguidade, impossível evoluir.
**Correção**: flags. `mycmd --src a --dst b --mode c`.

### A13 — Senha em flag
**Sintoma**: `acdg auth login --password senha123`.
**Por quê é ruim**: vaza em `ps`, em shell history, em logs de exec.
**Correção**: `--password-file <path>`, stdin, ou prompt com `echoMode=false`.

### A14 — Short flag sem long
**Sintoma**: `mycmd -X`, sem `--exclude`.
**Por quê é ruim**: scripts ilegíveis, futuro programador sofre.
**Correção**: TODA flag short tem long.

### A15 — Conflito de short
**Sintoma**: `-V` para version e verbose no mesmo binário.
**Por quê é ruim**: ambíguo, depende da ordem do parsing.
**Correção**: `-v` verbose, `--version` (sem short) para versão. Ou `-V` apenas para version.

### A16 — Flag obrigatória sem mensagem clara
**Sintoma**: `error: option --cpf` sem explicar que é obrigatória.
**Por quê é ruim**: forças o usuário a ler a fonte ou o `--help`.
**Correção**: `package:args` com `mandatory: true` lança mensagem clara.

### A17 — Default invisível
**Sintoma**: `--output` aceita `auto|json|yaml`, mas help não diz qual é o default.
**Por quê é ruim**: usuário não consegue prever comportamento.
**Correção**: `(default: auto)` no help.

### A18 — Sem `-` para stdin
**Sintoma**: `mycmd --from-file <path>` exige path real, não aceita `-`.
**Por quê é ruim**: quebra pipe (`cat x | mycmd --from-file -`).
**Correção**: aceite `-` como stdin/stdout em flags de file.

---

## Subcommands

### A19 — Catch-all subcomando
**Sintoma**: `mycmd unknown` cai num `run` default.
**Por quê é ruim**: bloqueia adicionar `mycmd unknown` real no futuro.
**Correção**: comando desconhecido = erro com sugestão.

### A20 — Auto-abreviação
**Sintoma**: `mycmd ins` = `mycmd install`.
**Por quê é ruim**: bloqueia `mycmd inspect` no futuro; quebra scripts.
**Correção**: aliases EXPLÍCITOS (`'ls'` para `'list'`).

### A21 — `update` E `upgrade`
**Sintoma**: dois subcomandos com semântica próxima.
**Por quê é ruim**: usuário nunca sabe qual usar.
**Correção**: escolha um. Se precisar diferenciar, use nomes mais específicos: `update-config` vs `upgrade-version`.

### A22 — Singular vs plural inconsistente
**Sintoma**: `acdg patient list` E `acdg lookups create`.
**Por quê é ruim**: usuário nunca lembra.
**Correção**: padronize. ACDG usa singular (`patient`, `family`, `lookup`).

### A23 — Mistura `noun verb` e `verb noun`
**Sintoma**: `acdg patient register` E `acdg register-family-member`.
**Por quê é ruim**: quebra mental model do usuário.
**Correção**: `noun verb` SEMPRE (ou `verb noun` SEMPRE). Não misture.

---

## Interactivity

### A24 — Prompt obrigatório sem fallback
**Sintoma**: comando trava em CI esperando "y/n" sem `--yes`.
**Por quê é ruim**: bloqueia automação.
**Correção**: detecta não-TTY → falha cedo com mensagem; sempre suporta `--yes` e `--no-input`.

### A25 — Senha com echo
**Sintoma**: usuário digita senha, aparece no terminal.
**Por quê é ruim**: shoulder-surfing, screen recording, log do terminal.
**Correção**: `stdin.echoMode = false` antes do `readLineSync`.

### A26 — Confirmação destrutiva ausente
**Sintoma**: `acdg patient delete <id>` deleta sem perguntar.
**Por quê é ruim**: dedos rápidos, dados perdidos.
**Correção**: `[y/N]` para mild; digitar nome do recurso para severe.

### A27 — `--force` ausente
**Sintoma**: confirmação obrigatória, sem como pular para script.
**Por quê é ruim**: bloqueia automação legítima.
**Correção**: `--force`/`--yes` pula confirmação.

---

## Robustness

### A28 — Sem timeout
**Sintoma**: HTTP request trava infinito.
**Por quê é ruim**: usuário tem que matar processo, sem feedback.
**Correção**: timeout default (15-30s) + `--timeout=Xs` configurável.

### A29 — Retry em 4xx
**Sintoma**: 401/403/404 dispara 3 retries.
**Por quê é ruim**: nunca vai melhorar; gasta rate-limit; mascara o erro.
**Correção**: retry só em 5xx, network errors, e timeout.

### A30 — `Ctrl-C` ignorado
**Sintoma**: comando não responde a Ctrl-C durante "fase crítica".
**Por quê é ruim**: usuário fica refém. Em alguns OS pode forçar SIGKILL e corromper estado.
**Correção**: SIGINT handler imprime "cancelando..." imediatamente, com timeout para cleanup. Segundo Ctrl-C força exit.

### A31 — `exit(1)` para tudo
**Sintoma**: `if (anyError) exit(1)`.
**Por quê é ruim**: script não consegue distinguir auth-expirada de api-down.
**Correção**: mapeie cada `CliError` para exit code distinto (cf. `Robustness_Checklist.md`).

### A32 — Estado perdido em re-run
**Sintoma**: usuário cancela, re-roda, refaz tudo do zero.
**Por quê é ruim**: tempo perdido, possivelmente custo de API.
**Correção**: persista progresso em `$XDG_CACHE_HOME/acdg/`, retome.

### A33 — Sem `--dry-run` em destrutivo
**Sintoma**: usuário não tem como ver o que vai acontecer antes.
**Por quê é ruim**: surpresa = dados perdidos.
**Correção**: `--dry-run` mostra payload sem executar.

---

## Configuration

### A34 — Segredo em env var óbvia
**Sintoma**: `ACDG_PASSWORD=...` no shell.
**Por quê é ruim**: env vars vazam (logs, `docker inspect`, `systemctl show`).
**Correção**: credential file em `$XDG_CONFIG_HOME` com `chmod 600`, ou keychain do OS.

### A35 — Config no `$HOME`, não em XDG
**Sintoma**: `~/.acdgrc` em vez de `~/.config/acdg/config.yaml`.
**Por quê é ruim**: polui $HOME, viola XDG Base Directory Spec.
**Correção**: respeite `$XDG_CONFIG_HOME` (default `~/.config`).

### A36 — Modificar config alheia silenciosamente
**Sintoma**: instalador adiciona linhas em `~/.bashrc` sem avisar.
**Por quê é ruim**: usuário perde controle.
**Correção**: ofereça `--install-completions`, mostre o que vai mudar, peça confirmação.

### A37 — Hierarquia de config errada
**Sintoma**: arquivo de sistema sobrescreve flag explícita.
**Por quê é ruim**: usuário não consegue overrride por linha de comando.
**Correção**: ordem **flag > env > .env > user > system**.

---

## Distribution

### A38 — Múltiplos arquivos espalhados
**Sintoma**: instalação coloca binário em `/usr/local/bin`, libs em `/opt/acdg`, configs em `/etc/acdg`, sem pacote.
**Por quê é ruim**: difícil de desinstalar.
**Correção**: single binary (`dart compile exe`), ou pacote nativo (deb/rpm/pkg/brew).

### A39 — Sem instruções de uninstall
**Sintoma**: README explica install, não uninstall.
**Por quê é ruim**: o momento mais comum de querer desinstalar é logo depois de instalar.
**Correção**: `acdg uninstall` ou seção `## Uninstalling` no README.

---

## Future-Proofing

### A40 — Breaking change sem deprecation
**Sintoma**: v2.0 muda flag silenciosamente, scripts quebram em prod.
**Por quê é ruim**: usuários perdem confiança.
**Correção**: 1 versão de aviso (`--old-flag` funciona + warning em stderr), depois remoção em major.

### A41 — Phone home sem consent
**Sintoma**: CLI envia analytics ao executar, sem opt-in.
**Por quê é ruim**: viola LGPD/GDPR; quebra confiança.
**Correção**: opt-in explícito, mensagem clara, fácil desabilitar (`--no-analytics` ou env var).

### A42 — Time bomb
**Sintoma**: CLI depende de servidor que pode sumir; ou de cert que expira hardcoded.
**Por quê é ruim**: 5 anos depois, ferramenta para de funcionar sem motivo aparente.
**Correção**: dependências auto-suficientes, certs configuráveis, não hardcode datas.

---

## Naming

### A43 — Nome muito curto e genérico
**Sintoma**: comando chamado `cli`, `tool`, `run`.
**Por quê é ruim**: colide com 50 outros, ambíguo no histórico.
**Correção**: nome curto MAS específico — `acdg`, `gh`, `kubectl`.

### A44 — Difícil de digitar
**Sintoma**: `qzwxecv` ou comando one-handed que requer chord.
**Por quê é ruim**: usuário digita 50x/dia.
**Correção**: teste alternância de mãos, evite letras que demandam shift.

### A45 — UPPERCASE ou CamelCase
**Sintoma**: `MyTool` no lugar de `mytool`.
**Por quê é ruim**: convenção UNIX é lowercase. Shell é case-sensitive.
**Correção**: lowercase, hífen para composto.

---

## Dual-Use (Anti-Padrão Recorrente)

### A46 — "Funciona em humano OU em script, não em ambos"
**Sintoma**: comando sem `--output json`, ou JSON sempre poluído com cores.
**Por quê é ruim**: força fork de comportamento.
**Correção**: detecte TTY, ofereça `--output` explícito. **Humano-primeiro, script-também**.

---

## Resumo: Top 10 Anti-Patterns por Frequência

1. Stack trace cru (A10).
2. Sem `--dry-run` em destrutivo (A33).
3. `exit(1)` para tudo (A31).
4. Senha em flag (A13).
5. Cor sem detectar TTY (A7).
6. Prompt sem fallback `--no-input` (A24).
7. Catch-all subcomando (A19).
8. `print()` no stream errado (A5).
9. Sem timeout HTTP (A28).
10. Help sem exemplos (A2).
