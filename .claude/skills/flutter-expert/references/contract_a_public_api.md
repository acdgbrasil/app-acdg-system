# Contract A — Public API (Flutter ↔ BFF)

> **Status:** Proposta (draft)
> **Autor:** Gabriel + Chat (discussão arquitetural 2026-04-16)
> **Aceita breaking changes?** Sim — reformulação deliberada, Web como piloto.
> **Escopo inicial:** `bff/social_care_web/` + `packages/social_care/`.
> **Consumido pela skill:** `flutter-expert` (referência oficial — ver §12).

---

## Sumário
1. Motivação
2. Os 3 contratos (A/B/C)
3. Antes × depois — registrar paciente
4. Segurança — Information Hiding
5. Contract A completo — endpoints públicos
6. Estrutura do Flutter pós-migração (alinhada à skill)
7. O que muda no BFF Web
8. Alinhamento com os Non-Negotiables da skill
9. Estratégia de migração (Strangler Fig)
10. Trade-offs
11. Literatura
12. Como a skill `flutter-expert` opera sobre este contrato
13. Apêndices

---

## 1. Motivação

Hoje `packages/social_care/` importa `bff/shared/` em **70 arquivos** (ViewModels, Views, UseCases). Registrar um paciente com família dispara **5–15 requests HTTP** do Flutter, orquestrando lógica que expõe a topologia interna:

- `POST /people` (revela People Context)
- `POST /patients`
- `POST /people` + `POST /patients/:id/family-members` (loop N)
- `PUT /patients/:id/intake`
- `PUT /patients/:id/social-identity`

Problemas técnicos:

1. **Acoplamento** — DTO muda → 70 arquivos quebram.
2. **Information leakage** — cliente sabe que há microserviços separados.
3. **Attack surface** — cada endpoint é superfície independente.
4. **Estado parcial no cliente** — falha no 3º de 7 passos é inconsistência.

Violações diretas dos Non-Negotiables da skill (`SKILL.md` §"Non-Negotiable Rules"):
- Rule #4: *"Models as schemas — business logic in BFF, never in Model"* — cliente hoje ORQUESTRA, não só consome.
- Rule #6: *"Unidirectional data flow"* — cliente hoje precisa conhecer ordem de operações.

**Esta proposta:** 1 request por ação de usuário. BFF orquestra. Cliente não sabe que microserviços existem.

---

## 2. Os 3 Contratos

```
┌─────────────────────────────────────────────────────────────┐
│ Flutter App (packages/social_care)                          │
│                                                             │
│  View → ViewModel → UseCase → Repository → Service          │
│  (ChangeNotifier + Command pattern — skill §Core Patterns)  │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              │  CONTRACT A  (Public API)
                              │  - Feature-oriented
                              │  - 1 request = 1 ação de usuário
                              │  - Payload auto-suficiente
                              │  - Zero conhecimento de microserviços
                              │
┌─────────────────────────────▼───────────────────────────────┐
│ BFF Web (bff/social_care_web)                               │
│                                                             │
│  Handler → Intent → UseCase (scatter-gather)                │
└──┬─────────────────────┬────────────────────┬───────────────┘
   │                     │                    │  CONTRACT B
   ▼                     ▼                    ▼
┌──────────┐      ┌──────────────┐     ┌──────────────┐
│ Swift    │      │ People       │     │ (futuros)    │
│ Social   │      │ Context      │     │              │
│ Care     │      │              │     │              │
└──────────┘      └──────────────┘     └──────────────┘
              CONTRACT C (Backend internal)
```

| Contrato | Entre | Schema | Propriedades |
|----------|-------|--------|--------------|
| **A — Public API** | Flutter ↔ BFF Web | Próprio do BFF Web | REST síncrono, fat payloads, feature-oriented |
| **B — Orchestration** | BFF ↔ backends | `bff/shared/` | Granular, conhece topologia |
| **C — Backend Internal** | Swift ↔ Swift / DB | DTOs Vapor | Interno a cada microserviço |

**Regra de ouro:** `packages/social_care/` **nunca** importa `bff/shared/`. Apenas o BFF Web importa.

