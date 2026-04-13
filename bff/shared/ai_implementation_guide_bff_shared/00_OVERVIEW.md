# 00 - OVERVIEW: BFF Shared Kernel

> Shared Dart package contendo domain models, value objects, mappers, analytics, contract e testing utilities reutilizados pelos BFFs Desktop e Web.

---

## 1. Indice de Documentos

| Doc | Conteudo |
|-----|----------|
| `00_OVERVIEW.md` | Estrutura, stack, arquitetura, convencoes |
| `01_DOMAIN_KERNEL.md` | Value Objects cross-cutting: IDs, CPF, CNS, NIS, CEP, RG, Address, TimeStamp |
| `02_DOMAIN_REGISTRY.md` | PersonalData, CivilDocuments, SocialIdentity, FamilyMember, Patient (aggregate root) |
| `03_DOMAIN_ASSESSMENT.md` | Housing, SocioEconomic, WorkAndIncome, Education, Health, CommunitySupport, SocialHealthSummary |
| `04_DOMAIN_CARE_PROTECTION.md` | IcdCode, Diagnosis, IngressInfo, Appointment, Referral, ViolationReport, PlacementHistory |
| `05_DOMAIN_ANALYTICS.md` | Housing, Financial, Family, Education analytics services |
| `06_INFRASTRUCTURE.md` | DTOs (PatientRemote, PatientOverview), Mappers (Registry, Assessment, Care, Protection), PatientTranslator, PeopleContextClient, PatientEnrichmentService |
| `07_CONTRACT_TESTING.md` | SocialCareContract (interface), FakeSocialCareBff, utils |

## 2. Stack

| Tecnologia | Versao | Papel |
|------------|--------|-------|
| Dart SDK | `>=3.11.0 <4.0.0` | Runtime |
| `core_contracts` | path local | `Result<T>`, `Success<T>`, `Failure<T>`, `Equatable` |
| `collection` | `^1.19.1` | `UnmodifiableListView` etc |
| `dio` | `^5.7.0` | HTTP client (PeopleContextClient) |
| `json_annotation` | `^4.9.0` | Serialization annotations |
| `json_serializable` | `^6.9.0` | Code generation (dev) |

**Package name:** `shared`
**Version:** `1.2.0`
**publish_to:** none (workspace package)

## 3. Arquitetura

