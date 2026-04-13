# 03 - DOMAIN ASSESSMENT: Value Objects de Avaliacao

> HousingCondition, SocioEconomicSituation, WorkAndIncome, EducationalStatus, HealthStatus, CommunitySupportNetwork, SocialHealthSummary.

---

## 1. Housing Condition

**Arquivo:** `domain/assessment/assessment_vos.dart`

### 1.1 Enums de Habitacao

```dart
enum ConditionType { owned, rented, ceded, squatted }
enum WallMaterial { masonry, finishedWood, makeshiftMaterials }
enum WaterSupply { publicNetwork, wellOrSpring, rainwaterHarvest, waterTruck, other }
enum ElectricityAccess { meteredConnection, irregularConnection, noAccess }
enum SewageDisposal { publicSewer, septicTank, rudimentaryPit, openSewage, noBathroom }
enum WasteCollection { directCollection, indirectCollection, noCollection }
enum AccessibilityLevel { fullyAccessible, partiallyAccessible, notAccessible }
```

### 1.2 HousingCondition

```dart
final class HousingCondition with Equatable {
  final ConditionType type;
  final WallMaterial wallMaterial;
  final int numberOfRooms;
  final int numberOfBedrooms;
  final int numberOfBathrooms;
  final WaterSupply waterSupply;
  final bool hasPipedWater;
  final ElectricityAccess electricityAccess;
  final SewageDisposal sewageDisposal;
  final WasteCollection wasteCollection;
  final AccessibilityLevel accessibilityLevel;
  final bool isInGeographicRiskArea;
  final bool hasDifficultAccess;
  final bool isInSocialConflictArea;
  final bool hasDiagnosticObservations;
}
```

**`static Result<HousingCondition> create({...})` — validacao:**

| Codigo | Condicao | Modulo |
|--------|----------|--------|
| `HC-001` | `numberOfRooms < 0` | `social-care/housing-condition` |
| `HC-002` | `numberOfBedrooms < 0` | |
| `HC-003` | `numberOfBathrooms < 0` | |
| `HC-004` | `numberOfBedrooms > numberOfRooms` | |

---

## 2. SocialBenefit

```dart
final class SocialBenefit with Equatable {
  final String benefitName;
  final LookupId benefitTypeId;
  final double amount;
  final PersonId beneficiaryId;
  final String? birthCertificateNumber;
  final Cpf? deceasedCpf;
}
```

**`static Result<SocialBenefit> create({...})` — validacao:**

| Codigo | Condicao | Modulo |
|--------|----------|--------|
| `SB-001` | benefitName vazio | `social-care/social-benefit` |
| `SB-002` | `amount <= 0` | |

### 2.1 SocialBenefitsCollection

```dart
final class SocialBenefitsCollection with Equatable {
  final List<SocialBenefit> items;  // unmodifiable
  bool get isEmpty;
  int get count;
  double get totalAmount;
}
```

**`static Result<SocialBenefitsCollection> create(List<SocialBenefit> items)`:**
- `SBC-002` se nomes de beneficio duplicados.

---

## 3. SocioEconomicSituation

```dart
final class SocioEconomicSituation with Equatable {
  final double totalFamilyIncome;
  final double incomePerCapita;
  final bool receivesSocialBenefit;
  final SocialBenefitsCollection socialBenefits;
  final String mainSourceOfIncome;
  final bool hasUnemployed;
}
```

**`static Result<SocioEconomicSituation> create({...})` — validacao:**

| Codigo | Condicao |
|--------|----------|
| `SES-003` | `totalFamilyIncome < 0` |
| `SES-004` | `incomePerCapita < 0` |
| `SES-006` | `incomePerCapita > totalFamilyIncome` |
| `SES-005` | `mainSourceOfIncome` vazio |
| `SES-001` | `!receivesSocialBenefit && !socialBenefits.isEmpty` |
| `SES-002` | `receivesSocialBenefit && socialBenefits.isEmpty` |

**Modulo:** `social-care/socio-economic`

