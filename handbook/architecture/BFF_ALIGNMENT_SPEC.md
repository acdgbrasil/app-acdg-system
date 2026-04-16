# BFF Alignment Spec — social-care Backend vs Frontend BFF

> **Status:** Draft (2026-04-16)
> **Autor:** Gabriel Aderaldo + Claude Code
> **Escopo:** `bff/shared/`, `bff/social_care_web/`, `bff/social_care_desktop/`, `packages/social_care/`
> **Referencia:** Backend Swift/Vapor `social-care/` v0.12.0 (35 endpoints, 20 use cases)

---

## 1. Diagnostico: O Que Esta Errado

### 1.1 Resumo Executivo

O BFF (`bff/shared/lib/src/contract/social_care_contract.dart`) divergiu significativamente do backend `social-care`. O contrato atual tem **23 metodos** para um backend com **35 endpoints** e **26 use cases**. Alem de endpoints faltantes, ha problemas estruturais no design do contrato que forcam anti-patterns no frontend.

### 1.2 Mapa de Divergencias

```
LEGENDA:
  [OK]     = Presente e alinhado
  [MISS]   = Ausente no BFF (endpoint existe no backend)
  [BROKEN] = Presente mas com contrato errado
  [DRIFT]  = Parametros/retorno divergentes do backend
```

#### Registry

| Backend Endpoint | BFF Contract | Status |
|-----------------|--------------|--------|
| `GET /patients` (paginado, filtros) | `fetchPatients()` sem params | **[DRIFT]** |
| `POST /patients` | `registerPatient(Patient)` | **[BROKEN]** |
| `GET /patients/:id` | `fetchPatient(PatientId)` | [OK] |
| `GET /patients/by-person/:personId` | `fetchPatientByPersonId(PersonId)` | [OK] |
| `POST /patients/:id/family-members` | `addFamilyMember(...)` | [OK] |
| `DELETE /patients/:id/family-members/:mid` | `removeFamilyMember(...)` | [OK] |
| `PUT /patients/:id/primary-caregiver` | `assignPrimaryCaregiver(...)` | [OK] |
| `PUT /patients/:id/social-identity` | `updateSocialIdentity(...)` | [OK] |
| `GET /patients/:id/audit-trail` | `getAuditTrail(...)` | **[DRIFT]** |

#### Patient Lifecycle

| Backend Endpoint | BFF Contract | Status |
|-----------------|--------------|--------|
| `POST /patients/:id/discharge` | _(nao existe)_ | **[MISS]** |
| `POST /patients/:id/readmit` | _(nao existe)_ | **[MISS]** |
| `POST /patients/:id/admit` | _(nao existe)_ | **[MISS]** |
| `POST /patients/:id/withdraw` | _(nao existe)_ | **[MISS]** |

#### Assessment

| Backend Endpoint | BFF Contract | Status |
|-----------------|--------------|--------|
| `PUT .../housing-condition` | `updateHousingCondition(...)` | [OK] |
| `PUT .../socioeconomic-situation` | `updateSocioEconomicSituation(...)` | [OK] |
| `PUT .../work-and-income` | `updateWorkAndIncome(...)` | [OK] |
| `PUT .../educational-status` | `updateEducationalStatus(...)` | [OK] |
| `PUT .../health-status` | `updateHealthStatus(...)` | [OK] |
| `PUT .../community-support-network` | `updateCommunitySupportNetwork(...)` | [OK] |
| `PUT .../social-health-summary` | `updateSocialHealthSummary(...)` | [OK] |

#### Care

| Backend Endpoint | BFF Contract | Status |
|-----------------|--------------|--------|
| `POST .../appointments` | `registerAppointment(...)` | [OK] |
| `PUT .../intake-info` | `updateIntakeInfo(...)` | [OK] |

#### Protection

| Backend Endpoint | BFF Contract | Status |
|-----------------|--------------|--------|
| `PUT .../placement-history` | `updatePlacementHistory(...)` | [OK] |
| `POST .../violation-reports` | `reportViolation(...)` | [OK] |
| `POST .../referrals` | `createReferral(...)` | [OK] |

#### Lookup (Dominios)

| Backend Endpoint | BFF Contract | Status |
|-----------------|--------------|--------|
| `GET /dominios/:tableName` | `getLookupTable(String)` | [OK] |
| `POST /dominios/:tableName` (admin) | _(nao existe)_ | **[MISS]** |
| `PUT /dominios/:tableName/:id` (admin) | _(nao existe)_ | **[MISS]** |
| `PATCH /dominios/:tableName/:id/toggle` (admin) | _(nao existe)_ | **[MISS]** |
| `GET /dominios/requests` | _(nao existe)_ | **[MISS]** |
| `POST /dominios/requests` | _(nao existe)_ | **[MISS]** |
| `PUT /dominios/requests/:id/approve` (admin) | _(nao existe)_ | **[MISS]** |
| `PUT /dominios/requests/:id/reject` (admin) | _(nao existe)_ | **[MISS]** |

---

## 2. Anti-Patterns Identificados

### AP-01: Contrato Aceita Agregado Inteiro para Registro

```dart
// ATUAL — ERRADO
Future<Result<PatientId>> registerPatient(Patient patient);
```

**Problema:** O frontend e OBRIGADO a montar um `Patient` completo (com todos os VOs aninhados, familyMembers, diagnoses, prRelationshipId) para registrar. Isso:

1. **Acopla o frontend a invariantes de dominio do backend** — o frontend precisa saber que Patient exige exatamente 1 PR member, pelo menos 1 diagnostico, etc.
2. **Forca dupla validacao** — o frontend valida para montar o Patient, o backend valida de novo. Divergencias entre as validacoes causam bugs silenciosos.
3. **Impede evolucao independente** — se o backend adicionar um campo obrigatorio no Patient, o frontend quebra no `Patient.create()` antes mesmo de fazer a request.
4. **O RegistryHandler web faz orquestracao pesada** — registra pessoa no people-context, depois registra patient, depois adiciona membros extras em loop, depois atualiza social identity. Tudo em um unico handler de ~100 linhas.

**Correto:** O contrato deveria aceitar um **DTO de comando** (`RegisterPatientRequest`) que espelha exatamente o que o backend espera — campos primitivos/strings, sem validacao de dominio no BFF.

### AP-02: fetchPatients() Sem Paginacao

```dart
// ATUAL — ERRADO
Future<Result<List<PatientOverview>>> fetchPatients();
```

**Problema:** O backend retorna `PaginatedResponse` com `cursor`, `hasMore`, `totalCount`, `pageSize`. O BFF ignora tudo e pede `?limit=100` hardcoded. Com mais de 100 pacientes, o frontend simplesmente nao vê os demais.

**Correto:**
```dart
Future<Result<PaginatedList<PatientOverview>>> fetchPatients({
  String? search,
  String? status,
  String? cursor,
  int limit = 20,
});
```

### AP-03: Zero Suporte a Lifecycle

O backend tem 4 endpoints de lifecycle (`discharge`, `readmit`, `admit`, `withdraw`) que controlam o status do paciente. O BFF nao tem nenhum. Consequencias:

1. **Impossivel dar alta a um paciente** pelo frontend
2. **Impossivel gerenciar fila de espera** (admit/withdraw)
3. O campo `status` existe no model (`Patient.status`) mas e somente leitura — nao ha como muta-lo
4. O `PatientOverview` nem retorna `status` no `fromJson` corretamente para filtros

### AP-04: Lookup Governance Inexistente

O backend tem um workflow completo de governanca de dominios:
- Workers podem SOLICITAR novos valores (POST /dominios/requests)
- Admins podem APROVAR ou REJEITAR
- Admins podem CRIAR, EDITAR e DESATIVAR valores

O BFF so tem `getLookupTable()` (leitura). Consequencias:

1. **Admins nao conseguem gerenciar dominios** pelo frontend
2. **Workers nao conseguem solicitar novos valores** — precisam pedir fora do sistema
3. Todo o fluxo de governanca que o backend suporta e inacessivel

### AP-05: Audit Trail Sem Paginacao

```dart
// ATUAL
Future<Result<List<AuditEvent>>> getAuditTrail(PatientId patientId, {String? eventType});
```

**Problema:** O backend aceita `limit` (1-200, default 50) e `offset`. O BFF nao passa nenhum. Para pacientes com historico longo, isso significa carregar TODOS os eventos de uma vez.

### AP-06: PatientRemote como Map<String, dynamic>

O `PatientRemote` DTO usa `Map<String, dynamic>?` para quase todos os campos complexos:

```dart
final Map<String, dynamic>? personalData;
final Map<String, dynamic>? civilDocuments;
final Map<String, dynamic>? address;
final List<Map<String, dynamic>> familyMembers;
```

**Problema:** Zero type safety. O `PatientTranslator.toDomain()` faz parsing manual de maps com chaves hardcoded como strings. Qualquer rename de campo no backend quebra silenciosamente.

**Correto:** Cada sub-objeto deveria ter seu proprio `@JsonSerializable()` DTO tipado.

### AP-07: Erro Backend Perdido na Traducao

O `SocialCareApiClient` extrai erros assim:

```dart
String code = errorMap?['code'];
String message = errorMap?['message'] ?? response.data['message'];
return "CODE: message";
```

Depois o `HttpSocialCareClient` tenta re-parsear esse string concatenado. O codigo estruturado do backend (`PAT-001`, `RGD-005`, severity, category) e achatado em uma string — perdendo informacao que o frontend precisa para mostrar mensagens contextuais.

---

## 3. Spec de Realinhamento

### 3.1 Principios

1. **O contrato BFF espelha os endpoints do backend** — 1 metodo por endpoint, sem agrupar ou omitir
2. **Parametros de entrada sao DTOs de comando** (records/classes com campos primitivos), NAO agregados de dominio
3. **Retornos sao DTOs de resposta tipados** com `@JsonSerializable()`, NAO `Map<String, dynamic>`
4. **Paginacao e first-class** — `PaginatedList<T>` com cursor, hasMore, totalCount
5. **Erros sao estruturados** — `BackendError` com `code`, `message`, `httpStatus` separados
6. **Cada bounded context tem seu proprio sub-contrato** para evitar um contrato monolitico

### 3.2 Novo Contrato — Estrutura por Bounded Context

```
bff/shared/lib/src/contract/
  social_care_contract.dart          # Fachada que compoe os sub-contratos
  registry_contract.dart             # Patient CRUD + Family + Lifecycle
  assessment_contract.dart           # 7 assessments
  care_contract.dart                 # Appointments + Intake
  protection_contract.dart           # Referrals + Violations + Placement
  lookup_contract.dart               # Lookup read + governance (admin)
  health_contract.dart               # Health checks
```

### 3.3 Registry Contract (Novo)

```dart
abstract interface class RegistryContract {
  // === Patient CRUD ===

  /// Lista pacientes com paginacao e filtros.
  /// Espelha: GET /api/v1/patients?search=&status=&cursor=&limit=
  Future<Result<PaginatedList<PatientSummaryDto>>> listPatients({
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  });

  /// Registra paciente. Aceita DTO plano, NAO agregado.
  /// Espelha: POST /api/v1/patients
  Future<Result<String>> registerPatient(RegisterPatientRequest request);

  /// Busca paciente por ID.
  /// Espelha: GET /api/v1/patients/:id
  Future<Result<PatientDetailDto>> getPatient(String patientId);

  /// Busca paciente por PersonId.
  /// Espelha: GET /api/v1/patients/by-person/:personId
  Future<Result<PatientDetailDto>> getPatientByPersonId(String personId);

  // === Family ===

  /// Espelha: POST /api/v1/patients/:id/family-members
  Future<Result<void>> addFamilyMember(
    String patientId,
    AddFamilyMemberRequest request,
  );

  /// Espelha: DELETE /api/v1/patients/:id/family-members/:memberId
  Future<Result<void>> removeFamilyMember(String patientId, String memberId);

  /// Espelha: PUT /api/v1/patients/:id/primary-caregiver
  Future<Result<void>> assignPrimaryCaregiver(
    String patientId,
    String memberPersonId,
  );

  /// Espelha: PUT /api/v1/patients/:id/social-identity
  Future<Result<void>> updateSocialIdentity(
    String patientId,
    UpdateSocialIdentityRequest request,
  );

  // === Lifecycle ===

  /// Espelha: POST /api/v1/patients/:id/discharge
  Future<Result<void>> dischargePatient(
    String patientId,
    DischargePatientRequest request,
  );

  /// Espelha: POST /api/v1/patients/:id/readmit
  Future<Result<void>> readmitPatient(
    String patientId, {
    String? notes,
  });

  /// Espelha: POST /api/v1/patients/:id/admit
  Future<Result<void>> admitPatient(String patientId);

  /// Espelha: POST /api/v1/patients/:id/withdraw
  Future<Result<void>> withdrawPatient(
    String patientId,
    WithdrawPatientRequest request,
  );

  // === Audit ===

  /// Espelha: GET /api/v1/patients/:id/audit-trail?eventType=&limit=&offset=
  Future<Result<List<AuditEntryDto>>> getAuditTrail(
    String patientId, {
    String? eventType,
    int limit = 50,
    int offset = 0,
  });
}
```

### 3.4 Assessment Contract (Novo)

```dart
abstract interface class AssessmentContract {
  /// PUT /api/v1/patients/:id/housing-condition
  Future<Result<void>> updateHousingCondition(
    String patientId,
    UpdateHousingConditionRequest request,
  );

  /// PUT /api/v1/patients/:id/socioeconomic-situation
  Future<Result<void>> updateSocioEconomicSituation(
    String patientId,
    UpdateSocioEconomicRequest request,
  );

  /// PUT /api/v1/patients/:id/work-and-income
  Future<Result<void>> updateWorkAndIncome(
    String patientId,
    UpdateWorkAndIncomeRequest request,
  );

  /// PUT /api/v1/patients/:id/educational-status
  Future<Result<void>> updateEducationalStatus(
    String patientId,
    UpdateEducationalStatusRequest request,
  );

  /// PUT /api/v1/patients/:id/health-status
  Future<Result<void>> updateHealthStatus(
    String patientId,
    UpdateHealthStatusRequest request,
  );

  /// PUT /api/v1/patients/:id/community-support-network
  Future<Result<void>> updateCommunitySupportNetwork(
    String patientId,
    UpdateCommunitySupportNetworkRequest request,
  );

  /// PUT /api/v1/patients/:id/social-health-summary
  Future<Result<void>> updateSocialHealthSummary(
    String patientId,
    UpdateSocialHealthSummaryRequest request,
  );
}
```

### 3.5 Care Contract (Novo)

```dart
abstract interface class CareContract {
  /// POST /api/v1/patients/:id/appointments
  Future<Result<String>> registerAppointment(
    String patientId,
    RegisterAppointmentRequest request,
  );

  /// PUT /api/v1/patients/:id/intake-info
  Future<Result<void>> updateIntakeInfo(
    String patientId,
    UpdateIntakeInfoRequest request,
  );
}
```

### 3.6 Protection Contract (Novo)

```dart
abstract interface class ProtectionContract {
  /// PUT /api/v1/patients/:id/placement-history
  Future<Result<void>> updatePlacementHistory(
    String patientId,
    UpdatePlacementHistoryRequest request,
  );

  /// POST /api/v1/patients/:id/violation-reports
  Future<Result<String>> reportViolation(
    String patientId,
    ReportViolationRequest request,
  );

  /// POST /api/v1/patients/:id/referrals
  Future<Result<String>> createReferral(
    String patientId,
    CreateReferralRequest request,
  );
}
```