---

## 3. Antes × Depois — Registrar Paciente

### Hoje (acoplado)

```
Flutter Web                         BFF Web                      Backends
───────────                         ───────                      ────────
POST /people             ────►      [proxy]             ────►    PeopleContext
  ◄─── personId         ◄────
POST /patients           ────►      [proxy]             ────►    Social Care
  ◄─── patientId        ◄────
(loop N: POST /people + POST /patients/:id/family-members)
PUT /patients/:id/intake ────►      [proxy]             ────►    Social Care
PUT /patients/:id/social-identity ──► [proxy]           ────►    Social Care

Total: 5–15 requests do Flutter
F12 do atacante: vê 8+ endpoints distintos → mapeia arquitetura
```

### Contract A (coeso, opaco)

```
Flutter Web                         BFF Web                      Backends
───────────                         ───────                      ────────
POST /patients           ────►      RegisterPatientIntent
{ personalData, civilDocs,            ├──► PeopleContext: create primary
  address, intakeInfo,                ├──► PeopleContext: create each member (loop)
  socialIdentity,                     ├──► Social Care: registerPatient
  familyMembers: [...],               ├──► Social Care: addFamilyMember (loop)
  initialDiagnoses: [...] }           ├──► Social Care: updateIntake
                                      └──► Social Care: updateSocialIdentity
  ◄─── { patientId }   ◄────

Total: 1 request do Flutter
F12 do atacante: vê apenas POST /api/patients 201
```

---

## 4. Segurança — Information Hiding

**Princípio** (Parnas, 1972): cada módulo esconde suas decisões de design.

Aplicado ao BFF como boundary:
- Cliente não sabe de People Context → vulnerabilidade lá não é atacável diretamente.
- Cliente não sabe granularidade de updates → não especula `PUT /patients/:id/cpf`.
- Cliente não sabe ordem de operações → não explora race conditions.
- 1 request = 1 unidade de auditoria → log de segurança limpo.

**Literatura:**
- Parnas, *"On the Criteria To Be Used in Decomposing Systems into Modules"* (CACM, 1972)
- OWASP Top 10, A01:2021 — Information Disclosure
- Sam Newman, *Building Microservices* (2ª ed., 2021), Cap. 5

---

## 5. Contract A Completo — Endpoints Públicos

Agrupados por **user journey**. Prefixo `/api/*`.

### 5.1. Autenticação (mantém)
```
GET  /api/auth/login              inicia OIDC PKCE
GET  /api/auth/callback           troca code por tokens
POST /api/auth/logout
GET  /api/auth/me
POST /api/auth/refresh
```

### 5.2. Paciente — listagem & detalhe (scatter-gather)
```
GET  /api/patients?search=&status=&cursor=&limit=
     ─► BFF compõe Social Care + People Context; retorna lista enriquecida.

GET  /api/patients/{id}
     ─► BFF compõe Social Care (dados) + People Context (pessoas) + Analysis BI (indicadores);
        retorna aggregate completo.
```

### 5.3. Paciente — registro completo em 1 request
```
POST /api/patients
Body: {
  personalData:     {...},
  civilDocuments:   {...},
  address:          {...},
  intakeInfo:       {...},
  socialIdentity:   {...},
  initialDiagnoses: [...],
  familyMembers:    [{...}, {...}]
}
─► BFF orquestra PeopleContext + SocialCare com saga/compensação.
─► Resposta: { patientId }
```

### 5.4. Lifecycle do paciente
```
POST /api/patients/{id}/admit       { reason, admittedAt }
POST /api/patients/{id}/discharge   { reason, dischargedAt }
POST /api/patients/{id}/readmit     { reason, readmittedAt }
POST /api/patients/{id}/withdraw    { reason, withdrawnAt }
```

### 5.5. Família (incremental pós-registro)
```
POST   /api/patients/{id}/family       { fullName, birthDate, cpf, relationship, ... }
DELETE /api/patients/{id}/family/{memberId}
PUT    /api/patients/{id}/family/{memberId}/primary-caregiver
```

