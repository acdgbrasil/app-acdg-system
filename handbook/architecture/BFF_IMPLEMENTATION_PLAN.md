# BFF Implementation Plan — Social Care

> **Status:** Aprovado (2026-03-12)
> **Decisores:** Gabriel Aderaldo + Claude Code
> **Escopo:** `bff/` do monorepo frontend ACDG

---

## 1. Decisoes Tomadas

Registro de todas as decisoes feitas durante o planejamento, para auditoria.

### D-001: Dois tipos de BFF

Existem **dois BFFs** com responsabilidades distintas:

| | BFF Desktop (Nativo) | BFF Web |
|---|---|---|
| **Deploy** | In-process (package Dart importado) | Servidor Darto HTTP no edge |
| **Validacao** | Replica **100%** das validacoes do servidor (dominio completo: VOs, regras de negocio, state machines, cross-entity) | Proxy + seguranca (Split-Token, RBAC). Validacao leve. |
| **Offline** | Totalmente Offline First. Garante integridade local antes de persistir no Isar. | Nao aplica (requer conexao) |
| **Proposito** | Quando a SyncQueue roda em background, dados ja validados = zero rejeicao no servidor | Barreira de seguranca. Web nunca fala direto com a API. |

**Referencia:** [ADR-002](DECISIONS.md) | [ADR-007](DECISIONS.md) | [ARCHITECTURE.md secao 4](ARCHITECTURE.md)

### D-002: Kernel compartilhado

Um **package Dart compartilhado** (`bff/shared/`) contem tudo que ambos os BFFs usam:
- Models de dominio (VOs, agregados, entidades, erros)
- Validacoes estruturais e de negocio
- Contract (interface abstrata que ambos implementam)
- DTOs de request/response

Cada BFF tem apenas sua implementacao especifica:
- Desktop: in-process, Isar, SyncQueue
- Web: Darto HTTP, proxy, Split-Token

### D-003: SyncQueue de Commands (nao Event Sourcing local)

**Escolha:** Opcao B — enfileirar commands serializados, enviar em ordem ao servidor.

**Motivos:**
1. Os contracts YAML ja definem os requests como commands prontos
2. BFF Desktop valida 1:1 com servidor — chance de rejeicao na sync e minima
3. API REST do backend e orientada a commands (POST/PUT) — nao expoe event ingestion
4. Complexidade drasticamente menor
5. Pode evoluir para Event Sourcing local depois, se necessario

**Fluxo:**
```
Usuario -> Command -> BFF Desktop valida -> Aplica no estado local (Isar) -> Enfileira command na SyncQueue
                                                                          -> Background: envia commands em ordem para API
                                                                          -> Servidor aceita/rejeita cada command
```

### D-004: Ordem de implementacao

```
1. Shared (kernel compartilhado)
2. BFF Desktop (nativo, offline first)
3. BFF Web (Darto HTTP, proxy)
```

---

## 2. Arquitetura de Packages

