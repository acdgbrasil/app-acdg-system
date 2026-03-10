# Codebase — frontend (Conecta Raros)

Documentacao dos modulos internos, contratos e convencoes de pasta.

---

## 1. Mapa de Packages

| Package | Tipo | Descricao |
|---------|------|-----------|
| `shell` | App | Aplicacao principal. Login, roteamento, DI global. |
| `design_system` | Library | Tokens (cores, tipografia, spacing) + widgets Atomic Design. |
| `core` | Library | Network (Dio), Offline (Isar/SyncQueue), Auth, Platform, Base classes. |
| `social_care` | Feature Package | Micro-app do dominio Social Care. Features MVVM. |
| `people_context` | Feature Package | Micro-app do dominio People Context (futuro). |
| `social_care_bff` | BFF | Backend for Frontend do Social Care. EDD + DDD. Dart AOT. |
| `people_context_bff` | BFF | BFF do People Context (futuro). |

---

## 2. Dependencias entre Packages

```
shell
  +-- core
  +-- design_system
  +-- social_care
  |     +-- core
  |     +-- design_system
  |     +-- social_care_bff (desktop: in-process)
  +-- people_context (futuro)
        +-- core
        +-- design_system
        +-- people_context_bff (desktop: in-process)
```

**Regra:** Feature packages NUNCA dependem uns dos outros. Comunicacao entre dominios passa pelo Shell (routing).

---

## 3. Estrutura de Feature (template)

Toda feature segue esta estrutura:

```
features/<feature_name>/
+-- view/
|   +-- pages/
|   |   +-- <feature>_desktop_page.dart
|   |   +-- <feature>_web_page.dart
|   |   +-- <feature>_mobile_page.dart
|   +-- components/
|       +-- atoms/        # Widgets atomicos especificos da feature
|       +-- cells/        # Composicoes especificas da feature
+-- view_model/
|   +-- <feature>_view_model.dart
+-- use_case/
|   +-- <action>_use_case.dart
+-- model/
    +-- repositories/
    |   +-- <entity>_repository.dart     # Interface
    |   +-- <entity>_repository_impl.dart # Implementacao
    +-- services/
        +-- <entity>_service.dart
```

---

## 4. Features do Social Care

| Feature | API Endpoints | Descricao |
|---------|--------------|-----------|
| `patient_registration` | POST /patients, GET /patients/:id | Cadastro da PR (3 partes: dados, endereco, composicao) |
| `family_composition` | POST/DELETE family-members, PUT primary-caregiver | Composicao familiar + perfil etario |
| `housing_assessment` | PUT /housing-condition | Condicoes habitacionais + densidade |
| `health_status` | PUT /health-status | Saude, deficiencias, gestantes |
| `work_income` | PUT /work-and-income | Rendimento e trabalho (4 calculos automaticos) |
| `education` | PUT /educational-status | Educacao + vulnerabilidades |
| `socioeconomic` | PUT /socioeconomic-situation | Situacao socioeconomica |
| `benefits` | (via socioeconomic) | Beneficios sociais (metadata-driven) |
| `community_support` | PUT /community-support-network | Rede de apoio comunitario |
| `social_health_summary` | PUT /social-health-summary | Resumo de saude social |
| `protection` | PUT placement-history, POST violation-reports, POST referrals | Acolhimento + violencia + encaminhamentos |
| `care` | POST appointments, PUT intake-info | Atendimentos + ingresso |
| `audit_trail` | GET /audit-trail | Historico de eventos |
| `lookup` | GET /dominios/:table | Tabelas de dominio (dropdowns) |

---

## 5. Contratos BFF

### 5.1 Interface In-Process (Desktop)

O BFF expoe classes Dart com metodos tipados:

```dart
abstract class SocialCareBffContract {
  Future<Result<PatientModel>> getPatient(String patientId);
  Future<Result<String>> registerPatient(RegisterPatientCommand command);
  Future<Result<void>> updateHousing(String patientId, UpdateHousingCommand command);
  // ... demais operacoes
}
```

### 5.2 Interface HTTP (Web)

O BFF expoe endpoints HTTP via Darto que espelham o contrato in-process:

```
BFF Routes (Darto):
  GET  /bff/patients/:id        -> getPatient()
  POST /bff/patients            -> registerPatient()
  PUT  /bff/patients/:id/housing -> updateHousing()
  ...
```

O Flutter web usa Dio para chamar esses endpoints.
O Flutter desktop importa o package e chama os metodos diretamente.

---

## 6. Convencoes de Arquivo

| Tipo | Sufixo | Exemplo |
|------|--------|---------|
| Page | `_page.dart` | `patient_registration_desktop_page.dart` |
| ViewModel | `_view_model.dart` | `patient_registration_view_model.dart` |
| UseCase | `_use_case.dart` | `register_patient_use_case.dart` |
| Repository (interface) | `_repository.dart` | `patient_repository.dart` |
| Repository (impl) | `_repository_impl.dart` | `patient_repository_impl.dart` |
| Service | `_service.dart` | `patient_service.dart` |
| Model | `_model.dart` | `patient_model.dart` |
| Atom | Widget name | `acdg_button.dart`, `acdg_text_field.dart` |
| Cell | Widget name | `patient_info_card.dart` |
| Template | `_template.dart` | `form_layout_template.dart` |
| Test | `_test.dart` | `patient_registration_view_model_test.dart` |