### 5.6. Fichas de avaliação (1 request cada)
```
PUT /api/patients/{id}/assessment/housing
PUT /api/patients/{id}/assessment/socioeconomic
PUT /api/patients/{id}/assessment/work-income
PUT /api/patients/{id}/assessment/education
PUT /api/patients/{id}/assessment/health
PUT /api/patients/{id}/assessment/community-support
PUT /api/patients/{id}/assessment/social-health-summary
PUT /api/patients/{id}/intake
PUT /api/patients/{id}/social-identity
```

### 5.7. Cuidado & proteção
```
POST /api/patients/{id}/appointments       { type, date, notes, ... }
PUT  /api/patients/{id}/placement-history  { entries: [...] }
POST /api/patients/{id}/violations         { type, description, ... }
POST /api/patients/{id}/referrals          { target, reason, ... }
```

### 5.8. Equipe (sem expor "people")
```
GET  /api/team?role=&active=
POST /api/team
GET  /api/team/{id}
PUT  /api/team/{id}/deactivate
PUT  /api/team/{id}/reactivate
POST /api/team/{id}/reset-password
POST /api/team/{id}/roles
PUT  /api/team/{id}/roles/{roleId}/deactivate
PUT  /api/team/{id}/roles/{roleId}/reactivate
```
`/people/by-cpf/*` e `/team/people/*` **não existem** no Contract A.

### 5.9. Governança de lookups
```
GET   /api/lookups/{tableName}
POST  /api/lookups/{tableName}                 (admin)
PUT   /api/lookups/{tableName}/{id}
PATCH /api/lookups/{tableName}/{id}/toggle
GET   /api/lookup-requests
POST  /api/lookup-requests
PUT   /api/lookup-requests/{id}/approve
PUT   /api/lookup-requests/{id}/reject
```

---

## 6. Estrutura do Flutter Pós-Migração

Estrutura **100% alinhada à skill** (`SKILL.md` §"Package Structure Reference" + §"Implementation Order"):

```
packages/social_care/lib/src/
│
├── domain/
│   └── models/                    ← Entidades puras (Patient, FamilyMember, …)
│                                    with Equatable, imutáveis, copyWith
│                                    SEM fromJson/toJson
│
├── data/
│   ├── model/                     ← API models (payloads Contract A)
│   │   ├── patient_payload.dart     (fromJson / toJson)
│   │   ├── family_payload.dart
│   │   └── ... (1 por endpoint do Contract A)
│   │
│   ├── services/                  ← HTTP client puro (stateless, 1 método/endpoint)
│   │   ├── patient_service.dart
│   │   ├── assessment_service.dart
│   │   ├── team_service.dart
│   │   └── lookup_service.dart
│   │
│   ├── mappers/                   ← 1 mapper por endpoint, retorna Result<T>
│   │   ├── patient_register_mapper.dart
│   │   ├── patient_detail_mapper.dart
│   │   ├── housing_mapper.dart
│   │   └── ...
│   │
│   └── repositories/              ← Abstract + impl por strategy (Http*, Drift*, InMemory*)
│       ├── patient_repository.dart
│       ├── assessment_repository.dart
│       └── team_repository.dart
│
├── ui/
│   └── <feature>/
│       ├── view_models/           ← ChangeNotifier + Command0/Command1
│       ├── use_cases/             ← Orquestra repositories, retorna Result<T>
│       ├── widgets/               ← Atomic Design (Page → Organism → Molecule → Atom)
│       └── di/                    ← Stub providers (throw UnimplementedError)
│
└── testing/
    └── fakes/                     ← Fake repositories/services (skill §Testing)
```

### Regra de import (lint obrigatório)
`packages/social_care/analysis_options.yaml` proíbe `package:shared/shared.dart` fora de:
- `lib/src/data/model/`
- `lib/src/data/services/`
- `lib/src/data/mappers/`

ViewModels, UseCases e Views **não podem** importar `bff/shared/`.

---

## 7. O que Muda no BFF Web