```
bff/
├── shared/                              # D-002: Kernel compartilhado
│   ├── lib/
│   │   ├── shared.dart                  # Barrel export
│   │   └── src/
│   │       ├── contract/                # Interface abstrata (o que Flutter importa)
│   │       │   ├── social_care_contract.dart
│   │       │   └── dto/
│   │       │       ├── requests/        # Commands (1:1 com OpenAPI requests)
│   │       │       └── responses/       # Respostas tipadas
│   │       ├── domain/                  # Models de dominio puro
│   │       │   ├── kernel/              # 9 VOs cross-cutting
│   │       │   │   ├── person_id.dart
│   │       │   │   ├── professional_id.dart
│   │       │   │   ├── patient_id.dart
│   │       │   │   ├── lookup_id.dart
│   │       │   │   ├── cpf.dart
│   │       │   │   ├── nis.dart
│   │       │   │   ├── cep.dart
│   │       │   │   ├── rg_document.dart
│   │       │   │   ├── address.dart
│   │       │   │   └── timestamp.dart
│   │       │   ├── registry/            # Agregado Patient + entidades
│   │       │   │   ├── patient.dart
│   │       │   │   ├── family_member.dart
│   │       │   │   ├── personal_data.dart
│   │       │   │   ├── civil_documents.dart
│   │       │   │   ├── social_identity.dart
│   │       │   │   └── required_document.dart
│   │       │   ├── assessment/          # VOs de avaliacao
│   │       │   │   ├── housing_condition.dart
│   │       │   │   ├── health_status.dart
│   │       │   │   ├── educational_status.dart
│   │       │   │   ├── socio_economic_situation.dart
│   │       │   │   ├── work_and_income.dart
│   │       │   │   ├── social_benefit.dart
│   │       │   │   ├── social_benefits_collection.dart
│   │       │   │   ├── community_support_network.dart
│   │       │   │   └── social_health_summary.dart
│   │       │   ├── care/                # Atendimento
│   │       │   │   ├── social_care_appointment.dart
│   │       │   │   ├── appointment_id.dart
│   │       │   │   ├── diagnosis.dart
│   │       │   │   ├── icd_code.dart
│   │       │   │   └── ingress_info.dart
│   │       │   └── protection/          # Protecao
│   │       │       ├── referral.dart
│   │       │       ├── referral_id.dart
│   │       │       ├── rights_violation_report.dart
│   │       │       ├── violation_report_id.dart
│   │       │       └── placement_history.dart
│   │       ├── error/                   # AppError padronizado
│   │       │   ├── app_error.dart
│   │       │   └── error_codes.dart     # 60+ codigos (PAT-001, CPF-001, etc.)
│   │       ├── validation/              # Regras de negocio
│   │       │   ├── cross_validator.dart       # Regras inter-campo
│   │       │   ├── aggregate_validator.dart   # Invariantes do agregado
│   │       │   └── metadata_validator.dart    # Regras metadata-driven
│   │       └── analytics/               # Servicos de calculo
│   │           ├── family_analytics.dart
│   │           ├── education_analytics.dart
│   │           ├── financial_analytics.dart
│   │           └── housing_analytics.dart
│   ├── test/                            # Testes unitarios de TUDO acima
│   │   ├── domain/
│   │   ├── validation/
│   │   └── analytics/
│   ├── testing/                         # Fakes e fixtures exportados
│   │   ├── testing.dart
│   │   └── src/
│   │       ├── fake_patient.dart
│   │       └── fixtures.dart
│   └── pubspec.yaml
│
├── social_care_desktop/                 # BFF Nativo (Offline First)
│   ├── lib/
│   │   ├── social_care_desktop.dart     # Barrel export
│   │   └── src/
│   │       ├── bff.dart                 # InProcessBff implements SocialCareContract
│   │       ├── sync/                    # SyncQueue (D-003)
│   │       │   ├── sync_queue.dart
│   │       │   ├── sync_command.dart    # Command serializado + metadata
│   │       │   └── sync_reconciler.dart # Trata aceite/rejeicao do servidor
│   │       ├── storage/                 # Isar schemas + repositories locais
│   │       │   ├── isar_schemas.dart
│   │       │   ├── local_patient_repository.dart
│   │       │   └── local_lookup_repository.dart
│   │       └── api_client/              # Dio wrapper -> API backend
│   │           ├── social_care_api_client.dart
│   │           └── api_mappers.dart
│   ├── test/
│   └── pubspec.yaml                     # depends on bff/shared
│
└── social_care_web/                     # BFF Web (Darto HTTP)
    ├── lib/
    │   ├── social_care_web.dart          # Barrel export
    │   └── src/
    │       ├── server.dart              # Darto HTTP server
    │       ├── routes/                  # Route handlers (proxy para API)
    │       │   ├── registry_routes.dart
    │       │   ├── assessment_routes.dart
    │       │   ├── care_routes.dart
    │       │   ├── protection_routes.dart
    │       │   └── lookup_routes.dart
    │       ├── middleware/              # Auth, CORS, error handling
    │       │   ├── auth_middleware.dart  # Split-Token + JWT validation
    │       │   ├── role_guard.dart       # RBAC
    │       │   └── error_middleware.dart
    │       └── api_client/              # Dio wrapper -> API backend
    │           └── social_care_api_client.dart
    ├── bin/
    │   └── server.dart                  # Entry point
    ├── test/
    └── pubspec.yaml                     # depends on bff/shared
```

