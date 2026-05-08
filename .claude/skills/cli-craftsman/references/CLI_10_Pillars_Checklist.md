# 10 Pilares — Checklist Operacional

> Use este checklist em PR review de qualquer mudança em `apps/cli/`, ou ao desenhar uma nova CLI do zero. Cada pilar tem critério de aceite verificável.
>
> Espelha a SKILL.md desta skill — esta versão é "imprimível", para colar em template de issue/PR.

---

## P1 — Argument Parser de Verdade

- [ ] Usa biblioteca canônica (`package:args` em Dart, Cobra em Go, clap em Rust, click em Python).
- [ ] `CommandRunner` ou equivalente, não parser feito à mão.
- [ ] Aceita `--option value` E `--option=value`.
- [ ] Lida com `--` para fim de flags.
- [ ] Sugere typos automaticamente.

---

## P2 — Exit Codes Honestos

- [ ] `0` apenas em sucesso completo.
- [ ] Pelo menos 3 códigos não-zero distintos para os principais modos de falha.
- [ ] `64` (EX_USAGE) para uso inválido.
- [ ] `130` quando terminado por SIGINT.
- [ ] Cada `CliError` tem mapeamento documentado para exit code.
- [ ] Help inclui seção `EXIT CODES`.

---

## P3 — Stdout vs Stderr

- [ ] Dados estruturados (JSON, tabela) **somente** em stdout.
- [ ] Mensagens (progresso, log, erro, prompt) **somente** em stderr.
- [ ] Testes: `mycmd | jq` funciona.
- [ ] Testes: `mycmd 2>/dev/null` ainda mostra dado.
- [ ] Em Dart: `IOSink` injetável para testes capturarem cada stream.

---

## P4 — `--help` que Ensina

- [ ] `mycmd` sem args → help conciso (se requer args).
- [ ] `mycmd -h` E `mycmd --help` E `mycmd help` funcionam.
- [ ] `mycmd <sub> --help` funciona em todos os níveis.
- [ ] Help começa com **descrição em 1 linha**.
- [ ] Tem **EXEMPLOS** antes da listagem de flags.
- [ ] Lista flags com **default visível**: `(default: auto)`.
- [ ] Tem seções `ENVIRONMENT` e `EXIT CODES` quando relevantes.
- [ ] Link para doc web no rodapé.

---

## P5 — Output Disciplinado

- [ ] Default detecta TTY (humano) vs pipe (máquina).
- [ ] `--output json` produz JSON estável e parseável.
- [ ] `--plain` produz texto tabular sem cor/multi-line.
- [ ] `-q`/`--quiet` silencia tudo exceto erros.
- [ ] `-v`/`--verbose` adiciona detalhe.
- [ ] Cores condicionais a `stdout.hasTerminal`.
- [ ] Respeita `NO_COLOR` (lowercase env).
- [ ] Respeita `FORCE_COLOR`.
- [ ] Não imprime ANSI quando `TERM=dumb`.

---

## P6 — Erros que Ensinam

- [ ] Mensagem em **1 linha humana**.
- [ ] **Hint acionável** logo abaixo (`hint: rode X para Y`).
- [ ] Vermelho **só na palavra** `error:`, não na mensagem inteira.
- [ ] Stack trace salvo em `$XDG_CACHE_HOME` para erros inesperados.
- [ ] Output mostra path do log + URL para reportar bug.
- [ ] Múltiplos erros similares são **agrupados**, não repetidos.

---

## P7 — Args vs Flags

- [ ] Toda flag short tem versão long.
- [ ] Sem flag short genérica ambígua (`-V` apenas se não conflita).
- [ ] Nomes padrão: `-h/--help`, `-v/--verbose`, `-q/--quiet`, `-f/--force`, `-o/--output`, `-n/--dry-run`.
- [ ] Senha **NUNCA** em flag direta — apenas via file/stdin/prompt.
- [ ] `-` aceito como stdin em flags de file.
- [ ] Validação local antes de chamada de rede.
- [ ] Default sempre visível no help.

---

## P8 — Interatividade

- [ ] Prompt apenas se `stdin.hasTerminal`.
- [ ] `--no-input` e `--yes` honrados.
- [ ] Em não-TTY sem `--yes`: falha com mensagem clara apontando flags.
- [ ] Senha com `echoMode = false`.
- [ ] Confirmação destrutiva tem 3 níveis (mild/moderate/severe).
- [ ] Severe pede digitar nome do recurso.

---

## P9 — Subcomandos

- [ ] Hierarquia `noun verb` (ou `verb noun`) consistente em **todo** o binário.
- [ ] Sem catch-all (comando desconhecido → erro com sugestão).
- [ ] Sem auto-abreviação automática.
- [ ] Aliases explícitos quando úteis (`ls` para `list`).
- [ ] Mesmas flags em mesmas posições para verbos similares.
- [ ] Sem sinônimos no mesmo binário (`update`/`upgrade`).
- [ ] Singular/plural consistente.
- [ ] Help top-level lista recursos com 1 linha cada.

---

## P10 — Robustez

- [ ] Resposta < 100ms (mesmo "Carregando...").
- [ ] Spinner/progress em stderr, condicional a TTY.
- [ ] Timeout HTTP default razoável + `--timeout` configurável.
- [ ] Retry só em 5xx/network, com backoff exponencial.
- [ ] `Ctrl-C` imprime "cancelando..." e força saída no segundo.
- [ ] Cleanup tem timeout interno.
- [ ] `--dry-run` em toda operação destrutiva ou de rede.
- [ ] Estado de operação longa em `$XDG_CACHE_HOME` para retomada.
- [ ] Idempotency key suportada (gerada ou explicitada).

---

## Bônus: Configuração e Distribuição

- [ ] Config em `$XDG_CONFIG_HOME/<app>/config.yaml`.
- [ ] Cache em `$XDG_CACHE_HOME/<app>/`.
- [ ] Credenciais com `chmod 600`.
- [ ] Ordem de precedência: flag > env > `.env` > user config > system config.
- [ ] Single binary distribuído (ou pacote nativo).
- [ ] Instruções de uninstall no README.
- [ ] Sem analytics/phone-home sem opt-in.

---

## Critério de "Pronto" para `apps/cli/`

Para uma feature/comando ser considerado **production-ready** no monorepo ACDG:

1. Todos os 10 pilares verificados (P1-P10).
2. Golden tests com `IOSink` capturado para stdout, stderr (cf. C10 em `apps/cli/test/`).
3. Help text revisado por humano (não só auto-gerado).
4. Pelo menos 3 exit codes distintos mapeados.
5. `--dry-run` se há side effect.
6. `--output json` se retorna dado estruturado.
7. Documentado em `apps/cli/README.md` com exemplo.