### 3.7 Lookup Contract (Novo)

```dart
abstract interface class LookupContract {
  // === Read (worker, owner, admin) ===

  /// GET /api/v1/dominios/:tableName
  Future<Result<List<LookupItemDto>>> getLookupTable(String tableName);

  // === Governance Requests (worker, admin) ===

  /// GET /api/v1/dominios/requests?status=
  Future<Result<List<LookupRequestDto>>> listLookupRequests({String? status});

  /// POST /api/v1/dominios/requests
  Future<Result<String>> createLookupRequest(CreateLookupRequestDto request);

  // === Admin CRUD ===

  /// POST /api/v1/dominios/:tableName
  Future<Result<String>> createLookupItem(
    String tableName,
    CreateLookupItemRequest request,
  );

  /// PUT /api/v1/dominios/:tableName/:itemId
  Future<Result<void>> updateLookupItem(
    String tableName,
    String itemId,
    UpdateLookupItemRequest request,
  );

  /// PATCH /api/v1/dominios/:tableName/:itemId/toggle
  Future<Result<void>> toggleLookupItem(String tableName, String itemId);

  /// PUT /api/v1/dominios/requests/:requestId/approve
  Future<Result<void>> approveLookupRequest(String requestId);

  /// PUT /api/v1/dominios/requests/:requestId/reject
  Future<Result<void>> rejectLookupRequest(
    String requestId,
    String reviewNote,
  );
}
```

### 3.8 Fachada Composta

```dart
/// Fachada que compoe todos os sub-contratos.
/// Cada implementacao (Web, Desktop) implementa esta interface.
abstract interface class SocialCareContract
    implements
        HealthContract,
        RegistryContract,
        AssessmentContract,
        CareContract,
        ProtectionContract,
        LookupContract {}
```

---

## 4. DTOs de Request (Espelham o Backend)

### 4.1 Principio

Cada Request DTO espelha EXATAMENTE o `RequestDTO` do backend Swift. Campos sao primitivos (`String`, `int`, `double`, `bool`, `DateTime`, `List`, `Map`). Nenhum VO de dominio (CPF, NIS, PatientId) aparece aqui — validacao e responsabilidade do backend.

### 4.2 Estrutura de Pastas

```
bff/shared/lib/src/infrastructure/dtos/
  requests/
    registry/
      register_patient_request.dart
      add_family_member_request.dart
      update_social_identity_request.dart
      discharge_patient_request.dart
      readmit_patient_request.dart
      withdraw_patient_request.dart
    assessment/
      update_housing_condition_request.dart
      update_socio_economic_request.dart
      update_work_and_income_request.dart
      update_educational_status_request.dart
      update_health_status_request.dart
      update_community_support_request.dart
      update_social_health_summary_request.dart
    care/
      register_appointment_request.dart
      update_intake_info_request.dart
    protection/
      update_placement_history_request.dart
      report_violation_request.dart
      create_referral_request.dart
    lookup/
      create_lookup_item_request.dart
      update_lookup_item_request.dart
      create_lookup_request_dto.dart
  responses/
    patient_summary_dto.dart
    patient_detail_dto.dart
    personal_data_dto.dart
    civil_documents_dto.dart
    address_dto.dart
    family_member_dto.dart
    diagnosis_dto.dart
    housing_condition_dto.dart
    socio_economic_dto.dart
    work_and_income_dto.dart
    educational_status_dto.dart
    health_status_dto.dart
    community_support_dto.dart
    social_health_summary_dto.dart
    placement_history_dto.dart
    appointment_dto.dart
    referral_dto.dart
    violation_report_dto.dart
    ingress_info_dto.dart
    computed_analytics_dto.dart
    lookup_item_dto.dart
    lookup_request_dto.dart
    audit_entry_dto.dart
    paginated_list.dart
    backend_error.dart
```

### 4.3 Exemplo: RegisterPatientRequest

```dart
/// Espelha RegisterPatientRequest do backend Swift.
/// Campos sao primitivos — zero validacao de dominio aqui.
@JsonSerializable()
class RegisterPatientRequest {
  const RegisterPatientRequest({
    required this.personId,
    required this.initialDiagnoses,
    required this.prRelationshipId,
    this.personalData,
    this.civilDocuments,
    this.address,
    this.socialIdentity,
  });

  factory RegisterPatientRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterPatientRequestFromJson(json);

  final String personId;
  final List<DiagnosisDraft> initialDiagnoses;
  final String prRelationshipId;
  final PersonalDataDraft? personalData;
  final CivilDocumentsDraft? civilDocuments;
  final AddressDraft? address;
  final SocialIdentityDraft? socialIdentity;

  Map<String, dynamic> toJson() => _$RegisterPatientRequestToJson(this);
}

@JsonSerializable()
class DiagnosisDraft {
  const DiagnosisDraft({
    required this.icdCode,
    required this.date,
    required this.description,
  });

  factory DiagnosisDraft.fromJson(Map<String, dynamic> json) =>
      _$DiagnosisDraftFromJson(json);

  final String icdCode;
  final DateTime date;
  final String description;

  Map<String, dynamic> toJson() => _$DiagnosisDraftToJson(this);
}

@JsonSerializable()
class PersonalDataDraft {
  const PersonalDataDraft({
    required this.firstName,
    required this.lastName,
    required this.motherName,
    required this.nationality,
    required this.sex,
    required this.birthDate,
    this.socialName,
    this.phone,
  });

  factory PersonalDataDraft.fromJson(Map<String, dynamic> json) =>
      _$PersonalDataDraftFromJson(json);

  final String firstName;
  final String lastName;
  final String motherName;
  final String nationality;
  final String sex;
  final DateTime birthDate;
  final String? socialName;
  final String? phone;

  Map<String, dynamic> toJson() => _$PersonalDataDraftToJson(this);
}

// CivilDocumentsDraft, AddressDraft, SocialIdentityDraft seguem o mesmo padrao.
```

### 4.4 Exemplo: PatientDetailDto (Resposta Tipada)

```dart
/// Espelha PatientResponse do backend.
/// Substitui PatientRemote com seus Map<String, dynamic>.
@JsonSerializable()
class PatientDetailDto {
  const PatientDetailDto({
    required this.patientId,
    required this.personId,
    required this.version,
    required this.status,
    this.dischargeInfo,
    this.withdrawInfo,
    this.personalData,
    this.civilDocuments,
    this.address,
    this.socialIdentity,
    this.familyMembers = const [],
    this.diagnoses = const [],
    this.housingCondition,
    this.socioeconomicSituation,
    this.workAndIncome,
    this.educationalStatus,
    this.healthStatus,
    this.communitySupportNetwork,
    this.socialHealthSummary,
    this.placementHistory,
    this.intakeInfo,
    this.appointments = const [],
    this.referrals = const [],
    this.violationReports = const [],
    this.computedAnalytics,
  });

  factory PatientDetailDto.fromJson(Map<String, dynamic> json) =>
      _$PatientDetailDtoFromJson(json);

  final String patientId;
  final String personId;
  final int version;
  final String status;
  final DischargeInfoDto? dischargeInfo;
  final WithdrawInfoDto? withdrawInfo;
  final PersonalDataDto? personalData;
  final CivilDocumentsDto? civilDocuments;
  final AddressDto? address;
  final SocialIdentityDto? socialIdentity;
  final List<FamilyMemberDto> familyMembers;
  final List<DiagnosisDto> diagnoses;
  final HousingConditionDto? housingCondition;
  final SocioEconomicDto? socioeconomicSituation;
  final WorkAndIncomeDto? workAndIncome;
  final EducationalStatusDto? educationalStatus;
  final HealthStatusDto? healthStatus;
  final CommunitySupportDto? communitySupportNetwork;
  final SocialHealthSummaryDto? socialHealthSummary;
  final PlacementHistoryDto? placementHistory;
  final IngressInfoDto? intakeInfo;
  final List<AppointmentDto> appointments;
  final List<ReferralDto> referrals;
  final List<ViolationReportDto> violationReports;
  final ComputedAnalyticsDto? computedAnalytics;

  Map<String, dynamic> toJson() => _$PatientDetailDtoToJson(this);
}
```

