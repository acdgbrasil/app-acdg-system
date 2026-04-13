# 01 - DOMAIN KERNEL: Value Objects Cross-Cutting

> IDs UUID-based, documentos brasileiros (CPF, CNS, NIS, CEP, RG), Address e TimeStamp — todos com validacao via `Result<T>`.

---

## 1. Utils

### 1.1 StringNormalization (extension on String)

```dart
extension StringNormalization on String {
  String normalizedTrim();           // trim()
  String collapseWhitespace();       // regex \s+ → ' '
  String normalize();                // normalizedTrim().collapseWhitespace()
  String? nullIfEmptyTrimmed();      // trim; null se vazio
  String? nullIfEmptyNormalized();   // normalize; null se vazio
  String toSnakeCaseUpper();         // camelCase → SNAKE_CASE_UPPER
}
```

**`toSnakeCaseUpper` exemplos:**
- `homeVisit` → `HOME_VISIT`
- `masonry` → `MASONRY`

### 1.2 TimeStamp API Extensions

```dart
extension TimeStampApiExtensions on TimeStamp {
  String toIso8601();    // ISO8601 completo com Z (delega para toISOString())
  String toShortDate();  // YYYY-MM-DD (split no T)
}
```

### 1.3 AppError

```dart
enum ErrorCategory {
  domainRuleViolation, externalApiFailure, externalContractMismatch,
  crossLayerCommunicationFailure, dataConsistencyIncident,
  securityBoundaryViolation, infrastructureDependencyFailure,
  observabilityPipelineFailure, unexpectedSystemState, conflict
}

enum ErrorSeverity { debug, info, warning, error, critical }

class Observability with Equatable {
  final ErrorCategory category;
  final ErrorSeverity severity;
  final List<String> fingerprint;   // default: const []
  final Map<String, String> tags;   // default: const {}
}

class AppError implements Exception {
  final String id;                          // auto: DateTime.now().millisecondsSinceEpoch.toString()
  final String code;                        // ex: 'CPF-004'
  final String message;
  final String bc;                          // default: 'social-care'
  final String module;                      // ex: 'social-care/cpf'
  final String kind;                        // ex: 'domainValidation'
  final Map<String, dynamic> context;       // default: const {}
  final Map<String, dynamic> safeContext;   // default: const {}
  final Observability observability;
  final int? http;                          // ex: 422
  final String? stackTrace;
  final Object? cause;
}
```

**Igualdade:** por `id` OU `(code == && bc == && module ==)`.

---

## 2. IDs (UUID-based)

**Arquivo:** `domain/kernel/ids.dart`

Regex de validacao:
```dart
final _uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
```

**Validacao (`_validateUuid`):** normaliza via `normalizedTrim().toLowerCase()`, rejeita null/vazio/nao-UUID.

**Classe base:**
```dart
abstract class BaseUuid with Equatable {
  final String value;
  List<Object?> get props => [value];
  String toString() => value;
}
```

**Classes concretas:** todas seguem o padrao `final class XxxId extends BaseUuid` com `static Result<XxxId> create(String? rawValue)`.

| Classe | Codigo Erro | Modulo |
|--------|-------------|--------|
| `PersonId` | `PID-001` | `social-care/person-id` |
| `ProfessionalId` | `PRI-001` | `social-care/professional-id` |
| `PatientId` | `PAI-001` | `social-care/patient-id` |
| `LookupId` | `LID-001` | `social-care/lookup-id` |
| `AppointmentId` | `AI-001` | `social-care/appointment-id` |
| `ReferralId` | `RI-001` | `social-care/referral-id` |
| `ViolationReportId` | `VRI-001` | `social-care/violation-report-id` |

Todos falham com `http: 422`, `kind: 'invalidFormat'`, `category: domainRuleViolation`, `severity: error`.

---

## 3. CPF

**Arquivo:** `domain/kernel/cpf.dart`

### 3.1 FiscalRegion

```dart
enum FiscalRegion {
  region0,  // RS
  region1,  // DF, GO, MS, MT, TO
  region2,  // AC, AM, AP, PA, RO, RR
  region3,  // CE, MA, PI
  region4,  // AL, PB, PE, RN
  region5,  // BA, SE
  region6,  // MG
  region7,  // ES, RJ
  region8,  // SP
  region9,  // PR, SC
}
```