---

## 3. Fases de Implementacao

### Fase 1: Shared — Kernel de Dominio

**Objetivo:** Package `bff/shared/` com todos os models, validacoes e contract.

#### 1.1 — Infraestrutura do package
- [ ] Criar `bff/shared/pubspec.yaml`
- [ ] Criar barrel export `bff/shared/lib/shared.dart`
- [ ] Configurar `analysis_options.yaml`

**Fonte:** [pubspec.yaml existente](../../packages/social_care/pubspec.yaml)

#### 1.2 — AppError e codigos de erro
- [ ] `error/app_error.dart` — Erro padronizado com code, message, severity, http, observability
- [ ] `error/error_codes.dart` — Registry dos 60+ codigos

**Fonte:**
- [bff_reference.yaml linhas 114-152](../references/bff_reference/bff_reference.yaml) — AppError spec
- [bff_reference.yaml linhas 2073-2169](../references/bff_reference/bff_reference.yaml) — Error code registry

#### 1.3 — Kernel Value Objects (9 VOs)
Cada VO deve implementar: constructor com validacao, `tryParse`, `==`, `hashCode`, `toString`.

| VO | Referencia bff_reference.yaml | Referencia contracts/ | Testes |
|---|---|---|---|
| `PersonId` | linhas 179-208 | kernel.yaml | UUID format |
| `ProfessionalId` | linhas 211-240 | kernel.yaml | UUID format |
| `PatientId` | linhas 243-271 | kernel.yaml | UUID format |
| `LookupId` | linhas 275-297 | kernel.yaml | UUID format |
| `CPF` | linhas 300-380 | kernel.yaml | checksum, repeated, length, chars |
| `NIS` | linhas 383-410 | kernel.yaml | length, empty |
| `CEP` | linhas 413-510 | kernel.yaml | length, chars, postal range |
| `RGDocument` | linhas 513-586 | kernel.yaml | check digit, state, agency, date |
| `Address` | linhas 589-640 | kernel.yaml | state, city, CEP optional |
| `TimeStamp` | linhas 643-690 | kernel.yaml | ISO8601, UTC, comparisons |

**Fonte:**
- [bff_reference.yaml linhas 175-690](../references/bff_reference/bff_reference.yaml)
- [contracts/shared/validation-rules/kernel.yaml](../../contracts/shared/validation-rules/kernel.yaml)
- [CPF existente no frontend](../../packages/social_care/lib/domain/value_objects/cpf.dart) — referencia de padrao

> **ATENCAO:** Os VOs do `packages/social_care/domain/value_objects/` ja existem com validacao estrutural (ADR-014). O shared do BFF deve conter a versao **completa** (estrutural + negocio). Avaliar se faz sentido o frontend importar os VOs do shared ao inves de manter duplicata.

#### 1.4 — Registry: Agregado Patient
- [ ] `domain/registry/patient.dart` — Agregado com todas as propriedades
- [ ] `domain/registry/family_member.dart` — Entidade com mutators
- [ ] `domain/registry/personal_data.dart` — VO com validacoes
- [ ] `domain/registry/civil_documents.dart` — VO (ao menos 1 doc obrigatorio)
- [ ] `domain/registry/social_identity.dart` — VO com regra condicional
- [ ] `domain/registry/required_document.dart` — Enum

