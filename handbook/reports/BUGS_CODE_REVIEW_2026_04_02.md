# Bugs — Code Review 2026-04-02

Achados validados a partir do code review da migração Isar→Drift + PatientDetailResult.
Todos os bugs foram cruzados com os contratos em `contracts/services/social-care/model/schemas/`.

---

## BUG-1: Referrals mapeados para objeto vazio (HIGH)

**Arquivos:**
- `packages/social_care/lib/src/data/repositories/bff_patient_repository.dart:256-258`
- `packages/social_care/testing/fakes/in_memory_patient_repository.dart:499-500`

**Problema:** `patient.referrals.map((r) => ReferralDetail.fromJson(const {}))` descarta todos os campos. A UI não consegue exibir nenhum detalhe de encaminhamento.

**Campos perdidos (contrato PatientResponse.yaml):**
- `id` (Uuid)
- `date` (IsoDate)
- `professionalId` (Uuid)
- `referredPersonId` (Uuid)
- `destinationService` (enum: CRAS, CREAS, HEALTH_CARE, EDUCATION, LEGAL, OTHER)
- `reason` (string)
- `status` (enum: PENDING, COMPLETED, CANCELLED)

**Correção:**
```dart
referrals: patient.referrals
    .map((r) => ReferralDetail.fromJson({
          'id': r.id.value,
          'date': r.date.toIso8601(),
          'professionalId': r.requestingProfessionalId.value,
          'referredPersonId': r.referredPersonId.value,
          'destinationService': r.destinationService.name.toSnakeCaseUpper(),
          'reason': r.reason,
          'status': r.status.name.toSnakeCaseUpper(),
        }))
    .toList(),
```

**Nota:** Enums devem usar `toSnakeCaseUpper()` para alinhar com o contrato (SCREAMING_SNAKE).

---

## BUG-2: Violation reports mapeados para objeto vazio (HIGH)

**Arquivos:**
- `packages/social_care/lib/src/data/repositories/bff_patient_repository.dart:259-261`
- `packages/social_care/testing/fakes/in_memory_patient_repository.dart:501-503`

**Problema:** `patient.violationReports.map((v) => ViolationReportDetail.fromJson(const {}))` descarta todos os campos.

**Campos perdidos (contrato PatientResponse.yaml):**
- `id` (Uuid)
- `reportDate` (IsoDate)
- `incidentDate` (IsoDate, nullable)
- `victimId` (Uuid)
- `violationType` (enum: NEGLECT, PSYCHOLOGICAL_VIOLENCE, PHYSICAL_VIOLENCE, SEXUAL_ABUSE, SEXUAL_EXPLOITATION, CHILD_LABOR, FINANCIAL_EXPLOITATION, DISCRIMINATION, OTHER)
- `descriptionOfFact` (string)
- `actionsTaken` (string, nullable)

**Campo extra no domain (não no contrato response mas usado internamente):**
- `violationTypeId` (LookupId, nullable)

**Correção:**
```dart
violationReports: patient.violationReports
    .map((v) => ViolationReportDetail.fromJson({
          'id': v.id.value,
          'reportDate': v.reportDate.toIso8601(),
          'incidentDate': v.incidentDate?.toIso8601(),
          'victimId': v.victimId.value,
          'violationType': v.violationType.name.toSnakeCaseUpper(),
          'violationTypeId': v.violationTypeId?.value,
          'descriptionOfFact': v.descriptionOfFact,
          'actionsTaken': v.actionsTaken,
        }))
    .toList(),
```

---

## BUG-3: Cálculo de idade impreciso (MEDIUM)

**Arquivo:** `packages/social_care/lib/src/data/repositories/bff_patient_repository.dart:349`

**Problema:**
```dart
int age(DateTime birth) => now.year - birth.year;
```
Não verifica se o aniversário já ocorreu no ano corrente. Alguém nascido em dezembro aparece 1 ano mais velho em janeiro. Afeta analytics de perfil etário (faixas 0-6, 7-14, etc.).

**Correção:**
```dart
int age(DateTime birth) {
  int a = now.year - birth.year;
  if (now.month < birth.month ||
      (now.month == birth.month && now.day < birth.day)) {
    a--;
  }
  return a;
}
```

---

## BUG-4: FichaStatus com nome errado (MEDIUM)

**Arquivo:** `packages/social_care/lib/src/ui/home/models/ficha_status.dart:50-52`

**Problema:**
```dart
FichaStatus(
  name: 'Serviços e programas de convivência comunitária',
  filled: detail.housingCondition != null,
),
```
O nome diz "convivência comunitária" mas o campo é `housingCondition`. O contrato define `housingCondition` como condições de habitação (tipo, material, cômodos, água, esgoto, etc.).

**Correção:**
```dart
FichaStatus(
  name: 'Condições habitacionais da família',
  filled: detail.housingCondition != null,
),
```

---

## Observação sobre ReferralDetail / ViolationReportDetail

Ambas as classes de UI model (`referral_detail.dart`, `violation_report_detail.dart`) são apenas wrappers de `Map<String, dynamic>` sem getters tipados:

```dart
final class ReferralDetail {
  const ReferralDetail._fromJson(this._json);
  final Map<String, dynamic> _json;
  factory ReferralDetail.fromJson(Map<String, dynamic> json) => ReferralDetail._fromJson(json);
}
```

Quando essas fichas forem implementadas na UI, será necessário adicionar getters tipados (ex: `String get reason => _json['reason'] ?? ''`). Mas o mapeamento correto dos dados no repository é pré-requisito — sem ele, os getters retornariam sempre valores default.
