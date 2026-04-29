# A12 Wave 1 REPORT — Implementer (Protection: Violation, Referral, PlacementHistory)

## Status: COMPLETED — 100/100 A12 GREEN · 590/590 A07–A12 canon GREEN · zero regression

Wave 0 pinou 86; runner reporta 100 (cada switch-case counta separado em compact mode). Zero divergência comportamental.

## Files created (6)

### Intents (3)
- `create_referral_intent.dart` — **P2** if-case, 3 required; `_CreateReferralParseError` non-const (dynamic)
- `report_rights_violation_intent.dart` — **P2** if-case, 3 required; `_ReportRightsViolationParseError` non-const (dynamic)
- `update_placement_history_intent.dart` — **P2b** try/catch, 0 top-level required; `{ObservabilityContext? obs}` opcional + `logError('protection.placement_history.parse_failed', cause, stack)`; `_UpdatePlacementHistoryParseError` const

### UseCases (3)
- `create_referral_use_case.dart` — retorna `StandardIdResponse`; ns `protection.referral.create.*`; `.completed` data `{referralId}`
- `report_rights_violation_use_case.dart` — retorna `StandardIdResponse`; ns `protection.violation.report.*`; `.received` APENAS `{patientId}`
- `update_placement_history_use_case.dart` — retorna `StandardResponse<void>`; ns `protection.placement_history.update.*`; rewrap de `Result<void>` → `Result<StandardResponse<void>>` (pattern A08 Admit)

## Files modified (3)

- `handlers/protection_handler.dart` — **REWRITE**. Legacy A05 (`contractFactory` + leaky `catch (e) { jsonError(400, 'Invalid: $e') }`) deletado. Handler condicionalmente passa `obs: obs` somente para Placement.
- `server/app_router.dart` — new `required ProtectionContract protectionContract` + `buildProtectionHandler(...)` + Cascade append (**patient → family → assessment → care → protection**)
- `bin/server.dart` — `FakeProtectionBff()` injetado

## PII pinned (verified)

- Referral: `reason`, `destinationService` — zero echo em breadcrumbs/400
- Violation: `descriptionOfFact`, `actionsTaken`, `victimId`, `violationType` — zero echo
- Placement: `homeLossReport`, `thirdPartyGuardReport`, `registries[].reason`, `memberId`, separation flags — zero echo
- 500 body: no `'leak marker'`, `'Exception:'`, `'#0'`

Markers pinados e ausentes: `SECRET_REASON_MARKER_ZZZ`, `Familia perdeu moradia`, `Conselho Tutelar`, `Jardim Catarina`, `violencia domestica`, `CREAS`, `Afastamento`, `Mae`, `8 anos`, `14/04/2026`, `agressao fisica`, `pai violento`, `PHYSICAL`, UUID fragment `11111111`, `adultInPrison`/`adolescentInInternment` keys.

## Aprendizados (novos, para A13–A15)

### 1. O carrier da decisão P2/P2b é a ASSINATURA do Intent, não o handler

O handler chama `parseFromBody(id, body)` ou `parseFromBody(id, body, obs: obs)` dependendo do Intent. Uma linha condicional, não um fork arquitetural. Isso escala sem polução do handler.

```dart
// Handler permanece uniforme:
final parsed = CreateReferralIntent.parseFromBody(id, body);           // P2
final parsed = UpdatePlacementHistoryIntent.parseFromBody(id, body, obs: obs);  // P2b
```

### 2. `.received` breadcrumb deve ter **shape estrito** — pinar com `keys.toSet()`

Teste A12 introduz novo invariante (estrela da shop):

```dart
test('.received carries patientId ONLY (no drift)', () {
  expect(received.data.keys.toSet(), equals({'patientId'}));
});
```

Motivo: shapes como `{patientId, registriesCount: 3}` passariam nos testes de substring-PII (não contém nome) mas violariam o canon canônico. Em DTOs com sub-DTOs sensíveis, **conte as chaves**.

**Recomendação**: adicionar esse pattern ao canonical de A13+ quando houver sub-DTOs PII-densos.

### 3. UseCase rewrap mantém handler simétrico

Quando contract retorna `Result<void>` mas canon handler usa `_wrapVoidResult(Result<StandardResponse<void>>)`, o UseCase faz o rewrap (padrão A08 Admit). Evita criar helper `_wrapPlainResult` dedicado para 1 rota.

### 4. Lints Camada 2 pegaram legacy logo de cara

Durante o rewrite do legacy `protection_handler.dart`, o implementer identificou o anti-pattern `catch (e) { jsonError(400, 'Invalid: $e') }` — exatamente o que ADR-019 proíbe. A Camada 2 já catcharia esse em CI agora.

## Regras invioláveis respeitadas

- [x] Zero `catch (_)` — único P2b catch é `catch (e, st)` + `obs?.logError`
- [x] Zero `throw` em domínio/UseCases
- [x] Equatable em Intents + `_XxxParseError`
- [x] P2 intents: mensagem dinâmica, non-const error
- [x] P2b intent: mensagem fixa const, `{obs}` opcional
- [x] PII hard-blocks em 3 camadas (parse error, breadcrumbs, handler body)
- [x] Lints Camada 2 clean
- [x] A07–A11 intocados
- [x] Dart 3 pattern matching (switch expressions, if-case)
- [x] Code EN / comments EN

## Validação executada

- `dart format` → 9 files formatted
- `analyze_files` A12 scope → No errors
- `run_tests` A12 (7 files) → **+100: All tests passed**
- `run_tests` canon (intents + use_cases + 6 handlers) → **+590: All tests passed**