**Fonte:**
- [bff_reference.yaml linhas 696-1086](../references/bff_reference/bff_reference.yaml)
- [contracts/shared/validation-rules/registry.yaml](../../contracts/shared/validation-rules/registry.yaml)

**Invariantes do agregado Patient (devem ter teste):**
1. `initialDiagnosesCantBeEmpty` — ao menos 1 diagnostico na criacao
2. `mustHaveExactlyOnePrimaryReference` — exatamente 1 PR na familia
3. `multiplePrimaryReferencesNotAllowed` — sem PRs duplicados
4. `familyMemberAlreadyExists` — personId unico na familia
5. `familyMemberNotFound` — membro deve existir para remocao/promocao
6. `referralTargetOutsideBoundary` — encaminhamento so para membros do prontuario
7. `violationTargetOutsideBoundary` — vitima so dentro do prontuario
8. `incompatiblePlacementSituation` — adolescente internado requer 12-17 na familia
9. `incompatibleGuardianshipSituation` — guarda por terceiros requer 0-17 na familia

#### 1.5 — Assessment: Value Objects
- [ ] `domain/assessment/housing_condition.dart`
- [ ] `domain/assessment/health_status.dart`
- [ ] `domain/assessment/educational_status.dart`
- [ ] `domain/assessment/socio_economic_situation.dart`
- [ ] `domain/assessment/work_and_income.dart`
- [ ] `domain/assessment/social_benefit.dart`
- [ ] `domain/assessment/social_benefits_collection.dart`
- [ ] `domain/assessment/community_support_network.dart`
- [ ] `domain/assessment/social_health_summary.dart`

**Fonte:**
- [bff_reference.yaml linhas 1292-1558](../references/bff_reference/bff_reference.yaml)
- [contracts/shared/validation-rules/assessment.yaml](../../contracts/shared/validation-rules/assessment.yaml)

#### 1.6 — Care: Agregados e VOs
- [ ] `domain/care/social_care_appointment.dart` — com state machine de tipo
- [ ] `domain/care/appointment_id.dart` — UUID
- [ ] `domain/care/diagnosis.dart` — com ICDCode
- [ ] `domain/care/icd_code.dart` — auto-dot, normalize
- [ ] `domain/care/ingress_info.dart` — com ProgramLink nested

**Fonte:**
- [bff_reference.yaml linhas 1652-1831](../references/bff_reference/bff_reference.yaml)
- [contracts/shared/validation-rules/care.yaml](../../contracts/shared/validation-rules/care.yaml)

#### 1.7 — Protection: Agregados e VOs
- [ ] `domain/protection/referral.dart` — com state machine (PENDING -> COMPLETED/CANCELLED)
- [ ] `domain/protection/referral_id.dart` — UUID
- [ ] `domain/protection/rights_violation_report.dart` — com mutator updateActions
- [ ] `domain/protection/violation_report_id.dart` — UUID
- [ ] `domain/protection/placement_history.dart` — com nested structs

**Fonte:**
- [bff_reference.yaml linhas 1837-2049](../references/bff_reference/bff_reference.yaml)
- [contracts/shared/validation-rules/protection.yaml](../../contracts/shared/validation-rules/protection.yaml)

#### 1.8 — Cross-Validations
- [ ] `validation/cross_validator.dart` — regras inter-campo
- [ ] `validation/aggregate_validator.dart` — invariantes do agregado Patient
- [ ] `validation/metadata_validator.dart` — regras metadata-driven (lookup tables)

**Regras cross-field (devem ter teste):**
1. `cv_pregnancy_requires_female` — gestante deve ser sexo feminino
2. `cv_placement_date_chronology` — endDate >= startDate
3. `cv_third_party_guard_requires_minor` — guarda por terceiros requer menor (0-17)
4. `cv_adolescent_internment_requires_12_17` — internacao requer adolescente (12-17)

**Fonte:**
- [contracts/shared/validation-rules/cross-validations.yaml](../../contracts/shared/validation-rules/cross-validations.yaml)

