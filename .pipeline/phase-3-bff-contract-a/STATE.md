# Pipeline State: phase-3-bff-contract-a

## Current Phase
phase: implementation (Onda 3 em andamento)
agent: —
status: 14/22 tickets done | A15 paused at Wave 4.5 awaiting A23 | A23 W0+W1 complete (Patient surface canonical) | next is A23 W2 (Family + Audit, 5 intents)

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
- [/] A15 — Team (9 endpoints, sem `/people/by-cpf/*` e `/team/people/*`); estreia do **query-tolerant** (variante de query-only com TODOS os params opcionais — `ListTeamIntent`); 9 intents + 9 use cases + 1 handler + 1 handler test; +102 tests GREEN (946 total) ao pausar; **PAUSADO em Wave 4.5** após descoberta de route bleed em `/team/<id>` (qualquer 2-seg como `id`, gerando 500 ao backend para URLs legadas tipo `/team/people`); decisão (usuário, 2026-04-28): "validação de UUID em path params é regra global, não escolha por feature" → **bloqueia em A23** (canon UUID path validation + retrofit A07-A14); A15 retoma APÓS A23 fechar para aplicar o helper canônico aos 9 Team intents; documentado test cheat (REGRA #2 do CLAUDE.md) em `team_handler_test.dart` grupo `topology hiding` que A15-resume corrige

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
- [/] A15 — Team (sem /people/by-cpf/* e /team/people/*) — **PAUSED at W4.5, blocked by A23**

### Wave 4 — bff/social_care_desktop/ (3 tickets)
- [ ] A16 — remote/ consome sub-contracts
- [ ] A17 — storage/ alinhado com payloads novos
- [ ] A18 — sync/ SyncEngine com DTOs novos

### Wave 5 — Gate final (3 tickets)
- [ ] A19 — dart analyze bff/ zero errors em src/
- [ ] A20 — Atualizar handbook/architecture/CONTRACT_A_PUBLIC_API.md com Contract A real
- [ ] A21 — Deletar código legado (HttpSocialCareClient, PatientTranslator, stubs deprecated)

### Cross-cutting — Onda 3.5 (1 ticket — descoberto durante A15)
- [ ] A23 — UUID Path Validation Canon (helper + retrofit A07-A14, ~26 intents, ~150 tests novos; bloqueia A15 resume)

## Completed
(none yet)

## Blockers
(none)

## Context for Resume
Last action: A23 W0 + W1 **complete** (helper + Patient surface
end-to-end).
- W0: helper canônico `validateUuidPathParam` + `UuidPathParamError`
  (28 GREEN). Naming PÚBLICO por fundamentação na ENCAPSULATION_POLICY
  (H7 — função antes de classe quando stateless; reutilizado por 35+
  arquivos).
- W1: GetPatient (Template A) + Admit/Discharge/Readmit/Withdraw
  (Template C) retrofitados. **Ambos templates A e C validados
  end-to-end** (Intent + Test + Handler + Handler test). 90 GREEN
  combinados (28 helper + 62 Patient surface).
- REGRA #2 aplicada: fixture `'unknown'` → `kPatientUuidAlt` em
  `registry_patient_handler_test.dart` (intenção 404 preservada,
  fixture não-UUID corrigida).
- `test/_test_uuids.dart` com fixtures canônicos compartilhados.

Estado coerente em 2026-04-28: 0 issues novos no analyze do A23
surface, 90/90 tests do A23 surface GREEN, 69/69 tests do W2 baseline
(5 intents-alvo + family handler) GREEN e ainda pré-retrofit.

Next action: A23 **W2 — A09 Family + Audit** (5 intents). Templates
A/B/C documentados em `tickets/A23-uuid-path-validation/STATE.md`,
com **3 desvios verbatim já catalogados** no próprio STATE do ticket
(seção "What's pending → W2"):
1. RemoveFamilyMember usa parseFromParams com named args (não
   posicionais como Template B literal) — preferir adaptar inline.
2. AssignPrimaryCaregiver tem 1 path param, não 2 (correção de uma
   linha incorreta da Wave-list anterior).
3. GetAuditTrail só tem parseFromQuery factory — adicionar segundo
   factory parseFromPath para casar com o spírito de Template A.

Fixtures de UUID já presentes em `_test_uuids.dart` (kPatientUuid,
kFamilyMemberUuid, kAuditUuid, kNonUuid). Nada a criar antes de W2.
