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
│               └── view_model/                          # (próximo passo)
├── testing/
│   ├── social_care_testing.dart            # Barrel export para testes
│   ├── fakes/
│   │   ├── in_memory_patient_repository.dart
│   │   └── in_memory_lookup_repository.dart
│   └── fixtures/
│       └── patient_fixtures.dart
└── test/
    ├── data/repositories/
    │   └── bff_patient_repository_test.dart   # 4 testes ✅
    └── ui/patient_registration/
        ├── register_patient_use_case_test.dart # 4 testes ✅
        └── get_patient_use_case_test.dart      # 2 testes ✅
```

**Decisões:**
- Nomenclatura sem `Impl`: `BffPatientRepository` (tecnologia), `InMemoryPatientRepository` (fake)
- Modelos de domínio reutilizados de `bff/shared` (sem duplicação)
- `SocialCareContract` serve como abstração da infra; Repository faz thin-wrapper focado por bounded context
- Package registrado no workspace (`pubspec.yaml` raiz)

**Testes:** 10/10 passando ✅
- `RegisterPatientUseCase`: validação de invariantes (diagnoses vazio, PR ausente), registro válido, campos opcionais
- `GetPatientUseCase`: busca existente, busca inexistente
- `BffPatientRepository`: delegação ao contrato BFF (register, get, getByPerson, not found)

#### 📅 Próximos Passos
- [ ] `PatientRegistrationViewModel` (ChangeNotifier + Commands)
- [ ] Pages (Desktop/Web/Mobile) via Atomic Design
- [ ] Registro no DI (Provider) no `root.dart`
- [ ] Registro de rotas no GoRouter
- [ ] Widget tests
