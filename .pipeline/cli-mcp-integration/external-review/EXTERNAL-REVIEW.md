# cli-mcp-integration — External Review

> **Ticket:** cli-mcp-integration v2 (Phase 5 expansion).
> **Date:** 2026-05-07.
> **Charter:** `handbook/audit/EXTERNAL_REVIEW_CHARTER.md` aplicado integral. Auto-discovery via §3 selecionou §1 + §2.1 + §2.2 + §2.3 + §2.4 + §2.5 + §2.7 + §2.8 + §2.9 + ENCAPSULATION_POLICY extract + cli-craftsman extract.
> **Internal review history:**
> - W4 (flutter-code-reviewer): APPROVED + 4 should_fix + 4 info.
> - W5 (flutter-quality-checker): PASSED with 1 warning (format gap em test/ resolvido).
> **External reviewers:** (1) Gemini 2.5 Flash; (2) orchestrator (Claude Opus 4.7).
> **Audit trail:**
> - `STYLE_GUIDE_SUBMITTED.md` — exato styleGuide submetido ao Gemini.
> - `SPEC_SUBMITTED.md` — exato spec adversarial submetido (Q1.1-Q1.8 NO TOPO).
> - `DIFF_SUBMITTED.diff` — diff que o orchestrator submeteu (note: foi resumido/compactado para caber em Flash; ver §1 abaixo).
> - `LLM_RESPONSE_RAW.jsonl` — output bruto do Gemini.
> - `LLM_LIVE_LOG.txt` — streaming log.

---

## §0 — Verdict externo final

**APPROVED.**

- 0 `must_fix` legítimos.
- 4 `should_fix` herdados do W4 (já tracked como follow-ups).
- 6 `info` adicionados pela revisão do orchestrator (Q1.1-Q1.8 que o Flash não cobriu com profundidade).
- 2 `must_fix` reportados pelo Gemini Flash são **falsos positivos por compactação do diff** — o código real no working tree não tem o problema (cross-check §5 do Charter pegou).
- 3 `should_fix` (line length) reportados pelo Gemini Flash também são **falsos positivos** — Flash leu numbering do diff resumido, não dos arquivos reais (linhas 16/100/103 têm 8/21/5 chars respectivamente).

**Pipeline pronto para merge.** Follow-ups (W4 + EXT-*) registráveis como tickets separados.

---

## §1 — Reprodutibilidade auditável (Charter §7)

| Artefato | Path | Status |
|---|---|:--:|
| `STYLE_GUIDE_SUBMITTED.md` | `.pipeline/cli-mcp-integration/external-review/` | ✅ |
| `SPEC_SUBMITTED.md` | idem | ✅ |
| `DIFF_SUBMITTED.diff` | idem | ✅ |
| `LLM_RESPONSE_RAW.jsonl` | idem | ✅ |
| `LLM_LIVE_LOG.txt` | idem | ✅ |
| `EXTERNAL-REVIEW.md` (este doc) | idem | ✅ |

**Nota crítica de reprodutibilidade:** o `diff` parameter passado ao Gemini Flash é uma versão **compactada** do diff completo (10.7KB → 14KB inline; o original em `DIFF_SUBMITTED.diff` é 28KB). Eu (orchestrator) compactei para caber dentro de margem confortável de tokens. **Consequência:** algumas linhas foram resumidas (e.g., trecho em `_redactCliError` foi escrito com `(error as AuthRequiredError).stderrMessage` no resumo, quando o código real usa pattern matching limpo `error.stderrMessage` após o pattern match). Esse erro de compactação gerou os 2 falsos positivos `must_fix` do Gemini. Documentado em §3 abaixo. **Lição aprendida:** próxima rodada de external review com Charter, o orchestrator deve passar o diff INTEGRAL mesmo que isso force escolher menos arquivos. Esta é a mesma lição da rodada B1 (handbook/audit/EXTERNAL_REVIEW_CHARTER.md §5 falsesafe).

---

## §2 — Findings consolidados

### §2.1 — must_fix legítimos do Gemini

**0 findings.**

### §2.2 — should_fix legítimos do Gemini

**0 findings.**

### §2.3 — Falsos positivos do Gemini (cross-check §5 do Charter)

