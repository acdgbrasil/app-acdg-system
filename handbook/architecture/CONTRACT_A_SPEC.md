# Contract A — Especificação (APP ↔ BFF)

> **Produzido por:** A01 (2026-04-17)
> **Status:** spec-implementado (guiou A02–A21; rev. final 2026-05-01)
> **Racional:** `handbook/architecture/CONTRACT_A_PUBLIC_API.md`
> **Filosofia:** o BFF dita o que o APP pode fazer. O que o backend Swift tem é detalhe de implementação do BFF.
> **Status pós-implementação:** ver §"Estado pós-implementação" no fim do documento — discrepâncias entre spec e código real.

---

## Sumário

| Métrica | Valor |
|---------|------:|
| Total de ações do APP | **35** |
| Endpoints já implementados (parcial/total) | 52 |
| Endpoints compostos (1 request = N ações internas) | **5** |
| Endpoints a REMOVER (vazam topologia) | **6** |
| Sub-contracts internos (Contract B) | **9** |
| Backend requests (Swift) | 4 (2 prováveis, 2 novas) |
| Features Flutter inventariadas | 15 (13 social_care + 2 people_admin) |

---

## Seção A — Tabela de ações (Contract A)

Agrupado por bounded context. Cada linha = 1 ação do usuário = 1 endpoint público.

### A.1 — Auth (5 ações)
| # | Ação | Método + Endpoint | Payload | Response | Sub-contract | Orquestração interna | Status |
|---|------|-------------------|---------|----------|--------------|----------------------|--------|
| 1 | Iniciar login OIDC | GET `/api/auth/login` | — | redirect 302 → Zitadel | AuthContract | 1. PKCE gen<br>2. state cookie<br>3. redirect | existente |
| 2 | Processar callback OIDC | GET `/api/auth/callback?code=&state=` | — | StandardResponse + session cookie | AuthContract | 1. trocar code por tokens<br>2. persistir session<br>3. set-cookie HttpOnly | existente |
| 3 | Logout | POST `/api/auth/logout` | — | StandardResponse | AuthContract | 1. revogar session<br>2. limpar cookie | existente |
| 4 | Dados do usuário atual | GET `/api/auth/me` | — | MeResponse | AuthContract | 1. ler session → retornar claims | existente |
| 5 | Renovar token | POST `/api/auth/refresh` | — | StandardResponse | AuthContract | 1. refresh_token → tokens novos | existente |

### A.2 — Registry / Paciente (6 ações)
| # | Ação | Método + Endpoint | Payload | Response | Sub-contract | Orquestração interna | Status |
|---|------|-------------------|---------|----------|--------------|----------------------|--------|
| 6 | Registrar paciente completo | POST `/api/patients` | **PatientRegisterPayload** (gordo: personal + civil + address + family + intake + socialIdentity + diagnoses) | StandardIdResponse | RegistryContract + people-context | 1. PeopleContext.register (principal)<br>2. PeopleContext.register (cada familiar)<br>3. SocialCare.registerPatient<br>4. SocialCare.addFamilyMember (loop)<br>5. SocialCare.updateIntake<br>6. SocialCare.updateSocialIdentity | **composto** — Intent+UseCase já existe (Phase 2) |
| 7 | Listar pacientes | GET `/api/patients?search=&status=&cursor=&limit=` | — | PaginatedList\<PatientSummaryResponse\> | RegistryContract + people-context | 1. SocialCare.fetchPatients<br>2. PeopleContext.batchGetByIds (enrich nomes) | **scatter-gather** existente |
| 8 | Buscar paciente (detalhe) | GET `/api/patients/{id}` | — | PatientDetailResponse | RegistryContract + people-context + analytics | 1. SocialCare.fetchPatient<br>2. PeopleContext.batchGetByIds (família)<br>3. Analytics.getIndicators (opcional) | **scatter-gather** existente |
| 9 | Admissão | POST `/api/patients/{id}/admit` | AdmitPayload { reason, admittedAt } | StandardResponse | RegistryContract | SocialCare.admitPatient | existente |
| 10 | Alta | POST `/api/patients/{id}/discharge` | DischargePayload { reason, dischargedAt } | StandardResponse | RegistryContract | SocialCare.dischargePatient | existente |
| 11 | Readmissão | POST `/api/patients/{id}/readmit` | ReadmitPayload | StandardResponse | RegistryContract | SocialCare.readmitPatient | existente |
| 12 | Desligamento | POST `/api/patients/{id}/withdraw` | WithdrawPayload | StandardResponse | RegistryContract | SocialCare.withdrawPatient | existente |

