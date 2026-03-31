# 🧩 Fase 5 — Features Social Care

Implementação das 12 funcionalidades do módulo Social Care.

## Status: 🚧 EM PROGRESSO

### Estratégia por Funcionalidade
Para cada funcionalidade (ex: `Patient Registration`):
1.  **Logic**: UseCase + Modelos.
2.  **Data**: Repositório integrado ao BFF + Cache Isar.
3.  **UI**: ViewModel + Páginas (Desktop/Web/Mobile) via Atomic Design.
4.  **Test**: Unitário (Logic) + Widget (UI) + Integração (Data).

### Lista de Prioridades
1.  `patient_registration` (Fundamental)
2.  `lookup` (Infra)
3.  `housing_assessment` (Avaliação)
4.  ...demais avaliações e atendimentos.

---

## Progresso Detalhado

### 1. `patient_registration` — 🚧 EM PROGRESSO

#### ✅ Package `social_care` criado (2026-03-18)

**Estrutura:**
```
packages/social_care/
├── lib/
│   ├── social_care.dart                    # Barrel export
│   └── src/
│       ├── data/
│       │   ├── repositories/
│       │   │   ├── patient_repository.dart         # Interface (abstract)
│       │   │   ├── bff_patient_repository.dart     # Impl via SocialCareContract
│       │   │   ├── lookup_repository.dart          # Interface (abstract)
│       │   │   └── bff_lookup_repository.dart      # Impl via SocialCareContract
│       │   └── services/                           # (reservado para futuros services)
│       ├── domain/
│       │   └── models/                             # (reutiliza modelos de bff/shared)
│       └── ui/
│           └── patient_registration/
│               ├── use_case/
│               │   ├── register_patient_use_case.dart   # Orquestra registro com validação
│               │   └── get_patient_use_case.dart        # Busca paciente por ID
│               ├── use_case/
│               │   ├── register_patient_use_case.dart   # Orquestra registro com validação
│               │   └── get_patient_use_case.dart        # Busca paciente por ID
│               ├── view_model/
│               │   └── patient_registration_view_model.dart  # ChangeNotifier + Commands
│               ├── pages/
│               │   ├── patient_registration_page.dart        # Entry point adaptativo
│               │   ├── patient_registration_desktop_page.dart
│               │   ├── patient_registration_web_page.dart
│               │   └── patient_registration_mobile_page.dart
│               └── widgets/
│                   └── patient_form.dart                     # Form compartilhado
├── testing/
│   ├── social_care_testing.dart            # Barrel export para testes
│   ├── fakes/
│   │   ├── in_memory_patient_repository.dart
│   │   └── in_memory_lookup_repository.dart
│   └── fixtures/
│       └── patient_fixtures.dart
└── test/
    ├── data/repositories/
    │   └── bff_patient_repository_test.dart                   # 4 testes ✅
    └── ui/patient_registration/
        ├── register_patient_use_case_test.dart                # 4 testes ✅
        ├── get_patient_use_case_test.dart                     # 2 testes ✅
        └── patient_registration_view_model_test.dart          # 13 testes ✅
```

**Decisões:**
- Nomenclatura sem `Impl`: `BffPatientRepository` (tecnologia), `InMemoryPatientRepository` (fake)
- Modelos de domínio reutilizados de `bff/shared` (sem duplicação)
- `SocialCareContract` serve como abstração da infra; Repository faz thin-wrapper focado por bounded context
- Package registrado no workspace (`pubspec.yaml` raiz)
- ViewModel compartilhado entre 3 Pages (Desktop/Web/Mobile) via PlatformResolver
- UUID v4 gerado client-side para PatientId/PersonId (sem dependência de package externo)

**Testes:** 23/23 passando ✅
- `RegisterPatientUseCase`: validação de invariantes (diagnoses vazio, PR ausente), registro válido, campos opcionais
- `GetPatientUseCase`: busca existente, busca inexistente
- `BffPatientRepository`: delegação ao contrato BFF (register, get, getByPerson, not found)
- `PatientRegistrationViewModel`: load lookups, canSubmit, add/remove diagnosis, add/remove family member, reset form, register success/fail, load patient success/fail

#### ✅ UI Layer implementada (2026-03-18)
- [x] `PatientRegistrationViewModel` (ChangeNotifier + Commands)
- [x] Pages (Desktop/Web/Mobile) via Atomic Design com PlatformResolver
- [x] PatientForm widget compartilhado entre plataformas
- [x] Registro no DI (Provider) no `root.dart`
- [x] Registro de rotas no GoRouter (`/patient-registration`)
- [x] Testes unitários do ViewModel (13 testes)

#### 📅 Próximos Passos
- [ ] Widget tests das Pages
- [ ] Lookup table de relacionamentos integrado com a UI
- [ ] Formulário de família (adicionar FamilyMember via dialog)
- [ ] Formulário de documentos civis (CivilDocuments)
- [ ] Formulário de endereço (Address)
- [ ] Validação visual de campos obrigatórios
- [ ] Navegação pós-registro (redirect para detalhes do paciente)