#### 1.9 — Analytics Services
- [ ] `analytics/family_analytics.dart` — AgeProfile (8 faixas)
- [ ] `analytics/education_analytics.dart` — VulnerabilityReport (notInSchool, illiteracy)
- [ ] `analytics/financial_analytics.dart` — Indicators (RTF, RPC, RTG)
- [ ] `analytics/housing_analytics.dart` — density, isOvercrowded

**Fonte:**
- [bff_reference.yaml linhas 1248-1277](../references/bff_reference/bff_reference.yaml) (Family)
- [bff_reference.yaml linhas 1560-1630](../references/bff_reference/bff_reference.yaml) (Education, Financial, Housing)
- [contracts/shared/validation-rules/analytics.yaml](../../contracts/shared/validation-rules/analytics.yaml)

#### 1.10 — Contract (Interface)
- [ ] `contract/social_care_contract.dart` — Interface abstrata com todos os metodos
- [ ] `contract/dto/requests/` — 1:1 com OpenAPI request schemas
- [ ] `contract/dto/responses/` — Respostas tipadas

**Fonte:**
- [contracts/services/social-care/openapi/openapi.yaml](../../contracts/services/social-care/openapi/openapi.yaml) — 29 endpoints

**Metodos do contract (29 operacoes):**

```dart
abstract class SocialCareContract {
  // Health
  Future<HealthResponse> health();
  Future<ReadinessResponse> ready();

  // Registry (8)
  Future<IdResponse> registerPatient(RegisterPatientRequest request);
  Future<PatientResponse> getPatientById(PatientId id);
  Future<PatientResponse> getPatientByPersonId(PersonId id);
  Future<void> addFamilyMember(PatientId id, AddFamilyMemberRequest request);
  Future<void> removeFamilyMember(PatientId id, PersonId memberId);
  Future<void> assignPrimaryCaregiver(PatientId id, AssignPrimaryCaregiverRequest request);
  Future<void> updateSocialIdentity(PatientId id, UpdateSocialIdentityRequest request);
  Future<List<AuditTrailEntry>> getAuditTrail(PatientId id);

  // Assessment (7)
  Future<void> updateHousingCondition(PatientId id, UpdateHousingConditionRequest request);
  Future<void> updateSocioEconomicSituation(PatientId id, UpdateSocioEconomicSituationRequest request);
  Future<void> updateWorkAndIncome(PatientId id, UpdateWorkAndIncomeRequest request);
  Future<void> updateEducationalStatus(PatientId id, UpdateEducationalStatusRequest request);
  Future<void> updateHealthStatus(PatientId id, UpdateHealthStatusRequest request);
  Future<void> updateCommunitySupportNetwork(PatientId id, UpdateCommunitySupportNetworkRequest request);
  Future<void> updateSocialHealthSummary(PatientId id, UpdateSocialHealthSummaryRequest request);

  // Care (2)
  Future<void> registerAppointment(PatientId id, RegisterAppointmentRequest request);
  Future<void> registerIntakeInfo(PatientId id, RegisterIntakeInfoRequest request);

  // Protection (3)
  Future<void> createReferral(PatientId id, CreateReferralRequest request);
  Future<void> reportRightsViolation(PatientId id, ReportRightsViolationRequest request);
  Future<void> updatePlacementHistory(PatientId id, UpdatePlacementHistoryRequest request);

  // Lookup (1)
  Future<List<LookupItem>> getLookupTable(String tableName);
}
```

#### 1.11 — Testing utilities
- [ ] `testing/src/fake_patient.dart` — Patient fixture builder
- [ ] `testing/src/fixtures.dart` — VOs validos pre-construidos

---

### Fase 2: BFF Desktop (Nativo, Offline First)

**Objetivo:** Package `bff/social_care_desktop/` — implementacao in-process com Isar + SyncQueue.