### 7.1. `bff/social_care_web/lib/src/intents/` (expande)
Um Intent por endpoint do Contract A:
```
register_patient_intent.dart        (já existe)
update_housing_intent.dart          (novo)
update_intake_intent.dart           (novo)
add_family_member_intent.dart       (já existe)
register_worker_intent.dart         (já existe)
assign_role_intent.dart             (novo)
...
```

### 7.2. `bff/social_care_web/lib/src/use_cases/` (expande)
Cada Intent tem seu UseCase que chama Contract B (`bff/shared/`).

### 7.3. `bff/social_care_web/lib/src/handlers/` (fica fino)
Handler apenas: receber JSON → montar Intent → delegar UseCase → serializar resposta.

### 7.4. `bff/shared/` (sem mudanças)
Continua sendo Contract B. Desktop BFF e Web BFF continuam usando.

---

## 8. Alinhamento com os Non-Negotiables da Skill

Mapeamento direto com `.claude/skills/flutter-expert/SKILL.md` §"Non-Negotiable Rules" (23 regras):

| # | Regra da skill | Como Contract A reforça |
|---|----------------|-------------------------|
| 1 | MVVM strict + Command | ViewModel mantém Command pattern; payload construído sem lógica extra |
| 3 | Total immutability on Models | Domain models do Flutter não têm fromJson — imutáveis de verdade |
| 4 | Models as schemas — business logic in BFF | **Este é o coração do Contract A** — orquestração sai do cliente |
| 5 | UseCase mandatory | UseCases continuam, mas agora recebem/retornam **apenas domain models** |
| 6 | Unidirectional data flow | 1 request = 1 ação. Sem side effects encadeados no cliente |
| 7 | Repository as abstract class | `PatientRepository` abstrato + `HttpPatientRepository` concreto |
| 8 | Fakes for tests | `FakePatientRepository` fica trivial (opera em domain models) |
| 12 | Never use Impl suffix | `HttpPatientRepository`, não `PatientRepositoryImpl` |
| 13 | Each mapper per endpoint | 1 mapper por endpoint do Contract A (ex: `patient_register_mapper.dart`) |
| 14 | Mapper returns Result<T> | `Result<Patient>` com switch exhaustivo |
| 21 | Result<T> everywhere | `Ok<T>` / `Error<T>` em toda operação async |
| 22 | Services are private in Repository | `HttpPatientRepository` guarda `_service` como campo privado |
| 23 | Repositories are private in ViewModel | ViewModel recebe UseCase; UseCase guarda repository privado |

Não há regra da skill **violada** por este contrato. Pelo contrário, várias que hoje estão **parcialmente violadas** passam a ser naturalmente respeitadas.

---

## 9. Estratégia de Migração (Strangler Fig — Fowler 2004)

Princípio: manter velho e novo lado a lado, migrar feature por feature, deletar o velho quando ninguém mais usa.

**Ordem por feature (dentro de cada feature, a ordem oficial da skill):**

```
Model → Service → Repository → UseCase → ViewModel → View
```

### Onda 1 — Infraestrutura (sem mudar comportamento)
1. Criar `packages/social_care/lib/src/domain/models/` com domain models próprios.
2. Criar `packages/social_care/lib/src/data/model/` com payloads do Contract A.
3. Criar `packages/social_care/lib/src/data/mappers/` (um por endpoint).
4. Criar services HTTP puros (`PatientService`, `AssessmentService`, …).
5. Criar abstract repositories + `Http*` impls.

### Onda 2 — Feature piloto (sugestão: Housing)
Justificativa: ficha simples, 1 endpoint, baixo risco.
1. `HousingConditionUseCase` recebe/retorna domain.
2. `HousingConditionViewModel` usa Command pattern; **remove import de `bff/shared/`**.
3. Widget tree consome selectors/connectors.
4. Validar em produção.
5. Se passar: template para replicar.

### Onda 3 — Fichas restantes
Socioeconomic → Work/Income → Education → Health → Community Support → Social Health Summary → Intake → Social Identity.