### 4.5 Exemplo: PaginatedList

```dart
/// Container generico para respostas paginadas.
/// Espelha PaginatedResponse do backend.
class PaginatedList<T> {
  const PaginatedList({
    required this.items,
    required this.totalCount,
    required this.hasMore,
    required this.pageSize,
    this.nextCursor,
  });

  final List<T> items;
  final int totalCount;
  final bool hasMore;
  final int pageSize;
  final String? nextCursor;
}
```

### 4.6 Exemplo: BackendError Estruturado

```dart
/// Erro estruturado do backend. Preserva code + message separados.
class BackendError {
  const BackendError({
    required this.httpStatus,
    required this.code,
    required this.message,
    this.details,
  });

  /// Codigo estruturado do backend (ex: "PAT-001", "RGD-005").
  final String code;

  /// Mensagem legivel do backend.
  final String message;

  /// HTTP status code da resposta.
  final int httpStatus;

  /// Detalhes adicionais (campos invalidos, contexto).
  final Map<String, dynamic>? details;

  @override
  String toString() => '[$code] $message (HTTP $httpStatus)';
}
```

---

## 5. DTOs de Response — Mapeamento Completo Backend -> BFF

### 5.1 Tabela de Correspondencia

| Backend Swift DTO | BFF Dart DTO (Novo) | Campos |
|------------------|--------------------|----|
| `PatientSummaryResponse` | `PatientSummaryDto` | patientId, personId, firstName?, lastName?, fullName?, primaryDiagnosis?, memberCount, **status** |
| `PatientResponse` | `PatientDetailDto` | (ver 4.4 acima — todos os campos tipados) |
| `PersonalDataResponse` | `PersonalDataDto` | firstName, lastName, motherName, nationality, sex, socialName?, phone?, birthDate |
| `CivilDocumentsResponse` | `CivilDocumentsDto` | cpf?, nis?, rgDocument?: RgDocumentDto, cns?: CnsDto |
| `AddressResponse` | `AddressDto` | cep?, isShelter, isHomeless, residenceLocation, street?, neighborhood?, number?, complement?, state, city |
| `FamilyMemberResponse` | `FamilyMemberDto` | personId, relationshipId, isPrimaryCaregiver, residesWithPatient, hasDisability, requiredDocuments, birthDate |
| `DiagnosisResponse` | `DiagnosisDto` | icdCode, description, date |
| `HousingConditionResponse` | `HousingConditionDto` | type, wallMaterial, numberOfRooms, numberOfBedrooms, numberOfBathrooms, waterSupply, hasPipedWater, electricityAccess, sewageDisposal, wasteCollection, accessibilityLevel, isInGeographicRiskArea, hasDifficultAccess, isInSocialConflictArea, hasDiagnosticObservations |
| `SocioEconomicResponse` | `SocioEconomicDto` | totalFamilyIncome, incomePerCapita, receivesSocialBenefit, hasUnemployed, mainSourceOfIncome, socialBenefits: List |
| `WorkAndIncomeResponse` | `WorkAndIncomeDto` | hasRetiredMembers, individualIncomes: List, socialBenefits: List |
| `EducationalStatusResponse` | `EducationalStatusDto` | memberProfiles: List, programOccurrences: List |
| `HealthStatusResponse` | `HealthStatusDto` | foodInsecurity, deficiencies: List, gestatingMembers: List, constantCareNeeds: List |
| `CommunitySupportNetworkResponse` | `CommunitySupportDto` | hasRelativeSupport, hasNeighborSupport, familyConflicts, patientParticipatesInGroups, familyParticipatesInGroups, patientHasAccessToLeisure, facesDiscrimination |
| `SocialHealthSummaryResponse` | `SocialHealthSummaryDto` | requiresConstantCare, hasMobilityImpairment, hasRelevantDrugTherapy, functionalDependencies: List |
| `PlacementHistoryResponse` | `PlacementHistoryDto` | individualPlacements: List, homeLossReport?, thirdPartyGuardReport?, adultInPrison, adolescentInInternment |
| `AppointmentResponse` | `AppointmentDto` | id, date, professionalId, type, summary, actionPlan |
| `ReferralResponse` | `ReferralDto` | id, date, professionalId, referredPersonId, destinationService, reason, status |
| `ViolationReportResponse` | `ViolationReportDto` | id, reportDate, incidentDate?, victimId, violationType, descriptionOfFact, actionsTaken |
| `IngressInfoResponse` | `IngressInfoDto` | ingressTypeId, originName?, originContact?, serviceReason, linkedSocialPrograms: List |
| `ComputedAnalyticsResponse` | `ComputedAnalyticsDto` | housing?: HousingAnalyticsDto, financial?: FinancialIndicatorsDto, ageProfile: AgeProfileDto, educationalVulnerabilities?: EducationalVulnerabilityDto |
| `LookupItemResponse` | `LookupItemDto` | id, codigo, descricao |
| `LookupRequestResponse` | `LookupRequestDto` | id, tableName, codigo, descricao, justificativa, status, requestedBy, requestedAt, reviewedBy?, reviewedAt?, reviewNote? |
| `AuditTrailEntryResponse` | `AuditEntryDto` | id, aggregateId, eventType, actorId?, payload, occurredAt, recordedAt |

---

## 6. Impacto no Data Flow

### 6.1 Antes (Anti-Pattern)

```
View → ViewModel.command → UseCase → Mapper (monta Patient agregado inteiro)
  → Repository → Service → BFF Contract (aceita Patient)
  → PatientTranslator.toJson(patient) (serializa agregado inteiro)
  → Dio POST /patients (JSON monstruoso)
  → Backend valida tudo de novo e rejeita com erro generico
  → BFF recebe string "CODE: message" e tenta re-parsear
  → UseCase traduz AppError → SocialCareError
  → ViewModel mostra mensagem generica
```

### 6.2 Depois (Correto)

```
View → ViewModel.command → UseCase (monta RegisterPatientRequest com primitivos)
  → Repository → BFF Contract.registerPatient(request)
  → request.toJson() (serializacao trivial, gerada por json_serializable)
  → Dio POST /patients (JSON limpo, espelha backend)
  → Backend valida e retorna Result ou BackendError estruturado
  → BFF preserva BackendError(code, message, httpStatus)
  → UseCase mapeia BackendError.code → SocialCareError tipado
  → ViewModel mostra mensagem especifica baseada no code
```

### 6.3 Onde Fica a Validacao

| Camada | O Que Valida | Como |
|--------|-------------|------|
| **View** | Campos obrigatorios preenchidos, formato visual (mascara CPF) | Form validators do Flutter |
| **ViewModel** | Nada — delega para UseCase | - |
| **UseCase** | Monta o Request DTO, valida tipos basicos (String nao vazia, DateTime valido) | Funcoes puras |
| **BFF** | NADA — proxy transparente | Passa o JSON direto |
| **Backend** | TUDO — VOs, invariantes, cross-validation, lookup metadata | Smart constructors, CrossValidator, MetadataValidator |

**Regra:** A unica validacao real e a do backend. O frontend faz validacao de UX (campos preenchidos) para evitar round-trips desnecessarios, mas NAO replica regras de negocio.

---

## 7. O Que Acontece com os Domain Models do BFF Shared

### 7.1 Decisao

