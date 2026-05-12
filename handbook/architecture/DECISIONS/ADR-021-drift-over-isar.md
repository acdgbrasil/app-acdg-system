# ADR-021: Pivot Drift sobre Isar para Offline Storage (supersede ADR-005)

**Data:** 2026-04-30
**Status:** Aceito
**Supersede:** [ADR-005](ADR-005-isar-offline-storage.md) (Isar para offline storage, 2026-03-08)
**Relacionado:** A16-v2, A17-v2, A18-v2 (Onda 4 — Desktop rebuild)

## Contexto

[ADR-005](ADR-005-isar-offline-storage.md) (2026-03-08) prescrevia **Isar** como engine de offline storage para o monorepo Flutter ACDG, baseado nos seguintes argumentos da época:

- API NoSQL idiomática para Dart (schema por classe anotada).
- Performance superior em benchmarks de inserção/leitura.
- Suporte a queries reativas via streams.

Em **2026-04-29**, durante o re-baseline da Onda 4 (rebuild do `bff/social_care_desktop/`), a decisão foi reavaliada com pesquisa atualizada do ecossistema Flutter e análise das exigências de build modernas. **Três fatos novos invalidam a premissa do ADR-005:**

### 1. Manutenção do Isar colapsou

O autor original do Isar (Simon Leier) **abandonou o pacote**. Comunidade tentou manter via forks (`isar_community`, `isar_plus`) mas threads recentes (2025-2026) em r/FlutterDev e GitHub mostram:

- Issues críticos de produção sem resposta há meses.
- Forks instáveis com regressões em queries complexas.
- Migração ativa de desenvolvedores **de volta para Drift** para garantir estabilidade.

**Risco:** adotar Isar em código novo significa apostar em dependência sem mantenedor — débito técnico inevitável.

### 2. Incompatibilidade com Swift Package Manager (SPM)

Flutter está **adotando SPM como padrão**, depreciando CocoaPods. Isar depende de **binários Rust pré-compilados** que falham sob hooks de build do SPM:

- Issue #1750 do repo Isar (aberta, sem resolução): "Support for Swift Package Manager".
- Build hooks modernos não conseguem resolver os artefatos Rust ofuscados.
- Workarounds requerem patches manuais a cada release.

Drift, em contraste, usa **`sqlite3` nativo** que se adapta cleanly aos hooks modernos do Dart e SPM (via `sqlite3_flutter_libs` em produção e `sqlite3` Dart package em testes).

### 3. Drift tem Isolates de primeira classe

O `SyncEngine` offline-first (A18-v2) precisa rodar em background sem travar UI. Drift é a **única biblioteca de persistência embarcada robusta no Flutter** com:

- Suporte multithread testado para Isolates.
- API `IsolatedExecutor` documentada e estável.
- Compatibilidade fluida com `compute()` e isolates Dart.

Isar tem APIs de isolate marcadas como experimentais e instáveis nos forks comunitários.

## Decisão

**Pivot Isar → Drift** para todo offline storage no monorepo, em escopos novos OU re-implementados:

1. **`apps/social_care_bff/desktop/lib/src/cache/`** (A17-v2) — implementado com Drift, FTS5 + 6 triggers, schema denormalizado JSON-blob + B-Tree indices. Closed 2026-04-30, commit `891814a`. **`feat consummated`**.
2. **`apps/social_care_bff/desktop/lib/src/sync/`** (A18-v2 — pendente) — usará `SyncDatabase` em arquivo `.sqlite` físico separado (`app_sync_queue.sqlite`), também via Drift, com migration strategy versionada (Outbox protection contra Data Loss).
3. **`apps/social_care_ui/` (Phase 6+)** — quando o frontend Flutter for reescrito para consumir o BFF rebuilt, o storage local também migrará para Drift. Não há ação imediata; Phase 6 será disparada após Phase 5 CLI estabilizar.

## Justificativa