### Onda 4 — Fluxos compostos
1. Redesenhar BFF Web: `POST /api/patients` aceita payload completo.
2. Flutter: 1 request substitui os 5–15 antigos.
3. Mesmo para Team admin.

### Onda 5 — Limpeza
1. Deletar `HttpSocialCareClient` (god-interface).
2. Deletar `PatientTranslator` (ACL primitivo).
3. Ativar lint: proibir `package:shared/shared.dart` fora de `data/model,services,mappers`.

---

## 10. Trade-offs

| Ganho | Preço |
|-------|-------|
| ViewModels imunes a mudanças de DTO | 3 shapes para o mesmo dado: domain + payload + DTO (`bff/shared/`) |
| Information hiding → security | Mais código no BFF (orquestração explícita) |
| 1 request por ação → idempotência, auditoria, compensação centralizadas | Payloads maiores → mais validação no BFF |
| Testes do Flutter não importam `bff/shared/` | Test builders mantêm 2 shapes (domain + payload) |
| BFF pode refatorar backends sem tocar cliente | BFF Web cresce — estrutura Intent + UseCase já comporta |

Para um app com dados sensíveis (saúde, CPF, violação de direitos) o trade-off é favorável.

---

## 11. Literatura

- Chris Richardson, *Microservices Patterns* (2018), Cap. 7 — API Composition
- Sam Newman, *Building Microservices* (2ª ed., 2021), Cap. 5 — BFF Pattern
- Phil Calçado, "The Back-end for Front-end Pattern" (2015)
- David Parnas, *"On the Criteria To Be Used in Decomposing Systems into Modules"* (CACM, 1972)
- Martin Fowler, "StranglerFigApplication" (bliki, 2004)
- Eric Evans, *Domain-Driven Design* (2003), Cap. 14 — Anti-Corruption Layer
- OWASP Top 10, A01:2021 — Broken Access Control / Information Disclosure

---

## 12. Como a skill `flutter-expert` opera sobre este contrato

Este documento é **referência oficial** da skill (registrar em `SKILL.md` §"Reference Sources").

### Papel de cada agente do Maestro Pipeline

| Agente | O que produz em um ticket Contract A |
|--------|--------------------------------------|
| `flutter-domain-modeler` | Domain model em `domain/models/` (puro, `with Equatable`, `copyWith`) **+** payload em `data/model/` (`fromJson`/`toJson`) |
| `flutter-mapper-engineer` | Mapper em `data/mappers/` — 1 por endpoint do Contract A, retorna `Result<T>`, switch exhaustivo |
| `flutter-service-builder` | Service em `data/services/` — stateless, 1 método por endpoint, usa Dio, sempre `/api/...` |
| `flutter-repository-architect` | Abstract repository + `HttpPatientRepository` (strategy name), service como campo **privado** |
| `flutter-usecase-orchestrator` | UseCase em `ui/<feature>/use_cases/` — orquestra repositories; recebe/retorna domain; `Result<T>` |
| `flutter-viewmodel-engineer` | ViewModel (`ChangeNotifier` + `Command0`/`Command1`); estado privado + getters; `notifyListeners()` |
| `flutter-view-implementer` | Pages + Organisms + Molecules + Atoms; 1 widget/arquivo; selectors/connectors; `ListenableBuilder` no nível mínimo |
| `flutter-test-writer` | Fakes em `testing/fakes/`; AAA; cobertura de `running/completed/error` |
| `flutter-code-reviewer` | Valida os 23 Non-Negotiables + a regra de import (proibir `bff/shared/` fora da fronteira) |
| `flutter-quality-checker` | `dart analyze`, `dart format`, `run_tests` via Dart MCP Server |

### Checklist do `flutter-code-reviewer` específico para Contract A
Além dos 23 Non-Negotiables da skill:
- [ ] Nenhum arquivo fora de `data/model,services,mappers/` importa `package:shared/shared.dart`.
- [ ] ViewModel não tem `import 'package:shared/...';` em nenhuma hipótese.
- [ ] UseCase recebe e retorna apenas domain models.
- [ ] Service chama exclusivamente rotas `/api/*` do Contract A.
- [ ] Repository converte domain ↔ payload via mapper antes de falar com Service.
- [ ] Nenhuma lógica de orquestração inter-request no cliente (ex: "se isso funcionar, chamar aquilo").