Os domain models em `bff/shared/lib/src/domain/` (Patient, FamilyMember, HousingCondition, etc.) **continuam existindo** mas com papel alterado:

| Antes | Depois |
|-------|--------|
| Usados como parametro de entrada no contrato | Usados SOMENTE para representar dados lidos do backend |
| Validacao no `create()` antes de enviar | Validacao removida — `reconstitute()` e o unico factory |
| Traduzidos de/para JSON no PatientTranslator | Substituidos por DTOs tipados com `@JsonSerializable` |

### 7.2 Nova Responsabilidade

- **Domain models** = representacao rica para o frontend manipular dados LIDOS
- **Request DTOs** = estrutura plana para ENVIAR dados ao backend
- **Response DTOs** = estrutura tipada para RECEBER dados do backend

Fluxo:
```
Backend JSON → Response DTO (fromJson) → Domain Model (reconstitute) → UI
UI → Request DTO (campos primitivos) → toJson → Backend
```

---

## 8. Plano de Implementacao (Fases)

### Fase 1: Foundation (DTOs + Contrato)

**Escopo:** `bff/shared/`

1. Criar todos os Response DTOs tipados com `@JsonSerializable()` (substituir `Map<String, dynamic>`)
2. Criar todos os Request DTOs espelhando o backend
3. Criar `PaginatedList<T>` e `BackendError`
4. Reescrever o contrato com sub-contratos por bounded context
5. Manter contrato antigo como `@Deprecated` para migracao gradual

**Entregavel:** Contrato novo compilando, testes de serialization round-trip para cada DTO.

### Fase 2: API Client (Web + Desktop)

**Escopo:** `bff/social_care_web/`, `bff/social_care_desktop/`

1. Implementar `SocialCareApiClient` novo usando DTOs tipados
2. Adicionar endpoints faltantes (lifecycle, lookup governance, paginacao)
3. Preservar `BackendError` estruturado (sem concatenar code+message)
4. Atualizar handlers web para delegar corretamente

**Entregavel:** Todos os 35 endpoints do backend acessiveis via BFF.

### Fase 3: Frontend Migration

**Escopo:** `packages/social_care/`

1. Atualizar `PatientRepository` e `LookupRepository` para usar novo contrato
2. Simplificar UseCases — remover montagem de agregados, usar Request DTOs
3. Remover `PatientTranslator` e mappers manuais (substituidos por json_serializable)
4. Adicionar UseCases para lifecycle e lookup governance
5. Adicionar ViewModels para lifecycle e lookup governance

**Entregavel:** Frontend usando 100% do novo contrato, PatientTranslator removido.

### Fase 4: Cleanup

**Escopo:** todos

1. Remover contrato antigo (`@Deprecated`)
2. Remover domain models com validacao redundante (`Patient.create()`)
3. Remover `PatientRemote` (substituido por `PatientDetailDto`)
4. Atualizar testes para usar novos DTOs
5. Atualizar FakeSocialCareBff para novo contrato

---

## 9. Checklist de Validacao

Ao final da implementacao, cada item abaixo DEVE ser verdadeiro:

- [ ] Contrato BFF tem 1 metodo por endpoint do backend (35 metodos)
- [ ] Todos os metodos de escrita aceitam Request DTOs (primitivos), NAO agregados
- [ ] Todos os metodos de leitura retornam Response DTOs tipados, NAO `Map<String, dynamic>`
- [ ] `listPatients()` suporta paginacao (cursor, limit, search, status)
- [ ] Lifecycle completo acessivel: discharge, readmit, admit, withdraw
- [ ] Lookup governance acessivel: CRUD items, request workflow (create, approve, reject)
- [ ] Audit trail com paginacao (limit, offset)
- [ ] `BackendError` preserva code, message e httpStatus separados
- [ ] Zero validacao de dominio no BFF — backend e a unica fonte de verdade
- [ ] FakeSocialCareBff atualizado com novo contrato para testes
- [ ] PatientTranslator.toJson() removido (substituido por Request DTO.toJson())
- [ ] PatientRemote removido (substituido por PatientDetailDto tipado)
- [ ] Frontend UseCase NAO monta agregado Patient para registro
- [ ] Todos os Response DTOs usam `@JsonSerializable()` (zero parsing manual)

---

## Apendice A: Endpoints Backend vs Metodos BFF (Referencia Cruzada)

| # | Backend HTTP | Metodo BFF Novo | BC |
|---|-------------|----------------|-----|
| 1 | `GET /health` | `checkHealth()` | Health |
| 2 | `GET /ready` | `checkReady()` | Health |
| 3 | `GET /patients` | `listPatients({search, status, cursor, limit})` | Registry |
| 4 | `POST /patients` | `registerPatient(RegisterPatientRequest)` | Registry |
| 5 | `GET /patients/:id` | `getPatient(String)` | Registry |
| 6 | `GET /patients/by-person/:pid` | `getPatientByPersonId(String)` | Registry |
| 7 | `POST /patients/:id/family-members` | `addFamilyMember(String, AddFamilyMemberRequest)` | Registry |
| 8 | `DELETE /patients/:id/family-members/:mid` | `removeFamilyMember(String, String)` | Registry |
| 9 | `PUT /patients/:id/primary-caregiver` | `assignPrimaryCaregiver(String, String)` | Registry |
| 10 | `PUT /patients/:id/social-identity` | `updateSocialIdentity(String, UpdateSocialIdentityRequest)` | Registry |
| 11 | `POST /patients/:id/discharge` | `dischargePatient(String, DischargePatientRequest)` | Registry |
| 12 | `POST /patients/:id/readmit` | `readmitPatient(String, {String? notes})` | Registry |
| 13 | `POST /patients/:id/admit` | `admitPatient(String)` | Registry |
| 14 | `POST /patients/:id/withdraw` | `withdrawPatient(String, WithdrawPatientRequest)` | Registry |
| 15 | `GET /patients/:id/audit-trail` | `getAuditTrail(String, {eventType, limit, offset})` | Registry |
| 16 | `PUT .../housing-condition` | `updateHousingCondition(String, Request)` | Assessment |
| 17 | `PUT .../socioeconomic-situation` | `updateSocioEconomicSituation(String, Request)` | Assessment |
| 18 | `PUT .../work-and-income` | `updateWorkAndIncome(String, Request)` | Assessment |
| 19 | `PUT .../educational-status` | `updateEducationalStatus(String, Request)` | Assessment |
| 20 | `PUT .../health-status` | `updateHealthStatus(String, Request)` | Assessment |
| 21 | `PUT .../community-support-network` | `updateCommunitySupportNetwork(String, Request)` | Assessment |
| 22 | `PUT .../social-health-summary` | `updateSocialHealthSummary(String, Request)` | Assessment |
| 23 | `POST .../appointments` | `registerAppointment(String, Request)` | Care |
| 24 | `PUT .../intake-info` | `updateIntakeInfo(String, Request)` | Care |
| 25 | `PUT .../placement-history` | `updatePlacementHistory(String, Request)` | Care |
| 26 | `POST .../violation-reports` | `reportViolation(String, Request)` | Protection |
| 27 | `POST .../referrals` | `createReferral(String, Request)` | Protection |
| 28 | `GET /dominios/:table` | `getLookupTable(String)` | Lookup |
| 29 | `POST /dominios/:table` | `createLookupItem(String, Request)` | Lookup |
| 30 | `PUT /dominios/:table/:id` | `updateLookupItem(String, String, Request)` | Lookup |
| 31 | `PATCH /dominios/:table/:id/toggle` | `toggleLookupItem(String, String)` | Lookup |
| 32 | `GET /dominios/requests` | `listLookupRequests({status})` | Lookup |
| 33 | `POST /dominios/requests` | `createLookupRequest(Request)` | Lookup |
| 34 | `PUT /dominios/requests/:id/approve` | `approveLookupRequest(String)` | Lookup |
| 35 | `PUT /dominios/requests/:id/reject` | `rejectLookupRequest(String, String)` | Lookup |