### A.3 — Registry / Família & Identidade (4 ações)
| # | Ação | Método + Endpoint | Payload | Response | Sub-contract | Orquestração interna | Status |
|---|------|-------------------|---------|----------|--------------|----------------------|--------|
| 13 | Adicionar familiar | POST `/api/patients/{id}/family-members` | AddFamilyMemberPayload | StandardResponse | RegistryContract + people-context | 1. PeopleContext.register (se cpf)<br>2. SocialCare.addFamilyMember | existente |
| 14 | Remover familiar | DELETE `/api/patients/{id}/family-members/{memberId}` | — | StandardResponse | RegistryContract | SocialCare.removeFamilyMember | existente |
| 15 | Cuidador principal | PUT `/api/patients/{id}/primary-caregiver` | AssignPrimaryCaregiverPayload | StandardResponse | RegistryContract | SocialCare.assignPrimaryCaregiver | existente |
| 16 | Atualizar identidade social | PUT `/api/patients/{id}/social-identity` | UpdateSocialIdentityPayload | StandardResponse | RegistryContract | SocialCare.updateSocialIdentity | existente |

### A.4 — Audit (1 ação)
| # | Ação | Método + Endpoint | Payload | Response | Sub-contract | Status |
|---|------|-------------------|---------|----------|--------------|--------|
| 17 | Histórico de auditoria | GET `/api/patients/{id}/audit-trail?eventType=` | — | StandardResponse\<List\<AuditEventResponse\>\> | AuditContract | existente |

### A.5 — Assessment (7 fichas)
| # | Ação | Método + Endpoint | Payload | Response | Sub-contract | Status |
|---|------|-------------------|---------|----------|--------------|--------|
| 18 | Ficha moradia | PUT `/api/patients/{id}/assessment/housing` | UpdateHousingPayload | StandardResponse | AssessmentContract | existente |
| 19 | Ficha socioeconômica | PUT `/api/patients/{id}/assessment/socioeconomic` | UpdateSocioeconomicPayload | StandardResponse | AssessmentContract | existente |
| 20 | Trabalho & renda | PUT `/api/patients/{id}/assessment/work-income` | UpdateWorkIncomePayload | StandardResponse | AssessmentContract | existente |
| 21 | Educação | PUT `/api/patients/{id}/assessment/education` | UpdateEducationPayload | StandardResponse | AssessmentContract | existente |
| 22 | Saúde | PUT `/api/patients/{id}/assessment/health` | UpdateHealthPayload | StandardResponse | AssessmentContract | existente |
| 23 | Apoio comunitário | PUT `/api/patients/{id}/assessment/community-support` | UpdateCommunitySupportPayload | StandardResponse | AssessmentContract | existente |
| 24 | Resumo saúde social | PUT `/api/patients/{id}/assessment/social-health-summary` | UpdateSocialHealthSummaryPayload | StandardResponse | AssessmentContract | existente |

### A.6 — Care (2 ações)
| # | Ação | Método + Endpoint | Payload | Response | Sub-contract | Status |
|---|------|-------------------|---------|----------|--------------|--------|
| 25 | Atendimento (appointment) | POST `/api/patients/{id}/appointments` | RegisterAppointmentPayload | StandardIdResponse | CareContract | existente |
| 26 | Ingresso / acolhimento | PUT `/api/patients/{id}/intake` | UpdateIntakePayload | StandardResponse | CareContract | existente |

