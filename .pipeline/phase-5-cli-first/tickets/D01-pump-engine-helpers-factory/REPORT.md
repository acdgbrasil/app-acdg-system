# D01 — PumpingSyncEngine extract + DriftExecutorFactory + helpers — REPORT

## Status: GREEN
Closed: 2026-05-02

## Pipeline executada (5 waves, 5 dispatches sem rejection rounds)

| Wave | Agent | Resultado |
|------|-------|-----------|
| W0 — Baseline | Bash direct | 426 GREEN +1 skip confirmado |
| W0.5 — RED | test-writer | 24 RED tests em 3 arquivos (705L) + 5 REGRA #2 pins |
| W0.5-bis — Fixture-fix | test-writer | 4 tests RED por fixture inválida → fix via `_ProbeDb` shim + substring catch |
| W1 — Refactor | flutter-bff-implementer | Extract sem mudar comportamento; 446 → 450 GREEN |
| W2 — Review | flutter-code-reviewer | **APPROVED Round 1/3** (zero MUST_FIX) |
| W3 — Quality | flutter-quality-checker | **PASSED** — analyze 0, format clean, 2122 GREEN total BFF |

## Padrões GoF aplicados

- **Factory Method** — `DriftExecutorFactory` (production / inMemory) encapsula decisão `:memory:` vs disk; substitui o if-else inline do legacy

## Files

### Produção (criados)
- `apps/social_care_bff/desktop/lib/src/sync/engine/pumping_sync_engine.dart` (48L) — `PumpingSyncEngine` público, ex-`_PumpingSyncEngine` privado
- `apps/social_care_bff/desktop/lib/src/facade/composition/db_executor.dart` (107L) — `abstract interface class DriftExecutorFactory` + `_ProductionFactory` + `_InMemoryFactory` + `defaultDesktopFilePath()`
- `apps/social_care_bff/desktop/lib/src/facade/composition/connectivity_helpers.dart` (13L) — `resultsAreOnline()`

### Produção (modificados)
- `apps/social_care_bff/desktop/lib/src/facade/social_care_desktop.dart` — **718L → 637L** (-81L). Removeu `_PumpingSyncEngine`, `_inMemoryMarker`, `_defaultPath`, `_openDriftExecutor`, `_resultsAreOnline`. Adicionou parâmetro opcional `DriftExecutorFactory? executorFactory` em `create()` (default `production`). Imports `dart:io`, `drift/native`, `path_provider` removidos (movidos pros novos arquivos).

### Tests (criados)
- `apps/social_care_bff/desktop/test/facade/composition/db_executor_test.dart` (303L, 11 tests, 4 com REGRA #2 exception comments)
- `apps/social_care_bff/desktop/test/facade/composition/connectivity_helpers_test.dart` (100L, 7 tests)
- `apps/social_care_bff/desktop/test/sync/engine/pumping_sync_engine_test.dart` (302L, 6 tests)

## REGRA #2 exceptions (W0.5-bis)

4 tests fixados por **fixture inválida** (não regressão do refactor — W1 verificou empiricamente que impl é byte-idêntica ao legacy):

| Test | Problema | Fix |
|------|----------|-----|
| #5 | `LazyDatabase.runCustom()` direto sem `ensureOpen()` → `LateInitializationError` | Wrap em `_ProbeDb extends GeneratedDatabase` que dispara handshake |
| #6 | Idem | Idem |
| #10 | Catch específico `MissingPluginException`, mas `flutter test` raise `FlutterError("Binding not initialized")` antes | `on Object catch (e)` + substring `'plugin' \|\| 'Binding' \|\| 'initialized'` (matching legacy `social_care_desktop_test.dart:455-505`) |
| #11 | Idem | Idem |

REGRA #2 exception comments adicionados em cada teste explicando: failure mode + production reference + intent preserved.

## 5 REGRA #2 pins do W0.5 — todos honored em W1

| Pin | Status |
|-----|--------|
| `:memory:` marker preservation | ✅ `_ProductionFactory.open(':memory:')` delega pra `_InMemoryFactory.open(':memory:')` |
| Empty-list semantics em `resultsAreOnline` | ✅ `results.any((r) => r != none)` → false p/ `[]` natural |
| Failure pump policy | ✅ switch preservado: Success pumps, Failure breaks |
| Closed-controller branch | ✅ `if (!_drainController.isClosed) _drainController.add(value)` preservado |
| `MissingPluginException` gate | ✅ impl byte-idêntica; tests broadenados pra cobrir realidade do flutter test |

## Test counts

- Antes D01 (após C00): 2098 GREEN +1 skip (535 contracts + 1137 web + 426 desktop)
- Após D01: **2122 GREEN +1 skip** (535 contracts + 1137 web + **450** desktop)
- Delta: **+24 desktop tests** (24 new from W0.5)

## Architectural choices APROVADAS (W2)

1. **`_ProductionFactory` delega `:memory:` para `_InMemoryFactory.open()`** — uma extra hop em troca de ownership limpo (marker-handling co-located with factory map)
2. **`abstract interface class DriftExecutorFactory`** — H9 cross-layer; tests confirmam external implementability
3. **`defaultDesktopFilePath` como free function** — não acoplada a `DriftExecutorFactory` (orthogonal concerns)
4. **No barrel changes** — novos types stay internal; tests reach via `package:social_care_desktop/src/...`

## SHOULD_FIX (não bloqueiam — para D02/D03)

1. Move `_ProbeDb` para `test/_test_helpers/probe_db.dart` (D02/D03 podem reusar)
2. Cross-link no docstring de `social_care_desktop.dart` para `pumping_sync_engine.dart`

## NICE_TO_HAVE (catalogados para futuro)

1. Barrel re-export de `DriftExecutorFactory` se consumers externos precisarem injetar custom factory
2. Convert `PumpingSyncEngine` para Decorator-via-composition quando D6 lands
3. Split `db_executor.dart` em + `desktop_paths.dart` se mais path helpers acresecerem

## Próximo

**D02 — UseCases Builders por Bounded Context**. Cria 7 builders (`RegistryUseCases`, `AssessmentUseCases`, etc.) agrupando os 42 use cases. Reduz `social_care_desktop.dart` de 637L para ~350L.

## Comandos de verificação

```bash
# Analyze
dart analyze apps/social_care_bff/desktop/lib/  # No issues found!

# Format check
dart format --output=none --set-exit-if-changed apps/social_care_bff/desktop/lib/  # exit 0

# Tests
cd apps/social_care_bff/desktop && flutter test  # 450 GREEN +1 skip

# Cross-package non-regression
cd apps/social_care_bff/contracts && flutter test  # 535 GREEN
cd apps/social_care_bff/web && flutter test         # 1137 GREEN
```
