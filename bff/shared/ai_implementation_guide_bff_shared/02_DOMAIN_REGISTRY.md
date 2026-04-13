# 02 - DOMAIN REGISTRY: Agregado Patient e VOs

> PersonalData, CivilDocuments, SocialIdentity, FamilyMember e Patient (aggregate root) — nucleo do bounded context Registry.

---

## 1. Enums

### 1.1 Sex

```dart
enum Sex { masculino, feminino, outro }
```

### 1.2 RequiredDocument

| Valor | `.value` | `.description` |
|-------|---------|----------------|
| `cn` | `CN` | Certidao de Nascimento |
| `rg` | `RG` | Registro Geral |
| `ctps` | `CTPS` | Carteira de Trabalho e Previdencia Social |
| `cpf` | `CPF` | Cadastro de Pessoa Fisica |
| `te` | `TE` | Titulo de Eleitor |

---

## 2. PersonalData

**Arquivo:** `domain/registry/registry_vos.dart`

```dart
final class PersonalData with Equatable {
  final String firstName;
  final String lastName;
  final String motherName;
  final String nationality;
  final Sex sex;
  final String? socialName;
  final TimeStamp birthDate;
  final String? phone;
}
```

**`static Result<PersonalData> create({..., TimeStamp? now})` — validacao:**

| Codigo | Campo | Condicao |
|--------|-------|----------|
| `PDT-001` | firstName | null/vazio apos `nullIfEmptyNormalized()` |
| `PDT-002` | lastName | null/vazio |
| `PDT-003` | motherName | null/vazio |
| `PDT-005` | nationality | null/vazio |
| `PDT-004` | birthDate | null |
| `PDT-004` | birthDate | apos `now` |

Campos texto armazenados via `normalize()`. `socialName` e `phone` via `nullIfEmptyNormalized()` / `nullIfEmptyTrimmed()`.

---

## 3. CivilDocuments

```dart
final class CivilDocuments with Equatable {
  final Cns? cns;
  final Cpf? cpf;
  final Nis? nis;
  final RgDocument? rgDocument;
}
```

**`static Result<CivilDocuments> create({...})` — validacao:**

| Codigo | Condicao |
|--------|----------|
| `CVD-001` | todos os 4 campos sao null |
| `CNS-006` | `cpf != null && cns?.cpf != null && cpf.value != cns.cpf.value` |

---

## 4. SocialIdentity

```dart
final class SocialIdentity with Equatable {
  final LookupId typeId;
  final String? otherDescription;
}
```

**`static Result<SocialIdentity> create({required LookupId typeId, String? otherDescription, bool isOtherType = false})` — validacao:**

| Codigo | Condicao |
|--------|----------|
| `SID-003` | `isOtherType == true` mas `otherDescription` null/vazio |

---

## 5. FamilyMember

**Arquivo:** `domain/registry/family_member.dart`

```dart
final class FamilyMember with Equatable {
  final PersonId personId;
  final LookupId relationshipId;
  final bool isPrimaryCaregiver;       // default: false
  final bool residesWithPatient;
  final bool hasDisability;            // default: false
  final List<RequiredDocument> requiredDocuments;  // default: const []
  final TimeStamp birthDate;
  // props: [personId] — igualdade por personId apenas
}
```

**`static Result<FamilyMember> create({...})`** — deduplica e ordena alfabeticamente `requiredDocuments` por `.value`.

**`static FamilyMember reconstitute({...})`** — pula dedup/sort.

**`copyWith({...})`** — todos os campos.

---

## 6. Patient (Aggregate Root)

**Arquivo:** `domain/registry/patient.dart`

```dart
final class Patient with Equatable {
  final PatientId id;
  final int version;                                    // default: 1
  final PersonId personId;
  final LookupId prRelationshipId;
  final PersonalData? personalData;
  final CivilDocuments? civilDocuments;
  final Address? address;
  final List<FamilyMember> familyMembers;               // default: const []
  final SocialIdentity? socialIdentity;
  final HousingCondition? housingCondition;
  final SocioEconomicSituation? socioeconomicSituation;
  final WorkAndIncome? workAndIncome;
  final EducationalStatus? educationalStatus;
  final HealthStatus? healthStatus;
  final CommunitySupportNetwork? communitySupportNetwork;
  final SocialHealthSummary? socialHealthSummary;
  final List<SocialCareAppointment> appointments;       // default: const []
  final List<Referral> referrals;                       // default: const []
  final List<RightsViolationReport> violationReports;   // default: const []
  final PlacementHistory? placementHistory;
  final IngressInfo? intakeInfo;
  final List<Diagnosis> diagnoses;                      // default: const []
  // props: [id] — igualdade por id apenas
}
```

Todas listas armazenadas como `List.unmodifiable(...)`.

**`static Result<Patient> create({...})` — invariantes:**

| Codigo | Condicao |
|--------|----------|
| `PAT-003` | `diagnoses.isEmpty` |
| `PAT-008` | nenhum membro com `relationshipId == prRelationshipId` |
| `PAT-009` | mais de um membro com `relationshipId == prRelationshipId` |

**`static Patient reconstitute({...})`** — sem verificacao de invariantes; usado para hidratacao do banco.

**`Patient copyWith({...})`** — todos campos opcionais usam `T? Function()? field` para null explicito.
