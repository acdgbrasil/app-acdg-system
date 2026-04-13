# 06 - INFRASTRUCTURE: DTOs, Mappers, Translator, Clients

> PatientRemote, PatientOverview, 4 Mappers (Registry, Assessment, Care, Protection), PatientTranslator (facade), PeopleContextClient, PatientEnrichmentService.

---

## 1. DTOs

### 1.1 PatientRemote

**Arquivo:** `infrastructure/dtos/patient_remote.dart`

```dart
@JsonSerializable()
class PatientRemote {
  final String patientId;
  final String personId;
  final int version;                                    // default: 0
  final String? prRelationshipId;
  final Map<String, dynamic>? personalData;
  final Map<String, dynamic>? civilDocuments;
  final Map<String, dynamic>? address;
  final Map<String, dynamic>? socialIdentity;
  final List<Map<String, dynamic>> familyMembers;      // default: const []
  final List<Map<String, dynamic>> diagnoses;           // default: const []
  final Map<String, dynamic>? housingCondition;
  final Map<String, dynamic>? socioeconomicSituation;
  final Map<String, dynamic>? workAndIncome;
  final Map<String, dynamic>? educationalStatus;
  final Map<String, dynamic>? healthStatus;
  final Map<String, dynamic>? communitySupportNetwork;
  final Map<String, dynamic>? socialHealthSummary;
  final List<Map<String, dynamic>> appointments;        // default: const []
  final Map<String, dynamic>? intakeInfo;
  final Map<String, dynamic>? placementHistory;
  final List<Map<String, dynamic>> violationReports;    // default: const []
  final List<Map<String, dynamic>> referrals;           // default: const []
  final Map<String, dynamic>? computedAnalytics;

  factory PatientRemote.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

**Key aliasing:** campo `diagnoses` le de `json['initialDiagnoses'] ?? json['diagnoses'] ?? const []` via `@JsonKey(readValue: _readDiagnoses)`. `initialDiagnoses` tem precedencia.

### 1.2 PatientOverview

**Arquivo:** `infrastructure/dtos/patient_overview.dart`

```dart
@JsonSerializable()
class PatientOverview {
  final String patientId;
  final String personId;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? primaryDiagnosis;
  final int memberCount;  // default: 0

