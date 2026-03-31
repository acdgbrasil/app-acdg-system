# Plano: Refatorar Fluxo de Detalhe do Paciente (getPatient)

## 1. Contexto e Motivacao

### O que ja foi feito (listagem)
Na sessao de 2026-03-31 refatoramos o fluxo de listagem end-to-end:
```
BFF Contract → PatientService (wrapper) → BffPatientRepository (JSON → ApiModel → PatientSummary) → ListPatientsUseCase (orquestra) → HomeViewModel (Command0, so estado)
```
Cada camada faz exatamente seu papel. Dado entra cru pelo Service e sai tipado do Repository.

### O problema atual (detalhe)
O fluxo de detalhe NAO segue esse padrao:
```
SocialCareContract.getPatient() → Patient (domain)
  → BffPatientRepository (pass-through, retorna Patient domain)
    → GetPatientUseCase (pass-through, retorna Patient domain)
      → HomeViewModel._selectPatient() (FAZ MAPPING aqui — PatientDetail.fromPatient + FichaStatus.fromPatient)
```

**Violacoes:**
1. **ViewModel faz mapping** — `PatientDetail.fromPatient(value)` e `FichaStatus.fromPatient(value)` acontecem na ViewModel (linha 61-62 de home_view_model.dart)
2. **Domain vaza na UI** — `patient_detail.dart` importa `package:shared/shared.dart` para o factory `fromPatient(Patient)`
3. **FichaStatus depende de domain** — `ficha_status.dart` importa `package:shared/shared.dart` e recebe `Patient` domain
4. **PatientService incompleto** — so tem `listPatients()`, nao tem `getPatient()`
5. **Repository e pass-through** — `BffPatientRepository.getPatient()` so delega pra `_bff.getPatient(id)` sem nenhum mapping
6. **UseCase e pass-through** — `GetPatientUseCase` recebe `PatientId` (domain VO) e retorna `Patient` (domain) sem orquestrar nada

### Contratos atualizados (v3.0.0)
Os contratos definem schemas canonicos que sao a fonte de verdade:
- `PatientResponse.yaml` — schema completo do GET /patients/:id
- `PatientSummaryResponse.yaml` — schema do GET /patients (listagem)
- Enums em SCREAMING_SNAKE_CASE (OWNED, MASONRY, PUBLIC_NETWORK, etc.)
- `StandardResponse.yaml` — envelope `{ data, meta: { timestamp } }`
- Validation rules por bounded context com error codes

### Objetivo
Aplicar o mesmo padrao da listagem ao detalhe, respeitando os contratos:
```
SocialCareContract.getPatient() → Patient (domain, nao muda)
  → PatientService.getPatient() (wrapper puro, novo)
    → BffPatientRepository.getPatient() (mapeia Patient → PatientDetailResult, refatorado)
      → GetPatientUseCase (orquestra, aceita String, retorna PatientDetailResult, refatorado)
        → HomeViewModel (Command1, so estado, zero imports de domain)
```

---

## 2. Fluxo Alvo Detalhado

### Diagrama de sequencia
```
[View] — select.execute("uuid-string") →
  [HomeViewModel] — _selectPatient("uuid-string") →
    [Command1<void, String>] — gerencia running/error/completed →
      [GetPatientUseCase] — execute("uuid-string") →
        cria PatientId.create(string) internamente
        chama _patientRepository.getPatient(patientId)
          [BffPatientRepository] — getPatient(PatientId) →
            chama _patientService.getPatient(patientId)
              [PatientService] — getPatient(PatientId) →
                chama _bff.getPatient(patientId)
                  [SocialCareContract / OfflineFirstRepository] →
                    online? → remote (HTTP GET /patients/:id → PatientMapper.fromJson → Patient)
                    offline? → local (Isar → PatientMapper.fromJson → Patient)
                  ← Patient domain
                ← Result<Patient>
              ← Result<Patient>
            mapeia Patient → PatientDetail (move logica de fromPatient pra ca)
            deriva FichaStatus.fromDetail(patientDetail)
            empacota em PatientDetailResult(patientDetail, fichas)
          ← Result<PatientDetailResult>
        ← Result<PatientDetailResult>
      ← Result<PatientDetailResult>
    ViewModel so faz:
      detailPanelState.patientDetail.value = value.patientDetail
      detailPanelState.fichas.value = value.fichas
  [View] — escuta select (ChangeNotifier) para running/error
```

