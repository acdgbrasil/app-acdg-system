# 07 - CONTRACT & TESTING: Interface e Fake

> SocialCareContract (interface BFF) e FakeSocialCareBff (implementacao in-memory para testes).

---

## 1. SocialCareContract

**Arquivo:** `contract/social_care_contract.dart`

```dart
abstract interface class SocialCareContract { ... }
```

Todos os metodos retornam `Future<Result<T>>`.

### 1.1 Health

| Metodo | Retorno |
|--------|---------|
| `checkHealth()` | `Result<void>` |
| `checkReady()` | `Result<void>` |

### 1.2 Registry

| Metodo | Retorno |
|--------|---------|
| `fetchPatients()` | `Result<List<PatientOverview>>` |
| `registerPatient(Patient patient)` | `Result<PatientId>` |
| `fetchPatient(PatientId id)` | `Result<PatientRemote>` |
| `fetchPatientByPersonId(PersonId personId)` | `Result<PatientRemote>` |
| `addFamilyMember(PatientId, FamilyMember, LookupId prRelationshipId)` | `Result<void>` |
| `removeFamilyMember(PatientId, PersonId memberId)` | `Result<void>` |
| `assignPrimaryCaregiver(PatientId, PersonId memberId)` | `Result<void>` |
| `updateSocialIdentity(PatientId, SocialIdentity identity)` | `Result<void>` |
| `getAuditTrail(PatientId, {String? eventType})` | `Result<List<AuditEvent>>` |

### 1.3 Assessment

| Metodo | Retorno |
|--------|---------|
| `updateHousingCondition(PatientId, HousingCondition)` | `Result<void>` |
| `updateSocioEconomicSituation(PatientId, SocioEconomicSituation)` | `Result<void>` |
| `updateWorkAndIncome(PatientId, WorkAndIncome)` | `Result<void>` |
| `updateEducationalStatus(PatientId, EducationalStatus)` | `Result<void>` |
| `updateHealthStatus(PatientId, HealthStatus)` | `Result<void>` |
| `updateCommunitySupportNetwork(PatientId, CommunitySupportNetwork)` | `Result<void>` |
| `updateSocialHealthSummary(PatientId, SocialHealthSummary)` | `Result<void>` |

### 1.4 Care

| Metodo | Retorno |
|--------|---------|
| `registerAppointment(PatientId, SocialCareAppointment)` | `Result<AppointmentId>` |
| `updateIntakeInfo(PatientId, IngressInfo info)` | `Result<void>` |

### 1.5 Protection

| Metodo | Retorno |
|--------|---------|
| `updatePlacementHistory(PatientId, PlacementHistory)` | `Result<void>` |
| `reportViolation(PatientId, RightsViolationReport)` | `Result<ViolationReportId>` |
| `createReferral(PatientId, Referral)` | `Result<ReferralId>` |

### 1.6 Lookup

| Metodo | Retorno |
|--------|---------|
| `getLookupTable(String tableName)` | `Result<List<LookupItem>>` |

---

## 2. FakeSocialCareBff

**Arquivo:** `testing/fake_social_care_bff.dart`

```dart
class FakeSocialCareBff implements SocialCareContract {
  final Duration delay;  // default: Duration(milliseconds: 200)
  final Map<String, Patient> _patients;  // in-memory store
}
```

### 2.1 Comportamento

| Metodo | Fake Behavior |
|--------|---------------|
| `checkHealth` / `checkReady` | `Success(null)` sempre |
| `fetchPatients` | mapeia `_patients.values` para `PatientOverview` |
| `registerPatient` | armazena em `_patients`, retorna `patient.id` |
| `fetchPatient` | lookup por `id.value`; `Failure('Patient not found: ...')` se nao encontrado |
| `fetchPatientByPersonId` | `firstWhere` por `personId` |
| `addFamilyMember` | `Success(null)` no-op |
| `removeFamilyMember` | `Success(null)` no-op |
| `assignPrimaryCaregiver` | `Success(null)` no-op |
| `updateSocialIdentity` | `Success(null)` no-op |
| `getAuditTrail` | `Success([])` |
| Todas updates Assessment | `Success(null)` no-op |
| `registerAppointment` | retorna `appointment.id` |
| `updateIntakeInfo` | `Success(null)` no-op |
| `updatePlacementHistory` | `Success(null)` no-op |
| `reportViolation` | retorna `report.id` |
| `createReferral` | retorna `referral.id` |
| `getLookupTable` | `Success([])` sempre |

---

## 3. RegisterPatientRequest (Placeholder)

**Arquivo:** `contract/dto/requests/register_patient_request.dart`

```dart
class RegisterPatientRequest {}
```

Classe vazia, nao implementada ainda.