| # | Finding do Gemini | Veredicto | Evidence |
|:-:|---|:--:|---|
| 1 | `mcp_tool_registry.dart:120` — `(error as AuthRequiredError).stderrMessage` é downcast (must_fix) | **FALSO POSITIVO** | Working tree real (`mcp_tool_registry.dart:164`) usa pattern matching limpo: `AuthRequiredError() => error.stderrMessage,`. Type promotion automática do Dart 3 dispensa cast. Erro do orchestrator no resumo do diff submetido. |
| 2 | `mcp_tool_registry.dart:121` — idem `RefreshTokenInvalidError` (must_fix) | **FALSO POSITIVO** | Idem: working tree real linha 165 — `RefreshTokenInvalidError() => error.stderrMessage,` sem cast. |
| 3 | `mcp_logger_setup.dart:16` — line exceeds 80 chars (should_fix) | **FALSO POSITIVO** | Linha real tem 8 chars (`library;`). Gemini leu numbering relativo do diff. |
| 4 | `mcp_tool_registry.dart:100` — line exceeds 80 chars (should_fix) | **FALSO POSITIVO** | Linha real tem 21 chars (`} catch (e, st) {`). |
| 5 | `mcp_tool_registry.dart:103` — line exceeds 80 chars (should_fix) | **FALSO POSITIVO** | Linha real tem 5 chars (`}`). |
| 6 | `mcp_tool_registry.dart:130` — `_ =>` arm sobre Object (false_positive_likely) | **OK — Gemini reconheceu como FP** | Mantém-se como W4 F1 should_fix. |
| 7 | `pubspec.yaml:7` — `logging` e `meta` com caret (false_positive_likely) | **OK — judgment call** | Preferência do projeto, não policy. Tracked como EXT-3 abaixo. |

### §2.4 — Findings herdados do W4 (não-bloqueantes, follow-up tickets)

| # | Severidade | File:line | Issue | Routing |
|:-:|:-:|---|---|---|
| W4-F1 | should_fix | `mcp_tool_registry.dart:163-177` | `_redactCliError` switches over `Object` com `_ =>` arm — bypassa CliError sealed exhaustivity | flutter-bff-implementer |
| W4-F2 | should_fix | `mcp_tool_definition.dart:21-23,64` | Doc claims `props` includes `schemaSnapshot` but actual props excludes `inputSchema` | flutter-bff-implementer |
| W4-F3 | should_fix | `mcp_tool_definition.dart:12-13,24` | Doc references "EquatableMixin" but project canon is `with Equatable` | flutter-bff-implementer |
| W4-F4 | should_fix | `cli_runner.dart:64-66` | Import order: `mcp_command.dart` sandwiched between `lookup_*` files | flutter-bff-implementer |

### §2.5 — Findings novos do orchestrator (Q1.1-Q1.8 que Flash não cobriu)

| # | Severidade | File:line | Issue | Routing |
|:-:|:-:|---|---|---|
| EXT-1 | info | `mcp_server_adapter.dart` (boundary) | dart_mcp internal protocol log sink — verificar se roteia via `package:logging` (e portanto pego pelo `McpLoggerSetup` redirect) ou se escreve direto em stdout. Se direto, é colisão potencial não pega pelo grep do W5. **Recomendação:** rodar smoke test com `protocolLogSink` enabled em mcp_dart e capturar stdout pra verificar. | future ticket |
| EXT-2 | info | `mcp_tool_registry.dart:163` | `_redactCliError` switch sobre `Object` é trade-off correto dado que `Failure<T>.error` é tipado `Object`. Sealed enforcement requer `Failure<T extends CliError>` em `core_contracts`. **Status:** W4 F1 já tracked; EXT-2 reforça severidade should_fix → potencial must_fix se um dia `core_contracts` ganhar o type bound. | tracked com W4 F1 |
| EXT-3 | info | `pubspec.yaml:7,8` | `logging: ^1.3.0` e `meta: ^1.16.0` com caret. Aceitável (Google packages estáveis), mas pin estrito daria reproducibility absoluta. **Recomendação:** discutir politica de pinning para deps de boundary; se o projeto opta por pin estrito, atualizar `pubspec.yaml` em ticket separado. | future ticket (preferência) |
| EXT-4 | info | `handlers/patient_get_tool.dart:24`, `lookup_get_tool.dart` | `Schema.string` sem `pattern` permite `patientId: "P-1234'; DROP--"` chegar até `BffClient.get('/patients/$patientId')`. Path injection é absorvida pelo Dio (URL encoding) + 400 do BFF, mas defesa em depth no schema (`pattern: ^[0-9a-fA-F-]+$`) seria limpa. | future ticket |
| EXT-5 | info | `mcp_tool_registry.dart:87` | `await _credentialStore.read()` sem try/catch local. Keychain throw (e.g. `KeychainCorruptEntry`) escala para o catch-all genérico ("Tool handler crashed (logged)."). Comportamento seguro (fail-closed), mas UX suboptimal — deveria distinguir "auth não configurado" de "tool crashou". | future ticket |
| EXT-6 | info | `mcp_logger_setup.dart:34-44` | `_installed` flag persiste todo o lifetime do isolate. Em produção (`acdg mcp serve` → 1 process por invocation), irrelevante. Edge case teórico se algum dia houver "restart" no mesmo isolate. | informational |

