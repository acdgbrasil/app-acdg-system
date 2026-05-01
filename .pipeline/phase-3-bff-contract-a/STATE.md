# Pipeline State: phase-3-bff-contract-a

## Current Phase
phase: done
agent: —
status: **22/22 tickets done — PHASE 3 CLOSED 2026-05-01.** Onda 1 (A01) | Onda 2 (A02-A06d) | Onda 3 (A07-A15) | Onda 3.5 cross-cutting (A23) | Onda 4 (A16-v2 + A17-v2 + A18a-v2 + A18b-v2 + A18c-v2) | **Onda 5 closed 2026-05-01: A19 (analyze gate — zero errors em src/ dos 3 BFFs, 2 infos rg_document) + A20 (CONTRACT_A_PUBLIC_API §14 + CONTRACT_A_SPEC seção final + README expandido) + A21 (BFF-side complete: PatientTranslator + mappers/ deleted, comentários mortos limpos; packages/-side deferred to Phase 4 conforme memória user-owned)**. Phase 4 (`.pipeline/phase-4-flutter-migration/`) destravada — ataca packages/social_care/ + apps/acdg_system/ + bff/shared/dtos/ herdados.

## Completed tickets
- [x] A01 — Contract A design (35 ações mapeadas, 9 sub-contracts, CONTRACT_A_SPEC.md produzido)
- [x] A02 — 5 request DTOs (registry/admit + 4 governance/) + 20 tests GREEN
- [x] A03 — 6 response DTOs (3 governance + 1 auth + 2 team) + 25 tests GREEN
- [x] A04 — 3 sub-contracts (auth, lookup, team) + exports; dart analyze zero errors
- [x] A05 — SocialCareContract god-interface deletada; bff/shared/lib zero errors; breakage esperado em desktop/web (A06, A07-A18 consertam)
- [x] A06 — 11 fakes per sub-contract; FakeSocialCareBff deletado; 336 tests GREEN em bff/shared; dart analyze zero
- [x] A06b — 6 InMemory Stores extraídos, 7 fakes refatorados (composição + SRP), 4 stateless validados; 377 tests GREEN em bff/shared; dart analyze zero
- [x] A06c — Equatable em 71 classes de DTOs; 102 equality tests GREEN; 479 total bff/shared; zero regressões
- [x] A06d — 11 VOs → `extension type` const; BaseUuid deletado; CNS shape colapsado (wire preservado); 545 tests GREEN
- [x] A07 — Auth handler (5 endpoints) + observabilityMiddleware + ObservabilityContext; 87 tests GREEN; padrão canônico estabelecido para A08–A15
- [x] A08 — Registry Patient (7 endpoints: POST composto + list + get + 4 lifecycle) + pii_mask helper; saga sem compensação; 133 tests GREEN (255 canônico total); padrão refinado com sealed `_PersonResolution`
- [x] A09 — Registry Family + Identity + Audit (5 endpoints) + RegistryFamilyHandler + AuditContract injetado via Cascade; 114 tests GREEN (390 canônico total); saga AddFamilyMember com short-circuit pinado; 4 legados deletados
- [x] A10 — Assessment 7 fichas (7 endpoints PUT) + AssessmentHandler rewrite; 122 tests GREEN (480 canônico total); padrão novo try/catch sobre fromJson (mais PII-safe que P2 if-case); 7× duplicação aceita; Cascade ordem patient→family→assessment
- [x] A11 — Care (2 endpoints: POST /appointments + PUT /intake) + CareHandler rewrite; 57 tests GREEN (482 canônico total); **1ª aplicação post-ADR-019 do P2 if-case default** (gatilho P2b falhou: ≤2 required, non-PII-dense); Cascade ordem patient→family→assessment→care; Lints Camada 2 passam clean
- [x] A12 — Protection (3 endpoints: referrals + violations + placement-history) + ProtectionHandler rewrite; 100 tests GREEN (590 canônico total); **1ª coexistência P2+P2b no mesmo handler** (carrier: signature do Intent); novo invariante pinado `keys.toSet() == {'patientId'}` no breadcrumb `.received` para DTOs com sub-DTOs PII-densos; UseCase rewrap `Result<void>` → `Result<StandardResponse<void>>`
- [x] A13 — Lookup (8 endpoints governance) + LookupHandler rewrite (maior do monorepo com 8 rotas); 147 tests GREEN (638 canônico total); **estreia do P2-tolerant** (parse total sem ParseError, sem 400 code) para UpdateLookupItem (0 required); padrão `throw StateError('parseFromBody is total')` no branch Failure defensivo; wiring factory+field+Cascade consolidado como zero-cost reusável para A14/A15
- [x] A14 — Lookup batch composto (1 endpoint: `GET /lookups?tables=a,b,c`) + 9th rota no LookupHandler; 26 tests GREEN (844 total no BFF Web, 2 falhas pré-existentes A21); **estreia do query-only parse strategy** (`parseFromQuery(Map<String, String>)` espelha `parseFromBody`, primeiro intent não-body do canon); cap 20 tabelas (~54% headroom sobre `AllowedLookupTables.swift` com 13); CSV tolerante (split→trim→filter, alinhado com `people-context/env.ts:31-34`); error-code convention pinada no dartdoc do handler — `INVALID_*` (BFF-local parse 400) vs `<PREFIX>-<NNN>` (BackendError passthrough) como namespaces separados por design; elimina o `Future.wait([...])` em `PatientRegistrationViewModel` (consumido no app na Fase 4)
- [x] A15 — Team (9 endpoints, sem `/people/by-cpf/*` e `/team/people/*`); estreia do **query-tolerant** (`ListTeamIntent`); 9 intents + 9 use cases + 1 handler; pausado em W4.5 (2026-04-28) por route bleed em `/team/<id>`; **RETOMADO E CLOSED em 2026-04-29** via 3-agent BFF pipeline (test-writer → flutter-bff-implementer → flutter-code-reviewer); 7 intents path-UUID retrofitted ao canon V2 do A23 (4×A + 2×B + 1×C-P2); test cheat REGRA #2 corrigido textbook-style (`GET /team/people → 400 INVALID_GET_TEAM_MEMBER_PARAMS`); reviewer APPROVED zero MUST_FIX zero SHOULD_FIX; 1071 GREEN / 2 FAIL pré-existentes A21 (+45 net vs baseline A23 W4 1026)
- [x] **A16-v2 — Desktop Remote (BREAK CHANGE) — closed 2026-04-29** via 3-agent BFF pipeline. Original A16 escopado como refactor; **re-baselineado como rebuild break-change** após decisão arquitetural do usuário ("vamos considerar que tudo do desktop estava ERRADO"). Desktop agora espelha o pattern web (A07-A15) menos a camada HTTP. Deletada god-class `SocialCareBffRemote` (917 LoC, 50+ métodos) + `storage/` + `sync/` + tests legados (11 arquivos deletados). Construídas 8 impl novas (972 LoC: 1 `RemoteBase` + 7 thin remotes implementando sub-contracts: Registry, Assessment, Care, Protection, Audit, Lookup, Health). 153 tests RED → 153/153 GREEN. dart analyze zero issues. Reviewer APPROVED Round 1, zero MUST_FIX zero SHOULD_FIX. **Decisão Drift-stays:** ADR-005 prescreve Isar mas usuário decidiu manter Drift (Isar abandonado + SPM-incompatível); ADR-005 será atualizado para v2 em follow-up. **Out-of-scope autorizado:** `apps/acdg_system/` quebra contra novos exports — A18-v2 (facade) restaura.
- [x] **A17-v2 — Desktop Cache Layer (BREAK CHANGE) — closed 2026-04-30** via 3-agent BFF pipeline. Construída camada `cache/` do zero com Drift como engine (decisão Drift-stays, override do ADR-005). 5 cache contracts **Aggregate-Root aligned** (não 7 espelhando sub-contracts) — colapsa Assessment em Patient (fichas embedded), exclui Health (real-time only): `PatientsCache`, `CareCache`, `ProtectionCache`, `AuditCache`, `LookupCache`. CRUD surface CQRS-aligned (`find*`, `list*`, `search*`, `upsert*`, `delete*`, `clear*`) — sem ações de negócio. Schema denormalizado JSON-blob (`payload` TEXT) + B-Tree indices (id, personId, status, etc.) + **2 FTS5 virtual tables** (`patient_summaries_fts`, `lookup_tables_fts`) com 6 triggers (AI/AU/AD external-content protocol) substituindo `searchTerms LIKE '%...%'` (Full Table Scan eliminado). **Optimistic-locking `version`** column em todas as 9 tabelas (caller-controlled; A18 usa). **`cachedAt` DateTime** column para refresh policy (no TTL automático). **Separação física do SyncQueue:** A17 só cria `CacheDatabase` (droppable); A18-v2 vai criar `SyncDatabase` em arquivo `app_sync_queue.sqlite` separado (Outbox protection contra Data Loss). Header docstring obrigatório na `cache_database.dart` documenta a separação. 24 impl files + 11 codegen `.drift.dart` (build_runner). 81 tests RED → 81/81 GREEN. Full BFF Desktop suite 234/234 GREEN (zero regressão A16-v2). dart analyze zero issues. Reviewer APPROVED Round 1, 13/13 audit checks pass, zero MUST_FIX zero SHOULD_FIX, 3 NICE_TO_HAVE não-bloqueantes. 1 REGRA #2 surfaceada e resolvida sem alterar testes (`_ready` warm-up pattern para forçar inicialização do Drift antes de close mid-test).