### Responsabilidade por camada

| Camada | Responsabilidade no detalhe | O que NAO faz |
|--------|---------------------------|---------------|
| **View** | Chama `select.execute(id)`, escuta `select.running` | Nao mapeia, nao cria IDs |
| **ViewModel** | Atribui `patientDetail` e `fichas` ao state, toggle do painel | Nao mapeia domain→UI, nao importa shared |
| **UseCase** | Cria `PatientId` do String, delega pro repository | Nao mapeia Patient→PatientDetail |
| **Repository** | Chama service, mapeia `Patient→PatientDetail`, deriva fichas | Nao faz HTTP, nao gerencia cache |
| **Service** | Wrapper puro: chama `_bff.getPatient(id)` | Nao mapeia, nao trata erro |
| **BFF Contract** | Retorna `Patient` domain (via offline-first ou remote) | Nao muda |

---

## 3. Passos de Implementacao

### Passo 1: Adicionar `getPatient` ao PatientService

**Arquivo:** `packages/social_care/lib/src/data/services/patient_service.dart`

**Estado atual:**
```dart
class PatientService {
  PatientService({required SocialCareContract bff}) : _bff = bff;
  final SocialCareContract _bff;

  Future<Result<List<Map<String, dynamic>>>> listPatients() {
    return _bff.listPatients();
  }
}
```

**Adicionar:**
```dart
Future<Result<Patient>> getPatient(PatientId id) {
  return _bff.getPatient(id);
}
```

**Imports necessarios:** `PatientId` e `Patient` ja vem de `package:shared/shared.dart` (ja importado).

**Por que:** O service e o gateway unico para o BFF. O repository deve chamar o service, nao o BFF diretamente.

---

### Passo 2: Criar `PatientDetailResult`

**Novo arquivo:** `packages/social_care/lib/src/ui/home/models/patient_detail_result.dart`

**Conteudo:**
```dart
import 'ficha_status.dart';
import 'patient_detail.dart';

/// Bundles the patient detail and ficha status for a single getPatient call.
final class PatientDetailResult {
  final PatientDetail patientDetail;
  final List<FichaStatus> fichas;

  const PatientDetailResult({
    required this.patientDetail,
    required this.fichas,
  });
}
```

**Por que:** O repository precisa retornar ambos (`PatientDetail` + `List<FichaStatus>`) de uma unica chamada. Sem esse VO, precisariamos de duas chamadas ou de o ViewModel montar o `FichaStatus` (que e exatamente o que queremos eliminar).

---

### Passo 3: Refatorar `FichaStatus` para usar `PatientDetail`

**Arquivo:** `packages/social_care/lib/src/ui/home/models/ficha_status.dart`

**Estado atual:**
```dart
import 'package:shared/shared.dart';  // ← LEAK: domain na UI

final class FichaStatus {
  // ...
  static List<FichaStatus> fromPatient(Patient patient) {
    return [
      FichaStatus(name: 'Composição familiar', filled: patient.familyMembers.isNotEmpty),
      FichaStatus(name: 'Acesso a benefícios eventuais', filled: patient.socioeconomicSituation != null),
      // ... 8 mais
    ];
  }
}
```

**Refatorar para:**
```dart
import 'patient_detail.dart';  // ← UI model, sem domain

final class FichaStatus {
  // ...
  static List<FichaStatus> fromDetail(PatientDetail detail) {
    return [
      FichaStatus(name: 'Composição familiar', filled: detail.familyMembers.isNotEmpty),
      FichaStatus(name: 'Acesso a benefícios eventuais', filled: detail.socioeconomicSituation != null),
      FichaStatus(name: 'Condições de saúde da família', filled: detail.healthStatus != null),
      FichaStatus(name: 'Convivência familiar e comunitária', filled: detail.communitySupportNetwork != null),
      FichaStatus(name: 'Condições educacionais da família', filled: detail.educationalStatus != null),
      FichaStatus(name: 'Situações de violência e violação de direitos', filled: detail.violationReports.isNotEmpty),
      FichaStatus(name: 'Condições de trabalho e rendimento da família', filled: detail.workAndIncome != null),
      FichaStatus(name: 'Especificidades sociais, étnicas ou culturais', filled: detail.socialIdentity != null),
      FichaStatus(name: 'Forma de ingresso e motivo do primeiro atendimento', filled: detail.intakeInfo != null),
      FichaStatus(name: 'Serviços e programas de convivência comunitária', filled: detail.housingCondition != null),
    ];
  }
}
```