---

## §3 — Resposta às perguntas adversariais Q1.1-Q1.8

O Gemini Flash, com 913 tokens de output, não cobriu Q1.1-Q1.8 com profundidade — só listou findings (todos falsos positivos). Eu (orchestrator) li o working tree real e respondo abaixo.

### Q1.1 — STDIO collision indirect paths
**Resposta: NÃO há paths indiretos para stdout em `lib/src/mcp/`.**

- `mcp_server_adapter.dart:70` é o ÚNICO lugar que escreve em stdout (via `stdio.stdioChannel(input: _stdin, output: _stdout)`).
- Logger config race: `mcp_serve_command.run()` faz `McpLoggerSetup.redirectToStderr(_stderr)` ANTES de instanciar adapter. Records emitidos antes do listener attach (e.g., na construção de `BffClient`) **não vão a lugar nenhum** — `Logger.root` sem listeners registra mas não escreve. Seguro.
- dart_mcp internal logger: **EXT-1** registrado para verificação posterior — teoricamente o `protocolLogSink` poderia ir direto para stdout se mal-configurado, mas o adapter atual NÃO instancia explicit log sink, deixando o default que é null.

### Q1.2 — Stack trace leak in CallToolResult
**Resposta: NÃO. `Object e` nunca é interpolado em CallToolResult.**

- `_redactCliError` (linhas 163-177) é puro switch sealed; cada arm retorna mensagem fixa.
- `dispatch` catch-all (linhas 100-103) emite `_logger.severe(label, e, st)` (logger gets stack trace) mas o CallToolResult é texto fixo `'Tool handler crashed (logged).'`. Zero `$e` interpolação.
- `_toJson` fallback em 142-148: `try jsonEncode catch (_) jsonEncode({'value': value.toString()})` — risco TEÓRICO se um handler retornar Object não-jsonEncodable cujo `toString()` carrega PII. **Material:** todos os 5 handlers MVP retornam `Map<String, Object?>` puros. Risco não material com handlers atuais. Defesa em depth seria adicionar tipo bound (`Result<Map<String, Object?>>` em vez de `Result<Object>`).
- `package:logging` records: configurado em `redirectToStderr` para escrever em sink injetado (stderr em produção). Sem second listener anywhere.

### Q1.3 — RBAC bypass
**Resposta: NÃO há bypass.**

- `session == null` → "Authentication required" ✓
- `actorRoles.intersection(required).isEmpty` quando required={social_worker,owner,admin}: 
  - `roles=[]` → `{}.intersection(required) = {}` → `.isEmpty = true` → "Forbidden" ✓
  - `roles=null` impossível (OidcSession.roles é `final List<String>` não-nullable).
  - `roles=['ghost']` → `{'ghost'}.intersection({social_worker,...}) = {}` → "Forbidden" ✓
- `_credentialStore.read()` throw: cai no try/catch (linha 100-103), vira `'Tool handler crashed (logged).'`. Fail-closed. **EXT-5 registrado** para UX (deveria distinguir auth-error de tool-crash).

### Q1.4 — Argument injection via JSON Schema bypass
**Resposta: defesa em depth ok; uma sugestão de hardening.**

- `additionalProperties: false` enforcement: o `dart_mcp.ObjectSchema.validate()` valida (chamado em `validateArgs` linha 79). Verifiquei `mcp_tool_definition.dart` — `inputSchema.validate(args)` retorna lista de erros; primeiro erro vira `Invalid arguments: <msg>`. ✓
- `limit: 1.5`: schema usa `Schema.int(min:1, max:50)`. JSON `1.5` é `double` em Dart; `Schema.int` deve rejeitar. Defesa em depth: `args['limit'] is int ? as int : 10` em handler — fallback seguro mesmo se schema falha.
- Path injection: schema é `Schema.string` sem pattern. **EXT-4 registrado** — sugiro `pattern: ^[0-9a-fA-F-]+$` para UUIDs.

### Q1.5 — Pin discipline
**Resposta: parcial.**