### A.7 — Protection (3 ações)
| # | Ação | Método + Endpoint | Payload | Response | Sub-contract | Status |
|---|------|-------------------|---------|----------|--------------|--------|
| 27 | Relatar violação | POST `/api/patients/{id}/violations` | ReportViolationPayload | StandardIdResponse | ProtectionContract | existente |
| 28 | Criar referência | POST `/api/patients/{id}/referrals` | CreateReferralPayload | StandardIdResponse | ProtectionContract | existente |
| 29 | Atualizar histórico placement | PUT `/api/patients/{id}/placement-history` | UpdatePlacementHistoryPayload | StandardResponse | ProtectionContract | existente |

### A.8 — Lookup (8 ações)
| # | Ação | Método + Endpoint | Payload | Response | Sub-contract | Status |
|---|------|-------------------|---------|----------|--------------|--------|
| 30 | Buscar 1 tabela | GET `/api/lookups/{tableName}` | — | StandardResponse\<List\<LookupItemResponse\>\> | LookupContract | existente |
| 31 | **Batch lookups** | GET `/api/lookups?tables=a,b,c,d` | — | LookupsBatchResponse { Map\<String, List\<LookupItem\>\> } | LookupContract | **NOVO** (substitui N requests do cliente) |
| 32 | Criar item (admin) | POST `/api/lookups/{tableName}` | CreateLookupItemPayload | StandardIdResponse | LookupContract | existente |
| 33 | Atualizar item (admin) | PUT `/api/lookups/{tableName}/{id}` | UpdateLookupItemPayload | StandardResponse | LookupContract | existente |
| 34 | Toggle item (admin) | PATCH `/api/lookups/{tableName}/{id}/toggle` | — | StandardResponse | LookupContract | existente |
| 35 | Listar requests | GET `/api/lookup-requests` | — | List | LookupContract | existente |
| 36 | Criar request | POST `/api/lookup-requests` | CreateLookupRequestPayload | StandardIdResponse | LookupContract | existente |
| 37 | Aprovar request | PUT `/api/lookup-requests/{id}/approve` | — | StandardResponse | LookupContract | existente |
| 38 | Rejeitar request | PUT `/api/lookup-requests/{id}/reject` | — | StandardResponse | LookupContract | existente |

### A.9 — Team (9 ações)
| # | Ação | Método + Endpoint | Payload | Response | Sub-contract | Orquestração | Status |
|---|------|-------------------|---------|----------|--------------|--------------|--------|
| 39 | Listar profissionais | GET `/api/team?role=&active=&search=` | — | List\<TeamMemberResponse\> | TeamContract + people-context | scatter-gather (team + people + roles) | **enriched** |
| 40 | Registrar profissional | POST `/api/team` | RegisterWorkerPayload | StandardIdResponse | TeamContract + people-context | 1. PeopleContext.register<br>2. Team.createWorker<br>3. Team.assignRole | composto existente |
| 41 | Detalhe do profissional | GET `/api/team/{id}` | — | TeamMemberDetailResponse | TeamContract + people-context | 1. Team.get<br>2. PeopleContext.get<br>3. Team.listRoles | **scatter-gather** |
| 42 | Desativar profissional | PUT `/api/team/{id}/deactivate` | — | StandardResponse | TeamContract | existente |
| 43 | Reativar profissional | PUT `/api/team/{id}/reactivate` | — | StandardResponse | TeamContract | existente |
| 44 | Reset de senha | POST `/api/team/{id}/reset-password` | — | StandardResponse | TeamContract | existente |
| 45 | Atribuir role | POST `/api/team/{id}/roles` | AssignRolePayload | StandardResponse | TeamContract | existente |
| 46 | Desativar role | PUT `/api/team/{id}/roles/{roleId}/deactivate` | — | StandardResponse | TeamContract | existente |
| 47 | Reativar role | PUT `/api/team/{id}/roles/{roleId}/reactivate` | — | StandardResponse | TeamContract | existente |

### A.10 — Health Check (2 ações — infra)
| # | Ação | Método + Endpoint | Response | Status |
|---|------|-------------------|----------|--------|
| 48 | Liveness | GET `/api/health/live` | 200 OK | existente |
| 49 | Readiness | GET `/api/health/ready` | 200 OK | existente |

