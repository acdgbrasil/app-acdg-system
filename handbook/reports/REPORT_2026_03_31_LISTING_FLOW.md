# Report — Refatoracao Completa do Fluxo de Listagem

**Data:** 2026-03-31
**Branch:** `feat/phase5-social_care`

---

## Resumo

Refatoracao end-to-end do fluxo de listagem de pacientes, corrigindo a separacao de responsabilidades entre camadas (MVVM + Clean Architecture), corrigindo bugs no offline-first e garantindo compatibilidade com o JSON real do backend.

---

## 1. UI Layer — Models (`packages/social_care/lib/src/ui/home/models/`)

### PatientDetail reescrito com schema completo
- Reescreveu `patient_detail.dart` mapeando o response completo de `GET /api/v1/patients/:patientId`
- 20 sub-models criados em arquivos separados, cada um com `fromJson()`
- Factory `fromPatient(Patient)` para mapear domain -> UI
- Getters computados (`fullName`, `status`, `cpf`, `birthDate`, `formattedAddress`, etc.) para compatibilidade com Views existentes

### Arquivos criados
- `personal_data_detail.dart`
- `civil_documents_detail.dart` (+ `RgDocumentDetail`)
- `address_detail.dart`
- `social_identity_detail.dart`
- `housing_condition_detail.dart`
- `social_benefit_detail.dart`
- `socioeconomic_situation_detail.dart`
- `work_and_income_detail.dart` (+ `IndividualIncomeDetail`)
- `educational_status_detail.dart` (+ `MemberProfileDetail`, `ProgramOccurrenceDetail`)
- `health_status_detail.dart` (+ `DeficiencyDetail`, `GestatingMemberDetail`)
- `community_support_network_detail.dart`
- `social_health_summary_detail.dart`
- `placement_history_detail.dart` (+ `IndividualPlacementDetail`)
- `intake_info_detail.dart` (+ `LinkedProgramDetail`)
- `family_member_detail.dart`
- `diagnosis_detail.dart`
- `appointment_detail.dart`
- `referral_detail.dart`
- `violation_report_detail.dart`
- `computed_analytics_detail.dart` (+ `HousingAnalyticsDetail`, `FinancialAnalyticsDetail`, `AgeProfileDetail`, `EducationalVulnerabilitiesDetail`)

---

## 2. UI Layer — Mappers (`packages/social_care/lib/src/ui/home/mappers/`)

9 mappers criados (UI Detail Model -> Intent) para comunicacao UI -> UseCase:

| Mapper | Entrada | Saida |
|--------|---------|-------|
| `HousingConditionDetailMapper` | `HousingConditionDetail` | `UpdateHousingConditionIntent` |
| `SocioeconomicDetailMapper` | `SocioeconomicSituationDetail` | `UpdateSocioEconomicIntent` |
| `WorkAndIncomeDetailMapper` | `WorkAndIncomeDetail` | `UpdateWorkAndIncomeIntent` |
| `EducationalStatusDetailMapper` | `EducationalStatusDetail` | `UpdateEducationalStatusIntent` |
| `HealthStatusDetailMapper` | `HealthStatusDetail` | `UpdateHealthStatusIntent` |
| `CommunitySupportDetailMapper` | `CommunitySupportNetworkDetail` | `UpdateCommunitySupportIntent` |
| `SocialHealthSummaryDetailMapper` | `SocialHealthSummaryDetail` | `UpdateSocialHealthSummaryIntent` |
| `IntakeInfoDetailMapper` | `IntakeInfoDetail` | `UpdateIntakeInfoIntent` |
| `PlacementHistoryDetailMapper` | `PlacementHistoryDetail` | `UpdatePlacementHistoryIntent` |

---

## 3. UI Layer — ViewModel

- `HomeViewModel.loadPatients()` simplificado: recebe `List<PatientSummary>` tipado, sem mapping
- `selectPatient()` usa `PatientDetail.fromPatient()` para mapear domain -> UI
- Removidos todos os `debugPrint` de debug