---

## Apendice B: Mapa de Arquivos por Issue (Onde Olhar, Onde Criar)

> Todos os paths sao relativos a raiz do monorepo frontend.
> Paths do backend sao relativos a `social-care/Sources/social-care-s/`.

---

### #47 — Response DTOs tipados (`phase-1`)

**Onde criar:**
```
bff/shared/lib/src/infrastructure/dtos/responses/   ← CRIAR pasta
  patient_summary_dto.dart
  patient_detail_dto.dart
  personal_data_dto.dart
  civil_documents_dto.dart
  address_dto.dart
  family_member_dto.dart
  diagnosis_dto.dart
  housing_condition_dto.dart
  socio_economic_dto.dart
  work_and_income_dto.dart
  educational_status_dto.dart
  health_status_dto.dart
  community_support_dto.dart
  social_health_summary_dto.dart
  placement_history_dto.dart
  appointment_dto.dart
  referral_dto.dart
  violation_report_dto.dart
  ingress_info_dto.dart
  computed_analytics_dto.dart
  lookup_item_dto.dart
  lookup_request_dto.dart
  audit_entry_dto.dart
  discharge_info_dto.dart
  withdraw_info_dto.dart
```

**Referencia no backend (campos e tipos exatos):**
```
IO/HTTP/DTOs/ResponseDTOs.swift          ← FONTE DE VERDADE de todos os campos
```

**O que substituem (remover na Phase 4):**
```
bff/shared/lib/src/infrastructure/dtos/patient_remote.dart      ← PatientRemote com Map<String, dynamic>
bff/shared/lib/src/infrastructure/dtos/patient_overview.dart     ← PatientOverview sem status
bff/shared/lib/src/infrastructure/patient_translator.dart        ← parsing manual de maps
bff/shared/lib/src/infrastructure/mappers/registry_mapper.dart   ← *FromJson manual
bff/shared/lib/src/infrastructure/mappers/assessment_mapper.dart
bff/shared/lib/src/infrastructure/mappers/care_mapper.dart
bff/shared/lib/src/infrastructure/mappers/protection_mapper.dart
```

---

### #48 — Request DTOs (`phase-1`)

**Onde criar:**
```
bff/shared/lib/src/infrastructure/dtos/requests/   ← CRIAR pasta
  registry/
    register_patient_request.dart
    add_family_member_request.dart
    update_social_identity_request.dart
    discharge_patient_request.dart
    withdraw_patient_request.dart
  assessment/
    update_housing_condition_request.dart
    update_socio_economic_request.dart
    update_work_and_income_request.dart
    update_educational_status_request.dart
    update_health_status_request.dart
    update_community_support_request.dart
    update_social_health_summary_request.dart
  care/
    register_appointment_request.dart
    update_intake_info_request.dart
  protection/
    update_placement_history_request.dart
    report_violation_request.dart
    create_referral_request.dart
  lookup/
    create_lookup_item_request.dart
    update_lookup_item_request.dart
    create_lookup_request_dto.dart
    reject_lookup_request_dto.dart
```

**Referencia no backend (campos e tipos exatos):**
```
IO/HTTP/DTOs/RequestDTOs.swift                        ← FONTE DE VERDADE
Application/Registry/RegisterPatient/Command/RegisterPatientCommand.swift
Application/Care/RegisterAppointment/Command/RegisterAppointmentCommand.swift
Application/Care/RegisterIntakeInfo/Command/RegisterIntakeInfoCommand.swift
Application/Protection/CreateReferral/Command/CreateReferralCommand.swift
Application/Protection/ReportRightsViolation/Command/ReportRightsViolationCommand.swift
Application/Protection/UpdatePlacementHistory/Command/UpdatePlacementHistoryCommand.swift
Application/Assessment/*/Command/*.swift              ← 7 commands de assessment
Application/Registry/DischargePatient/Command/DischargePatientCommand.swift
Application/Registry/ReadmitPatient/Command/ReadmitPatientCommand.swift
Application/Registry/AdmitPatient/Command/AdmitPatientCommand.swift
Application/Registry/WithdrawFromWaitlist/Command/WithdrawFromWaitlistCommand.swift
Application/Configuration/*/Command/*.swift           ← Lookup CRUD commands
```

**O que substituem (remover na Phase 4):**
```
bff/shared/lib/src/domain/registry/patient.dart             ← Patient.create() usado como input
bff/shared/lib/src/infrastructure/patient_translator.dart    ← toJson() que serializa agregado
```

---

### #49 — PaginatedList + BackendError (`phase-1`)

**Onde criar:**
```
bff/shared/lib/src/infrastructure/dtos/paginated_list.dart    ← CRIAR
bff/shared/lib/src/infrastructure/dtos/backend_error.dart     ← CRIAR
```

**Referencia no backend:**
```
IO/HTTP/DTOs/ResponseDTOs.swift    ← PaginatedResponse<T>, PaginatedMeta
shared/AppError.swift              ← Estrutura de erro (code, message, kind, http)
```

**O que substituem:**
```
bff/social_care_web/lib/src/remote/social_care_api_client.dart    ← _backendFailure() que concatena string
bff/social_care_web/lib/src/handlers/handler_utils.dart           ← BackendError atual (so statusCode + message)
```

---

### #50 — Novo contrato por bounded context (`phase-1`)

**Onde criar:**
```
bff/shared/lib/src/contract/
  health_contract.dart          ← CRIAR
  registry_contract.dart        ← CRIAR
  assessment_contract.dart      ← CRIAR
  care_contract.dart            ← CRIAR
  protection_contract.dart      ← CRIAR
  lookup_contract.dart          ← CRIAR
  social_care_contract.dart     ← REESCREVER (fachada que implements all)
```

**Referencia no backend (quais metodos cada contrato precisa):**
```
IO/HTTP/Controllers/HealthController.swift       → HealthContract (2 metodos)
IO/HTTP/Controllers/PatientController.swift      → RegistryContract (15 metodos)
IO/HTTP/Controllers/AssessmentController.swift   → AssessmentContract (7 metodos)
IO/HTTP/Controllers/CareController.swift         → CareContract (2 metodos)
IO/HTTP/Controllers/ProtectionController.swift   → ProtectionContract (3 metodos)
IO/HTTP/Controllers/LookupController.swift       → LookupContract (8 metodos)
```

**O que substitui:**
```
bff/shared/lib/src/contract/social_care_contract.dart   ← Contrato monolitico atual (23 metodos)
```

**Quem implementa (atualizar na Phase 2):**
```
bff/social_care_web/lib/src/remote/social_care_api_client.dart       ← Web API client
bff/social_care_desktop/lib/src/remote/social_care_bff_remote.dart   ← Desktop remote client
bff/social_care_desktop/lib/src/storage/offline_first_repository.dart ← Desktop offline-first
bff/social_care_desktop/lib/src/storage/local_social_care_repository.dart ← Desktop local cache
bff/shared/lib/src/testing/fake_social_care_bff.dart                 ← Fake para testes
```

---

### #51 — Lifecycle endpoints (`phase-2`)

**Onde implementar:**

| Camada | Arquivo | O que adicionar |
|--------|---------|-----------------|
| Web API Client | `bff/social_care_web/lib/src/remote/social_care_api_client.dart` | 4 metodos: discharge, readmit, admit, withdraw |
| Web Handler | `bff/social_care_web/lib/src/handlers/registry_handler.dart` | 4 rotas novas no Router |
| Desktop Remote | `bff/social_care_desktop/lib/src/remote/social_care_bff_remote.dart` | 4 metodos |
| Desktop Offline | `bff/social_care_desktop/lib/src/storage/offline_first_repository.dart` | 4 metodos (write-through) |
| Desktop Local | `bff/social_care_desktop/lib/src/storage/local_social_care_repository.dart` | 4 metodos (update status local) |
| Fake | `bff/shared/lib/src/testing/fake_social_care_bff.dart` | 4 metodos mock |