## Onda 2 — FECHADA (9/21 tickets)
bff/shared 100% modernizado e arquiteturalmente limpo:
- 35 DTOs request + 34 responses (todos com Equatable)
- 11 sub-contracts (Contract B consolidado)
- 11 fakes + 6 InMemory stores (SRP puro)
- 11 branded types como `extension type` (zero-cost)
- ZERO `_field` de coleção privada; ZERO god-interface; ZERO classes herdando BaseUuid
- 545 tests GREEN, dart analyze zero errors

**Políticas aplicadas:**
- `ENCAPSULATION_POLICY.md` — H1-H9 (composition, Equatable, extension type, SRP)
- `PATTERN_MATCHING_POLICY.md` — P1-P4 (state matrix, if-case, tear-offs, Never)

## Débito P0 identificado (antes de A07)
2× `throw StateError('Unreachable')` em switch — candidato a função `Never` (P4):
- `packages/social_care/lib/src/data/services/http/_http_shared.dart:129, 134`
- `packages/social_care/lib/src/ui/patient_registration/viewModel/patient_registration_view_model.dart:310`

Ver `handbook/reports/LEGACY_PATTERNS_AUDIT_2026_04_17.md` para panorama completo.

## Próximo: Onda 3 (A07-A15) — BFF Web handlers
Sobre kernel estável e moderno, handlers + Intents + UseCases.