**Mapeamento 1:1:**
| `Patient` (domain) | `PatientDetail` (UI) | Funciona? |
|--------------------|-----------------------|-----------|
| `patient.familyMembers.isNotEmpty` | `detail.familyMembers.isNotEmpty` | Sim — ambos sao `List` |
| `patient.socioeconomicSituation != null` | `detail.socioeconomicSituation != null` | Sim — ambos nullable |
| `patient.healthStatus != null` | `detail.healthStatus != null` | Sim |
| `patient.communitySupportNetwork != null` | `detail.communitySupportNetwork != null` | Sim |
| `patient.educationalStatus != null` | `detail.educationalStatus != null` | Sim |
| `patient.violationReports.isNotEmpty` | `detail.violationReports.isNotEmpty` | Sim |
| `patient.workAndIncome != null` | `detail.workAndIncome != null` | Sim |
| `patient.socialIdentity != null` | `detail.socialIdentity != null` | Sim |
| `patient.intakeInfo != null` | `detail.intakeInfo != null` | Sim |
| `patient.housingCondition != null` | `detail.housingCondition != null` | Sim |

**Impacto:** Remove `import 'package:shared/shared.dart'` — domain nao vaza mais na UI.

---

### Passo 4: Alterar retorno de `PatientRepository.getPatient()`

**Arquivo:** `packages/social_care/lib/src/data/repositories/patient_repository.dart`

**De:**
```dart
Future<Result<Patient>> getPatient(PatientId id);
```

**Para:**
```dart
Future<Result<PatientDetailResult>> getPatient(PatientId id);
```

**Import adicional:** `PatientDetailResult` do `ui/home/models/`.

**Nota:** Apenas `getPatient` muda. Os metodos de escrita (`addFamilyMember`, `updateHousingCondition`, etc.) continuam aceitando domain types pois enviam dados PARA o BFF.

---

### Passo 5: Refatorar `BffPatientRepository.getPatient()`

**Arquivo:** `packages/social_care/lib/src/data/repositories/bff_patient_repository.dart`

**Estado atual (pass-through):**
```dart
@override
Future<Result<Patient>> getPatient(PatientId id) {
  return _bff.getPatient(id);
}
```

**Refatorar para (com mapping):**
```dart
@override
Future<Result<PatientDetailResult>> getPatient(PatientId id) async {
  final result = await _patientService.getPatient(id);

  return switch (result) {
    Success(:final value) => Success(_toDetailResult(value)),
    Failure(:final error) => Failure(error),
  };
}

PatientDetailResult _toDetailResult(Patient patient) {
  final detail = _toPatientDetail(patient);
  return PatientDetailResult(
    patientDetail: detail,
    fichas: FichaStatus.fromDetail(detail),
  );
}
```

O metodo `_toPatientDetail(Patient)` contera a logica que hoje esta em `PatientDetail.fromPatient()`:
- Extrai `personalData` → `PersonalDataDetail`
- Extrai `civilDocuments` → `CivilDocumentsDetail` (cpf.formatted, nis.value, etc.)
- Extrai `address` → `AddressDetail` (cep.formatted, residenceLocation.name, etc.)
- Extrai `socialIdentity` → `SocialIdentityDetail`
- Extrai `intakeInfo` → `IntakeInfoDetail`
- Mapeia listas: `familyMembers`, `diagnoses`, `appointments`, `referrals`, `violationReports`
- Computa `ComputedAnalyticsDetail` (ageProfile a partir de familyMembers)

**Alinhamento com contratos (enums SCREAMING_SNAKE_CASE):**
O `PatientMapper.fromJson()` no BFF remote converte JSON do server → domain enums Dart (camelCase). Ao mapear domain → UI strings no repository, usamos `.name` que retorna camelCase. Nossas UI models armazenam strings que vem do domain ou do `fromJson()` (que le direto do server em SCREAMING_SNAKE). Para consistencia, o repository devera usar o mesmo formato que o `PatientMapper.toJson()` usa ao serializar — que e `.name.toSnakeCaseUpper()` (SCREAMING_SNAKE).

Exemplo:
```dart
// No mapping do repository:
type: patient.housingCondition!.type.name,  // camelCase do Dart enum
// OU alinhado com contrato:
type: patient.housingCondition!.type.name.toSnakeCaseUpper(),  // SCREAMING_SNAKE
```