`static FiscalRegion fromDigit(int digit)` — mapeia digito 0-9 para a regiao.

### 3.2 Cpf

```dart
final class Cpf with Equatable {
  final String value;            // 11 digitos numericos
  String get baseNumber;         // value.substring(0,8)
  int get fiscalRegionDigit;     // value[8]
  FiscalRegion get fiscalRegion; // fromDigit(value[8])
  int get firstVerifierDigit;    // value[9]
  int get secondVerifierDigit;   // value[10]
  String get formatted;          // XXX.XXX.XXX-XX
}
```

**`static Result<Cpf> create(String? rawValue)` — cadeia de validacao:**

| Ordem | Codigo | Condicao | Severidade |
|-------|--------|----------|------------|
| 1 | `CPF-001` | null/vazio | warning |
| 2 | `CPF-005` | chars fora de `[\d.\-\s]` | warning |
| 3 | `CPF-001` | digitos vazios apos strip | warning |
| 4 | `CPF-002` | length != 11 | warning |
| 5 | `CPF-003` | todos digitos iguais | warning |
| 6 | `CPF-004` | check digit Mod11 falha | error |

**Algoritmo Mod11:** algoritmo padrao brasileiro com duplo verificador.

---

## 4. CNS

**Arquivo:** `domain/kernel/cns.dart`

```dart
final class Cns with Equatable {
  final String number;   // 15 digitos numericos
  final Cpf? cpf;        // CPF associado (opcional)
  final String? qrCode;  // QR code (opcional)
}
```

**`static Result<Cns> create({required String? number, Cpf? cpf, String? qrCode})` — validacao:**

| Ordem | Codigo | Condicao | Severidade |
|-------|--------|----------|------------|
| 1 | `CNS-001` | null/vazio | warning |
| 2 | `CNS-002` | digitos != 15 | warning |
| 3 | `CNS-003` | primeiro digito nao esta em `[1,2,7,8,9]` | warning |
| 4 | `CNS-005` | checksum falha | warning |

**Algoritmo de checksum (`_isValidCns`):**
- **Digitos 1-3:** baseado em PIS com pesos 15..5, logica de DV com remainder, possivel insercao de sufixo `001`
- **Digitos 7-9:** soma ponderada de 15 digitos deve ser divisivel por 11

---

## 5. NIS

**Arquivo:** `domain/kernel/nis.dart`

```dart
final class Nis with Equatable {
  final String value;      // 11 digitos numericos
  String get formatted;    // XXX.XXXXX.XX-X
}
```

**`static Result<Nis> create(String? rawValue)` — validacao:**

| Ordem | Codigo | Condicao |
|-------|--------|----------|
| 1 | `NIS-001` | null/vazio |
| 2 | `NIS-002` | length != 11 ou todos digitos iguais |
| 3 | `NIS-002` | Mod11 com pesos `[3,2,9,8,7,6,5,4,3,2]` falha |

---

## 6. CEP

**Arquivo:** `domain/kernel/cep.dart`

### 6.1 PostalRegion

```dart
enum PostalRegion { region0, region1, ..., region9 }
// fromDigit(int digit) — via index
```

### 6.2 DistributionKind

| Valor | Raw | Faixa Sufixo |
|-------|-----|--------------|
| `streetRange` | `STREET_RANGE` | 000-899 |
| `specialCodes` | `SPECIAL_CODES` | 900-959 |
| `promotional` | `PROMOTIONAL` | 960-969 |
| `postOfficeUnits` | `POST_OFFICE_UNITS` | 970-989, 999 |
| `other` | `OTHER` | restante |

### 6.3 Cep

```dart
final class Cep with Equatable {
  final String value;                   // 8 digitos numericos
  String get prefix;                    // value[0..4]
  String get suffix;                    // value[5..7]
  int get regionDigit;                  // value[0]
  PostalRegion get region;              // fromDigit
  DistributionKind get distributionKind;// do sufixo
  String get formatted;                 // XXXXX-XXX
}
```

**`static Result<Cep> create(String? rawValue)` — validacao:**