#### 2.1 — InProcessBff
- [ ] `bff.dart` — Implementa `SocialCareContract`
- [ ] Recebe comandos, valida via shared, persiste no Isar, enfileira na SyncQueue

#### 2.2 — Storage (Isar)
- [ ] `storage/isar_schemas.dart` — Schemas Isar para Patient, FamilyMember, assessments, etc.
- [ ] `storage/local_patient_repository.dart` — CRUD local
- [ ] `storage/local_lookup_repository.dart` — Cache de lookup tables

**Fonte:** [ADR-005](DECISIONS.md) | [ARCHITECTURE.md secao 5](ARCHITECTURE.md)

#### 2.3 — SyncQueue (D-003)
- [ ] `sync/sync_command.dart` — Command serializado com metadata (id, timestamp, endpoint, payload)
- [ ] `sync/sync_queue.dart` — Fila persistida no Isar, processada em ordem FIFO
- [ ] `sync/sync_reconciler.dart` — Trata respostas do servidor (aceite/rejeicao)

**Fluxo da SyncQueue:**
```
1. Command validado pelo shared
2. Estado local atualizado no Isar (projecao otimista)
3. SyncCommand criado: { id, timestamp, method, path, payload, status: PENDING }
4. Persistido na fila Isar
5. Background worker (quando online):
   a. Pega proximo PENDING em ordem de timestamp
   b. Envia para API via ApiClient
   c. Se aceito: marca COMPLETED, atualiza estado local com resposta
   d. Se rejeitado (422): marca REJECTED, notifica usuario
   e. Se erro de rede: mantem PENDING, retry com backoff
6. Conflitos: se servidor retorna 409 (Conflict), marca CONFLICT, usuario resolve
```

**Status do SyncCommand:**
```
PENDING -> COMPLETED (aceito pelo servidor)
PENDING -> REJECTED (validacao falhou no servidor — raro, pois BFF valida igual)
PENDING -> CONFLICT (409 — versao divergiu)
PENDING -> PENDING (erro de rede — retry)
```

#### 2.4 — API Client
- [ ] `api_client/social_care_api_client.dart` — Dio wrapper para API backend
- [ ] `api_client/api_mappers.dart` — Conversao entre models do shared e JSON da API

**Fonte:** [API-REFERENCE.md](../references/api/API-REFERENCE.md) — endpoints, headers, auth

#### 2.5 — Testes
- [ ] Testes unitarios do InProcessBff (com Isar in-memory)
- [ ] Testes da SyncQueue (enfileirar, processar, retry, reject, conflict)
- [ ] Testes de integracao BFF Desktop <-> shared validations

---

### Fase 3: BFF Web (Darto HTTP)

**Objetivo:** Package `bff/social_care_web/` — servidor HTTP proxy com seguranca.

#### 3.1 — Servidor Darto
- [ ] `server.dart` — Setup Darto com middlewares e rotas
- [ ] `bin/server.dart` — Entry point

**Fonte:** [ADR-008](DECISIONS.md)

#### 3.2 — Routes (proxy para API)
- [ ] `routes/registry_routes.dart` — 8 endpoints
- [ ] `routes/assessment_routes.dart` — 7 endpoints
- [ ] `routes/care_routes.dart` — 2 endpoints
- [ ] `routes/protection_routes.dart` — 3 endpoints
- [ ] `routes/lookup_routes.dart` — 1 endpoint

**Fonte:** [contracts/services/social-care/openapi/openapi.yaml](../../contracts/services/social-care/openapi/openapi.yaml)

#### 3.3 — Middleware
- [ ] `middleware/auth_middleware.dart` — Split-Token: recebe cookie HttpOnly, injeta Bearer header
- [ ] `middleware/role_guard.dart` — RBAC (social_worker, owner, admin)
- [ ] `middleware/error_middleware.dart` — Traduz AppError para HTTP response

**Fonte:** [ADR-011](DECISIONS.md) | [SECURITY.md](../references/api/SECURITY.md)

