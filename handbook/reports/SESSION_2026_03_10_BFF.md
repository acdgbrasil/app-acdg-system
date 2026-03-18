# Report — 2026-03-10 — BFF Social Care (Fase 3)

## Contexto

Implementacao completa do BFF Social Care como proxy tipado ao social-care API (Swift/Vapor). Conforme handbook secao 4: o BFF NAO duplica DDD do backend — traduz chamadas Flutter em requests HTTP e retorna domain models Dart puros.

Adicionalmente, foram corrigidos 3 discrepancias nos contratos OpenAPI entre `contracts/` e a implementacao Swift.

## Decisoes Tomadas

1. **BFF como proxy tipado, nao DDD duplicado** — O backend ja tem agregados, VOs, event sourcing, CQRS. O BFF apenas encapsula HTTP e retorna modelos limpos.

2. **`SocialCareContract` como interface abstrata** — 21 metodos cobrindo todos os bounded contexts. Flutter depende APENAS do contract + models, nunca do api_client ou impl.

3. **Domain models sem JSON** — Modelos puros e imutaveis. Toda serializacao fica em `api_client/api_models/` (mapper classes separados).

4. **`contract/dto/responses/` como re-exports** — Como o BFF e um proxy tipado (sem transformacao), os response types SAO os domain models. Os barrels organizam por bounded context sem duplicar tipos.

5. **Value Objects nao lancam excecao** — `Cpf`, `Nis`, `Cep` aceitam qualquer string e expoe `isValid` + `formatted`. O backend e a autoridade de validacao; o frontend usa VOs para type safety e formatacao.

6. **`testing/` dentro de `lib/src/`** — Padrao Dart idiomatico para packages que exportam test utilities. Top-level `testing/` nao pode ser importado por outros packages. Handbook atualizado.

7. **`flutter test` obrigatorio** — Core depende transitivamente de Flutter via `oidc`. `dart test` falha por falta de `dart:ui`. Documentado no CLAUDE.md e IMPLEMENTATION_PLAN.

## Artefatos Produzidos

### Contratos OpenAPI corrigidos
- `contracts/services/social-care/openapi/openapi.yaml` — removido `security: []` do lookup endpoint
- `contracts/services/social-care/model/schemas/HousingCondition.yaml` — renomeados 4 campos, adicionados 4 campos faltantes
- `contracts/services/social-care/model/schemas/RegisterAppointmentRequest.yaml` — `summary` removido dos required

### BFF Package (`bff/social_care_bff/`)

**Novos arquivos (40 arquivos Dart):**

| Diretorio | Arquivos | Descricao |
|-----------|----------|-----------|
| `lib/` | 2 | Barrel exports (social_care_bff.dart, testing.dart) |
| `lib/src/contract/` | 1 | SocialCareContract (21 metodos) |
| `lib/src/contract/dto/requests/` | 4 | Request DTOs com toJson() |
| `lib/src/contract/dto/responses/` | 5 | Response barrels (re-exports) |
| `lib/src/models/` | 5 | Patient, FamilyMember, LookupItem, AuditEvent, ComputedAnalytics |
| `lib/src/models/assessment/` | 7 | HousingCondition, HealthStatus, etc. |
| `lib/src/models/care/` | 2 | Appointment, IntakeInfo |
| `lib/src/models/protection/` | 3 | Referral, ViolationReport, PlacementHistory |
| `lib/src/models/value_objects/` | 3 | Cpf, Nis, Cep |
| `lib/src/api_client/` | 1 | SocialCareApiClient (Dio wrapper) |
| `lib/src/api_client/api_models/` | 5 | PatientMapper, AssessmentMappers, CareMappers, ProtectionMappers, CommonMappers |
| `lib/src/impl/` | 1 | InProcessBff (desktop) |
| `lib/src/testing/` | 1 | FakeSocialCareBff |
| `test/` | 6 | 48 testes |

### Documentacao atualizada
- `handbook/architecture/ARCHITECTURE.md` — secoes 4.2 e 7.6 (responses, value_objects, testing path)
- `IMPLEMENTATION_PLAN.md` — Fase 3 reescrita com entregaveis reais, checklist final atualizado
- `CLAUDE.md` — comando de teste BFF corrigido (`flutter test`)

## Metricas

| Metrica | Valor |
|---------|-------|
| Arquivos Dart criados | 40 |
| Testes | 48 passando |
| Warnings/Errors (analyzer) | 0 (1 info) |
| Metodos no contract | 21 |
| Domain models | 16+ |
| Request DTOs | 14 classes |
| Mapper classes | 6 |
| Value Objects | 3 (Cpf, Nis, Cep) |
| Progresso geral | ~45% (Fases 1-3 completas) |

## Conformidade com Handbook

Apos revisao contra handbook/architecture/ARCHITECTURE.md, 4 divergencias foram identificadas e corrigidas:

1. **`contract/dto/responses/`** — Criados 5 barrel files organizados por bounded context
2. **`models/value_objects/`** — Criados Cpf, Nis, Cep integrados nos domain models
3. **`api_client/api_models/`** — Extraidos parsers para 5 mapper classes separados
4. **`testing/` path** — Mantido em `lib/src/testing/` (idiomatico Dart), handbook atualizado

## Proximos Passos

1. **Fase 4 — Offline Engine:** Isar schemas, SyncQueue, SyncEngine, conflict resolution
2. **Fase 5 — Features Social Care:** 12 features MVVM (patient_registration primeiro)
3. **DartoServer (web):** Implementacao futura quando deploy web for prioridade (Fase 6)