### Ordem de agentes para um ticket Contract A
Segue a ordem oficial da skill (§"Implementation Order"):
```
domain-modeler → service-builder + mapper-engineer (parallel)
              → repository-architect
              → usecase-orchestrator
              → viewmodel-engineer
              → view-implementer
              → code-reviewer → quality-checker
```

---

## 13. Apêndices

### A. Sequence Diagram — Registrar paciente com família

```
┌──────────┐    ┌─────────┐    ┌──────────────┐   ┌──────────────┐
│ Flutter  │    │ BFF Web │    │ PeopleContext│   │ Social Care  │
└────┬─────┘    └────┬────┘    └──────┬───────┘   └──────┬───────┘
     │ POST /patients │                │                  │
     │ (fat payload)  │                │                  │
     ├───────────────►│                │                  │
     │                │ register(main) │                  │
     │                ├───────────────►│                  │
     │                │◄─── personId ──│                  │
     │                │ register(mom)  │                  │
     │                ├───────────────►│                  │
     │                │◄─── personId ──│                  │
     │                │     registerPatient(resolved IDs) │
     │                ├──────────────────────────────────►│
     │                │◄─── patientId ────────────────────│
     │                │     addFamilyMember(mom)          │
     │                ├──────────────────────────────────►│
     │                │     updateIntake                  │
     │                ├──────────────────────────────────►│
     │                │     updateSocialIdentity          │
     │                ├──────────────────────────────────►│
     │ 201 {patientId}│                │                  │
     │◄───────────────┤                │                  │
```

### B. Exemplos de código alinhados à skill

#### B.1. Domain model (`domain/models/patient.dart`)
```dart
import 'package:core/core.dart';

class Patient with Equatable {
  const Patient({
    required this.id,
    required this.name,
    required this.cpf,
    required this.familyMembers,
  });

  final String id;
  final String name;
  final String cpf;
  final List<FamilyMember> familyMembers;

  Patient copyWith({
    String? id,
    String? name,
    String? cpf,
    List<FamilyMember>? familyMembers,
  }) =>
      Patient(
        id: id ?? this.id,
        name: name ?? this.name,
        cpf: cpf ?? this.cpf,
        familyMembers: familyMembers ?? this.familyMembers,
      );

  @override
  List<Object?> get props => [id, name, cpf, familyMembers];
}
```

#### B.2. API model / payload (`data/model/patient_register_payload.dart`)
```dart
class PatientRegisterPayload {
  const PatientRegisterPayload({
    required this.personalData,
    required this.civilDocuments,
    required this.address,
    required this.familyMembers,
    required this.initialDiagnoses,
  });

  final Map<String, dynamic> personalData;
  final Map<String, dynamic> civilDocuments;
  final Map<String, dynamic> address;
  final List<Map<String, dynamic>> familyMembers;
  final List<Map<String, dynamic>> initialDiagnoses;

  Map<String, dynamic> toJson() => {
        'personalData': personalData,
        'civilDocuments': civilDocuments,
        'address': address,
        'familyMembers': familyMembers,
        'initialDiagnoses': initialDiagnoses,
      };
}
```

#### B.3. Mapper (`data/mappers/patient_register_mapper.dart`)
```dart
import 'package:core/core.dart';

class PatientRegisterMapper {
  static Result<PatientRegisterPayload> toPayload(Patient patient) {
    // transformações + validações; switch exhaustivo se houver sub-results
    return Ok(PatientRegisterPayload(
      personalData: {...},
      civilDocuments: {...},
      address: {...},
      familyMembers: patient.familyMembers.map((m) => {...}).toList(),
      initialDiagnoses: const [],
    ));
  }
}
```

#### B.4. Service (`data/services/patient_service.dart`)
```dart
import 'package:core/core.dart';
import 'package:dio/dio.dart';

class PatientService {
  PatientService({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<Result<String>> register(PatientRegisterPayload payload) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/patients',
        data: payload.toJson(),
      );
      final id = res.data!['id'] as String;
      return Ok(id);
    } on Exception catch (e) {
      return Error(e);
    }
  }
}
```

