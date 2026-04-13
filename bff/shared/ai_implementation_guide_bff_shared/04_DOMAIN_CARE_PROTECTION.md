# 04 - DOMAIN CARE & PROTECTION: Atendimento e Protecao

> IcdCode, Diagnosis, IngressInfo, SocialCareAppointment, Referral, RightsViolationReport, PlacementHistory.

---

## 1. Care VOs

**Arquivo:** `domain/care/care_vos.dart`

### 1.1 IcdCode

```dart
final class IcdCode with Equatable {
  final String value;
  String get normalized;  // remove pontos
  bool isEquivalent(IcdCode other);  // compara normalized
}
```

**`static Result<IcdCode> create(String? rawValue, {bool requiresDot = false, bool autoDot = true})`:**

| Codigo | Condicao | Severidade |
|--------|----------|------------|
| `ICD-001` | vazio/null | — |
| `ICD-002` | `requiresDot == true` e sem ponto | error |

**Auto-dot:** se `autoDot == true` e length >= 3 e sem ponto, insere ponto antes do ultimo caractere.

**Modulo:** `social-care/icd-code`

### 1.2 Diagnosis

```dart
final class Diagnosis with Equatable {
  final IcdCode id;
  final TimeStamp date;
  final String description;
}
```

**`static Result<Diagnosis> create({..., TimeStamp? now})`:**

| Codigo | Condicao | Severidade |
|--------|----------|------------|
| `DIA-001` | date null ou futuro | — |
| `DIA-002` | `date.year < 0` | error |
| `DIA-003` | description vazio | — |

**Modulo:** `social-care/diagnosis`

### 1.3 ProgramLink

```dart
final class ProgramLink with Equatable {
  final LookupId programId;
  final String? observation;
}
```

### 1.4 IngressInfo

```dart
final class IngressInfo with Equatable {
  final LookupId ingressTypeId;
  final String? originName;
  final String? originContact;
  final String serviceReason;
  final List<ProgramLink> linkedSocialPrograms;  // unmodifiable
}
```

**`static Result<IngressInfo> create({...})`:** `ING-001` se `serviceReason` vazio. Modulo: `social-care/ingress-info`.

### 1.5 AppointmentType

```dart
enum AppointmentType { homeVisit, officeAppointment, phoneCall, multidisciplinary, other }
```

### 1.6 SocialCareAppointment

```dart
final class SocialCareAppointment with Equatable {
  final AppointmentId id;
  final TimeStamp date;
  final ProfessionalId professionalInChargeId;
  final AppointmentType type;
  final String? summary;
  final String? actionPlan;
  // props: [id]
}
```

**`static Result<SocialCareAppointment> create({..., TimeStamp? now})`:**

| Codigo | Condicao |
|--------|----------|
| `SCA-001` | date no futuro |
| `SCA-003` | summary e actionPlan ambos null/vazio |
| `SCA-004` | `summary.length > 500` |
| `SCA-005` | `actionPlan.length > 2000` |

**Modulo:** `social-care/appointment`

---

## 2. Protection VOs

**Arquivo:** `domain/protection/protection_vos.dart`

### 2.1 Enums

```dart
enum DestinationService { cras, creas, healthCare, education, legal, other }
enum ReferralStatus { pending, completed, cancelled }
enum ViolationType {
  neglect, psychologicalViolence, physicalViolence, sexualAbuse,
  sexualExploitation, childLabor, financialExploitation, discrimination, other
}
```

### 2.2 Referral

```dart
final class Referral with Equatable {
  final ReferralId id;
  final TimeStamp date;
  final ProfessionalId requestingProfessionalId;
  final PersonId referredPersonId;
  final DestinationService destinationService;
  final String reason;
  final ReferralStatus status;
  // props: [id]
}
```

**`static Result<Referral> create({..., ReferralStatus status = ReferralStatus.pending, TimeStamp? now})`:**

| Codigo | Condicao |
|--------|----------|
| `REF-001` | date no futuro |
| `REF-002` | reason vazio |

**Maquina de estados:**
- `Result<Referral> complete()` — so de `pending`; `REF-003` (severity: error) caso contrario
- `Result<Referral> cancel()` — so de `pending`; `REF-003` caso contrario

### 2.3 RightsViolationReport

```dart
final class RightsViolationReport with Equatable {
  final ViolationReportId id;
  final TimeStamp reportDate;
  final TimeStamp? incidentDate;
  final PersonId victimId;
  final ViolationType violationType;
  final LookupId? violationTypeId;
  final String descriptionOfFact;
  final String? actionsTaken;
  // props: [id]
}
```

**`static Result<RightsViolationReport> create({..., TimeStamp? now})`:**

| Codigo | Condicao |
|--------|----------|
| `RVR-001` | reportDate no futuro |
| `RVR-002` | `incidentDate.isAfter(reportDate)` |
| `RVR-003` | descriptionOfFact vazio |

**`updateActions(String newActions)`** — retorna nova instancia com `actionsTaken` normalizado.

### 2.4 PlacementRegistry

```dart
final class PlacementRegistry with Equatable {
  final String id;
  final PersonId memberId;
  final TimeStamp startDate;
  final TimeStamp? endDate;
  final String reason;
}
```

**`static Result<PlacementRegistry> create({String? id, ...})`:** `PLC-001` se `endDate.isBefore(startDate)`. Se `id` null, auto-gera `DateTime.now().microsecondsSinceEpoch.toString()`.

### 2.5 CollectiveSituations

```dart
final class CollectiveSituations with Equatable {
  final String? homeLossReport;
  final String? thirdPartyGuardReport;
}
```

### 2.6 SeparationChecklist

```dart
final class SeparationChecklist with Equatable {
  final bool adultInPrison;
  final bool adolescentInInternment;
}
```

### 2.7 PlacementHistory

```dart
final class PlacementHistory with Equatable {
  final PatientId familyId;
  final List<PlacementRegistry> individualPlacements;
  final CollectiveSituations collectiveSituations;
  final SeparationChecklist separationChecklist;
}
```

Construtor publico, sem validacao.