#### 3.4 — API Client
- [ ] `api_client/social_care_api_client.dart` — Dio wrapper (reusa logica do desktop ou extrai para shared)

#### 3.5 — Testes
- [ ] Testes de cada route handler
- [ ] Testes de middleware (auth, RBAC, error)
- [ ] Teste de integracao ponta a ponta (request HTTP -> proxy -> mock API)

---

## 4. Decisao: VOs compartilhados via shared (D-005)

O `bff/shared/` e a **unica fonte de verdade** para Value Objects. O `packages/social_care/` **importa os VOs do shared** ao inves de manter duplicata.

**Decisao:** Frontend importa VOs do `bff/shared/`.

**Motivos:**
1. Elimina duplicacao — uma unica implementacao para manter
2. Garante que frontend e BFF Desktop validam identicamente
3. O shared e Dart puro (sem dependencia de Flutter), entao qualquer package pode importar
4. Se uma regra de validacao muda, muda em um lugar so

**Consequencia:** O `packages/social_care/domain/value_objects/` existente sera **removido** e substituido por imports do shared. Os models de dominio do social_care (`Patient`, `FamilyMember`, etc.) tambem virao do shared.

**Impacto no pubspec.yaml do social_care:**
```yaml
dependencies:
  bff_shared:
    path: ../../bff/shared
```

---

## 5. Mapa de Referencias

Indice de todos os arquivos-fonte que guiam a implementacao.

### Handbook (fonte de verdade)
| Arquivo | Conteudo |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Arquitetura completa (7 secoes) |
| [DECISIONS.md](DECISIONS.md) | 14 ADRs |
| [DIAGRAMS.md](DIAGRAMS.md) | 8 diagramas Mermaid |

### BFF Reference (spec de dominio)
| Arquivo | Conteudo |
|---|---|
| [bff_reference.yaml](../references/bff_reference/bff_reference.yaml) | Spec 1:1 com backend Swift (2.169 linhas) |

### Contracts (schemas e validacoes)
| Arquivo | Conteudo |
|---|---|
| [openapi.yaml](../../contracts/services/social-care/openapi/openapi.yaml) | OpenAPI 3.0 — 29 endpoints |
| [asyncapi.yaml](../../contracts/services/social-care/asyncapi/asyncapi.yaml) | AsyncAPI — eventos assincronos |
| [kernel.yaml](../../contracts/shared/validation-rules/kernel.yaml) | Regras dos 9 VOs kernel |
| [registry.yaml](../../contracts/shared/validation-rules/registry.yaml) | Regras do Registry (Patient, Family) |
| [assessment.yaml](../../contracts/shared/validation-rules/assessment.yaml) | Regras dos 8 VOs de avaliacao |
| [care.yaml](../../contracts/shared/validation-rules/care.yaml) | Regras de Care (Appointment, Diagnosis) |
| [protection.yaml](../../contracts/shared/validation-rules/protection.yaml) | Regras de Protection (Referral, Violation) |
| [cross-validations.yaml](../../contracts/shared/validation-rules/cross-validations.yaml) | 4 regras inter-campo |
| [analytics.yaml](../../contracts/shared/validation-rules/analytics.yaml) | 4 servicos de calculo |
| [model/schemas/](../../contracts/services/social-care/model/schemas/) | 54 schemas YAML individuais |

### API Reference (infraestrutura)
| Arquivo | Conteudo |
|---|---|
| [API-REFERENCE.md](../references/api/API-REFERENCE.md) | 24 endpoints, auth, headers, roles |
| [SECURITY.md](../references/api/SECURITY.md) | JWT, RBAC, Split-Token, threat model |
| [ARCHITECTURE.md (API)](../references/api/ARCHITECTURE.md) | Edge Cloud, K3s, Tailscale, Caddy |

