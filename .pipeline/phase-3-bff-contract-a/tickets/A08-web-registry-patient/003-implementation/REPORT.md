# A08 Wave 1 REPORT — Implementer (Registry Patient)

## Status: COMPLETED — 133/133 tests GREEN

## Resultado
- `test/intents/` → 56/56 GREEN
- `test/use_cases/` → 48/48 GREEN
- `test/handlers/registry_patient_handler_test.dart` → 21/21 GREEN
- `test/observability/pii_mask_test.dart` → 21/21 GREEN
- Suite canônica completa (A07 + A08 + middleware) → **255/255 GREEN**
- `dart analyze lib` no escopo A08 → **No issues found**

## Arquivos

### Intents (7 — 1 rewrite + 6 novos)
`register_patient_intent.dart` (rewrite), `list_patients_intent.dart`, `get_patient_intent.dart`, `admit_patient_intent.dart`, `discharge_patient_intent.dart`, `readmit_patient_intent.dart`, `withdraw_patient_intent.dart`

### UseCases (7 — 1 rewrite + 6 novos)
`register_patient_use_case.dart` (rewrite — saga 6 passos), list/get + 4 lifecycle

### Handler (1)
`registry_patient_handler.dart` — 7 endpoints, P1 state matrix, 404 `PATIENT_NOT_FOUND`, 400 estruturado

### Observability (1)
`pii_mask.dart` — `maskCpf` / `maskName` / `maskCns`

### Wiring (3)
`app_router.dart`, `bin/server.dart`, `social_care_web.dart`

### Auxiliar (1)
`pre_registered_family_member_dto.dart` — extraído do rewrite para manter `add_family_member_intent.dart` legacy compilável até A09

## Decisões técnicas

### Saga sem compensação (conforme política)
`RegisterPatientUseCase` implementa sealed `_PersonResolution` com `_PersonResolved` / `_PersonSkipped` / `_PersonFailed`. Early-return em `registry.registerPatient` falhar (garante `addFamilyMember` **nunca** chamado após falha). Pessoas registradas no PeopleContext antes da falha **não** são desfeitas — doc-comment documenta dívida + aponta cleanup job futuro.

### PII masking em breadcrumbs
- Campos sensíveis (`cpf`, `fullName`, `motherName`, `cns`) NUNCA em breadcrumbs
- Emito apenas: `patientId` (UUID), `memberCount`, `status`, `hasSearch`/`hasCursor` (bool), `limit`, `count`, `errorCode`
- Helper `pii_mask.dart` com 3 funções totais

### parseFromBody PII-safe
Cada intent tem `_XxxParseError` privada com mensagem **estrutural** (`"Invalid admit body: missing or empty [reason]"`) — nunca eco do valor recebido. Teste explicitamente verifica "Failure message does NOT echo raw CPF/name".

### Wiring simplificado
`AppRouter` aceita `RegistryContract` + `PeopleContract` diretamente. Pipeline protegida monta apenas `observabilityMiddleware → sessionMiddleware → RegistryPatientHandler.router`. Handlers legacy (assessment/care/health/lookup/protection/team/registry) **não** montados — app não expõe até A09+ migrar.

## Padrão canônico refinado (para A09–A15)

1. **Intents** — `Result` return + `_XxxParseError` privada com mensagens estruturais
2. **UseCases simples** — triad breadcrumb `received {patientId}` → `completed` → `failed {errorCode}`. Mutações void envolvidas em `StandardResponse<void>` com meta
3. **UseCases compostos (saga)** — sealed class para decomposição + early-return controlado. Breadcrumbs granulares sem leak PII
4. **Handler P1 state matrix** — `switch (result)` exaustivo. Helper `_extractError` mapeia `BackendError.http` → status. Non-BackendError → genérico 500
5. **"Not found" convention** — `Failure(String)` do fake vira 404 via helper `_patientNotFoundOrError` (sem eco do patientId)
6. **`readJsonBody` defensivo** — `FormatException` vira `null` → handler mapeia 400 estruturado
7. **Wiring** — factory `buildXxxHandler(contract)` por módulo em `app_router.dart`

## Débito técnico deixado (documentado)

- Handlers legacy ainda quebrados por `SocialCareContract` undefined — A09+ resolve ao migrar cada módulo
- `add_family_member_use_case.dart` legacy quebrado — A09 rewrite
- `FakeRegistryBff` + `FakePeopleBff` no `server.dart` — adapter OIDC real fica para sub-ticket A07b/A21