| Ordem | Codigo | Condicao |
|-------|--------|----------|
| 1 | `CEP-001` | null/vazio |
| 2 | `CEP-002` | chars invalidos (so `[\d\-\s]` permitido) |
| 3 | `CEP-003` | digitos != 8 |
| 4 | `CEP-004` | fora de qualquer faixa de estado |

**Faixas de estados (inteiro):**

| Estado(s) | Inicio | Fim |
|-----------|--------|-----|
| SP | 1000000 | 19999999 |
| RJ | 20000000 | 28999999 |
| ES | 29000000 | 29999999 |
| MG | 30000000 | 39999999 |
| BA | 40000000 | 48999999 |
| SE | 49000000 | 49999999 |
| PE | 50000000 | 56999999 |
| AL | 57000000 | 57999999 |
| PB | 58000000 | 58999999 |
| RN | 59000000 | 59999999 |
| CE | 60000000 | 63999999 |
| PI | 64000000 | 64999999 |
| MA | 65000000 | 65999999 |
| PA | 66000000 | 68899999 |
| AP | 68900000 | 68999999 |
| AM | (duas sub-faixas) | |
| RR | 69300000 | 69389999 |
| AC | 69900000 | 69999999 |
| DF | 70000000 | 73699999 |
| GO | 72800000 | 76799999 |
| TO | 77000000 | 77995999 |
| MT | 78000000 | 78899999 |
| RO | 78900000 | 78999999 |
| MS | 79000000 | 79999999 |
| PR | 80000000 | 87999999 |
| SC | 88000000 | 89999999 |
| RS | 90000000 | 99999999 |

---

## 7. RG Document

**Arquivo:** `domain/kernel/rg_document.dart`

```dart
final class RgDocument with Equatable {
  final String number;         // 8 digitos + 1 check digit (sem pontuacao)
  final String issuingState;   // UF 2 letras (uppercase)
  final String issuingAgency;  // ex: SSP (uppercase)
  final TimeStamp issueDate;
  String get formattedNumber;  // XXXXXXXX-X
}
```

**Estados validos (27):** AC, AL, AP, AM, BA, CE, DF, ES, GO, MA, MT, MS, MG, PA, PB, PR, PE, PI, RJ, RN, RS, RO, RR, SC, SP, SE, TO

**`static Result<RgDocument> create({...}, TimeStamp? now)` — validacao:**

| Ordem | Codigo | Condicao |
|-------|--------|----------|
| 1 | `RGD-001` | number vazio |
| 2 | `RGD-005` | formato nao e `^[0-9]{8}[0-9X]$` |
| 3 | `RGD-006` | check digit Mod11 invalido |
| 4 | `RGD-002` | estado fora do set valido |
| 5 | `RGD-003` | agency vazio |
| 6 | `RGD-004` | issueDate null ou futuro |

**Algoritmo check digit:** pesos `[2,3,4,5,6,7,8,9]` nos 8 digitos base, `sum % 11`:
- remainder 0 → `'0'`
- remainder 1 → `'X'`
- else → `(11 - remainder).toString()`

---

## 8. Address

**Arquivo:** `domain/kernel/address.dart`

```dart
enum ResidenceLocation { urbano, rural }

final class Address with Equatable {
  final Cep? cep;
  final String state;
  final String city;
  final String? street;
  final String? neighborhood;
  final String? number;
  final String? complement;
  final ResidenceLocation residenceLocation;
  final bool isShelter;
  final bool isHomeless;   // default: false
}
```

**`static Result<Address> create({...})` — validacao:**

| Codigo | Condicao |
|--------|----------|
| `ADR-002` | state vazio |
| `ADR-003` | state fora do set de 27 UFs |
| `ADR-004` | city vazio apos normalizacao |

Campos opcionais armazenados via `nullIfEmptyNormalized()`.

**`Address copyWith({...})`** — campos opcionais usam `T? Function()? field` para null explicito.

---

## 9. TimeStamp

**Arquivo:** `domain/kernel/time_stamp.dart`

```dart
final class TimeStamp with Equatable implements Comparable<TimeStamp> {
  final DateTime date;              // sempre UTC
  static TimeStamp get now;        // DateTime.now().toUtc()
  int get year, month, day, hour, minute, second;  // delega para date
}
```