#### B.5. Repository (`data/repositories/patient_repository.dart`)
```dart
import 'package:core/core.dart';

abstract class PatientRepository {
  Future<Result<String>> registerPatient(Patient patient);
}

class HttpPatientRepository implements PatientRepository {
  HttpPatientRepository({required PatientService service}) : _service = service;
  final PatientService _service; // PRIVADO — View não acessa Service direto

  @override
  Future<Result<String>> registerPatient(Patient patient) async {
    final payloadResult = PatientRegisterMapper.toPayload(patient);
    switch (payloadResult) {
      case Ok<PatientRegisterPayload>():
        return _service.register(payloadResult.value);
      case Error<PatientRegisterPayload>():
        return Error(payloadResult.error);
    }
  }
}
```

#### B.6. UseCase (`ui/patient_registration/use_cases/register_patient_use_case.dart`)
```dart
import 'package:core/core.dart';

class RegisterPatientUseCase {
  RegisterPatientUseCase({required PatientRepository repository})
      : _repository = repository;
  final PatientRepository _repository; // PRIVADO

  Future<Result<String>> execute(Patient patient) =>
      _repository.registerPatient(patient);
}
```

#### B.7. ViewModel (`ui/patient_registration/view_models/patient_registration_view_model.dart`)
```dart
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

class PatientRegistrationViewModel extends ChangeNotifier {
  PatientRegistrationViewModel({required RegisterPatientUseCase useCase})
      : _useCase = useCase {
    register = Command1(_register);
  }

  final RegisterPatientUseCase _useCase; // PRIVADO
  late final Command1<String, Patient> register;

  String? _lastPatientId;
  String? get lastPatientId => _lastPatientId;

  Future<Result<String>> _register(Patient patient) async {
    final result = await _useCase.execute(patient);
    switch (result) {
      case Ok<String>():
        _lastPatientId = result.value;
      case Error<String>():
        break; // Command guarda error
    }
    notifyListeners();
    return result;
  }
}
```

#### B.8. View — Page (`ui/patient_registration/widgets/patient_registration_page.dart`)
```dart
class PatientRegistrationPage extends ConsumerStatefulWidget {
  const PatientRegistrationPage({super.key});

  @override
  ConsumerState<PatientRegistrationPage> createState() =>
      _PatientRegistrationPageState();
}

class _PatientRegistrationPageState
    extends ConsumerState<PatientRegistrationPage> {
  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(patientRegistrationViewModelProvider);
    return Scaffold(
      body: ListenableBuilder(
        listenable: vm.register,
        builder: (context, child) {
          if (vm.register.running) return const LoadingAtom();
          if (vm.register.error) {
            return ErrorOrganism(onRetry: () => vm.register.execute(_buildPatientFromForm()));
          }
          return child!;
        },
        child: PatientRegistrationForm(
          onSubmit: vm.register.execute, // Connector — sem ViewModel em Atoms
        ),
      ),
    );
  }

  Patient _buildPatientFromForm() => /* ... */;
}
```

#### B.9. Provider (stub) (`ui/patient_registration/di/patient_registration_providers.dart`)
```dart
final patientRegistrationViewModelProvider =
    Provider.autoDispose<PatientRegistrationViewModel>((ref) {
  throw UnimplementedError(
    'patientRegistrationViewModelProvider must be overridden in ProviderScope',
  );
});
```

#### B.10. Override (`apps/acdg_system/lib/logic/di/...`)
```dart
final patientRegistrationViewModelOverride =
    patientRegistrationViewModelProvider.overrideWith((ref) {
  final vm = PatientRegistrationViewModel(
    useCase: ref.watch(registerPatientUseCaseProvider),
  );
  ref.onDispose(vm.dispose);
  return vm;
});
```

Nada disso importa `package:shared/shared.dart`. Essa é a linha que move — e resolve 80 % da dor arquitetural.