---

## 4. WorkAndIncome

**Arquivo:** `domain/assessment/work_and_income.dart`

### 4.1 WorkIncomeVO

```dart
final class WorkIncomeVO with Equatable {
  final PersonId memberId;
  final LookupId occupationId;
  final bool hasWorkCard;
  final double monthlyAmount;
}
```

**`static Result<WorkIncomeVO> create({...})`:** `WI-001` se `monthlyAmount < 0`. Modulo: `social-care/work-income`.

### 4.2 WorkAndIncome

```dart
final class WorkAndIncome with Equatable {
  final PatientId familyId;
  final List<WorkIncomeVO> individualIncomes;
  final List<SocialBenefit> socialBenefits;
  final bool hasRetiredMembers;
}
```

Construtor publico, sem validacao.

---

## 5. EducationalStatus

**Arquivo:** `domain/assessment/educational_status.dart`

### 5.1 MemberEducationalProfile

```dart
final class MemberEducationalProfile with Equatable {
  final PersonId memberId;
  final bool canReadWrite;
  final bool attendsSchool;
  final LookupId educationLevelId;
}
```

### 5.2 ProgramOccurrence

```dart
final class ProgramOccurrence with Equatable {
  final PersonId memberId;
  final TimeStamp date;
  final LookupId effectId;
  final bool isSuspensionRequested;
}
```

### 5.3 EducationalStatus

```dart
final class EducationalStatus with Equatable {
  final PatientId familyId;
  final List<MemberEducationalProfile> memberProfiles;
  final List<ProgramOccurrence> programOccurrences;
}
```

Construtor publico, sem validacao.

---

## 6. HealthStatus

**Arquivo:** `domain/assessment/health_status.dart`

### 6.1 MemberDeficiency

```dart
final class MemberDeficiency with Equatable {
  final PersonId memberId;
  final LookupId deficiencyTypeId;
  final bool needsConstantCare;
  final String? responsibleCaregiverName;
}
```

### 6.2 PregnantMember

```dart
final class PregnantMember with Equatable {
  final PersonId memberId;
  final int monthsGestation;
  final bool startedPrenatalCare;
}
```

### 6.3 HealthStatus

```dart
final class HealthStatus with Equatable {
  final PatientId familyId;
  final List<MemberDeficiency> deficiencies;
  final List<PregnantMember> gestatingMembers;
  final List<PersonId> constantCareNeeds;
  final bool foodInsecurity;
}
```

Construtor publico, sem validacao.

---

## 7. CommunitySupportNetwork

**Arquivo:** `domain/assessment/community_support.dart`

```dart
final class CommunitySupportNetwork with Equatable {
  final bool hasRelativeSupport;
  final bool hasNeighborSupport;
  final String familyConflicts;
  final bool patientParticipatesInGroups;
  final bool familyParticipatesInGroups;
  final bool patientHasAccessToLeisure;
  final bool facesDiscrimination;
}
```

**`static Result<CommunitySupportNetwork> create({...})` — validacao:**

| Codigo | Condicao | Modulo |
|--------|----------|--------|
| `CSN-001` | `familyConflicts` nao-null mas colapsa para vazio (whitespace-only) | `social-care/community-support` |
| `CSN-002` | `familyConflicts.length > 300` | |

---

## 8. SocialHealthSummary

**Arquivo:** `domain/assessment/social_health_summary.dart`

```dart
final class SocialHealthSummary with Equatable {
  final bool requiresConstantCare;
  final bool hasMobilityImpairment;
  final List<String> functionalDependencies;  // unmodifiable
  final bool hasRelevantDrugTherapy;
}
```

**`static Result<SocialHealthSummary> create({...})` — validacao:**

| Codigo | Condicao | Modulo |
|--------|----------|--------|
| `SHS-001` | qualquer item em `functionalDependencies` vazio apos `normalizedTrim()` | `social-care/social-health-summary` |

**Deduplicacao:** preserva ordem de insercao, pula duplicatas case-sensitive.