| Critério | Isar ([ADR-005](ADR-005-isar-offline-storage.md)) | Drift (ADR-021) |
|---|---|---|
| Manutenção upstream | Abandonada | Ativa, single maintainer com release cadence |
| SPM compatibility | Quebrada (Issue #1750) | Funcional via `sqlite3_flutter_libs` |
| Isolates | Experimentais | Primeira classe (`IsolatedExecutor`) |
| Type safety | Reflexiva (annotations + codegen) | Compile-time (relacional + codegen) |
| FTS / busca textual | API limitada | FTS5 nativo via `customStatement` |
| Schema strategy | NoSQL (object store) | Relacional + JSON-blob híbrido |
| Migration tooling | Limitada | Drift `MigrationStrategy` + schema dumps |

A combinação **manutenção ativa + SPM compat + Isolates first-class** torna Drift a escolha correta. Os benefícios originais do Isar (NoSQL idiomática, performance) não compensam o risco de dependência abandonada e build quebrado.

## Consequências

**Imediatas:**

- [ADR-005](ADR-005-isar-offline-storage.md) fica historicamente registrado como decisão correta para o contexto da época, mas tecnicamente superseded.
- Schema de cache desktop é denormalizado JSON-blob (DTO completo no `payload` TEXT) com B-Tree indices em colunas filtráveis (`id`, `personId`, `status`, `eventType`) e FTS5 virtual tables onde busca textual é necessária (`patient_summaries_fts`, `lookup_tables_fts`).
- A18-v2 deve criar `SyncDatabase` em arquivo físico SEPARADO do `CacheDatabase` (Outbox protection — perda de fila de sync = perda de mutations offline = Data Loss).

**Para Phase 6+ (Flutter migration):**

- Quando `apps/social_care_ui/` for criado para consumir o BFF rebuilt, o storage local migrará para Drift no mesmo movimento. NÃO migrar incrementalmente — break-change autorizado pelo mesmo precedent que Onda 4 aplicou ao desktop.
- Não recomendar Isar em code reviews de novos componentes offline-first. Se um agente sugerir Isar baseado em [ADR-005](ADR-005-isar-offline-storage.md), citar ADR-021.

**Para o ecossistema do projeto:**

- `infra/storage/` (anteriormente `packages/persistence/`) continua usando Drift — verificar e alinhar build.yaml com o cache desktop quando relevante.
- Documentação histórica em [ARCHITECTURE.md](../ARCHITECTURE.md), [DIAGRAMS.md](../DIAGRAMS.md), [BFF_IMPLEMENTATION_PLAN.md](../BFF_IMPLEMENTATION_PLAN.md) que mencionam Isar como engine **estão desatualizadas**; updates incrementais vão ocorrer conforme cada doc é tocado em fases futuras (não é necessário re-escrever tudo agora — ADR-021 declara a verdade canônica e supera o que estiver no prose).

## Gatilho de reavaliação

Reabrir esta decisão se **qualquer** dos seguintes emergir:

- Isar restaura manutenção ativa com mantenedor estável + roadmap declarado.
- Isar publica suporte oficial a SPM (Issue #1750 fechada com release).
- Drift tem regressão crítica de performance ou abandono de mantenedor.
- Surge alternativa Dart-native superior (e.g. ObjectBox Dart com SPM compat) que justifique avaliação.

## Histórico de pesquisa

Decisão fundamentada em:

- r/FlutterDev threads 2025-2026 sobre migração Isar → Drift.
- Issue #1750 do Isar (Swift Package Manager support).
- Análise comparativa SPM compatibility entre Isar (Rust binaries) e Drift (sqlite3 native).
- Validação prática durante A17-v2 — Drift + FTS5 + 6 triggers funcionou cleanly em 81/81 tests com `NativeDatabase.memory()`.

## Referência

- Conversa-sessão 2026-04-29: alinhamento de break-change da Onda 4 + decisão Drift-stays.
- Conversa-sessão 2026-04-30: revisão Architect (CQRS + Aggregate Root + Outbox protection) + correção FTS5.
- Implementação concreta: commits `4bda87f` (A16-v2), `891814a` (A17-v2).
- Memória do projeto: `~/.claude/projects/-Users-gabriel-aderaldo-Desktop-Projetos-dev-envolve-acdg-frontend/memory/project_drift_stays_adr_005_pivot.md`.

## Superseded by

Nenhum.