  factory PatientOverview.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

---

## 2. JSON Helpers

**Arquivo:** `infrastructure/mappers/json_helpers.dart`

**Constante:** `const defaultUuid = '00000000-0000-0000-0000-000000000000'`

| Funcao | Assinatura | Comportamento |
|--------|-----------|---------------|
| `enumFromJson<T>` | `Result<T> enumFromJson(List<T> values, dynamic json, String field)` | Match `toSnakeCaseUpper()` do enum `.name` contra string JSON; falha se null ou sem match |
| `optionalFromJson<T>` | `Result<T?> optionalFromJson(dynamic json, Result<T> Function(Map) parse)` | `Success(null)` se json null |
| `listFromJson<T>` | `Result<List<T>> listFromJson(dynamic json, Result<T> Function(Map) parse, {String field = 'list'})` | Falha no primeiro item invalido com path indexado |
| `idFromJson<T>` | `Result<T> idFromJson(Result<T> Function(String?) create, dynamic json, String field)` | Wraps create com contexto de campo |
| `idFromJsonOrDefault<T>` | `Result<T> idFromJsonOrDefault(Result<T> Function(String?) create, dynamic json, String fallback)` | Se json null/vazio, usa `fallback` |

---

## 3. RegistryMapper

**Arquivo:** `infrastructure/mappers/registry_mapper.dart`

```dart
abstract final class RegistryMapper { ... }
```

### 3.1 To JSON

| Metodo | Chaves JSON Notaveis |
|--------|---------------------|
| `personalDataToJson(PersonalData d)` | `firstName`, `lastName`, `motherName`, `nationality`, `sex` (enum `.name`), `socialName`, `birthDate` (`.toIso8601()`), `phone` |
| `civilDocumentsToJson(CivilDocuments d)` | `cpf` (value), `nis` (value), `rgDocument` (objeto com `number`, `issuingState`, `issuingAgency`, `issueDate`), `cns` (objeto com `number`, `cpf`, `qrCode`) |
| `addressToJson(Address a)` | `residenceLocation` serializado como `'URBANO'` ou `'RURAL'` |
| `familyMemberToJson(FamilyMember m)` | **Duas chaves para personId:** `personId` E `memberPersonId`; `relationship` (nao `relationshipId`); `isResiding`, `isCaregiver`; `requiredDocuments` como array de `.value` strings; `birthDate` via `.toIso8601()` |
| `diagnosisToJson(Diagnosis d)` | `icdCode`, `date`, `description` |
| `socialIdentityToJson(SocialIdentity i)` | `typeId` (value), `description` (otherDescription) |

### 3.2 From JSON

Todos retornam `Result<T>`. **Aliases de chave notaveis:**
- `familyMemberFromJson`: aceita `j['relationship'] ?? j['relationshipId']` e `j['isResiding'] ?? j['residesWithPatient']` e `j['isCaregiver'] ?? j['isPrimaryCaregiver']`

---

## 4. AssessmentMapper

**Arquivo:** `infrastructure/mappers/assessment_mapper.dart`

```dart
abstract final class AssessmentMapper { ... }
```

**Serializacao de enums:** todos usam `.name.toSnakeCaseUpper()` ao escrever; `enumFromJson()` ao ler.

### 4.1 To JSON

- `housingConditionToJson` — chaves camelCase espelhando nomes dos campos
- `socialBenefitToJson` — inclui condicionalmente `birthCertificateNumber` e `deceasedCpf`
- `socioEconomicToJson` — inclui `socialBenefits` como lista
- `workAndIncomeToJson` — `individualIncomes` com `memberId`, `occupationId`, `hasWorkCard`, `monthlyAmount`
- `educationalStatusToJson` — `memberProfiles` e `programOccurrences`
- `healthStatusToJson` — `deficiencies`, `gestatingMembers`, `constantCareNeeds`, `foodInsecurity`
- `communitySupportToJson` — todos campos bool + `familyConflicts`
- `socialHealthSummaryToJson` — inclui `functionalDependencies` como lista

### 4.2 From JSON — Caso Especial

`socialBenefitFromJson` usa `idFromJsonOrDefault(LookupId.create, j['benefitTypeId'], defaultUuid)` — benefitTypeId ausente cai para UUID zeros. Mesmo padrao para `familyId` em `workAndIncomeFromJson`, `educationalStatusFromJson`, `healthStatusFromJson`, `placementHistoryFromJson`.

---

## 5. CareMapper

**Arquivo:** `infrastructure/mappers/care_mapper.dart`

```dart
abstract final class CareMapper { ... }
```

| Metodo | Chaves JSON |
|--------|-------------|
| `appointmentToJson` | `id`, `professionalId`, `summary`, `actionPlan`, `date`, `type` |
| `intakeInfoToJson` | `ingressTypeId`, `originName`, `originContact`, `serviceReason`, `linkedSocialPrograms` (array de `{programId, observation}`) |
| `appointmentFromJson` | `id` usa `idFromJsonOrDefault` com `defaultUuid`; chave `professionalId` (nao `professionalInChargeId`) |
| `intakeInfoFromJson` | parse padrao |

---

## 6. ProtectionMapper

**Arquivo:** `infrastructure/mappers/protection_mapper.dart`

```dart
abstract final class ProtectionMapper { ... }
```

| Metodo | Chaves JSON |
|--------|-------------|
| `placementHistoryToJson` | `registries` (array com `id`, `memberId`, `startDate`, `endDate`, `reason`), `collectiveSituations`, `separationChecklist` |
| `violationReportToJson` | `id`, `victimId`, `violationType` (SCREAMING_SNAKE), `violationTypeId`, `descriptionOfFact`, `reportDate`, `incidentDate`, `actionsTaken` |
| `referralToJson` | `id`, `referredPersonId`, `destinationService` (SCREAMING_SNAKE), `reason`, `date`, `professionalId`, `status` (SCREAMING_SNAKE) |

---

## 7. PatientTranslator (Facade)

**Arquivo:** `infrastructure/patient_translator.dart`

```dart
class PatientTranslator {
  static const _defaultPrRelationshipId = '00000000-0000-0000-0000-000000000000';

  static Map<String, dynamic> toJson(Patient p);
  // NOTA: diagnosticos serializados sob chave 'initialDiagnoses' (nao 'diagnoses')

  static Result<Patient> fromJson(Map<String, dynamic> json);
  // Parseia via PatientRemote.fromJson → toDomain

  static Result<Patient> toDomain(PatientRemote dto);
  // Conversao tipada completa com switch-case exaustivo; usa Patient.reconstitute
}
```

**39 metodos delegate (todos static):** encaminham para os 4 mappers por bounded context.

| Grupo | Quantidade |
|-------|-----------|
| Registry | 12 (personalData, civilDocuments, address, familyMember, diagnosis, socialIdentity — to/from JSON) |
| Assessment | 16 (housing, socioEconomic, workAndIncome, education, health, communitySupport, socialHealthSummary, socialBenefit — to/from JSON) |
| Care | 4 (appointment, intakeInfo — to/from JSON) |
| Protection | 6 (placementHistory, violationReport, referral — to/from JSON) |

---

## 8. PeopleContextClient

**Arquivo:** `infrastructure/people_context_client.dart`

```dart
class PeopleContextClient {
  PeopleContextClient({
    required String baseUrl,
    required String actorId,
    String? accessToken,
    String Function()? tokenProvider,
    Dio? dio,
  });
}
```

**Dio config default:** `Content-Type: application/json`, `Authorization: Bearer $accessToken` (se fornecido), `X-Actor-Id: $actorId`.
Se `tokenProvider` definido, um `InterceptorsWrapper` atualiza `Authorization` em cada request.

| Metodo | Assinatura | Endpoint | Comportamento |
|--------|-----------|----------|---------------|
| `registerPerson` | `Future<Result<String>> registerPerson({required String fullName, required String birthDate, String? cpf})` | `POST /api/v1/people` | Retorna `personId` de `response.data['data']['id']`; 201 ou 200 = sucesso; strip time do birthDate se contem `T` |
| `getPerson` | `Future<Result<Map<String, dynamic>>> getPerson(String personId)` | `GET /api/v1/people/$personId` | Retorna `response.data['data']` em 200 |

Ambos usam `validateStatus: (status) => true` e capturam todas excecoes como `'People Context unreachable: $e'`.

---

## 9. PatientEnrichmentService

**Arquivo:** `services/patient_enrichment_service.dart`

```dart
class PatientEnrichmentService {
  const PatientEnrichmentService(PeopleContextClient peopleContext);

  Future<void> enrichPayload(Map<String, dynamic> payload);
}
```

**Comportamento non-blocking** — ignora falhas silenciosamente (graceful degradation).

**Fluxo:**
1. `_enrichReferencePerson`: le `payload['personalData']['firstName']` + `lastName` → `fullName`, `birthDate`, `cpf` de `civilDocuments`; se nao-vazio chama `registerPerson`; em sucesso substitui `payload['personId']`
2. `_enrichFamilyMembers`: itera `payload['familyMembers']`; para cada um, le `fullName`, `birthDate`, `cpf`; em sucesso substitui `member['personId']` e `member['memberPersonId']`

---

## 10. Diagrama de Relacoes

```
PatientTranslator (facade)
  ├── RegistryMapper    → PersonalData, CivilDocuments, Address, FamilyMember, Diagnosis, SocialIdentity
  ├── AssessmentMapper  → HousingCondition, SocioEconomicSituation, WorkAndIncome, EducationalStatus,
  │                       HealthStatus, CommunitySupportNetwork, SocialHealthSummary, SocialBenefit
  ├── CareMapper        → SocialCareAppointment, IngressInfo
  └── ProtectionMapper  → PlacementHistory, RightsViolationReport, Referral

PatientRemote ──(toDomain)──► Patient (aggregate root)
PatientOverview  (listing DTO leve)

PatientEnrichmentService → PeopleContextClient → Dio → POST/GET /api/v1/people
```