```
shared/
├── lib/
│   ├── shared.dart                          # Barrel file (re-exporta tudo)
│   └── src/
│       ├── utils/
│       │   ├── app_error.dart               # AppError, ErrorCategory, ErrorSeverity, Observability
│       │   ├── string_helpers.dart           # StringNormalization extension
│       │   └── api_extensions.dart           # TimeStamp API extensions
│       ├── domain/
│       │   ├── kernel/
│       │   │   ├── ids.dart                  # 7 UUID-based IDs (PersonId, PatientId, etc)
│       │   │   ├── cpf.dart                  # CPF + FiscalRegion + Mod11
│       │   │   ├── cns.dart                  # CNS (Cartao Nacional de Saude)
│       │   │   ├── nis.dart                  # NIS (PIS/PASEP)
│       │   │   ├── cep.dart                  # CEP + PostalRegion + DistributionKind
│       │   │   ├── rg_document.dart          # RG + check digit + issuing state/agency
│       │   │   ├── address.dart              # Address + ResidenceLocation
│       │   │   └── time_stamp.dart           # TimeStamp (UTC wrapper)
│       │   ├── models/
│       │   │   └── lookup.dart               # LookupItem
│       │   ├── audit/
│       │   │   └── audit_event.dart          # AuditEvent
│       │   ├── registry/
│       │   │   ├── registry_vos.dart         # PersonalData, CivilDocuments, SocialIdentity, Sex, RequiredDocument
│       │   │   ├── family_member.dart        # FamilyMember
│       │   │   └── patient.dart              # Patient (aggregate root)
│       │   ├── assessment/
│       │   │   ├── assessment_vos.dart       # HousingCondition, SocioEconomicSituation, SocialBenefit(s)
│       │   │   ├── community_support.dart    # CommunitySupportNetwork
│       │   │   ├── educational_status.dart   # EducationalStatus, MemberEducationalProfile, ProgramOccurrence
│       │   │   ├── health_status.dart        # HealthStatus, MemberDeficiency, PregnantMember
│       │   │   ├── social_health_summary.dart # SocialHealthSummary
│       │   │   └── work_and_income.dart      # WorkAndIncome, WorkIncomeVO
│       │   ├── care/
│       │   │   └── care_vos.dart             # IcdCode, Diagnosis, IngressInfo, SocialCareAppointment, ProgramLink, AppointmentType
│       │   ├── protection/
│       │   │   └── protection_vos.dart       # Referral, RightsViolationReport, PlacementHistory, PlacementRegistry, etc
│       │   └── analytics/
│       │       ├── housing_analytics_service.dart
│       │       ├── financial_analytics_service.dart
│       │       ├── family_analytics.dart
│       │       └── education_analytics_service.dart
│       ├── infrastructure/
│       │   ├── dtos/
│       │   │   ├── patient_remote.dart       # PatientRemote (JSON ↔ domain)
│       │   │   └── patient_overview.dart     # PatientOverview (listing DTO)
│       │   ├── mappers/
│       │   │   ├── json_helpers.dart         # enumFromJson, listFromJson, idFromJson, etc
│       │   │   ├── registry_mapper.dart      # RegistryMapper
│       │   │   ├── assessment_mapper.dart    # AssessmentMapper
│       │   │   ├── care_mapper.dart          # CareMapper
│       │   │   └── protection_mapper.dart    # ProtectionMapper
│       │   ├── patient_translator.dart       # PatientTranslator (facade)
│       │   └── people_context_client.dart    # PeopleContextClient (Dio)
│       ├── services/
│       │   └── patient_enrichment_service.dart # PatientEnrichmentService
│       ├── contract/
│       │   ├── social_care_contract.dart     # SocialCareContract (interface)
│       │   └── dto/requests/
│       │       └── register_patient_request.dart # Placeholder
│       └── testing/
│           └── fake_social_care_bff.dart     # FakeSocialCareBff
└── test/
```

## 4. Padrao Result

Todas as operacoes de criacao/validacao retornam `Result<T>` (de `core_contracts`):
- `Success<T>(value)` — operacao bem-sucedida
- `Failure<T>(error)` — contem `AppError` ou outro objeto de erro

Pattern matching:
```dart
switch (result) {
  case Success(:final value): // usar value
  case Failure(:final error): // tratar error
}
```

## 5. Padrao AppError

Erro estruturado com codigo, modulo, categoria, severidade e observabilidade:

```dart
AppError(
  code: 'CPF-004',
  message: 'Invalid CPF: check digit mismatch',
  module: 'social-care/cpf',
  kind: 'domainValidation',
  http: 422,
  observability: Observability(
    category: ErrorCategory.domainRuleViolation,
    severity: ErrorSeverity.error,
  ),
)
```

## 6. Convencoes

- **Imutabilidade:** todos VOs sao `final class` com `with Equatable`
- **Validacao via factory:** `static Result<T> create({...})` — nunca construtor publico direto (exceto reconstitute)
- **reconstitute:** factory sem validacao, usado para hidratar do banco
- **copyWith:** campos opcionais usam `T? Function()? field` para permitir null explicito
- **Strings:** sempre normalizadas via `normalize()` ou `nullIfEmptyNormalized()`
- **Listas:** sempre `List.unmodifiable(...)` nos agregados
- **Enums → JSON:** `.name.toSnakeCaseUpper()` (ex: `homeVisit` → `HOME_VISIT`)
- **JSON → Enums:** `enumFromJson()` helper com match case-insensitive
- **Default UUID:** `'00000000-0000-0000-0000-000000000000'` para campos opcionais no mapper