---

## 4. Logic Layer — UseCase

- `ListPatientsUseCase`: mudou de `BaseUseCase<void, List<Map<String, dynamic>>>` para `NoInputUseCase<List<PatientSummary>>`
- Orquestra sem mapear — dado ja vem tipado do Repository

---

## 5. Data Layer

### Criados
- `data/model/patient_summary_api_model.dart` — API model com `fromJson()` para o response de listagem
- `data/services/patient_service.dart` — wrapper puro de chamadas ao BFF contract

### Refatorados
- `PatientRepository.listPatients()` — retorna `Result<List<PatientSummary>>` (tipado)
- `BffPatientRepository` — usa `PatientService`, mapeia `JSON -> PatientSummaryApiModel -> PatientSummary`
- `social_care.dart` — adicionado export do `PatientService`
- DI em `app_providers.dart` — registra `PatientService` e injeta no `BffPatientRepository`

---

## 6. Offline-First — Bugs corrigidos

### `updateCacheFromSummaries` (bug critico)
**Antes:** sobrescrevia `fullRecordJson` com summary JSON -> `getPatient` quebrava ao tentar reconstruir `Patient` de um summary.
**Depois:** verifica se ja existe full record (usando `prRelationshipId` como discriminador). Se sim, preserva `fullRecordJson` existente e so atualiza campos indexados.

### `listPatients` local (bug critico)
**Antes:** `json.containsKey('patientId')` era true para ambos os formatos (summary e full record) -> retornava full record como summary -> `PatientSummary.fromJson` nao encontrava `memberCount`, `primaryDiagnosis`.
**Depois:** `_extractSummary()` diferencia formato via `prRelationshipId`. Full record: extrai `primaryDiagnosis` de `initialDiagnoses[0].description` e `memberCount` de `familyMembers.length`. Summary: retorna direto.

---

## 7. PatientMapper — Compatibilidade com server

### `prRelationshipId` null
**Antes:** `json['prRelationshipId'] as String` crashava porque o server nao envia esse campo no detail response.
**Depois:** `as String?` com fallback UUID zero.

### `diagnoses` vs `initialDiagnoses`
**Antes:** so lia `initialDiagnoses` (formato local), ignorava `diagnoses` (formato server).
**Depois:** tenta `initialDiagnoses` primeiro, fallback para `diagnoses`.

---

## 8. Logs removidos

- `social_care_bff_remote.dart` — removidos todos os `debugPrint` do interceptor Dio (request/response/error), do `listPatients` e do `getPatient` (incluindo dump completo do JSON)
- `sync_engine.dart` — removidos `debugPrint` de `forceSyncNow` e `processQueue`

---

## 9. Fluxo final da listagem

```
BFF Contract (SocialCareContract)
    |  List<Map<String, dynamic>>
    v
PatientService (wrapper puro)
    |  List<Map<String, dynamic>>
    v
BffPatientRepository (JSON -> PatientSummaryApiModel -> PatientSummary)
    |  Result<List<PatientSummary>>
    v
ListPatientsUseCase (orquestrador, extensivel)
    |  Result<List<PatientSummary>>
    v
HomeViewModel (gerencia estado: loading/success/error)
    |  List<PatientSummary>
    v
View (renderiza)
```

---

## 10. View — Ajuste de compatibilidade

- `panel_dados.dart` — atualizado para usar `detail.formattedAddress` em vez de `detail.address` (que agora e `AddressDetail?`, nao `String?`)

---

## Testes atualizados

- `bff_patient_repository_test.dart` — construtor atualizado para receber `PatientService`
- `in_memory_patient_repository.dart` — assinatura de `listPatients` precisa atualizacao futura (retorna `Map` ainda)

---

commit message: refactor(social_care): restructure listing flow with proper MVVM layering, fix offline-first cache bugs, and add full PatientDetail model