## TDD Policy (2026-04-17)
Aplicada em tickets A02..A18. Agentes diferentes por wave:
- test-writer (Wave 0) — testes RED primeiro
- implementer (Wave 1) — código até GREEN
- reviewer (Wave 2) — audit read-only
- quality (Wave 3) — dart analyze verde
Princípios da skill `flutter-expert` aplicados ao BFF onde fazem sentido: Result<T>, imutabilidade, Fakes em testing/, sem Impl, EN, Dart 3+.

## Mindset
- **BFF é reimplementação.** Quem dita regra de negócio pro APP é o BFF, não o backend.
- **Contract A = pergunta do APP.** "O que o APP precisa?" — não "o que o backend tem?".
- **Backends são componentes.** BFF orquestra. Se precisa de feature nova no backend, a gente pede.
- **Zero teste por enquanto.** Breaking changes livres.
- **Desktop não está em produção** — pode quebrar.

## Decisão Arquitetural (2026-04-17) — Vertical antes de Horizontal

**Política:** completar toda a Fase 3 (BFF) antes de começar Fase 4 (Flutter migration). **NÃO intercalar.**

**Rationale (usuário, literal):**
> "Mantenho estratégia de UM BFF bonito MESMO sem consumidores. Ir intercalando assim pode correr risco de NOVAMENTE criar god Objects e abstrações para resolver problemas, sem uma base sólida só criamos mais 'bolas de lama' sem saber EXATAMENTE onde estamos pisando, criando areias movedissas secretas."

**Como essa decisão se alinha com as políticas:**
- **H1–H9 (Encapsulation):** god-interfaces emergem por pressão iterativa; vertical protege.
- **H6 (enum vs lookup):** mesma lógica — regras que crescem por pressão viram dívida.
- **Contract A (BFF dita regra de negócio):** só pode ditar se estiver completo antes de ouvir o cliente.

**Consequência operacional:**
- Onda 3 vai até A15 sem desvios para Flutter
- Onda 4 (A16-A18 Desktop alignment) completa antes de Fase 4
- Onda 5 (A19-A21 gate + cleanup) fecha com kernel total
- Só então Fase 4 (Flutter migration) começa

**Sub-tickets pendentes ficam categorizados:**
- **DS-semantics** — adiado para Fase 4 (só importa quando Flutter migra)
- **Adapter OIDC real** — candidato a A07b ou A21 (dentro da fase, sem intercalar Flutter)
- **QA-agent-v0** — adiado para após Fase 4