**Decisao:** Usar camelCase (`.name`) pois e consistente com o domain Dart e nao quebra os mappers UI→Intent que usam `.values.byName()`. Se o `fromJson()` receber SCREAMING_SNAKE do server, ele guarda como veio. Se vier do domain (via repository), guarda em camelCase. Ambos sao validos como strings.

---

### Passo 6: Refatorar `GetPatientUseCase`

**Arquivo:** `packages/social_care/lib/src/logic/use_case/registry/get_patient_use_case.dart`

**Estado atual:**
```dart
class GetPatientUseCase extends BaseUseCase<PatientId, Patient> {
  @override
  Future<Result<Patient>> execute(PatientId id) {
    return _patientRepository.getPatient(id);
  }
}
```

**Refatorar para:**
```dart
class GetPatientUseCase extends BaseUseCase<String, PatientDetailResult> {
  @override
  Future<Result<PatientDetailResult>> execute(String patientId) async {
    final id = PatientId.create(patientId);
    if (id.isFailure) return Failure((id as Failure).error);

    return _patientRepository.getPatient(id.valueOrNull!);
  }
}
```

**Mudancas:**
- Input: `PatientId` → `String` (cria `PatientId` internamente)
- Output: `Patient` → `PatientDetailResult`
- Logica: valida e converte o string para PatientId — orquestra

**Por que `String` como input:** A ViewModel nao deve saber criar `PatientId` (VO de domain). O UseCase encapsula essa responsabilidade. A ViewModel so passa o string que recebeu da View.

---

### Passo 7: Simplificar `HomeViewModel._selectPatient()`

**Arquivo:** `packages/social_care/lib/src/ui/home/viewModel/home_view_model.dart`

**Estado atual:**
```dart
Future<Result<void>> _selectPatient(String patientId) async {
  detailPanelState.selectPatient(patientId);
  if (detailPanelState.selectedPatientId.value == null) return const Success(null);

  final id = PatientId.create(patientId);        // ← domain VO na ViewModel
  if (id.isFailure) return const Success(null);

  final result = await _getPatientUseCase.execute(id.valueOrNull!);  // ← passa PatientId
  if (detailPanelState.selectedPatientId.value != patientId) return const Success(null);

  if (result case Success(:final value)) {
    detailPanelState.patientDetail.value = PatientDetail.fromPatient(value);  // ← MAPPING
    detailPanelState.fichas.value = FichaStatus.fromPatient(value);           // ← MAPPING
    return const Success(null);
  }
  return Failure((result as Failure).error);
}
```

**Refatorar para:**
```dart
Future<Result<void>> _selectPatient(String patientId) async {
  detailPanelState.selectPatient(patientId);
  if (detailPanelState.selectedPatientId.value == null) return const Success(null);

  final result = await _getPatientUseCase.execute(patientId);  // ← passa String
  if (detailPanelState.selectedPatientId.value != patientId) return const Success(null);

  if (result case Success(:final value)) {
    detailPanelState.patientDetail.value = value.patientDetail;  // ← ja pronto
    detailPanelState.fichas.value = value.fichas;                 // ← ja pronto
    return const Success(null);
  }
  return Failure((result as Failure).error);
}
```

**Removidos:**
- `import 'package:shared/shared.dart'` — nao precisa mais de `PatientId`
- `PatientDetail.fromPatient()` — mapping foi pro repository
- `FichaStatus.fromPatient()` — fichas ja vem prontas no `PatientDetailResult`

---

### Passo 8: Limpar `PatientDetail`

**Arquivo:** `packages/social_care/lib/src/ui/home/models/patient_detail.dart`

**Remover:**
- `import 'package:shared/shared.dart'`
- `factory PatientDetail.fromPatient(Patient patient)` (linhas ~235-349)
- `static ComputedAnalyticsDetail _buildAnalytics(Patient patient)` (linhas ~351-398)

**Manter:**
- `factory PatientDetail.fromJson(Map<String, dynamic> json)` — util para testes e deserializacao direta
- Todos os getters computados (`fullName`, `status`, `cpf`, `birthDate`, `formattedAddress`, etc.)
- Todos os exports dos sub-models

---

### Passo 9: Atualizar `PatientSummaryApiModel`

**Arquivo:** `packages/social_care/lib/src/data/model/patient_summary_api_model.dart`