| Metodo | Assinatura | Comportamento |
|--------|-----------|---------------|
| `fromDate` | `static Result<TimeStamp> fromDate(DateTime? date)` | `TS-001` se null |
| `fromIso` | `static Result<TimeStamp> fromIso(String iso)` | parse ISO8601, `TS-001` em erro de parse |
| `isSameDay` | `bool isSameDay(TimeStamp other)` | compara year/month/day em UTC |
| `yearsAt` | `int yearsAt({TimeStamp? referenceDate})` | anos completos, default = now |
| `toISOString` | `String toISOString()` | `yyyy-MM-dd'T'HH:mm:ss.SSSZ` (UTC) |
| `compareTo` | `int compareTo(TimeStamp other)` | delega para `date.compareTo` |

---

## 10. LookupItem

**Arquivo:** `domain/models/lookup.dart`

```dart
final class LookupItem with Equatable {
  final String id;
  final String codigo;
  final String descricao;
  // props: [id, codigo, descricao]
  LookupItem copyWith({String? id, String? codigo, String? descricao});
}
```

---

## 11. AuditEvent

**Arquivo:** `domain/audit/audit_event.dart`

```dart
final class AuditEvent with Equatable {
  final String id;
  final String aggregateId;
  final String eventType;
  final String? actorId;
  final Map<String, dynamic> payload;
  final TimeStamp occurredAt;
  final TimeStamp recordedAt;
  // props: [id] — igualdade por id apenas
  static AuditEvent reconstitute({...}); // factory sem validacao
}
```

---

## 12. Registro Completo de Codigos de Erro

| Codigo | Dominio | Significado |
|--------|---------|-------------|
| `PID-001` | PersonId | UUID invalido |
| `PRI-001` | ProfessionalId | UUID invalido |
| `PAI-001` | PatientId | UUID invalido |
| `LID-001` | LookupId | UUID invalido |
| `AI-001` | AppointmentId | UUID invalido |
| `RI-001` | ReferralId | UUID invalido |
| `VRI-001` | ViolationReportId | UUID invalido |
| `CPF-001..005` | Cpf | vazio, length, todos iguais, verifier, chars invalidos |
| `CNS-001..005` | Cns | vazio, length, primeiro digito, checksum |
| `CNS-006` | CivilDocuments | CPF/CNS mismatch |
| `NIS-001..002` | Nis | vazio, length/mod11 |
| `CEP-001..004` | Cep | vazio, chars, length, faixa estado |
| `RGD-001..006` | RgDocument | vazio, estado, agency, data, formato, check digit |
| `ADR-002..004` | Address | estado vazio, estado invalido, cidade vazia |
| `TS-001` | TimeStamp | null ou ISO invalido |
| `PDT-001..005` | PersonalData | firstName, lastName, motherName, birthDate, nationality |
| `CVD-001` | CivilDocuments | nenhum documento |
| `SID-003` | SocialIdentity | tipo outro sem descricao |
| `HC-001..004` | HousingCondition | contagens negativas, quartos > comodos |
| `SB-001..002` | SocialBenefit | nome vazio, valor zero |
| `SBC-002` | SocialBenefitsCollection | nome duplicado |
| `SES-001..006` | SocioEconomicSituation | inconsistencia, fonte vazia, renda negativa, per capita > total |
| `CSN-001..002` | CommunitySupportNetwork | whitespace-only, >300 chars |
| `SHS-001` | SocialHealthSummary | item vazio em functional deps |
| `WI-001` | WorkIncomeVO | monthlyAmount negativo |
| `ICD-001..002` | IcdCode | vazio, ponto ausente |
| `DIA-001..003` | Diagnosis | data null/futuro, ano negativo, descricao vazia |
| `ING-001` | IngressInfo | serviceReason vazio |
| `SCA-001,003..005` | Appointment | data futura, vazio, summary >500, plan >2000 |
| `REF-001..003` | Referral | data futura, motivo vazio, transicao invalida |
| `RVR-001..003` | ViolationReport | reportDate futuro, incidente apos report, descricao vazia |
| `PLC-001` | PlacementRegistry | endDate antes de startDate |
| `PAT-003,008,009` | Patient | sem diagnosticos, sem PR, multiplos PR |