**Referencia no backend:**
```
IO/HTTP/Controllers/PatientController.swift:
  - POST .../discharge   → lines ~110-125
  - POST .../readmit     → lines ~130-145
  - POST .../admit       → lines ~150-160
  - POST .../withdraw    → lines ~165-180

Application/Registry/DischargePatient/    ← Command, UseCase, Error, Services
Application/Registry/ReadmitPatient/
Application/Registry/AdmitPatient/
Application/Registry/WithdrawFromWaitlist/

Domain/Registry/Aggregates/Patient/PatientLifecycle.swift   ← regras de transicao de status
```

**Testes:**
```
bff/social_care_web/test/remote/social_care_api_client_test.dart   ← adicionar testes
bff/social_care_web/test/handlers/registry_handler_test.dart       ← adicionar testes
bff/social_care_desktop/test/social_care_bff_remote_test.dart      ← adicionar testes
```

---

### #52 — Lookup governance (`phase-2`)

**Onde implementar:**

| Camada | Arquivo | O que adicionar |
|--------|---------|-----------------|
| Web API Client | `bff/social_care_web/lib/src/remote/social_care_api_client.dart` | 7 metodos de lookup governance |
| Web Handler | `bff/social_care_web/lib/src/handlers/lookup_handler.dart` | 7 rotas novas |
| Desktop Remote | `bff/social_care_desktop/lib/src/remote/social_care_bff_remote.dart` | 7 metodos |
| Fake | `bff/shared/lib/src/testing/fake_social_care_bff.dart` | 7 metodos mock |

**Referencia no backend:**
```
IO/HTTP/Controllers/LookupController.swift   ← todas as rotas de governance
IO/HTTP/DTOs/RequestDTOs.swift               ← CreateLookupItemRequest, etc.
IO/HTTP/DTOs/ResponseDTOs.swift              ← LookupRequestResponse

Application/Configuration/CreateLookupItem/
Application/Configuration/UpdateLookupItem/
Application/Configuration/ToggleLookupItem/
Application/Configuration/CreateLookupRequest/
Application/Configuration/ApproveLookupRequest/
Application/Configuration/RejectLookupRequest/
Application/Query/ListLookupRequests/
```

**Testes:**
```
bff/social_care_web/test/handlers/lookup_handler_test.dart   ← adicionar/criar
bff/social_care_web/test/remote/social_care_api_client_test.dart
```

---

### #53 — Paginacao (`phase-2`)

**Onde modificar:**

| Camada | Arquivo | O que mudar |
|--------|---------|-------------|
| Web API Client | `bff/social_care_web/lib/src/remote/social_care_api_client.dart` | `fetchPatients()` → `listPatients({search, status, cursor, limit})`, retorna `PaginatedList` |
| Web Handler | `bff/social_care_web/lib/src/handlers/registry_handler.dart` | `_fetchPatients()` → passar query params |
| Desktop Remote | `bff/social_care_desktop/lib/src/remote/social_care_bff_remote.dart` | Mesma mudanca |
| Desktop Offline | `bff/social_care_desktop/lib/src/storage/offline_first_repository.dart` | Paginacao local com Isar |
| Fake | `bff/shared/lib/src/testing/fake_social_care_bff.dart` | Simular paginacao |

**Referencia no backend:**
```
IO/HTTP/Controllers/PatientController.swift   ← GET /patients com query params
  - search: String?     (busca por nome)
  - status: String?     (admitted|discharged|waitlist|withdrawn)
  - cursor: String?     (UUID do ultimo item)
  - limit: Int          (1-100, default 20)

IO/HTTP/DTOs/ResponseDTOs.swift   ← PaginatedResponse<PatientSummaryResponse>, PaginatedMeta
```

---

### #54 — BackendError estruturado (`phase-2`)

**Onde modificar:**

| Arquivo | O que mudar |
|---------|-------------|
| `bff/social_care_web/lib/src/remote/social_care_api_client.dart` | `_backendFailure()` retorna `BackendError` separado em vez de string concatenada |
| `bff/social_care_web/lib/src/handlers/handler_utils.dart` | `backendError()` usa `BackendError` novo |
| `bff/social_care_desktop/lib/src/remote/social_care_bff_remote.dart` | Mesma mudanca |
| `packages/social_care/lib/src/data/services/http_social_care_client.dart` | `_mapToSocialCareError()` mapeia `BackendError.code` direto |

**Referencia no backend (codigos de erro):**
```
shared/AppError.swift                                        ← Estrutura AppError
Domain/Kernel/CPF/Errors/CPFError.swift                      ← CPF-001 a CPF-004
Domain/Kernel/RGDocument/Errors/RGDocumentError.swift        ← RGD-001 a RGD-005
Domain/Kernel/NIS/Errors/NISError.swift                      ← NIS-001 a NIS-003
Domain/Kernel/CEP/Errors/CEPError.swift                      ← CEP-001 a CEP-005
Domain/Kernel/CNS/Errors/CNSError.swift                      ← CNS-001 a CNS-005
Application/Registry/RegisterPatient/Error/RegisterPatientError.swift ← PAT-001 a PAT-020
Application/Registry/*/Error/*.swift                         ← Erros por use case
Application/Assessment/*/Error/*.swift
Application/Care/*/Error/*.swift
Application/Protection/*/Error/*.swift
```

---

### #55 — Migrar UseCases e Repositories (`phase-3`)

**Onde modificar:**

**Repositories:**
```
packages/social_care/lib/src/data/repositories/bff_patient_repository.dart
  ← Usar PatientDetailDto em vez de PatientRemote + PatientTranslator
  ← Usar PaginatedList<PatientSummaryDto> em vez de List<PatientOverview>

packages/social_care/lib/src/data/repositories/bff_lookup_repository.dart
  ← Usar LookupItemDto
```

**UseCases — Registry:**
```
packages/social_care/lib/src/logic/use_case/registry/register_patient_use_case.dart
  ← Montar RegisterPatientRequest em vez de Patient

packages/social_care/lib/src/logic/use_case/registry/list_patients_use_case.dart
  ← Aceitar params de paginacao, retornar PaginatedList

packages/social_care/lib/src/logic/use_case/registry/get_patient_use_case.dart
  ← Receber PatientDetailDto em vez de PatientRemote
```

**UseCases — Family:**
```
packages/social_care/lib/src/logic/use_case/family/add_family_member_use_case.dart
  ← Montar AddFamilyMemberRequest

packages/social_care/lib/src/logic/use_case/family/remove_family_member_use_case.dart
packages/social_care/lib/src/logic/use_case/family/update_primary_caregiver_use_case.dart
```

**UseCases — Assessment (7):**
```
packages/social_care/lib/src/logic/use_case/assessment/update_housing_condition_use_case.dart
packages/social_care/lib/src/logic/use_case/assessment/update_socio_economic_use_case.dart
packages/social_care/lib/src/logic/use_case/assessment/update_educational_status_use_case.dart
packages/social_care/lib/src/logic/use_case/assessment/update_health_status_use_case.dart
packages/social_care/lib/src/logic/use_case/assessment/update_work_and_income_use_case.dart
packages/social_care/lib/src/logic/use_case/assessment/update_community_support_use_case.dart
packages/social_care/lib/src/logic/use_case/assessment/update_social_health_summary_use_case.dart
  ← Todos: montar Request DTO em vez de domain VO
```

**UseCases — Care:**
```
packages/social_care/lib/src/logic/use_case/care/register_appointment_use_case.dart
packages/social_care/lib/src/logic/use_case/care/update_intake_info_use_case.dart
```

