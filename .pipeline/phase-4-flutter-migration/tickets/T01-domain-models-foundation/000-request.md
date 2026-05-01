# T01 — Domain Models Foundation

## Onda: 1 (Infraestrutura)
## Prioridade: P0
## Profile: `domain-only`
## Depende de: — (primeiro ticket)

## Escopo
Criar `packages/social_care/lib/src/domain/models/` com domain models **próprios do Flutter**, imutáveis, sem serialização. Estes substituirão o uso de `bff/shared/` em ViewModels/UseCases/Views nas ondas seguintes.

## Entidades a criar
Mapear os tipos de `bff/shared/` para domain próprios:

| `bff/shared` (origem) | `domain/models/` (novo) | Notas |
|-----------------------|-------------------------|-------|
| `PatientResponse` | `Patient` | aggregate principal |
| `FamilyMemberResponse` | `FamilyMember` | |
| `PersonResponse` | `Person` | People Context |
| `PersonalData*` | `PersonalData` | VO |
| `CivilDocuments*` | `CivilDocuments` | VO |
| `Address*` | `Address` | VO |
| `SocialIdentity*` | `SocialIdentity` | |
| `IntakeInfo*` | `IntakeInfo` | |
| `HousingConditionResponse` | `HousingCondition` | |
| `SocioEconomicSituation*` | `SocioEconomicSituation` | |
| `WorkAndIncome*` | `WorkAndIncome` | |
| `EducationalStatus*` | `EducationalStatus` | |
| `HealthStatus*` | `HealthStatus` | |
| `CommunitySupport*` | `CommunitySupport` | |
| `SocialHealthSummary*` | `SocialHealthSummary` | |
| `AppointmentResponse` | `Appointment` | Care |
| `DiagnosisResponse` | `Diagnosis` | |
| `ReferralResponse` | `Referral` | Protection |
| `ViolationReportResponse` | `ViolationReport` | |
| `PlacementHistoryResponse` | `PlacementHistory` | |
| `RoleResponse` | `Role` | Team |
| `AuditTrailEntryResponse` | `AuditEvent` | |

Total aproximado: **22 entidades/VOs**.

## Waves

### Wave 0: Design (always)
- [x] flutter-domain-modeler → 001-contracts/

### Wave 5: Quality Gates
- [x] flutter-code-reviewer
- [x] flutter-quality-checker

Waves 1–4: **SKIP** (só domain models; sem data, usecase, viewmodel ou view).

## Critérios de aceitação
- [ ] 22 arquivos criados em `packages/social_care/lib/src/domain/models/`.
- [ ] Todos com `with Equatable` (mixin, não `extends`).
- [ ] Todos os campos `final`.
- [ ] Todos com `copyWith`.
- [ ] **Zero** `fromJson` / `toJson` / `Map<String, dynamic>`.
- [ ] **Zero** import de `package:shared/shared.dart`.
- [ ] Zero lógica de negócio (models são schemas).
- [ ] `dart analyze` sem warnings.
- [ ] `dart format` aplicado.
- [ ] Sem testes unitários obrigatórios (models puros); test-writer pode escrever round-trip `copyWith` + `Equatable` se quiser.

## Non-Regression
T01 **não deleta nada**. Os modelos novos convivem com o uso atual de `bff/shared/` no resto do código. Só em T04+ os ViewModels começam a trocar.

## Artefatos esperados
```
.pipeline/phase-3-flutter-acl/tickets/T01-domain-models-foundation/
├── 000-request.md           (este arquivo)
├── 001-contracts/
│   ├── patient.dart         (draft)
│   ├── family_member.dart
│   ├── ...
│   └── REPORT.md            (lista 22 models + Public API)
├── 005-quality/QUALITY.md
├── STATE.md
└── FINAL.md
```

## Código destino (produção)
`packages/social_care/lib/src/domain/models/*.dart`

## Agente responsável
`flutter-domain-modeler` (único agente da wave)

## Tempo estimado
1 sessão (2–4 h com revisão).