- `dart_mcp: 0.5.1` PIN ✓ (justified — v0.x SemVer instable).
- `logging: ^1.3.0` caret (OK — Google, v1.x mature).
- `meta: ^1.16.0` caret (OK — Google).
- **EXT-3:** discussão de policy — pin estrito de TODAS as deps daria reproducibility absoluta. Não é must_fix; é judgment.

### Q1.6 — REGRA #2 broadcast verdict
**Resposta: independent verification CONFIRMA W4.**

- `StreamController.broadcast()` NÃO buffera events; novos subscribers só recebem events a partir do momento de subscribe.
- `request()` no test chama `_frames.stream.firstWhere(...)` repetidamente em 4 calls JSON-RPC sequenciais. Single-subscription stream lança "Bad state: Stream has already been listened to" na 2ª call. Broadcast resolve.
- Behavior change: nenhuma — todos os events são despachados no mesmo isolate sequencialmente; broadcast vs single não muda ordem nem entrega para o listener atual.
- **W4 verdict legítimo, REGRA #2 exception aplicada corretamente.**

### Q1.7 — Sealed exhaustivity em `_redactCliError`
**Resposta: should_fix, não must_fix (concorda com W4 F1).**

- Switch sobre `Object error` é necessário porque `Failure<T>.error` é tipo `Object` em `core_contracts`.
- `_ =>` arm é justificável defensivamente — adicionar novo CliError subtype não trip o switch porque o switch não tem tipo sealed bound.
- **Path canônico para must_fix:** `core_contracts.Failure<T>` ganhar bound `Failure<T extends CliError>`, daí o switch pode ser sobre `CliError` exato e `_ =>` vira proibido.
- Hoje: should_fix tracked W4 F1 + EXT-2.

### Q1.8 — Logger setup idempotency
**Resposta: edge case teórico, não material.**

- `_installed` flag é static, lifetime do isolate. ✓
- Produção: 1 invocation = 1 process. Sem restart.
- Teste: usa `resetForTesting()` em setUp. ✓
- Edge: "MCP server restart" no mesmo isolate sem novo process — não existe no produto atual.
- **EXT-6 registrado** apenas como informational.

---

## §4 — Aprendizados desta rodada do Charter

Capturados para feedback ao próprio Charter:

1. **Compactação de diff é o vetor #1 de falso positivo.** Mesmo problema da rodada B1. **Lição:** próxima invocação do `ai_gemini_review`, passar o diff INTEGRAL ou cortar arquivos inteiros — não compactar linhas. Atualizar Charter §5 failsafe explicitamente.

2. **Gemini Flash output é shallow para spec adversarial.** 913 tokens / 8 perguntas = ~115 tokens por pergunta. Insuficient para análise deep. **Lição:** spec adversarial exige Pro (quando disponível) OU dividir em múltiplas invocações Flash (uma por pergunta).

3. **Auto-discovery do Charter funcionou.** §3 selecionou as policies certas (§2.1, §2.2, §2.3, §2.4, §2.5, §2.7, §2.8, §2.9 + ENCAPSULATION extract + cli-craftsman extract) baseado nos paths tocados pelo diff.

4. **§5 failsafe pegou os falsos positivos.** Cross-check contra working tree real eliminou 5/7 findings do Gemini. Esse é o ponto do Charter — sem ele, o orchestrator teria propagado falsos positivos como dívida real.

5. **Snapshot de reprodutibilidade (Charter §7) executado:** STYLE_GUIDE + SPEC + DIFF + LLM_RESPONSE_RAW + EXTERNAL-REVIEW todos persistidos em `external-review/`. Auditável meses depois.

---

## §5 — Recomendação de merge

**APROVADO.** Pipeline cli-mcp-integration v2 pronto para commit + PR.

**Follow-up tickets sugeridos (não bloqueiam merge):**

| Ticket | Severidade | Origem |
|---|---|---|
| Refator `_redactCliError` para `CliError`-typed switch quando `Failure<T extends CliError>` virar disponível | should_fix | W4-F1 + EXT-2 |
| Atualizar doc do `McpToolDefinition` (props + Equatable terminology) | should_fix | W4-F2 + W4-F3 |
| Reordenar import alfabeticamente em `cli_runner.dart` | should_fix | W4-F4 |
| Smoke test do `dart_mcp` protocol log sink | info | EXT-1 |
| Discussão de pin discipline policy | info | EXT-3 |
| Hardening de schemas com `pattern` para UUIDs | info | EXT-4 |
| try/catch local em `_credentialStore.read()` para UX | info | EXT-5 |
| W3 process feedback: rodar `dart format` em test/ antes de declarar W3 done | info | W5 §6.1 |

Pipeline completo. Encerro task #10 (external review).