> **Nota:** a contagem de "35 ações de usuário" conta apenas ações funcionais (exclui Health + opcionalmente Auth). Ações visíveis ao usuário final são ~35; endpoints totais ≈49.

---

## Seção B — Endpoints compostos (5)

Estes endpoints consolidam o que hoje é multi-request no cliente. BFF orquestra internamente.

| # | Endpoint | O que consolida | Ganho |
|---|----------|-----------------|-------|
| B1 | POST `/api/patients` | 5–15 requests do cliente (PeopleContext×N + SocialCare×5) em **1** | Wizard de registro faz 1 chamada só |
| B2 | GET `/api/patients` | SocialCare.fetchPatients + PeopleContext.batchGetByIds | Lista enriched com nomes em 1 request |
| B3 | GET `/api/patients/{id}` | SocialCare.fetchPatient + PeopleContext.batchGetByIds + Analytics.indicators | Página de detalhe 1 request |
| B4 | GET `/api/team` | TeamContract.list + PeopleContext.batchGet + roles | Listagem do people_admin em 1 request |
| B5 | **GET `/api/lookups?tables=...`** | N requests (1 por tabela) em **1** — substitui `Future.wait` no PatientRegistrationViewModel | **Será criado** |

---

## Seção C — Endpoints REMOVIDOS do Contract A

Vazam topologia (expõem "People Context" ao cliente). **Deletar em A15.**

| # | Endpoint atual | Razão | Lógica migra para |
|---|----------------|-------|-------------------|
| C1 | GET `/api/people/by-cpf/{cpf}` | "/people" ≠ conceito de negócio do APP | interna do POST `/api/patients` |
| C2 | GET `/api/team/people` | idem | GET `/api/team` (com people-context enrichment interno) |
| C3 | GET `/api/team/people/by-cpf/{cpf}` | idem | interna do POST `/api/team` |
| C4 | GET `/api/team/people/{id}` | idem | GET `/api/team/{id}` |
| C5 | GET `/api/team/people/{id}/roles` | idem | GET `/api/team/{id}` (roles no aggregate) |
| C6 | POST `/api/team/people/{id}/roles` | idem | POST `/api/team/{id}/roles` |

---

## Seção D — Backend requests (Swift)

Features que **podem** exigir ajuste no backend Swift para o BFF entregar o Contract A. Tem workaround no BFF se urgente.

| # | Feature | Por quê | Prioridade | Workaround no BFF |
|---|---------|---------|-----------|-------------------|
| D1 | Buscar pessoa por CPF (PeopleContext) | Validação de duplicidade em registro | Alta | **Provavelmente já existe** — confirmar em A08 |
| D2 | Batch lookup tables | `GET /lookups?tables=...` | Média | BFF pode fazer N chamadas internas e agregar (já é assim) — mas ideal é 1 chamada só ao backend |
| D3 | Patient aggregate enriched | Backend retornar paciente + pessoas resolvidas em 1 call | Baixa | BFF já faz isso via scatter-gather — não é bloqueador |
| D4 | Team member deactivate/reactivate | Status do profissional | Média | **Provavelmente já existe** — confirmar em A15 |

**Conclusão:** nenhum bloqueador crítico. BFF entrega tudo com workarounds se o backend não evoluir.

---

## Seção E — Mapeamento ação → sub-contract (Contract B)

Guia para A04 (consolidação de sub-contracts em `bff/shared/lib/src/contracts/`).