**UseCases — Protection:**
```
packages/social_care/lib/src/logic/use_case/protection/create_referral_use_case.dart
packages/social_care/lib/src/logic/use_case/protection/report_violation_use_case.dart
packages/social_care/lib/src/logic/use_case/protection/update_placement_history_use_case.dart
```

**Mappers a simplificar:**
```
packages/social_care/lib/src/logic/mappers/registry_mapper.dart
  ← Intent → RegisterPatientRequest (trivial) em vez de Intent → Patient aggregate (complexo)

packages/social_care/lib/src/logic/mappers/family_mapper.dart
packages/social_care/lib/src/logic/mappers/assessment_mapper.dart
packages/social_care/lib/src/logic/mappers/intervention_mapper.dart
```

**Erros a atualizar:**
```
packages/social_care/lib/src/domain/errors/social_care_errors.dart
  ← Mapear BackendError.code direto para SocialCareError tipado
```

**DI a atualizar:**
```
apps/acdg_system/lib/logic/di/infrastructure_providers.dart
apps/acdg_system/lib/logic/di/social_care_providers.dart
```

---

### #56 — UseCases + ViewModels para lifecycle (`phase-3`)

**Onde criar:**
```
packages/social_care/lib/src/logic/use_case/lifecycle/  ← CRIAR pasta
  discharge_patient_use_case.dart
  readmit_patient_use_case.dart
  admit_patient_use_case.dart
  withdraw_patient_use_case.dart
```

**Onde modificar (ViewModels existentes):**
```
packages/social_care/lib/src/ui/home/viewModel/home_view_model.dart
  ← Adicionar filtro por status
  ← Usar PaginatedList, load more on scroll

packages/social_care/lib/src/ui/home/models/patient_summary.dart
  ← Adicionar campo status
```

**Onde criar (novos ViewModels/Widgets):**
```
packages/social_care/lib/src/ui/patient_lifecycle/   ← CRIAR pasta
  view_models/patient_lifecycle_view_model.dart
  widgets/
    discharge_dialog.dart
    readmit_dialog.dart
    withdraw_dialog.dart
    lifecycle_action_buttons.dart
```

**Repository a estender:**
```
packages/social_care/lib/src/data/repositories/patient_repository.dart
  ← Adicionar: dischargePatient, readmitPatient, admitPatient, withdrawPatient

packages/social_care/lib/src/data/repositories/bff_patient_repository.dart
  ← Implementar os 4 metodos
```

**Testes:**
```
packages/social_care/test/logic/use_case/lifecycle/   ← CRIAR
packages/social_care/test/ui/patient_lifecycle/        ← CRIAR
```

**Fakes:**
```
packages/social_care/lib/src/testing/fakes/fake_patient_repository.dart
  ← Adicionar 4 metodos
```

---

### #57 — Feature de lookup governance (`phase-3`)

**Onde criar:**
```
packages/social_care/lib/src/logic/use_case/lookup/   ← CRIAR pasta
  list_lookup_requests_use_case.dart
  create_lookup_request_use_case.dart
  create_lookup_item_use_case.dart
  update_lookup_item_use_case.dart
  toggle_lookup_item_use_case.dart
  approve_lookup_request_use_case.dart
  reject_lookup_request_use_case.dart

packages/social_care/lib/src/ui/lookup_management/   ← CRIAR pasta
  view_models/lookup_management_view_model.dart
  widgets/
    lookup_management_page.dart
    organisms/
      lookup_items_table.dart
      lookup_requests_list.dart
    molecules/
      create_item_form.dart
      request_approval_card.dart
```

**Repository a estender:**
```
packages/social_care/lib/src/data/repositories/lookup_repository.dart
  ← Adicionar 7 metodos de governance

packages/social_care/lib/src/data/repositories/bff_lookup_repository.dart
  ← Implementar 7 metodos
```

**Testes:**
```
packages/social_care/test/logic/use_case/lookup/   ← CRIAR
packages/social_care/test/ui/lookup_management/    ← CRIAR
```

---

### #58 — Cleanup (`phase-4`)

**Onde REMOVER:**
```
bff/shared/lib/src/infrastructure/dtos/patient_remote.dart       ← DELETAR
bff/shared/lib/src/infrastructure/dtos/patient_remote.g.dart     ← DELETAR
bff/shared/lib/src/infrastructure/dtos/patient_overview.dart     ← DELETAR (substituido por PatientSummaryDto)
bff/shared/lib/src/infrastructure/dtos/patient_overview.g.dart   ← DELETAR
bff/shared/lib/src/infrastructure/patient_translator.dart        ← DELETAR
bff/shared/lib/src/infrastructure/mappers/registry_mapper.dart   ← DELETAR
bff/shared/lib/src/infrastructure/mappers/assessment_mapper.dart ← DELETAR
bff/shared/lib/src/infrastructure/mappers/care_mapper.dart       ← DELETAR
bff/shared/lib/src/infrastructure/mappers/protection_mapper.dart ← DELETAR
```

**Onde SIMPLIFICAR:**
```
bff/shared/lib/src/domain/registry/patient.dart
  ← Remover Patient.create() (validacao). Manter apenas reconstitute()

bff/shared/lib/src/domain/registry/family_member.dart
  ← Remover FamilyMember.create(). Manter reconstitute()

bff/shared/lib/src/domain/assessment/*
  ← Remover *.create() em todos os VOs. Manter reconstitute()

packages/social_care/lib/src/logic/mappers/registry_mapper.dart
  ← Simplificar drasticamente (Intent → Request DTO e trivial)

packages/social_care/lib/src/ui/home/models/patient_detail_translator.dart
  ← Simplificar (PatientDetailDto tipado ja vem pronto)
```

**Onde ATUALIZAR:**
```
bff/shared/lib/src/testing/fake_social_care_bff.dart
  ← Implementar novo SocialCareContract completo (35 metodos)

bff/shared/lib/shared.dart                   ← Barrel exports
bff/shared/lib/testing.dart                  ← Barrel exports

bff/shared/test/                             ← Remover testes de PatientTranslator
bff/social_care_web/test/                    ← Atualizar testes de handlers
bff/social_care_desktop/test/                ← Atualizar testes offline-first
packages/social_care/test/                   ← Atualizar todos os testes
```

---

### #59 — Testes de serialization (`phase-1`)

**Onde criar:**
```
bff/shared/test/infrastructure/dtos/responses/   ← CRIAR pasta
  patient_summary_dto_test.dart
  patient_detail_dto_test.dart
  personal_data_dto_test.dart
  civil_documents_dto_test.dart
  address_dto_test.dart
  family_member_dto_test.dart
  diagnosis_dto_test.dart
  housing_condition_dto_test.dart
  socio_economic_dto_test.dart
  work_and_income_dto_test.dart
  educational_status_dto_test.dart
  health_status_dto_test.dart
  community_support_dto_test.dart
  social_health_summary_dto_test.dart
  placement_history_dto_test.dart
  appointment_dto_test.dart
  referral_dto_test.dart
  violation_report_dto_test.dart
  ingress_info_dto_test.dart
  computed_analytics_dto_test.dart
  lookup_item_dto_test.dart
  lookup_request_dto_test.dart
  audit_entry_dto_test.dart
  paginated_list_test.dart
  backend_error_test.dart

bff/shared/test/infrastructure/dtos/requests/   ← CRIAR pasta
  register_patient_request_test.dart
  add_family_member_request_test.dart
  update_housing_condition_request_test.dart
  ... (1 teste por Request DTO)
```

**Fixtures de referencia (JSONs reais do backend):**
```
social-care/Tests/social-care-sTests/Application/TestDoubles/PatientFixture.swift
  ← Estrutura de Patient para gerar JSONs de teste realistas
```