**Adicionar `personId`** — e required no contrato `PatientSummaryResponse.yaml`:
```dart
final class PatientSummaryApiModel {
  final String patientId;
  final String personId;      // ← NOVO (required no contrato)
  final String firstName;
  // ...

  factory PatientSummaryApiModel.fromJson(Map<String, dynamic> json) {
    return PatientSummaryApiModel(
      patientId: json['patientId'] as String,
      personId: json['personId'] as String,  // ← NOVO
      // ...
    );
  }
}
```

---

### Passo 10: Atualizar `InMemoryPatientRepository` (fake de teste)

**Arquivo:** `packages/social_care/testing/fakes/in_memory_patient_repository.dart`

**`getPatient()` deve retornar `Result<PatientDetailResult>`:**
```dart
@override
Future<Result<PatientDetailResult>> getPatient(PatientId id) async {
  final patient = _store[id.value];
  if (patient == null) return Failure(...);

  // Reutiliza a mesma logica de mapping do BffPatientRepository
  // ou cria PatientDetail via fromJson com PatientMapper.toJson
  final json = PatientMapper.toJson(patient);
  final detail = PatientDetail.fromJson(json);
  return Success(PatientDetailResult(
    patientDetail: detail,
    fichas: FichaStatus.fromDetail(detail),
  ));
}
```

---

### Passo 11: Atualizar testes

**Arquivo:** `packages/social_care/test/data/repositories/bff_patient_repository_test.dart`

**Ajustar assertions:**
```dart
// Antes:
expect(result.valueOrNull?.id, patient.id);

// Depois:
expect(result.valueOrNull?.patientDetail.patientId, patient.id.value);
expect(result.valueOrNull?.fichas, isNotEmpty);
```

---

## 4. Alinhamento com Contratos v3.0.0

### Schemas utilizados

| Contract Schema | Arquivo | Uso no frontend |
|----------------|---------|-----------------|
| `PatientResponse.yaml` | Response do GET /patients/:id | `PatientDetail` + 20 sub-models mapeiam 1:1 |
| `PatientSummaryResponse.yaml` | Response do GET /patients | `PatientSummaryApiModel` + `PatientSummary` |
| `StandardResponse.yaml` | Envelope de todos os GETs | `fromJson()` trata o wrapper `data` |
| `HousingCondition.yaml` | Sub-objeto do PatientResponse | `HousingConditionDetail` |
| `SocialBenefit.yaml` | Usado em socioeconomic e workAndIncome | `SocialBenefitDetail` |
| Enums (12 schemas) | Valores de campos string-enum | Armazenados como String nas UI models |

### Enums canonicos (SCREAMING_SNAKE_CASE)

| Schema | Valores | Usado em |
|--------|---------|----------|
| `HousingConditionType` | OWNED, RENTED, CEDED, SQUATTED | `HousingConditionDetail.type` |
| `WallMaterial` | MASONRY, FINISHED_WOOD, MAKESHIFT_MATERIALS | `HousingConditionDetail.wallMaterial` |
| `WaterSupplyType` | PUBLIC_NETWORK, WELL_OR_SPRING, RAINWATER_HARVEST, WATER_TRUCK, OTHER | `HousingConditionDetail.waterSupply` |
| `ElectricityAccess` | METERED_CONNECTION, IRREGULAR_CONNECTION, NO_ACCESS | `HousingConditionDetail.electricityAccess` |
| `SewageDisposalMethod` | PUBLIC_SEWER, SEPTIC_TANK, RUDIMENTARY_PIT, OPEN_SEWAGE, NO_BATHROOM | `HousingConditionDetail.sewageDisposal` |
| `WasteCollectionType` | DIRECT_COLLECTION, INDIRECT_COLLECTION, NO_COLLECTION | `HousingConditionDetail.wasteCollection` |
| `AccessibilityLevel` | FULLY_ACCESSIBLE, PARTIALLY_ACCESSIBLE, NOT_ACCESSIBLE | `HousingConditionDetail.accessibilityLevel` |
| `SocialCareAppointmentType` | HOME_VISIT, OFFICE_APPOINTMENT, PHONE_CALL, MULTIDISCIPLINARY, OTHER | `AppointmentDetail` |
| `ViolationType` | NEGLECT, PSYCHOLOGICAL_VIOLENCE, PHYSICAL_VIOLENCE, SEXUAL_ABUSE, SEXUAL_EXPLOITATION, CHILD_LABOR, FINANCIAL_EXPLOITATION, DISCRIMINATION, OTHER | `ViolationReportDetail` |
| `ReferralDestinationService` | CRAS, CREAS, HEALTH_CARE, EDUCATION, LEGAL, OTHER | `ReferralDetail` |
| `ReferralStatus` | PENDING, COMPLETED, CANCELLED | `ReferralDetail` |