## Decisions Log
- [2026-04-17] Inversão de plano: BFF-first, Flutter migra depois (phase-4-flutter-migration em hold)
- [2026-04-17] SocialCareContract god-interface **será deletada** em A05
- [2026-04-17] `bff/shared/contracts/` = Contract B (BFF↔backends); `bff/shared/dto/request+response` = Contract A (APP↔BFF)
- [2026-04-17] BFF pode ter estado próprio (cache, workflow, saga) — não é só proxy
- [2026-04-17] BFF pode **pedir features** ao backend Swift quando necessário
- [2026-04-17] Testes BFF existentes (93 errors pré-existentes) são **deprecados** — ignorar

## Waves

### Wave 1 — Design (1 ticket)
- [ ] A01 — Contract A definitivo (ponto de vista do APP)

### Wave 2 — bff/shared/ limpo (5 tickets)
- [ ] A02 — DTOs request (payloads Contract A)
- [ ] A03 — DTOs response (respostas enriquecidas)
- [ ] A04 — Contracts consolidados (sub-contracts como cidadãos de primeira classe)
- [ ] A05 — Deletar SocialCareContract monolítico
- [ ] A06 — Fakes por contrato (FakeRegistryBff, FakeAssessmentBff, ...)

### Wave 3 — bff/social_care_web/ (9 tickets — 1 por bounded context)
- [x] A07 — Auth (login, callback, logout, refresh, me)
- [x] A08 — Registry: Patient (register, list, get, lifecycle)
- [x] A09 — Registry: Family + Social Identity + Audit
- [x] A10 — Assessment (7 fichas)
- [x] A11 — Care (Appointment, Intake)
- [x] A12 — Protection (Violation, Referral, PlacementHistory)
- [x] A13 — Lookup (get, create, update, toggle, requests)
- [x] A14 — Lookup batch composto (GET /api/lookups?tables=...)
- [x] A15 — Team (sem /people/by-cpf/* e /team/people/*) — **CLOSED 2026-04-29 via 3-agent BFF pipeline**

### Wave 4 — bff/social_care_desktop/ (3 tickets — BREAK CHANGE rebuild)
**Re-baselineado 2026-04-29:** desktop sendo reconstruído do zero espelhando o pattern web menos a camada HTTP. Drift permanece (não Isar — ADR-005 será atualizado).
- [x] **A16-v2** — `remote/` (7 thin remotes + RemoteBase implementando sub-contracts via Dio) — CLOSED 2026-04-29
- [x] **A17-v2** — `cache/` (Drift schema + 5 Aggregate-Root cache contracts + DAOs + FTS5 + impls) — CLOSED 2026-04-30
- [~] **A18-v2 — split em 3 sub-tickets sequenciais (2026-04-30):**
  - [x] **A18a-v2** — sync/ infra (SyncDatabase em arquivo SEPARADO `app_sync_queue.sqlite`, Outbox table com composite index, 27 SyncMutation sealed-class final classes, OutboxRepository + DriftOutboxRepository, SyncEngine com state machine + single-flight drain + FIFO + sealed-switch dispatch, RetryPolicy exp backoff capped 30min, ConflictResolver — 286/286 GREEN, dart analyze zero) — **CLOSED 2026-04-30**
  - [x] **A18b-v2** — use_cases/ (42 orchestrators × 3 canonical patterns: Read cache-first com staleAfter / Write optimistic-through `read→build→enqueue→optimistic upsert→trigger drain` / Health passthrough; Cached<T> envelope refactor cirúrgico em PatientsCache + LookupCache findById; Clock injection cross-cutting; uuid dep; 376/376 GREEN, dart analyze zero) — **CLOSED 2026-04-30**
  - [x] **A18c-v2** — facade/ pública (`SocialCareDesktop` + 7 sub-facades + 42 métodos delegating + lifecycle D4 α + connectivity_plus listener D5 γ + `_PumpingSyncEngine` private subclass para drainStream) + sweep dos 4 NICE_TO_HAVE de A18b (delete `extractPatientVersion`, doc cache-only Pattern 1 uniformity, promote `Clock` para `abstract interface class` H6, unify cache impl Clock typed); shell rewire DEFERRED a Phase 4 (user-owned packages/ — 51 residual issues mapeadas como trigger payload); 420/420 GREEN, dart analyze zero — **CLOSED 2026-05-01**

**ONDA 4 COMPLETA.** 4 sub-tickets BFF/desktop rebuild fechados em 3 dias com pipeline 3-agent Round 1 sem rejeição. Phase 4 (Flutter migration user-driven) é next; Onda 5 (gate final A19-A21) também queued.

### Wave 5 — Gate final (3 tickets) — CLOSED 2026-05-01
- [x] **A19** — `dart analyze bff/` zero errors em src/ dos 3 módulos. Pré-requisito BFF-side absorvido (delete `social_care_api_client.dart` + refactor `health_handler.dart` para depender de `HealthContract` canônico). 2050 GREEN.
- [x] **A20** — `CONTRACT_A_PUBLIC_API.md` ganhou §14 "Estado final" + `CONTRACT_A_SPEC.md` ganhou seção "Estado pós-implementação" (sub-contracts 9→11, Wave 4 rebuild, deferimentos a Phase 4). README expandido para 12 docs.
- [x] **A21** — BFF-side cleanup completo (deletado `bff/shared/lib/src/infrastructure/patient_translator.dart` + `mappers/` (5 arquivos) + 14 testes; comentários mortos a `SocialCareContract` removidos em 3 arquivos). Critérios grep passam em `bff/`. Inventário `packages/social_care/` + `apps/acdg_system/` + `bff/shared/dtos/` (12 arquivos + 4 com refs em apps/) deferido a Phase 4 conforme memória user-owned. 2036 GREEN (Δ -14 = patient_translator_test deletado).

### Cross-cutting — Onda 3.5 (1 ticket — descoberto durante A15)
- [ ] A23 — UUID Path Validation Canon (helper + retrofit A07-A14, ~26 intents, ~150 tests novos; bloqueia A15 resume)

## Completed
(none yet)

## Blockers
(none)

## Context for Resume
Last action: A23 W0 + W1 + **W2 complete** (helper + Patient surface +
A09 Family/Audit retrofit).
- W0: helper canônico `validateUuidPathParam` + `UuidPathParamError`
  (28 GREEN).
- W1: Patient surface end-to-end (GetPatient Template A + 4 lifecycle
  Template C). 90 GREEN combinados.
- W2: A09 retrofit completo — 5 intents (Add/Remove/AssignCaregiver/
  UpdateSocialIdentity/GetAuditTrail) + family handler + 17 testes
  novos. Decisões aplicadas:
  - RemoveFamilyMember: named-args mantidos, renomeados pra
    `rawPatientId`/`rawMemberId` por convenção do canon (option (a)).
  - AssignPrimaryCaregiver: Template C com 1 path param (correção
    da Wave-list anterior — `familyMemberId` é body, não path).
  - GetAuditTrail: novo factory `parseFromPath` retornando
    `Result<String>`; handler valida path antes de `parseFromQuery`
    (option (a) — mantém `parseFromQuery` total intacto).
  - `_RemoveFamilyMemberParseError` deletado (UUID gate cobre todos
    os caminhos; endpoint sem body).

Estado em 2026-04-28: 0 issues novos no analyze de W0+W1+W2 surface;
**1006 GREEN / 2 FAIL** no full BFF Web suite (mesmas 2 falhas
pré-existentes A21 — `health_handler_test` e
`social_care_api_client_test` referenciam tipos deletados em A05/A06).

Next action: A23 **W3 — A10 Assessment 7 fichas** (Template C-P2b × 7).
Detalhes precisos no STATE.md do ticket — seção "What's pending → W3".
Resumo:
1. **Variante P2b confirmada** — Assessment usa try/catch sobre
   `fromJson` (não P2 if-case). Não há `if (patientId.isEmpty)` pra
   remover: UUID gate é ADICIONADO acima do try/catch, sem alterar
   parsing existente. Recipe inline no STATE do ticket.
2. **Sweep mecânico** — todos os 7 intents têm shape idêntico
   (`parseFromBody(String patientId, body, {ObservabilityContext? obs})`).
3. **Test sweep numbers** — 78× `'pat-1'` + 7× `'pat-2'` em 7 intent
   tests; 29× `pat-1` em 1 handler test. Replace_all é seguro (`pat-1`
   só aparece em posição de patientId, nunca em body).
4. **REGRA #2 livre** — `assessment_handler_test.dart` não tem
   fixtures não-UUID em casos 404/500. Sweep puro, sem correções de
   intenção.
5. **Handler unchanged** — single-id parseFromBody short-circuits;
   `_handle<X>` continua chamando o mesmo `INVALID_<X>_BODY` em 400.

Baseline pre-W3: 86 GREEN no escopo (8×7 intent + 29 handler + 1
cross-cutting). Full suite: 1006 GREEN / 2 FAIL (mesmas 2 A21
pré-existentes). Esperado pós-W3: +14 GREEN
(7 intent + 7 handler rejection tests).

Fixtures `_test_uuids.dart` cobrem `kPatientUuid`, `kPatientUuidAlt`,
`kNonUuid` — suficientes para W3 (Assessment sempre 1 path param
patientId).