### Codigo existente (referencia de padrao)
| Arquivo | Conteudo |
|---|---|
| [cpf.dart](../../packages/social_care/lib/domain/value_objects/cpf.dart) | Exemplo de VO com validacao estrutural |
| [patient.dart](../../packages/social_care/lib/domain/aggregates/patient.dart) | Agregado Patient existente |
| [patient_repository.dart](../../packages/social_care/lib/data/repositories/patient_repository.dart) | Interface de repository |
| [patient_service_remote.dart](../../packages/social_care/lib/data/services/patient_service_remote.dart) | Service HTTP (Dio) |

---

## 6. Checklist de Auditoria

Use este checklist para validar cada fase antes de avancar.

### Fase 1 (Shared) — Criterios de aceite
- [ ] Todos os 9 VOs kernel possuem testes de happy path, normalizacao, erro de formato
- [ ] Agregado Patient implementa todas as 9 invariantes listadas em 1.4
- [ ] Cross-validations implementam todas as 4 regras listadas em 1.8
- [ ] Analytics services retornam valores corretos para cenarios documentados
- [ ] Contract define todos os 29 metodos do OpenAPI
- [ ] DTOs de request cobrem todos os schemas do `contracts/model/schemas/`
- [ ] AppError implementa todos os 60+ codigos do error registry
- [ ] Zero dependencia de Flutter (package Dart puro)
- [ ] `dart analyze` sem warnings

### Fase 2 (Desktop) — Criterios de aceite
- [ ] InProcessBff implementa `SocialCareContract` completo
- [ ] Isar schemas cobrem todos os models do shared
- [ ] SyncQueue persiste commands, processa em ordem, trata reject/conflict
- [ ] Funciona 100% offline (sem rede, CRUD local funciona)
- [ ] Testes rodam com Isar in-memory
- [ ] `dart analyze` sem warnings

### Fase 3 (Web) — Criterios de aceite
- [ ] Darto server responde nos 29 endpoints
- [ ] Auth middleware valida Split-Token corretamente
- [ ] Role guard bloqueia acesso nao autorizado
- [ ] Proxy repassa headers (Authorization, X-Actor-Id)
- [ ] Error middleware traduz AppError para HTTP status correto
- [ ] Testes de integracao com mock da API backend
- [ ] `dart analyze` sem warnings

---

## 7. Riscos e Mitigacoes

| Risco | Impacto | Mitigacao |
|---|---|---|
| Duplicacao de VOs frontend vs shared | Manutencao dobrada, divergencia | Decisao pendente (secao 4) — resolver na Fase 1.3 |
| SyncQueue com command rejeitado no meio da fila | Dados locais divergem do servidor | Reconciler notifica usuario; commands independentes continuam |
| Isar deprecado ou sem suporte web futuro | Rewrite de storage | Abstrair atras de interface; trocar implementacao sem impacto |
| Darto imaturo (poucos contribuidores) | Bugs, falta de features | Manter camada fina; alternativa: shelf (oficial Dart) |
| Schema evolution (backend muda contrato) | BFF Desktop offline com dados antigos | Versionar SyncCommands; migration na sync |

---

## 8. Glossario

| Termo | Definicao |
|---|---|
| **BFF** | Backend for Frontend — camada intermediaria entre app e API |
| **VO** | Value Object — objeto imutavel identificado por seus atributos |
| **Agregado** | Cluster de objetos tratado como unidade de consistencia |
| **SyncQueue** | Fila de commands pendentes para sincronizacao |
| **Command** | Intencao de mudanca de estado (CQRS) |
| **ADR** | Architecture Decision Record |
| **PR (familia)** | Pessoa de Referencia — membro principal da composicao familiar |
| **Split-Token** | Access Token em memoria + Refresh Token em cookie HttpOnly |
| **Isar** | Database local (IndexedDB web, file-based desktop) |
| **Darto** | Framework HTTP para Dart (servidor) |
| **Cross-validation** | Regra que depende de multiplos campos/entidades |
