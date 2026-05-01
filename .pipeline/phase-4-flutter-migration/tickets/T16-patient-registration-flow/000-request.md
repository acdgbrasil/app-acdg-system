# T16 — Patient Registration Flow

## Onda: 3 | P0 | Profile: `feature`
## Depende de: T13 (family-composition migrada), T03 (services split)

## Escopo
Refatorar o **wizard de registro de paciente** — feature mais complexa da aplicação — para usar 1 request do cliente para o BFF em vez de 5–15.

## Estado atual
`packages/social_care/lib/src/ui/patient_registration/viewModel/patient_registration_view_model.dart`
- `_loadLookups()` faz 4 `Future.wait` de lookups
- `registerPatientCommand` orquestra: registerPerson (People Context) → registerPatient → addFamilyMember loop → updateIntake → updateSocialIdentity
- Import de `shared/` em 2 lugares
- Carrega `family_member_modal.dart` (5 imports de `shared/`)

## Contract A alvo
- 1 request: `POST /api/patients` com payload gordo (PatientRegisterPayload)
- BFF já tem `RegisterPatientUseCase` em `bff/social_care_web/lib/src/use_cases/register_patient_use_case.dart` → **reaproveitar**
- BFF já tem `RegisterPatientIntent` — ajustar se necessário

## Arquivos afetados
- `ui/patient_registration/viewModel/patient_registration_view_model.dart` → renomear pasta (viewModel → view_models) + eliminar orquestração + 1 Command
- `ui/patient_registration/view/components/forms/reference_person/*.dart` (6+ arquivos com imports)
- `logic/use_case/registry/register_patient_use_case.dart` → mover + reduzir a 1 call
- `data/commands/register_patient_intent.dart` → renomear para `data/model/patient_register_payload.dart` (decisão Q1 do discuss)

## Endpoint composto (lookups)
Criar ou confirmar: `GET /api/lookups?tables=...` que retorna várias tables numa única request.

## Critérios
- [ ] 1 request do Flutter para registrar paciente (zero orquestração no cliente)
- [ ] 0 imports de `shared/` em `ui/patient_registration/**`
- [ ] `_loadLookups()` reduzido para 1 chamada com lista de tables
- [ ] Wizard funciona end-to-end em staging
- [ ] Tests GREEN (widget test do wizard completo)