| Sub-contract | Métodos (final) | Ações cobertas (Seção A) | Usado por |
|--------------|-----------------|--------------------------|-----------|
| **AuthContract** | login, callback, logout, refresh, me | 1–5 | AuthHandler |
| **RegistryContract** | registerPatient, fetchPatients, fetchPatient, addFamilyMember, removeFamilyMember, assignPrimaryCaregiver, updateSocialIdentity, admit, discharge, readmit, withdraw | 6–16 | RegistryHandler |
| **AssessmentContract** | updateHousing, updateSocioeconomic, updateWorkIncome, updateEducation, updateHealth, updateCommunitySupport, updateSocialHealthSummary | 18–24 | AssessmentHandler |
| **CareContract** | registerAppointment, updateIntake | 25–26 | CareHandler |
| **ProtectionContract** | reportViolation, createReferral, updatePlacementHistory | 27–29 | ProtectionHandler |
| **LookupContract** | getLookupTable, getLookupsBatch (novo), createItem, updateItem, toggleItem, getRequests, createRequest, approveRequest, rejectRequest | 30–38 | LookupHandler |
| **TeamContract** | listTeam, registerWorker, getTeamMember, deactivate, reactivate, resetPassword, assignRole, deactivateRole, reactivateRole | 39–47 | TeamHandler |
| **AuditContract** | getAuditTrail | 17 | RegistryHandler |
| **AnalyticsContract** | getIndicators (futuro — usado em #8) | — | RegistryHandler (composto #8) |

**Nota — PeopleContract:** NÃO aparece como sub-contract público do BFF. É cliente interno (`PeopleContextClient` em `bff/social_care_web/remote/`) usado apenas por UseCases que compõem operações. Cliente não sabe dele.

---

## Seção F — Notas para tickets downstream

### Para A02 — DTOs request (`bff/shared/lib/src/dto/request/`)
Criar 1 arquivo por payload de ação. Lista aproximada:
- `patient_register_payload.dart` (gordo — composto)
- `admit_payload.dart`, `discharge_payload.dart`, `readmit_payload.dart`, `withdraw_payload.dart`
- `add_family_member_payload.dart`, `assign_primary_caregiver_payload.dart`, `update_social_identity_payload.dart`
- `update_housing_payload.dart`, `update_socioeconomic_payload.dart`, `update_work_income_payload.dart`
- `update_education_payload.dart`, `update_health_payload.dart`, `update_community_support_payload.dart`
- `update_social_health_summary_payload.dart`, `update_intake_payload.dart`
- `register_appointment_payload.dart`
- `report_violation_payload.dart`, `create_referral_payload.dart`, `update_placement_history_payload.dart`
- `create_lookup_item_payload.dart`, `update_lookup_item_payload.dart`, `create_lookup_request_payload.dart`
- `register_worker_payload.dart`, `assign_role_payload.dart`
- **`lookups_batch_request.dart`** (novo — composto)

Total: ~25 payloads.

### Para A03 — DTOs response (`bff/shared/lib/src/dto/response/`)
A maioria já existe em `bff/shared/lib/src/model/`. Reorganizar para `dto/response/`:
- `patient_summary_response.dart`, `patient_detail_response.dart`
- `team_member_response.dart`, `team_member_detail_response.dart`
- `lookup_item_response.dart`, `lookups_batch_response.dart` (novo — batch)
- `audit_event_response.dart`
- `me_response.dart` (auth)
- Envelopes: `StandardResponse<T>`, `StandardIdResponse`, `PaginatedList<T>`

### Para A04 — Sub-contracts consolidados
Criar 9 arquivos em `bff/shared/lib/src/contracts/`:
- `auth_contract.dart` (5 métodos)
- `registry_contract.dart` (11 métodos)
- `assessment_contract.dart` (7 métodos)
- `care_contract.dart` (2 métodos)
- `protection_contract.dart` (3 métodos)
- `lookup_contract.dart` (9 métodos — incluindo batch)
- `team_contract.dart` (9 métodos)
- `audit_contract.dart` (1 método)
- `analytics_contract.dart` (1 método — futuro)

### Para A05 — Deletar SocialCareContract
Arquivo: `bff/shared/lib/src/contract/social_care_contract.dart`. Consumidores atuais (Desktop + Web) passam a importar os 9 sub-contracts individualmente.

### Para A06 — Fakes por contrato (`bff/shared/lib/src/testing/`)
- `fake_auth_bff.dart`, `fake_registry_bff.dart`, `fake_assessment_bff.dart`
- `fake_care_bff.dart`, `fake_protection_bff.dart`
- `fake_lookup_bff.dart`, `fake_team_bff.dart`
- `fake_audit_bff.dart`, `fake_analytics_bff.dart`
- **Deletar** `fake_social_care_bff.dart` monolítico.

### Para A07 — Auth handler
5 endpoints. Intent `AuthCallbackIntent` já existe. Criar Intents/UseCases para login, logout, me, refresh.

### Para A08 — Registry: Patient
7 endpoints (6, 7, 8, 9–12). **Endpoint composto B1** (POST `/api/patients`) já tem Intent/UseCase parcial (Phase 2). Reforçar:
- Payload completo (incluindo initialDiagnoses, socialIdentity, intake)
- Error handling com saga pattern (compensation se algum passo falhar)

### Para A09 — Registry: Family + Identity + Audit
Endpoints 13–17. `AddFamilyMemberIntent` já existe. Criar os demais.

### Para A10 — Assessment
7 endpoints (18–24). Pattern unificado: 1 Intent genérico `UpdateAssessmentIntent` com discriminator `type`, OU 7 Intents específicos. **Decisão em A10:** provavelmente 7 específicos para consistência.

### Para A11 — Care
2 endpoints (25–26).

### Para A12 — Protection
3 endpoints (27–29).

### Para A13 — Lookup
8 endpoints (30, 32–38). Endpoint 31 (batch) fica para A14.

### Para A14 — Lookups Batch
**Endpoint novo** `GET /api/lookups?tables=a,b,c,d`. Internamente: `Future.wait([getLookupTable(a), getLookupTable(b), ...])`. Resposta: `Map<String, List<LookupItem>>`. Único ticket com **comportamento inédito**.

### Para A15 — Team
9 endpoints (39–47). **Remover** 6 rotas de `/team/people/*` listadas na Seção C.

### Para A16–A18 — Desktop alignment
Desktop continua mesmo contrato (sub-contracts em vez de god-interface). Refactor de `remote/`, `storage/`, `sync/` para consumir sub-contracts.

### Para A19 — Gate
`dart analyze bff/` zero errors. Testes ignorados.

### Para A20 — Documentação final
Atualizar `CONTRACT_A_PUBLIC_API.md` com o estado real implementado. Links cruzados com este SPEC.

### Para A21 — Cleanup
Deletar:
- `HttpSocialCareClient` (643L — implementa god-interface morta)
- `PatientTranslator`
- `FakeSocialCareBff`
- Qualquer código que ainda importe `SocialCareContract`

---

## Blockers / Questões abertas descobertas

Nenhum bloqueador crítico. Duas sugestões:

1. **Analytics integration (ação #8 — patient detail enriched)** — hoje não vem dados de analytics no aggregate. Pode ficar pra ticket futuro (fora da Fase 3). Por ora, retornar sem indicadores.
2. **Saga compensation** em POST `/api/patients` — se falhar no passo 4 (addFamilyMember), os passos 1–3 (pessoas registradas) ficam órfãos no PeopleContext. Decisão em A08: implementar compensação ou aceitar inconsistência pequena (logs + job de reconciliação futuro).

---

## Referências
- `handbook/architecture/CONTRACT_A_PUBLIC_API.md` — racional filosófico (§14 inclui retrospectiva pós-implementação)
- `handbook/architecture/DECISIONS.md` — ADRs
- `.pipeline/phase-3-bff-contract-a/000-request.md` — plano da fase
- `bff/social_care_web/lib/src/handlers/` — handlers atuais (referência de implementação)
- `bff/social_care_web/lib/src/intents/` — 4 Intents existentes (padrão a seguir)
- `.claude/skills/flutter-expert/SKILL.md` — princípios arquiteturais (Result<T>, imutabilidade, Dart 3+)

---

## Estado pós-implementação (2026-05-01)

> Esta seção registra discrepâncias entre o spec congelado em A01 e o código que efetivamente existe após Phase 3. A análise filosófica completa está em `CONTRACT_A_PUBLIC_API.md §14`.

### Sub-contracts: 9 → 11

Spec original previa 9 sub-contracts (Seção E). Implementação fechou em **11**:

| # | Sub-contract | Status spec | Status final | Razão |
|---|--------------|-------------|--------------|-------|
| 1 | AuthContract | previsto | implementado em A04 | — |
| 2 | RegistryContract | previsto | implementado em A04 | — |
| 3 | AssessmentContract | previsto | implementado em A04 | — |
| 4 | CareContract | previsto | implementado em A04 | — |
| 5 | ProtectionContract | previsto | implementado em A04 | — |
| 6 | LookupContract | previsto | implementado em A04 | — |
| 7 | TeamContract | previsto | implementado em A04 | — |
| 8 | AuditContract | previsto | implementado em A04 | — |
| 9 | AnalyticsContract | previsto | implementado em A04 (placeholder) | usado em #8 (futuro) |
| 10 | **HealthContract** | não previsto | **adicionado em A04** | probes K8s consomem; A19 canonizou |
| 11 | **PeopleContract** | não previsto (era cliente interno) | **adicionado em A04** como interno | nunca exportado em `social_care_web.dart` |

**Localização:** `bff/shared/lib/src/contract/sub_contracts/{auth,registry,assessment,care,protection,lookup,team,audit,analytics,health,people}_contract.dart`.

### Endpoints REMOVIDOS (Seção C — A15)

Todos os 6 endpoints `/team/people/*` foram efetivamente removidos em A15 (2026-04-29). Confirmado por reviewer (zero MUST_FIX).

### Endpoint COMPOSTO B5 (lookups batch)

`GET /api/lookups?tables=a,b,c` foi entregue em A14 como previsto. Estreia do **query-only parse strategy** no canon. Cap em 20 tabelas. CSV tolerante (split→trim→filter).

### Wave 4 — Desktop (A16-v2 → A18c-v2)

Spec previa "Desktop continua mesmo contrato — refactor de remote/, storage/, sync/". **Re-baselineado como rebuild** em 2026-04-29 (decisão usuário). Resultado:

| Camada | Spec original | Implementado |
|--------|---------------|--------------|
| `remote/` | refactor | rebuild — 8 thin remotes |
| `storage/` | refactor | substituído por `cache/` (5 contracts Aggregate-Root aligned, não 7 espelhando Contract B) |
| `sync/` | refactor | rebuild — `SyncDatabase` em arquivo separado, 27 SyncMutation sealed-class |
| `use_cases/` | (não previsto na spec) | 42 use cases em 3 patterns canônicos (Read cache-first / Write optimistic-through / Health passthrough) |
| `facade/` | (não previsto) | `SocialCareDesktop` + 7 sub-facades |

### Itens deferidos a Phase 4

A21 listou cleanups em `packages/social_care/` que **não foram executados** em Phase 3 (memória `feedback_packages_user_owned` — packages/ é Phase 4 territory). Inventário:

| Arquivo | Localização | Quem deleta |
|---------|-------------|-------------|
| `http_social_care_client.dart` | `packages/social_care/lib/src/data/services/` | Phase 4 |
| `http/` split | `packages/social_care/lib/src/data/services/` | Phase 4 |
| `PatientTranslator` | `packages/social_care/lib/src/...` | Phase 4 |
| `PatientDetailTranslator` | `packages/social_care/lib/src/ui/home/...` | Phase 4 |
| `bff_patient_repository.dart` | `packages/social_care/lib/src/data/repositories/` | Phase 4 |

Cleanup BFF-side de A21 foi absorvido por A19:

| Arquivo | Localização | Disposição em A19 |
|---------|-------------|-------------------|
| `social_care_api_client.dart` | `bff/social_care_web/lib/src/remote/` | DELETADO (god-class implementando `SocialCareContract` morta) |
| `social_care_api_client_test.dart` | `bff/social_care_web/test/remote/` | DELETADO |
| `health_handler.dart` | `bff/social_care_web/lib/src/handlers/` | REFATORADO (depende de `HealthContract` agora) |
| `health_handler_test.dart` | `bff/social_care_web/test/handlers/` | REFATORADO (`FakeSocialCareBff` → `FakeHealthBff`) |