---

## 5. Impacto no Offline-First

**Nenhum.** A camada de offline-first (`OfflineFirstRepository`, `LocalSocialCareRepository`, `SyncEngine`) implementa `SocialCareContract` e retorna `Patient` domain. Isso NAO muda.

```
OfflineFirstRepository.getPatient(id) → Patient  [camada de infra, inalterada]
  ↓
PatientService.getPatient(id) → Patient  [wrapper, inalterado]
  ↓
BffPatientRepository.getPatient(id) → PatientDetailResult  [FRONTEIRA DE MAPPING]
```

O `PatientMapper` em `bff/shared` continua fazendo JSON ↔ Patient para storage/sync. Nao e afetado.

---

## 6. Arquivos Tocados (resumo)

| # | Arquivo | Acao |
|---|---------|------|
| 1 | `packages/social_care/lib/src/data/services/patient_service.dart` | Adicionar `getPatient()` |
| 2 | `packages/social_care/lib/src/ui/home/models/patient_detail_result.dart` | **NOVO** — agrupa PatientDetail + fichas |
| 3 | `packages/social_care/lib/src/ui/home/models/ficha_status.dart` | `fromPatient()` → `fromDetail()`, remove shared import |
| 4 | `packages/social_care/lib/src/data/repositories/patient_repository.dart` | Retorno `Patient` → `PatientDetailResult` |
| 5 | `packages/social_care/lib/src/data/repositories/bff_patient_repository.dart` | Usa service + mapping Patient→PatientDetail |
| 6 | `packages/social_care/lib/src/logic/use_case/registry/get_patient_use_case.dart` | Input `PatientId`→`String`, output `Patient`→`PatientDetailResult` |
| 7 | `packages/social_care/lib/src/ui/home/viewModel/home_view_model.dart` | Remove mapping, so estado |
| 8 | `packages/social_care/lib/src/ui/home/models/patient_detail.dart` | Remove `fromPatient()`, `_buildAnalytics()`, shared import |
| 9 | `packages/social_care/lib/src/data/model/patient_summary_api_model.dart` | Adiciona `personId` |
| 10 | `packages/social_care/testing/fakes/in_memory_patient_repository.dart` | `getPatient()` retorna `PatientDetailResult` |
| 11 | `packages/social_care/test/data/repositories/bff_patient_repository_test.dart` | Ajusta assertions |

---

## 7. Ordem de Execucao (grafo de dependencias)

```
Passo 1 (PatientService) ─────────────────────┐
Passo 2 (PatientDetailResult) ────────────┐    │
Passo 3 (FichaStatus.fromDetail) ────┐    │    │
                                      │    │    │
Passo 4 (PatientRepository) ─────────┼────┘    │
                                      │         │
Passo 5 (BffPatientRepository) ──────┼─────────┘
                                      │
Passo 6 (GetPatientUseCase) ─────────┤
                                      │
Passo 7 (HomeViewModel) ─────────────┤
                                      │
Passo 8 (Limpar PatientDetail) ──────┘
                                      
Passo 9 (PatientSummaryApiModel) ── independente
Passo 10 (InMemoryPatientRepository) ── depende de Passo 4
Passo 11 (Testes) ── depende de Passo 5, 10
```

**Passos 1, 2, 3 podem ser feitos em paralelo** (sem dependencias entre si).
**Passos 4-8 sao sequenciais** (cada um depende do anterior).
**Passo 9 e independente.**
**Passos 10-11 dependem de 4-5.**

---

## 8. Verificacao

1. `mcp dart analyze_files` nos packages: `social_care`, `acdg_system`
2. `mcp dart run_tests` no `packages/social_care` — 19 testes devem passar
3. Hot restart do app → listar pacientes → selecionar um → detalhe carrega com todos os campos
4. Verificar que `patient_detail.dart` NAO importa `package:shared`
5. Verificar que `ficha_status.dart` NAO importa `package:shared`
6. Verificar que `home_view_model.dart` NAO importa `package:shared`
