# Phase 3 — BFF Contract A (implementação completa)

## Objetivo
Reimplementar o BFF (`bff/shared/`, `bff/social_care_web/`, `bff/social_care_desktop/`) para que ele **dite as regras de negócio do APP**, orquestrando os microserviços Swift/Vapor como componentes. O resultado: um **Contract A** real e feature-oriented, pronto para ser consumido pelo Flutter na Fase 4.

## Filosofia
O BFF **não é proxy**. O BFF é o backend que o APP enxerga. Ele:
1. Define o vocabulário público (Contract A) pelo que o APP precisa, não pelo que o backend tem.
2. Orquestra microserviços internamente (Contract B).
3. Pode manter estado (cache, workflow, saga).
4. Pode **exigir** que o backend crie endpoints quando necessário.
5. Esconde totalmente a topologia interna do cliente.

## Política de encapsulamento (2026-04-17)
Ver `handbook/architecture/ENCAPSULATION_POLICY.md` — **regra adotada nesta fase**:
- `_` **apenas** em 3 casos: (1) deps injetadas em fronteiras arquiteturais, (2) helpers de arquivo, (3) state com invariante real.
- Preferir **composition + SRP** a esconder state em `_Map`/`_List`.
- **Sealed class** para variações de comportamento em vez de `_mode`/`_strategy`.
- Extrair classes colaboradoras explícitas quando state merece nome próprio.
- Aplicar em tickets A07–A21 e, opcionalmente, refatorar fakes de A06 (ticket A06b).

## Mudança vs plano anterior
- Pipeline anterior (`phase-3-flutter-acl`) foi renomeada para `phase-4-flutter-migration` e colocada em hold.
- Fase atual é **BFF-only**. Flutter não é tocado.

## Escopo (21 tickets)

### Onda 1 — Design (1)
**A01 — Contract A definitivo**
Pesquisa no Flutter (páginas, wizards, ações de usuário) para extrair o que o APP precisa. Saída: tabela completa de ações × payloads × responses × orquestração interna. Documento é base para A02..A21.

### Onda 2 — `bff/shared/` limpo (5)
**A02** — DTOs request (payloads Contract A em `dto/request/`)
**A03** — DTOs response (respostas em `dto/response/` — reorganizar existentes)
**A04** — Contracts consolidados em `contracts/` (sub-contracts como Contract B)
**A05** — Deletar `SocialCareContract` god-interface
**A06** — Fakes por contrato (`fake_registry_bff.dart`, `fake_assessment_bff.dart`, ...)

### Onda 3 — `bff/social_care_web/` (9)
**A07** — Auth (5 endpoints)
**A08** — Registry: Patient (register, list, get, lifecycle)
**A09** — Registry: Family + Social Identity + Audit
**A10** — Assessment (7 fichas)
**A11** — Care (Appointment, Intake)
**A12** — Protection (Violation, Referral, PlacementHistory)
**A13** — Lookup (get, create, update, toggle, requests)
**A14** — Lookup batch composto (`GET /api/lookups?tables=...`)
**A15** — Team (sem `/people/by-cpf/*` e `/team/people/*`)

Cada ticket cria: handler + Intent + UseCase + payloads + orquestração.

### Onda 4 — `bff/social_care_desktop/` (3)
**A16** — `remote/` consome sub-contracts (em vez de `SocialCareContract`)
**A17** — `storage/` (offline-first) alinhado com payloads novos
**A18** — `sync/` (SyncEngine) com DTOs novos

### Onda 5 — Gate final (3)
**A19** — `dart analyze bff/` zero errors em `src/` (testes ignorados)
**A20** — Atualizar `handbook/architecture/CONTRACT_A_PUBLIC_API.md` com Contract A real
**A21** — Deletar código legado (HttpSocialCareClient deprecated, PatientTranslator, stubs)

## Pipeline por ticket — **TDD obrigatório**

A fase é BFF Dart puro (shelf server, sem Flutter). A skill `flutter-expert` não se aplica 1:1, mas seus princípios fundamentais sim:
- **Result<T>** para todos os retornos
- **Immutable DTOs** (final fields, fromJson/toJson)
- **Repository/Service pattern** (sub-contracts, remote clients)
- **Fakes em testing/** (nunca magic mocks)
- **Naming:** sem sufixo `Impl`, classes PascalCase, arquivos snake_case
- **Code EN**
- **Dart 3+ APIs** (switch exhaustivo, sealed classes)
- **No `throw`** em domain/application — converter para `Result.error`

### Fluxo TDD por ticket de código (A02..A18)
```
000-request.md
  ↓
Wave 0 — test-writer agent → testes RED (falhando)
  ↓
Wave 1 — implementer agent → código até testes passarem GREEN
  ↓
Wave 2 — review agent → verifica princípios + Non-Negotiables
  ↓
Wave 3 — quality agent → dart analyze verde em src/
  ↓
STATE.md completed
```

### Regra de ouro — agentes diferentes por wave
- **test-writer** só lê contratos (sub-contract de A04 + payloads de A02/A03). NUNCA olha implementação.
- **implementer** lê os testes da Wave 0 e implementa até passarem. Não altera testes.
- **reviewer** lê tudo read-only, produz REPORT.md.
- **quality** roda `dart analyze`; se falhar, aponta para o implementer refazer.

Isso evita viés ("implementar pensando no teste" ou "testar pensando na implementação"). Testes viram contrato executável.

### Tickets que NÃO aplicam TDD
- A01 (design, só pesquisa)
- A19 (gate — só rodar analyze)
- A20 (documentação)
- A21 (cleanup — delete)

## Critérios de aceitação da fase
- [ ] Contract A documentado em `handbook/architecture/CONTRACT_A_PUBLIC_API.md`
- [ ] `dart analyze bff/` zero errors em `src/`
- [ ] Zero referência a `SocialCareContract` em todo o `bff/`
- [ ] Flutter Web usando apenas endpoints `/api/*` definidos no Contract A (validação manual)
- [ ] Desktop funciona (compila e sobe o app)
- [ ] `HttpSocialCareClient`, `PatientTranslator` e translators primitivos deletados

## Estratégia de merge
- 1 ticket = 1 PR
- CI roda só `dart analyze bff/` (testes ignorados)
- Review manual
- Merges em `dev`; deploy staging após cada onda
- Deploy prod só após Fase A completa

## O que fica para Fase 4
`phase-4-flutter-migration` retoma depois. T01 (domain models), T02 (mappers), split do `http_social_care_client` que já fizemos ficam como insumos. Flutter migra para consumir Contract A definitivo.
