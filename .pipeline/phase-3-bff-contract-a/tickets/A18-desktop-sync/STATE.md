# Ticket State: A18-v2-desktop-sync (BREAK CHANGE — SPLIT em 3 sub-tickets)

phase: split — A18a in progress, A18b/A18c queued
status: re-baselined as **A18-v2** + split em 3 sub-tickets sequenciais (2026-04-30)

## Re-baseline summary

A18 original ("sync/ SyncEngine com DTOs novos") foi expandido durante o re-baseline da Onda 4 para incluir use_cases + facade. Após análise, **escopo excede atomicidade** — splitado em 3 sub-tickets sequenciais para preservar revisão granular e atomicidade.

**User authorization (2026-04-30):** "vai com tudo recomendado" — split aprovado + todas as cross-cutting decisions.

## Sub-tickets

| Sub-ticket | Layer | LoC est. | Files | Tests | Status |
|---|---|---:|---:|---:|---|
| **A18a-v2** | Sync infra (Database + Queue + Engine) | ~1500 (real: 1824) | ~15 (real: 8 + 2 codegen) | ~50 (real: 52) | **CLOSED 2026-04-30 — APPROVED Round 1** |
| A18b-v2 | Use cases (~42 orquestradores cache+remote+queue) | ~2000 | ~42 | ~120 | queued (após A18a) |
| A18c-v2 | Facade pública + apps/acdg_system/ rewire | ~600 | ~8 + 7 shell rewires | ~30 | queued (após A18b) |

Cada sub-ticket roda 3-agent pipeline self-contained (test-writer → flutter-bff-implementer → flutter-code-reviewer), com revisão intercalada.

## Cross-cutting decisions (locked 2026-04-30)

### D1 — Optimistic locking: forward-compat header (a)

SyncEngine envia `X-Expected-Version` header em todas as mutations. Backend Swift/Vapor hoje **ignora** o header (ainda não suporta `If-Match`). Aceitamos resposta sem checagem. Quando backend implementar concurrency control, frontend já está pronto.

**Custo:** zero. **Benefício:** prepara para Phase 6+ sem coordenação backend.

### D2 — Conflict resolution: manual reconciliation (B)

Quando backend retorna 409 / OPTIMISTIC_LOCK_CONFLICT (futuro):
- Mutation transitiona para `failed_dead` no Outbox.
- UI surfaceia "conflito detectado, você precisa decidir" (sync_detail_panel evolve em A18c).
- **Sem auto-merge.** **Sem last-write-wins.** Healthcare data — fail-safe.

Auto-merge (CRDT-like) volta como evolução se for muito doloroso na prática.

### D3 — File paths: `path_provider` defaults

Default:
- Cache: `path_provider.getApplicationDocumentsDirectory()/app_cache.sqlite`
- SyncQueue: `path_provider.getApplicationDocumentsDirectory()/app_sync_queue.sqlite`

Override via `SocialCareDesktop.create(cacheFilePath: ..., syncQueueFilePath: ...)`.

`path_provider` é dep nova — vai pra `bff/social_care_desktop/pubspec.yaml` em A18a (porque SyncDatabase precisa do path).

### D4 — SyncEngine lifecycle: app-controlled (α)

`SocialCareDesktop.create()` constrói tudo mas **NÃO inicia** sync. Shell chama:
- `desktop.startSync()` após login OK (token disponível).
- `desktop.stopSync()` em logout.
- `desktop.close()` em app shutdown.

Match natural com fluxo OIDC.

### D5 — Drain concurrency: trigger-based (γ), background isolate como evolução

SyncEngine drena em response a:
- **Manual trigger** — chamado por write use case após enqueue.
- **Connectivity restore** — listener via `connectivity_plus` (nova dep).
- **App start** — `startSync()` faz primeira drenagem.

**SEM Timer.periodic ociosa.** SEM background isolate (Drift já é async e não trava UI; isolate vira evolução se medirmos jank real).

`connectivity_plus`: nova dep no A18a.

### D6 — Shell rewire validation: `flutter analyze` + tests existentes

A18c rewireia 7 arquivos do `apps/acdg_system/`. Validação mínima:
- `flutter analyze apps/acdg_system/` zero errors
- `flutter test apps/acdg_system/test/` passa (suite existente)

Sem integration tests novos. Phase 6+ adiciona.

## REGRA #2 antecipadas (locked 2026-04-30)

1. **Stale data threshold (`_isStale`):** read-from-cache se `cachedAt < now - 5min`; senão refresh remote. Configurável via `staleAfter` na `SocialCareDesktop.create()`.

2. **Optimistic write rollback em failed_dead:** **NÃO reverter** cache otimista. Surface inconsistência cache↔backend para o usuário resolver via UI. Cache é Read Model; mantém o que o user escreveu localmente até reconciliação manual.

3. **Concurrent writes ao mesmo aggregate:** SyncEngine drena FIFO por `createdAt ASC`. Race entre user actions é resolvida pela ordem original. Conflito real (409) cai em D2 (B).

4. **Lookup por chaves alternativas (CPF/etc):** A17 indexa apenas `id`/`personId`/`status`/`tableName`/`eventType`. Se A18b descobrir use case `findReferralByCpf` ou similar, **flagar como follow-up para criar índice no Drift**, não embed FTS5 no ID lookup. Por enquanto não há esses use cases mapeados.

## Follow-ups identificados (não-bloqueantes)

- **Backend Swift/Vapor** — adicionar suporte a `If-Match`/`X-Expected-Version` quando Phase 6+ priorizar concurrency control. Frontend já preparado.
- **Drift indexação por chaves alternativas** — se A18b ou Fase 4 descobrir use cases tipo `findReferralByCpf`, adicionar `@TableIndex` no schema e DAO method correspondente.
- **Background isolate para SyncEngine** — se medirmos UI jank real durante drain, mover SyncEngine pra Isolate. Drift `IsolatedExecutor` já suporta.
- **CRDT auto-merge** — se manual reconciliation virar bottleneck operacional, avaliar CRDT no BFF.

## Pipeline plan

3 rodadas separadas de 3-agent pipeline. Dispatch em sequência com revisão humana entre A18a→A18b→A18c.

## Status
- **A18a-v2 (sync infra) CLOSED 2026-04-30** — APPROVED Round 1, 286/286 GREEN, dart analyze zero
- A18b-v2 (use cases) — pending
- A18c-v2 (facade + shell rewire) — pending
